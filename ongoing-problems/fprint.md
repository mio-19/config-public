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

### What we did
* **`fprintd-sleep` in `modules/common.nix`**: one oneshot hooked to `sleep.target` the way systemd documents and NixOS `sleep-actions` does — `WantedBy`/`Before=sleep.target`, `StopWhenUnneeded`, `RemainAfterExit`; **ExecStart** stops `fprintd` before sleep; **ExecStop** after wake does `sleep 2` → `systemctl restart fprintd` → `pkill -TERM -x kscreenlocker_greet`.
* **Why not `WantedBy=suspend.target` + `After=suspend.target` + `ExecStart`**: that can appear to run post-wake because `suspend.target` is `After=systemd-suspend.service`, but it is not the documented hook, needs every sleep target listed, and diverges from nixpkgs `power-management.nix`. `WantedBy=sleep.target` + `After=sleep.target` + `ExecStart` is wrong (runs before sleep; [systemd#6364](https://github.com/systemd/systemd/issues/6364)).
* **Why not only restart fprintd**: greeter keeps a stale `pam_fprintd` D-Bus session → intermittent unlock.
* **Why not only stop-before-sleep**: issue author prefers that; Framework 13 still saw intermittency — logs needed greeter recycle.
* **Left alone for now**: commented-out `den.aspects.fprint-fix`; broken `fprintd_sudo_only_tty` flake patch (CVE mitigation noise, not the resume bug).

### Known Workarounds (Currently in Repo)
* **Disabled fprintAuth** on `login` / `kde` / `passwd` (`modules/desktop-basic.nix`); `polkit-1` follows `services.fprintd.enable`. Plasma fingerprint goes through `kde-fingerprint`.
* **Suspend/resume** ([nixpkgs#432276](https://github.com/NixOS/nixpkgs/issues/432276)): `fprintd-sleep` stop / restart+greeter-recycle via `sleep.target` ExecStart/ExecStop (`modules/common.nix`).
* **Experimental libfprint patch**: `den.aspects.fprint-fix` commented out in `modules/common.nix` (`wvhulle` kill-without-clean).
* **SSH sudo bypass**: `modules/sudo-fprint-ssh-bypass.nix` (works for normal SSH, fails in tmux).

If fingerprint still fails after resume: check `lsusb` for Goodix drop-off / USB autosuspend.
