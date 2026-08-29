//! Focused-display brightness for KDE Plasma 6 hardware keys.
//!
//! Inspired by llIlllIll's script on KDE Discuss:
//! <https://discuss.kde.org/t/plasma-6-2-brightness-control/21782/4>
//!
//! Extensions beyond that script: hold-to-repeat stepping (detached worker process,
//! hold-delay debounce for clean single taps), target-display caching for fast
//! repeats, and typed D-Bus calls via zbus.
//!
//! Hold-repeat keeps a detached worker alive while KDE re-fires the global shortcut
//! on keyboard repeat (System Settings → Keyboard → Key repeat). Each refire runs a
//! new parent process that applies one step; the worker only holds the repeat lock.

use anyhow::{Context, Result, bail};
use fs2::FileExt;
use std::env;
use std::fs::{self, File, OpenOptions};
use std::io::Read;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::thread;
use std::time::{Duration, SystemTime, UNIX_EPOCH};
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

const REPEAT_GRACE: Duration = Duration::from_millis(700);
const POLL_INTERVAL: Duration = Duration::from_millis(30);
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

fn touch_stamp(path: &Path) -> Result<u128> {
    fs::create_dir_all(
        path.parent()
            .context("stamp path must have a parent directory")?,
    )?;
    let stamp = now_ms();
    fs::write(path, stamp.to_string())?;
    Ok(stamp)
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

fn run_hold_repeat_worker(_connection: &Connection, config: &Config, direction: Direction) -> Result<()> {
    let stamp_file = config
        .state_dir
        .join(format!("{}.stamp", direction_label(direction)));
    let lock_file = config
        .state_dir
        .join(format!("{}.repeat.lock", direction_label(direction)));

    let lock = OpenOptions::new()
        .create(true)
        .write(true)
        .open(&lock_file)
        .with_context(|| format!("open {}", lock_file.display()))?;
    if lock.try_lock_exclusive().is_err() {
        // Another instance is already handling hold-repeat for this direction.
        return Ok(());
    }

    // Keep the lock alive while KDE re-fires the shortcut (system key-repeat delay).
    // Each refire is a new parent process that adjusts once; we only track stamp updates.
    let mut last_stamp = read_stamp(&stamp_file);

    loop {
        let stamp = read_stamp(&stamp_file);
        let now = now_ms();

        if now.saturating_sub(stamp) > REPEAT_GRACE.as_millis() {
            break;
        }

        if stamp != last_stamp {
            last_stamp = stamp;
        }

        thread::sleep(POLL_INTERVAL);
    }

    Ok(())
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

    let stamp_file = config
        .state_dir
        .join(format!("{}.stamp", direction_label(direction)));
    touch_stamp(&stamp_file)?;

    let connection = Connection::session().context("connect to session bus")?;
    adjust_brightness_once(&connection, &config, direction)?;
    spawn_hold_repeat_worker(direction)?;
    Ok(())
}
