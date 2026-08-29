//! Focused-display brightness for KDE Plasma 6 hardware keys.
//!
//! Inspired by llIlllIll's script on KDE Discuss:
//! <https://discuss.kde.org/t/plasma-6-2-brightness-control/21782/4>
//!
//! Extensions beyond that script: hold-to-repeat stepping (detached worker process,
//! evdev key-state tracking for clean single taps), target-display caching for fast
//! repeats, and typed D-Bus calls via zbus.
//!
//! KDE global shortcuts fire once per physical press; they do not re-fire on keyboard
//! repeat. The worker watches `/dev/input` for the brightness key staying down and
//! ramps at the kernel auto-repeat rate.

use anyhow::{Context, Result, bail};
use evdev::{Device, EventSummary, KeyCode};
use fs2::FileExt;
use std::env;
use std::fs::{self, File, OpenOptions};
use std::io::Read;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::thread;
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};
use zbus::blocking::Connection;
use zbus::zvariant::OwnedValue;

const SCREEN_BRIGHTNESS_SERVICE: &str = "org.kde.ScreenBrightness";
const SCREEN_BRIGHTNESS_ROOT: &str = "/org/kde/ScreenBrightness";
const DISPLAY_INTERFACE: &str = "org.kde.ScreenBrightness.Display";
const KWIN_SERVICE: &str = "org.kde.KWin";
const KWIN_PATH: &str = "/KWin";
const KWIN_INTERFACE: &str = "org.kde.KWin";
const PROPERTIES_INTERFACE: &str = "org.freedesktop.DBus.Properties";
const WORKER_ENV: &str = "PLASMA_FOCUSED_BRIGHTNESS_WORKER";

const DEFAULT_REPEAT_DELAY: Duration = Duration::from_millis(600);
const DEFAULT_REPEAT_INTERVAL: Duration = Duration::from_millis(40);
const TARGET_CACHE_TTL: Duration = Duration::from_millis(2000);
const DEFAULT_STEP_PERCENT: u32 = 5;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Direction {
    Up,
    Down,
}

impl Direction {
    fn parse(s: &str) -> Result<Self> {
        match s {
            "up" => Ok(Self::Up),
            "down" => Ok(Self::Down),
            _ => bail!("invalid direction {s:?}; use 'up' or 'down'"),
        }
    }

    fn brightness_key(self) -> KeyCode {
        match self {
            Self::Up => KeyCode::KEY_BRIGHTNESSUP,
            Self::Down => KeyCode::KEY_BRIGHTNESSDOWN,
        }
    }
}

#[derive(Debug, Clone)]
struct Config {
    step_percent: u32,
    state_dir: PathBuf,
}

impl Config {
    fn for_session() -> Self {
        let runtime_dir = env::var("XDG_RUNTIME_DIR")
            .map(PathBuf::from)
            .unwrap_or_else(|_| PathBuf::from("/tmp"));
        Self {
            step_percent: DEFAULT_STEP_PERCENT,
            state_dir: runtime_dir.join("plasma-focused-brightness"),
        }
    }
}

fn now_ms() -> u128 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_millis())
        .unwrap_or(0)
}

fn read_stamp(path: &Path) -> u128 {
    fs::read_to_string(path)
        .ok()
        .and_then(|s| s.trim().parse().ok())
        .unwrap_or(0)
}

fn value_to_u32(value: &OwnedValue) -> Result<u32> {
    value
        .downcast_ref::<u32>()
        .or_else(|_| value.downcast_ref::<i32>().map(|v| v.max(0) as u32))
        .or_else(|_| value.downcast_ref::<u16>().map(u32::from))
        .or_else(|_| value.downcast_ref::<u8>().map(u32::from))
        .context("expected numeric dbus value")
}

fn value_to_bool(value: &OwnedValue) -> Result<bool> {
    value
        .downcast_ref::<bool>()
        .context("expected bool dbus value")
}

fn value_to_string(value: &OwnedValue) -> Result<String> {
    value
        .downcast_ref::<String>()
        .context("expected string dbus value")
}

fn get_root_prop(connection: &Connection, prop: &str) -> Result<OwnedValue> {
    connection
        .call_method(
            Some(SCREEN_BRIGHTNESS_SERVICE),
            SCREEN_BRIGHTNESS_ROOT,
            Some(PROPERTIES_INTERFACE),
            "Get",
            &(SCREEN_BRIGHTNESS_SERVICE, prop),
        )
        .with_context(|| format!("Get {prop} from ScreenBrightness"))?
        .body()
        .deserialize()
        .context("deserialize ScreenBrightness property")
}

fn get_display_prop(connection: &Connection, display: &str, prop: &str) -> Result<OwnedValue> {
    let path = format!("{SCREEN_BRIGHTNESS_ROOT}/{display}");
    connection
        .call_method(
            Some(SCREEN_BRIGHTNESS_SERVICE),
            path.as_str(),
            Some(PROPERTIES_INTERFACE),
            "Get",
            &(DISPLAY_INTERFACE, prop),
        )
        .with_context(|| format!("Get {prop} for {display}"))?
        .body()
        .deserialize()
        .context("deserialize display property")
}

