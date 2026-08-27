# Telegram Desktop crashes on Plasma Wayland (fw13)

**Problem**: Telegram on account `user` exits suddenly on Plasma Wayland. No coredump for this failure mode — process exits with `status=255/EXCEPTION`.

**Host / stack (observed 2026-08-27)**:
- fw13, Plasma 6.7.4 Wayland, Mesa 26.2.1, AMD Radeon 780M
- Package: firejail-wrapped `telegram-desktop` via `cleanPkg` (unsets `LD_PRELOAD` / graphene hardened-malloc)
- Binary path ends at `.Telegram-wrapped` under nix store

## What killed it (2026-08-27 ~17:57)

Not OOM, not firejail, not the old hardened-malloc allocator abort.

Journal smoking gun:

```text
wl_fixes#40: error 0: the given registry did not announce global 73
warning: queue "mesa egl surface queue" ... destroyed while proxies still attached:
  wp_presentation#39 still attached
Could not create EGL surface (EGL error 0x3000)
The Wayland connection experienced a fatal error: Protocol error
dbus-:1.2-org.telegram.desktop@0.service: Main process exited, code=exited, status=255/EXCEPTION
```

Right before that: `libvpx-vp9` decode + `[RENDERER_TEST] component=overlay ... status=OK` — media/overlay OpenGL path.

**Meaning**: `wl_fixes` error `0` = `invalid_ack_remove`. Client acked removal of global `#73` that was never announced (or not in removed state) on that registry. Wayland protocol errors disconnect the whole client; Qt then dies. Mesa EGL / `wp_presentation` lines are teardown fallout.

## Why this exists (upstream)

- `wl_fixes` is a new Wayland fix for races when globals (often outputs) are removed; clients must `ack_global_remove` correctly or get disconnected.
  - [Vlad Zahorodnii — Addressing global removal race in Wayland](https://blog.vladzahorodnii.com/2026/03/24/addressing-global-removal-race-in-wayland/)
- Plasma **6.7.4** added compositor support: “Add support for wl_fixes.ack_global_remove” ([changelog](https://kde.org/announcements/changelogs/plasma/6/6.7.3-6.7.4/)).
- Same Qt/Telegram symptom class on Wayland (media viewer / second open / protocol error):
  - [tdesktop#30100](https://github.com/telegramdesktop/tdesktop/issues/30100)
  - [tdesktop#30435](https://github.com/telegramdesktop/tdesktop/issues/30435)
  - Older similar: [tdesktop#26907](https://github.com/telegramdesktop/tdesktop/issues/26907) (`EGL error 0x3000` + fatal Wayland protocol error)

## Separate / older failure mode

Hard SEGV-style dumps under `/var/lib/systemd/coredump/core.*Telegram-wrapp.*` (e.g. Aug 15–25 2026). Config already notes another historical killer:

```nix
# modules/desktop-full.nix
progs.telegram # fatal allocator error: sized deallocation mismatch (small)
```

mitigated by wrapping with `cleanPkg` (`--unset LD_PRELOAD`). That is **not** what happened on 2026-08-27.

## How to collect logs

```bash
# Telegram app log
tail -n 200 ~/.local/share/TelegramDesktop/log.txt
ls -lt ~/.local/share/TelegramDesktop/DebugLogs/ 2>/dev/null | head

# User journal (this is where the Wayland kill shows up)
journalctl --user --since '1 hour ago' --no-pager | rg -i 'telegram|firejail|wayland|egl|wl_fixes|protocol error|allocator|killed'
journalctl _UID="$(id -u)" --since '1 hour ago' --no-pager | rg -i 'telegram|wl_fixes|protocol error'

# Hard crashes (coredumps) — may be empty for protocol-error exits
coredumpctl list Telegram
ls -lt /var/lib/systemd/coredump/*Telegram* 2>/dev/null

# Optional: reproduce with Wayland protocol trace
WAYLAND_DEBUG=1 Telegram 2>~/telegram-wayland-debug.txt
```

## Workarounds

1. Telegram → Settings → Advanced → disable **Enable OpenGL rendering for media**
2. Force X11/XWayland: `QT_QPA_PLATFORM=xcb Telegram`
3. Longer-term: newer Qt / Telegram / Mesa / KWin once `wl_fixes` ack handling settles between client and compositor

## Repo touchpoints

- `modules/desktop-full.nix` — `den.aspects.telegram` (firejail wrap + `Telegram.local` portal/whitelist bits)
- `nixos/include.nix` — `cleanPkg` / `hardenedPkg` (`LD_PRELOAD` graphene hardened-malloc)
