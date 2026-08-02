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
* **Disabled fprintAuth**: Explicitly set `security.pam.services.*.fprintAuth = false;` for `login`, `kde`, and `passwd` (`modules/desktop-basic.nix`) due to SDDM/Plasma issues. (Note: `polkit-1` is conditionally enabled when `fprintd` is enabled).
* **Suspend/Resume Service Restart**: We observed from journalctl logs that `fprintd` attempted to start too quickly upon resume, causing a "Cannot run while suspended" error because the USB device wasn't fully ready. To fix this race condition, we created a dedicated `fprintd-resume` systemd service in `modules/common.nix` that waits for 2 seconds (`sleep 2`) after waking up before starting the service. This replaces the old `powerManagement.resumeCommands` workaround which was deprecated and could block other resume scripts. *(Note: If this still fails, check `lsusb` to see if the hardware dropped off entirely and needs USB autosuspend disabled, or if the `kscreenlocker_greet` PAM session is stuck and requires restarting the locker).*
* **Experimental libfprint patch**: Commented out `den.aspects.fprint-fix` in `modules/common.nix` (uses `wvhulle` kill-without-clean patch).
* **SSH sudo bypass**: Custom PAM rule in `modules/sudo-fprint-ssh-bypass.nix` (works for standard SSH, fails in tmux).
