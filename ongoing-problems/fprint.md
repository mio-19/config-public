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

### What we did
* **`fprintd-sleep` in `modules/common.nix`**: oneshot on `sleep.target` (`WantedBy`/`Before`, `StopWhenUnneeded`, `RemainAfterExit`). **ExecStart** stops `fprintd` before sleep. **ExecStop**: `sleep 2` → `systemctl restart fprintd` → `pkill -TERM -f kscreenlocker_greet` (not `-x`: `comm` is 15 chars so `-x` never matched; kill only after restart so Plasma does not respawn into the restart race).
* **Why not `WantedBy=suspend.target` + `After=suspend.target` + `ExecStart`**: that can appear to run post-wake because `suspend.target` is `After=systemd-suspend.service`, but it is not the documented hook, needs every sleep target listed, and diverges from nixpkgs `power-management.nix`. `WantedBy=sleep.target` + `After=sleep.target` + `ExecStart` is wrong (runs before sleep; [systemd#6364](https://github.com/systemd/systemd/issues/6364)).
* **Why not only restart fprintd**: greeter keeps a stale `pam_fprintd` D-Bus session → intermittent unlock.
* **Why not only stop-before-sleep**: issue author prefers that; Framework 13 still saw intermittency — logs needed greeter recycle.
* **Left alone for now**: commented-out `den.aspects.fprint-fix`; broken `fprintd_sudo_only_tty` flake patch (CVE mitigation noise, not the resume bug).

### Known Workarounds (Currently in Repo)
* **Disabled fprintAuth** on `login` / `kde` / `passwd` (`modules/desktop-basic.nix`); `polkit-1` follows `services.fprintd.enable`. Plasma fingerprint goes through `kde-fingerprint`.
* **Suspend/resume** ([nixpkgs#432276](https://github.com/NixOS/nixpkgs/issues/432276)): `fprintd-sleep` stop / restart+greeter-recycle via `sleep.target` ExecStart/ExecStop (`modules/common.nix`).
* **Experimental libfprint patch**: `den.aspects.fprint-fix` commented out in `modules/common.nix` (`wvhulle` kill-without-clean).
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

### Framework 13 specific: USB controller rebind on resume

The Goodix `27c6:609c` sensor on Framework 13 (especially AMD Ryzen AI 300) can disappear from USB after suspend. The xHCI controller fails to reinitialize the sensor. Simple fprintd restart is not enough; may need USB controller unbind/rebind (find the PCI address with `lspci -D | grep xHCI`):
```bash
# Example PCI address — verify on your machine first
echo "$PCI_ADDR" > /sys/bus/pci/drivers/xhci_hcd/unbind
sleep 2
echo "$PCI_ADDR" > /sys/bus/pci/drivers/xhci_hcd/bind
sleep 3
systemctl restart fprintd.service
```
Tracked at [FrameworkComputer/SoftwareFirmwareIssueTracker#102](https://github.com/FrameworkComputer/SoftwareFirmwareIssueTracker/issues/102). One user reported changing BIOS TPM Operation to "No operation" fixed it.

If fingerprint still fails after resume: check `lsusb` for Goodix drop-off / USB autosuspend. Manual unblock: `pkill -TERM -f kscreenlocker_greet`.
