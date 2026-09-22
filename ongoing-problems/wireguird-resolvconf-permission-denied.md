# Wireguird (wg-quick) resolvconf Permission Denied

## The Issue
When attempting to connect to a WireGuard profile using the `wireguird` GUI on NixOS, the connection fails with errors related to DNS resolution and process signaling:

```text
[#] resolvconf -a wgcf-profile -m 0 -x
/nix/store/.../libexec/resolvconf/libc: line 259: /etc/resolv.conf: Permission denied
/nix/store/.../libexec/resolvconf/libc.d/avahi-daemon: line 31: kill: (1720) - Operation not permitted
```

Along with GUI sandbox warnings:
```text
GDBus.Error:org.freedesktop.DBus.Error.AccessDenied: Portal operation not allowed: Unable to open /proc/.../root
```

## Root Cause (nurpkgs5 wireguird.nix)
The issue originates from how `wireguird` is packaged and configured in your `nurpkgs5` repository:
1. **Capabilities vs. Root**: In `modules/wireguird.nix`, `wireguird` and `wg-quick` are granted ambient capabilities (`CAP_NET_ADMIN`, `CAP_NET_RAW`) instead of running via `sudo`.
2. **The wg-quick Patch**: The custom patch (`wg-quick-capability-check.patch`) tricks `wg-quick` into skipping privilege escalation (`auto_su`) because it sees it already has network capabilities.
3. **The openresolv Conflict**: While `modules/wireguird.nix` attempts a clever hack to grant your user ACL access to `/run/resolvconf`, it misses a critical detail: `openresolv`'s subscriber scripts (like `libc.d/avahi-daemon`) need to send kill/restart signals to system services (e.g., `kill -HUP $(pidof avahi-daemon)`). Because `wg-quick` skipped `sudo`, it runs as your regular user and lacks `CAP_KILL` or root uid, causing the script to crash with `Operation not permitted`.
4. **Portal Warning**: The GTK warning (`Unable to open /proc/.../root`) happens because applying file capabilities disables Linux process dumpability (`PR_SET_DUMPABLE=0`), which blocks the `xdg-desktop-portal` daemon from verifying the application.

## Workarounds / Solutions

### 1. Use NetworkManager (Recommended)
NixOS's NetworkManager natively supports WireGuard and handles DNS routing correctly with full system privileges, avoiding permission errors entirely. 

Import the profile directly into NetworkManager:
```bash
nmcli connection import type wireguard file /path/to/your/wgcf-profile.conf
```
You can then seamlessly toggle the connection from the standard KDE/GNOME network applet.

### 2. Remove the DNS Directive in `wireguird`
If you prefer to keep using the `wireguird` app, edit the connection profile within the app and remove the `DNS = ...` line. This prevents `wg-quick` from invoking `resolvconf`. The VPN will connect successfully, but all DNS queries will fall back to your existing system DNS (e.g., Tailscale MagicDNS or local Wi-Fi).

### 3. Native NixOS Configuration
For permanent/always-on VPNs, define the interface declaratively in your NixOS configuration so systemd can manage it natively:

```nix
networking.wg-quick.interfaces.wgcf-profile = {
  configFile = "/path/to/your/wgcf-profile.conf";
};
```