fn value_to_string_list(value: &OwnedValue) -> Result<Vec<String>> {
    value
        .try_clone()
        .context("clone dbus value")?
        .try_into()
        .context("expected string list dbus value")
}

fn set_brightness(connection: &Connection, display: &str, value: u32) -> Result<()> {
    let path = format!("{SCREEN_BRIGHTNESS_ROOT}/{display}");
    connection
        .call_method(
            Some(SCREEN_BRIGHTNESS_SERVICE),
            path.as_str(),
            Some(DISPLAY_INTERFACE),
            "SetBrightness",
            &((value as i32), 0u32),
        )
        .with_context(|| format!("SetBrightness for {display}"))?
        .body()
        .deserialize::<()>()
        .context("deserialize SetBrightness reply")
}

fn active_output_name(connection: &Connection) -> Result<String> {
    connection
        .call_method(
            Some(KWIN_SERVICE),
            KWIN_PATH,
            Some(KWIN_INTERFACE),
            "activeOutputName",
            &(),
        )
        .context("activeOutputName")?
        .body()
        .deserialize()
        .context("deserialize activeOutputName")
}

fn display_names(connection: &Connection) -> Result<Vec<String>> {
    value_to_string_list(&get_root_prop(connection, "DisplaysDBusNames")?)
}

fn read_edid_for_output(output: &str) -> Option<String> {
    let suffix = format!("-{output}");
    let path = fs::read_dir("/sys/class/drm")
        .ok()?
        .filter_map(Result::ok)
        .map(|entry| entry.path())
        .find(|path| {
            path.file_name()
                .and_then(|name| name.to_str())
                .is_some_and(|name| name.ends_with(&suffix))
        })?
        .join("edid");
    if !path.is_file() {
        return None;
    }
    let mut bytes = Vec::new();
    File::open(path).ok()?.read_to_end(&mut bytes).ok()?;
    Some(
        bytes
            .into_iter()
            .filter(|b| (32..=126).contains(b))
            .map(|b| b as char)
            .collect(),
    )
}

fn best_edid_match(displays: &[String], edid_text: &str, connection: &Connection) -> Result<Option<String>> {
    let mut best_match = None;
    let mut highest_score = 0usize;
    let edid_lower = edid_text.to_ascii_lowercase();

    for display in displays {
        if value_to_bool(&get_display_prop(connection, display, "IsInternal")?)? {
            continue;
        }

        let label = value_to_string(&get_display_prop(connection, display, "Label")?)?;
        let words: Vec<&str> = label.split_whitespace().collect();
        let mut substring = String::new();
        let mut current_match_len = 0usize;

        for word in words.iter().rev() {
            if substring.is_empty() {
                substring = (*word).to_string();
            } else {
                substring = format!("{word} {substring}");
            }

            if edid_lower.contains(&substring.to_ascii_lowercase()) {
                current_match_len = substring.len();
            } else {
                break;
            }
        }

        if current_match_len > highest_score {
            highest_score = current_match_len;
            best_match = Some(display.clone());
        }
    }

    Ok(if highest_score > 0 {
        best_match
    } else {
        None
    })
}

fn resolve_target_display(connection: &Connection, config: &Config) -> Result<Option<String>> {
    fs::create_dir_all(&config.state_dir)?;
    let cache_file = config.state_dir.join("target-display");
    let cache_stamp = config.state_dir.join("target-display.stamp");

    if cache_file.is_file() && cache_stamp.is_file() {
        let cached_at = read_stamp(&cache_stamp);
        if now_ms().saturating_sub(cached_at) < TARGET_CACHE_TTL.as_millis() {
            return Ok(Some(fs::read_to_string(&cache_file)?.trim().to_string()));
        }
    }

    let displays = display_names(connection)?;
    if displays.is_empty() {
        return Ok(None);
    }

    let active_output = active_output_name(connection).unwrap_or_default();
    let target = if active_output.starts_with("eDP") || active_output.starts_with("LVDS") {
        displays
            .iter()
            .find(|display| {
                get_display_prop(connection, display, "IsInternal")
                    .ok()
                    .and_then(|value| value_to_bool(&value).ok())
                    .unwrap_or(false)
            })
            .cloned()
    } else if !active_output.is_empty() {
        read_edid_for_output(&active_output)
            .and_then(|edid| best_edid_match(&displays, &edid, connection).ok().flatten())
    } else {
        None
    }
    .or_else(|| displays.first().cloned());

    if let Some(ref name) = target {
        fs::write(&cache_file, name)?;
        fs::write(&cache_stamp, now_ms().to_string())?;
    }

    Ok(target)
}

