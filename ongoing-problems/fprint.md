# fprint Issues Tracker

## Issue 1: tmux over SSH doesn't skip fprintd for sudo
**Problem**: The SSH PAM bypass rule fails when running `sudo` inside a `tmux` session over SSH, causing the system to wait for a physical fingerprint instead of falling back to password immediately.
**How to collect logs**:
```bash
journalctl | grep pam_fprintd
journalctl -u sshd.service -b
```
**Status**: Still open. Bypass lives in `modules/sudo-fprint-ssh-bypass.nix` (works for normal SSH).

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
  echo '=== fprintd-sleep (resume workaround) ==='
  systemctl status fprintd-sleep.service --no-pager -l || true
  systemctl status fprintd-sleep-v2.service --no-pager -l || true
  systemctl status fprintd-sleep-rearm.service --no-pager -l || true
  journalctl -u fprintd-sleep.service -u fprintd-sleep-v2.service -u fprintd-sleep-rearm.service -b --no-pager || true
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
journalctl -u fprintd.service -u fprintd-sleep.service -u fprintd-sleep-v2.service -u fprintd-sleep-rearm.service -t kscreenlocker_greet -f
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

### What we saw (fw13, 2026-09-07 — root cause from source)
* **Hardware confirmed**: `lspci -D | grep -i xhci` → **empty** (no xHCI controller visible). USB rebind approach is inapplicable on this machine.
* **Sensor stays on USB**: `lsusb | grep 27c6` → `Bus 001 Device 003: ID 27c6:609c` visible after resume. USB device disappearance is NOT the failure mode.
* **Root cause confirmed via kscreenlocker source** (`pamauthenticator.cpp`):
  * `m_unavailable = true` is set when PAM returns `WorkerResult::Unavailable` or after >3 rapid failures within 2 seconds. Once set, `tryUnlock()` returns immediately — fingerprint is silently disabled for that greeter lifetime.
  * `busctl status net.reactivated.Fprint` (D-Bus name visible) fires ~500ms **before** fprintd finishes USB device enumeration. A fresh greeter started at this point calls pam_fprintd → `WorkerResult::Unavailable` → `m_unavailable=true` in the new greeter too.
  * Early `delay_restart` failed for this reason: it recycled the greeter on name presence, before the device was ready.
* **`ksldapp` auto-respawns greeter** (`ksldapp.cpp` line ~207): when `kscreenlocker_greet` exits (including via SIGTERM), `ksldapp` starts a fresh one — `pkill -TERM -f kscreenlocker_greet` is the correct mechanism, but timing is critical.

### What we tried and rejected (2026-09-07 → 2026-09-11)
* **`greeter_recycle` mode** (system `fprintd-pre-sleep` + user `fprintd-greeter-recycle`) was introduced to wait on `GetDefaultDevice` in a user unit, then kill the greeter. **Removed**: user systemd has no wired `sleep.target`, and user units cannot `After=` system `fprintd.service`. The readiness idea was kept in `delay_restart_v2` / `fingerprint_rearm`.

### Current preferred approach (2026-09-11)
* **`fingerprint_rearm`**: custom `kscreenlocker` patch rearms fingerprint PAM after resume when `GetDefaultDevice` succeeds (no `pkill` greeter). Pair with `fprint_fix = true`.

