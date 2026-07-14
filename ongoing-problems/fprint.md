# fprint Issues Tracker

## Issue 1: tmux over SSH doesn't skip fprintd for sudo
**Problem**: The SSH PAM bypass rule fails when running `sudo` inside a `tmux` session over SSH, causing the system to wait for a physical fingerprint instead of falling back to password immediately.
**How to collect logs**:
```bash
journalctl | grep pam_fprintd
journalctl -u sshd.service -b
```

## Issue 2: KDE Plasma Lockscreen Unlock
**Problem**: Fingerprint authentication is broken or inconsistent when unlocking KDE Plasma. (Plasma has known bugs when PAM `fprintAuth` is enabled).
**How to collect logs**:
```bash
# fprintd core logs
journalctl -u fprintd.service -b -f
# PAM/Lockscreen logs
journalctl -t kscreenlocker_greet -b
```

## Known Workarounds (Currently in Repo)
* **Disabled fprintAuth**: Explicitly set `security.pam.services.*.fprintAuth = false;` for `login`, `kde`, `passwd`, and `polkit-1` (`modules/desktop-basic.nix`) due to SDDM/Plasma issues.
* **Suspend/Resume Service Restart**: Stopping and starting `fprintd.service` around sleep (`modules/common.nix`). *(Note: This workaround is sometimes insufficient. If it fails, check `lsusb` to see if the hardware dropped off entirely and needs USB autosuspend disabled, or if the `kscreenlocker_greet` PAM session is stuck and requires restarting the locker).*
* **Experimental libfprint patch**: Commented out `den.aspects.fprint-fix` in `modules/common.nix` (uses `wvhulle` kill-without-clean patch).
* **SSH sudo bypass**: Custom PAM rule in `modules/sudo-fprint-ssh-bypass.nix` (works for standard SSH, fails in tmux).