fn adjust_brightness_once(
    connection: &Connection,
    config: &Config,
    direction: Direction,
) -> Result<()> {
    let Some(display) = resolve_target_display(connection, config)? else {
        return Ok(());
    };

    let current = value_to_u32(&get_display_prop(connection, &display, "Brightness")?)?;
    let max = value_to_u32(&get_display_prop(connection, &display, "MaxBrightness")?)?;
    if max == 0 {
        return Ok(());
    }

    let mut step = max.saturating_mul(config.step_percent) / 100;
    if step == 0 {
        step = 1;
    }

    let new_val = match direction {
        Direction::Up => current.saturating_add(step).min(max),
        Direction::Down => current.saturating_sub(step),
    };

    set_brightness(connection, &display, new_val)
}

fn open_brightness_devices(key: KeyCode) -> Vec<Device> {
    let Ok(entries) = fs::read_dir("/dev/input") else {
        return Vec::new();
    };

    entries
        .filter_map(Result::ok)
        .map(|entry| entry.path())
        .filter(|path| {
            path.file_name()
                .and_then(|name| name.to_str())
                .is_some_and(|name| name.starts_with("event"))
        })
        .filter_map(|path| Device::open(path).ok())
        .filter(|device| {
            device
                .supported_keys()
                .is_some_and(|keys| keys.contains(key))
        })
        .collect()
}

fn key_is_pressed(devices: &[Device], key: KeyCode) -> bool {
    devices.iter().any(|device| {
        device
            .get_key_state()
            .ok()
            .is_some_and(|keys| keys.contains(key))
    })
}

fn repeat_timing(devices: &[Device]) -> (Duration, Duration) {
    let Some(repeat) = devices.iter().find_map(|device| device.get_auto_repeat()) else {
        return (DEFAULT_REPEAT_DELAY, DEFAULT_REPEAT_INTERVAL);
    };

    let delay = Duration::from_millis(repeat.delay.max(1) as u64);
    let interval = Duration::from_millis(repeat.period.max(1) as u64);
    (delay, interval)
}

fn spawn_hold_repeat_worker(direction: Direction) -> Result<()> {
    // Re-exec the same binary so the worker inherits argv and session env.
    let program = env::args()
        .next()
        .context("missing argv0 for hold-repeat worker")?;
    Command::new(program)
        .env(WORKER_ENV, "1")
        .arg(direction_label(direction))
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn()
        .context("spawn hold-repeat worker")?;
    Ok(())
}

fn run_hold_repeat_worker(connection: &Connection, config: &Config, direction: Direction) -> Result<()> {
    let lock_file = config
        .state_dir
        .join(format!("{}.repeat.lock", direction_label(direction)));

    let lock = OpenOptions::new()
        .create(true)
        .write(true)
        .open(&lock_file)
        .with_context(|| format!("open {}", lock_file.display()))?;
    if lock.try_lock_exclusive().is_err() {
        return Ok(());
    }

    let key = direction.brightness_key();
    let mut devices = open_brightness_devices(key);
    if devices.is_empty() {
        return Ok(());
    }

    for device in &devices {
        let _ = device.set_nonblocking(true);
    }

    // Tap finished before the worker started: nothing more to do.
    if !key_is_pressed(&devices, key) {
        return Ok(());
    }

    let (repeat_delay, repeat_interval) = repeat_timing(&devices);
    let started = Instant::now();
    let mut last_ramp = started;
    let mut repeat_armed = false;

    loop {
        for device in &mut devices {
            let Ok(mut events) = device.fetch_events() else {
                continue;
            };
            for event in events.by_ref() {
                if let EventSummary::Key(_, code, value) = event.destructure() {
                    if code != key {
                        continue;
                    }
                    match value {
                        0 => return Ok(()),
                        2 => {
                            let _ = adjust_brightness_once(connection, config, direction);
                            last_ramp = Instant::now();
                            repeat_armed = true;
                        }
                        1 => {}
                        _ => {}
                    }
                }
            }
        }

        if !key_is_pressed(&devices, key) {
            return Ok(());
        }

        let now = Instant::now();
        if !repeat_armed && now.duration_since(started) >= repeat_delay {
            repeat_armed = true;
            last_ramp = now;
        }

        if repeat_armed && now.duration_since(last_ramp) >= repeat_interval {
            let _ = adjust_brightness_once(connection, config, direction);
            last_ramp = now;
        }

        thread::sleep(Duration::from_millis(5));
    }
}

fn direction_label(direction: Direction) -> &'static str {
    match direction {
        Direction::Up => "up",
        Direction::Down => "down",
    }
}

fn main() -> Result<()> {
    let direction = Direction::parse(
        env::args()
            .nth(1)
            .context("usage: plasma-focused-brightness up|down")?
            .as_str(),
    )?;
    let config = Config::for_session();

    if env::var(WORKER_ENV).is_ok() {
        let connection = Connection::session().context("connect to session bus")?;
        return run_hold_repeat_worker(&connection, &config, direction);
    }

    let connection = Connection::session().context("connect to session bus")?;
    adjust_brightness_once(&connection, &config, direction)?;
    spawn_hold_repeat_worker(direction)?;
    Ok(())
}