### Known Workarounds (Currently in Repo)
* **Disabled fprintAuth** on `login` / `kde` / `passwd` (`modules/desktop-basic.nix`); `polkit-1` follows `services.fprintd.enable`. Plasma fingerprint goes through `kde-fingerprint`.
* **`pam_fprintd timeout=60 max-tries=3`** on `kde-fingerprint` (`modules/desktop-basic.nix`): extends the fingerprint window past the default ~30s.
* **Suspend/resume** ([nixpkgs#432276](https://github.com/NixOS/nixpkgs/issues/432276)): option `fprintd-plasma_workaround`:
  * `"fingerprint_rearm"` (fw13): **preferred long-term**. Patches `kscreenlocker` (`nixos/kscreenlocker-fingerprint-rearm.patch`) to recreate fingerprint PAM once `GetDefaultDevice` succeeds after resume (no greeter kill). System unit `fprintd-sleep-rearm` only stops/restarts fprintd. **Requires `fprint_fix = true`** (asserted).
  * `"delay_restart_v2"`: recycle greeter after `GetDefaultDevice`; better than `delay_restart`. Better WITH `fprint_fix` (not required).
  * `"delay_restart"`: recycle greeter after D-Bus name presence. Better WITH `fprint_fix` (not required).
  * `"powerdown_cmd"`: only stop fprintd via `powerManagement.powerDownCommands` (no greeter recycle / no rearm). Weakest; `fprint_fix` optional / not particularly recommended with this alone.
  * `false`: no Plasma sleep workaround; `fprint_fix` independent.
  * Removed: `"greeter_recycle"` (user-unit sleep hook was invalid — no wired user `sleep.target`, cannot `After=` system `fprintd`).
* **libfprint USB serial retry patch**: option `fprint_fix` gates `den.aspects.fprint-fix` overlay (`nixos/fprint-fix.patch`, rebased on libfprint 1.94.100 / `wvhulle` kill-without-clean). Required for `fingerprint_rearm`; recommended for `delay_restart` / `delay_restart_v2`.
* **SSH sudo bypass**: `modules/sudo-fprint-ssh-bypass.nix` (works for normal SSH, fails in tmux — Issue 1).

### Issue 2b: Fingerprint prompt disappears / times out (no suspend involved)

**Problem**: Even without suspend/resume, the lock screen's fingerprint option times out and vanishes before the user scans.

**What we saw (fw13, 2026-08-05 ~21:21)**:
* No suspend/resume since 18:48. fprintd was idle (auto-deactivated at ~20:08).
* Locked screen at ~21:21. Journal shows **only `kde` PAM** at 21:21:36 (password unlock). Zero `kde-fingerprint` entries visible at unlock time.
* Locked again at ~21:25. `kde-fingerprint` PAM fired, fprintd started on demand, fingerprint worked.

**Root cause (from KDE source analysis)**:
* `kscreenlocker_greet` is **spawned fresh per-lock** (not persistent). It always starts all three PAM authenticators (`kde`, `kde-fingerprint`, `kde-smartcard`) in parallel immediately on lock (since Plasma 6.3, [MR !163](https://invent.kde.org/plasma/kscreenlocker/-/merge_requests/163)).
* `pam_fprintd` defaults to a **~30 second timeout**. If the user doesn't scan within that window, `pam_authenticate()` returns failure, and kscreenlocker marks fingerprint as `m_unavailable = true` via `PamAuthenticator` ([pamauthenticator.cpp](https://invent.kde.org/plasma/kscreenlocker/-/blob/master/greeter/pamauthenticator.cpp)).
* The 21:21 failure was likely the fingerprint option timing out before the user reached the lock screen, not a stale greeter.
* [KDE Bug 506567](https://bugs.kde.org/show_bug.cgi?id=506567) — fingerprint prompt deactivates after a moment (RESOLVED FIXED, commit `1cccd29c`). Included in Plasma 6.7.3. Fixes unlock delay, **not** the timeout-before-scan.
* [KDE Bug 469951](https://bugs.kde.org/show_bug.cgi?id=469951) — fingerprint errors if you don't scan promptly.
* [Fedora discussion](https://discussion.fedoraproject.org/t/fingerprint-kde-plasma-6-3-problem-with-unlock-computer/144842) — fingerprint only works for seconds after locking.

**Mitigation in repo**: `timeout=60` on `kde-fingerprint` (see above). Manual recovery: Enter on an empty password field restarts the PAM conversation and may re-trigger fingerprint.

**Still open**: No upstream fix for “scan whenever you’re ready after lock”; longer PAM timeout only softens it. Re-check after Plasma upgrades.

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
