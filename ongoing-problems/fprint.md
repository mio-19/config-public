# fprint Issues Tracker

## Issue 1: tmux over SSH doesn't skip fprintd for sudo
**Problem**: The SSH PAM bypass rule fails when running `sudo` inside a `tmux` session over SSH, causing the system to wait for a physical fingerprint instead of falling back to password immediately.
**How to collect logs**:
```bash
journalctl | grep pam_fprintd
journalctl -u sshd.service -b
```

## Issue 2: KDE Plasma Lockscreen Unlock (intermittent after suspend)

**Problem**: Fingerprint unlock on Plasma works sometimes and fails sometimes (especially after suspend/resume). Password unlock still works.

### How to collect logs
```bash
# one-shot dump (no need to re-lock)
{
  echo '=== fprintd status ==='
  systemctl status fprintd.service --no-pager -l
  echo '=== fprintd journal (this boot) ==='
  journalctl -u fprintd.service -b --no-pager
  echo '=== kscreenlocker / pam (this boot) ==='
  journalctl -b -t kscreenlocker_greet --no-pager
  journalctl -b --no-pager | grep -Ei 'fprint|pam_fprintd|kscreenlocker|fingerprint|goodix'
  echo '=== device + enrollments ==='
  lsusb | grep -Ei 'goodix|synaptics|fingerprint|27c6|06cb'
  fprintd-list "$USER"
  echo '=== PAM stacks ==='
  ls /etc/pam.d/ | grep -E 'kde|fprint'
  for f in /etc/pam.d/kde /etc/pam.d/kde-fingerprint /etc/pam.d/login; do
    [ -e "$f" ] && echo "----- $f -----" && cat "$f"
  done
} | tee ~/fprint-lockscreen-logs.txt
```

Live follow while reproducing:
```bash
journalctl -u fprintd.service -t kscreenlocker_greet -f
```

