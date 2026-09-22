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
1. **Missing Capabilities**: In `modules/wireguird.nix`, `wg-quick` is granted ambient capabilities (`CAP_NET_ADMIN`, `CAP_NET_RAW`) instead of running via `sudo` (using a custom patch). However, it missed two critical capabilities: `openresolv`'s subscriber scripts need `CAP_KILL` to send kill/restart signals to system services (like `avahi-daemon`), and `CAP_DAC_OVERRIDE` to safely bypass file ownership checks when updating `/etc/resolv.conf`. Without these, `resolvconf` crashes with `Permission denied` and `Operation not permitted`.
2. **Portal Warning**: The GTK warning (`Unable to open /proc/.../root`) happens because `wireguird` itself was wrapped with capabilities. Applying file capabilities disables Linux process dumpability (`PR_SET_DUMPABLE=0`), which completely blocks the `xdg-desktop-portal` daemon from verifying the application.

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
