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
1. **MagicDNS overriding ACLs**: The `wireguird` module tries to grant standard users write access to `/run/resolvconf` via `setfacl`. However, if **Tailscale MagicDNS** is enabled, it forcefully symlinks `/etc/resolv.conf` to `/run/tailscale/resolv.conf` instead, which *doesn't* have the ACL! Thus, `openresolv` fails with `Permission denied`. Disabling MagicDNS on laptops (`--accept-dns=false`) fixes this by restoring the symlink to `/run/resolvconf/resolv.conf` where the ACL applies natively.
2. **Missing `CAP_KILL`**: `openresolv`'s subscriber scripts need `CAP_KILL` to send kill/restart signals to system services (like `avahi-daemon`). Because `wg-quick` is running as a normal user (due to your custom patch skipping `sudo`), it crashed with `Operation not permitted`.
3. **Portal Warning**: The GTK warning (`Unable to open /proc/.../root`) happens because `wireguird` itself was wrapped with capabilities. Applying file capabilities disables Linux process dumpability (`PR_SET_DUMPABLE=0`), which completely blocks the `xdg-desktop-portal` daemon from verifying the application.

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