### What we saw (fw13, 2026-08-05)
* **Hardware OK**: Goodix `27c6:609c` present; `fprintd-list` showed enrolled left/right index fingers.
* **`fprintd` idle/`inactive` is normal** (D-Bus on-demand); not proof of failure by itself.
* **PAM path OK for Plasma**: unlock uses `kde` (password, `fprintAuth = false` on purpose) and `kde-fingerprint` (has `pam_fprintd`). Matches nixpkgs `plasma6.nix`.
* **Failures clustered on resume**: around wake, journal showed the old `fprintd-resume` unit + `pam_unix(...): conversation failed` on `kde` / `kde-fingerprint`; successful unlock later was password-only (`kde` + kwallet).
* **Same `kscreenlocker_greet` PID across suspend** (e.g. started ~00:23, still that PID at ~01:08) — greeter survived sleep with a stale `pam_fprintd` D-Bus connection after `fprintd` stopped/restarted ([nixpkgs#432276](https://github.com/NixOS/nixpkgs/issues/432276)).
* **Noise (not the intermittent bug)**: `pam_succeed_if(kde-fingerprint:auth): incomplete condition detected` from flake CVE patch `fprintd_sudo_only_tty` (NixOS brackets spaced args; rule still `default=ignore` so it should not skip `pam_fprintd`). `pam_zfs_key` / `pam_kwallet5` lines are unrelated.

### What we saw (fw13, 2026-08-05 later — unlock failed again)
* Greeter PID **9808** survived lock → suspend → resume → failed fprint → second sleep → password unlock.
* Wake race: greeter mid-`pam_fprintd` while `fprintd-sleep` ExecStop restarted the daemon → `fprintd name owner changed during operation!` / `ReleaseDevice failed`.
* **Broken recycle**: `pkill -TERM -x kscreenlocker_greet` never matches (Linux `comm` is 15 chars; name is 19). Need `pkill -f` ([pkill(1)](https://man.archlinux.org/man/pkill.1); same as Discourse / [nixpkgs#432276](https://github.com/NixOS/nixpkgs/issues/432276) workarounds).
* Stop-before-sleep alone is not enough on Framework 13 (also reported on that issue); greeter must actually die and respawn.

### What we saw (fw13, 2026-09-07 — all modes failed; root cause from source)
* **Hardware confirmed**: `lspci -D | grep -i xhci` → **empty** (no xHCI controller visible). USB rebind approach is inapplicable on this machine.
* **Sensor stays on USB**: `lsusb | grep 27c6` → `Bus 001 Device 003: ID 27c6:609c` visible after resume. USB device disappearance is NOT the failure mode.
* **Root cause confirmed via kscreenlocker source** (`pamauthenticator.cpp`):
  * `m_unavailable = true` is set when PAM returns `WorkerResult::Unavailable` or after >3 rapid failures within 2 seconds. Once set, `tryUnlock()` returns immediately — fingerprint is silently disabled for that greeter lifetime.
  * `busctl status net.reactivated.Fprint` (D-Bus name visible) fires ~500ms **before** fprintd finishes USB device enumeration. A fresh greeter started at this point calls pam_fprintd → `WorkerResult::Unavailable` → `m_unavailable=true` in the new greeter too.
  * This is why `delay_restart` failed: the greeter recycle happened at the right time but fprintd wasn't truly device-ready yet.
* **`ksldapp` auto-respawns greeter** (`ksldapp.cpp` line ~207): when `kscreenlocker_greet` exits (including via SIGTERM), `ksldapp` starts a fresh one — `pkill -TERM -f kscreenlocker_greet` is the correct mechanism, but timing is critical.

### What we did (2026-09-07)
* **New `greeter_recycle` mode** in `modules/common.nix` + `modules/options.nix`:
  - **System service `fprintd-pre-sleep`** (`sleep.target`, `WantedBy`/`Before`, `StopWhenUnneeded`, `RemainAfterExit`): ExecStart stops fprintd before sleep; ExecStop restarts it after resume. Does NOT kill the greeter — that is the user service's job.
  - **User service `fprintd-greeter-recycle`** (`systemd.user.services`): runs after resume in the login session. Polls `net.reactivated.Fprint.Manager.GetDefaultDevice` via `gdbus call` (not just D-Bus name presence) until it returns an object path (device enumerated and ready). Then `pkill -TERM -f kscreenlocker_greet`. `ksldapp` respawns the greeter into a ready fprintd.
  - `GetDefaultDevice` returning an object path (not an error) is the correct readiness signal — confirms the device is enumerated and fprintd can accept PAM sessions. Name-only presence is insufficient.
* **Enabled `den.aspects.fprint-fix`** in `modules/common.nix`: libfprint USB serial retry patch (3 attempts, exponential backoff) for Goodix and Synaptics drivers. Reduces probe failures when fprintd restarts after resume.
* **fw13 set to `greeter_recycle`** in `modules/hosts/fw13/_nixos/default.nix`.

### Known Workarounds (Currently in Repo)
* **Disabled fprintAuth** on `login` / `kde` / `passwd` (`modules/desktop-basic.nix`); `polkit-1` follows `services.fprintd.enable`. Plasma fingerprint goes through `kde-fingerprint`.
* **`pam_fprintd timeout=60 max-tries=3`** on `kde-fingerprint` (`modules/desktop-basic.nix`): extends the fingerprint window.
* **Suspend/resume** ([nixpkgs#432276](https://github.com/NixOS/nixpkgs/issues/432276)): `greeter_recycle` mode — `fprintd-pre-sleep` (system) + `fprintd-greeter-recycle` (user). Uses `GetDefaultDevice` readiness check before greeter recycle (`modules/common.nix`).
* **libfprint USB serial retry patch**: `den.aspects.fprint-fix` enabled in `modules/common.nix` (`wvhulle` kill-without-clean, rebased on v1.94.10).
* **SSH sudo bypass**: `modules/sudo-fprint-ssh-bypass.nix` (works for normal SSH, fails in tmux).

### Issue 2b: Fingerprint prompt disappears / times out (no suspend involved)

**Problem**: Even without suspend/resume, the lock screen's fingerprint option times out and vanishes before the user scans.

**What we saw (fw13, 2026-08-05 ~21:21)**:
* No suspend/resume since 18:48. fprintd was idle (auto-deactivated at ~20:08).
* Locked screen at ~21:21. Journal shows **only `kde` PAM** at 21:21:36 (password unlock). Zero `kde-fingerprint` entries visible at unlock time.
* Locked again at ~21:25. `kde-fingerprint` PAM fired, fprintd started on demand, fingerprint worked.

**Root cause (from KDE source analysis)**:
* `kscreenlocker_greet` is **spawned fresh per-lock** (not persistent). It always starts all three PAM authenticators (`kde`, `kde-fingerprint`, `kde-smartcard`) in parallel immediately on lock (since Plasma 6.3, [MR !163](https://invent.kde.org/plasma/kscreenlocker/-/merge_requests/163)).
* `pam_fprintd` has a **~30 second timeout**. If the user doesn't scan within that window, `pam_authenticate()` returns failure, and kscreenlocker marks fingerprint as `m_unavailable = true` via `PamAuthenticator` ([pamauthenticator.cpp](https://invent.kde.org/plasma/kscreenlocker/-/blob/master/greeter/pamauthenticator.cpp)).
* The 21:21 failure was likely the fingerprint option timing out before the user reached the lock screen, not a stale greeter.
* [KDE Bug 506567](https://bugs.kde.org/show_bug.cgi?id=506567) — fingerprint prompt deactivates after a moment (RESOLVED FIXED, commit `1cccd29c`). Included in Plasma 6.7.3 (our version). Fixes unlock delay, **not** the timeout-before-scan.
* [KDE Bug 469951](https://bugs.kde.org/show_bug.cgi?id=469951) — fingerprint errors if you don't scan promptly.
* [Fedora discussion](https://discussion.fedoraproject.org/t/fingerprint-kde-plasma-6-3-problem-with-unlock-computer/144842) — fingerprint only works for seconds after locking.

**Workaround**: Pressing Enter on an empty password field restarts the PAM conversation and re-triggers non-interactive authenticators (fingerprint). This may bring back the fingerprint prompt.

**Still open**: The ~30s `pam_fprintd` timeout means if you don't scan within that window after locking, fingerprint silently becomes unavailable. No upstream fix yet. Plasma version: 6.7.3 (kscreenlocker 6.7.3, nixpkgs-unstable `e72e4f299401`).

### Framework 13 specific: USB controller notes

On the fw13 AMD Ryzen AI 300: `lspci -D | grep -i xhci` returns **empty** — there is no separately-visible xHCI PCI controller. The Goodix sensor (`Bus 001 Device 003: ID 27c6:609c`) stays on USB after suspend — USB disappearance is NOT the failure mode on this machine. xHCI rebind workarounds are not applicable here.

For other Framework 13 variants (e.g. AMD Ryzen 7040 Series) that do show an xHCI controller and lose the sensor on resume, the unbind/rebind approach may help:
```bash
# Example PCI address — verify on your machine first with lspci -D | grep xHCI
echo "$PCI_ADDR" > /sys/bus/pci/drivers/xhci_hcd/unbind
sleep 2
echo "$PCI_ADDR" > /sys/bus/pci/drivers/xhci_hcd/bind
sleep 3
systemctl restart fprintd.service
```
Tracked at [FrameworkComputer/SoftwareFirmwareIssueTracker#102](https://github.com/FrameworkComputer/SoftwareFirmwareIssueTracker/issues/102). One user reported changing BIOS TPM Operation to "No operation" fixed it.

If fingerprint still fails after resume: check `lsusb` for Goodix drop-off / USB autosuspend. Manual greeter recycle: `pkill -TERM -f kscreenlocker_greet`.
