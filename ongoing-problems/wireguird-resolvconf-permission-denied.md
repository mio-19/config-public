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

## Root Cause
`wireguird` functions as a GUI wrapper that invokes `wg-quick up` under the hood. If the WireGuard configuration file contains a `DNS = ...` directive, `wg-quick` automatically attempts to execute `resolvconf` to inject its DNS servers into `/etc/resolv.conf`.

On NixOS, `/etc/resolv.conf` is strictly managed by the system (often symlinked to `/run/resolvconf/resolv.conf` or controlled by NetworkManager/systemd-resolved). `wireguird` (and by extension the `wg-quick` process it spawns) operates within a restricted context or sandbox. While it has sufficient capabilities (`CAP_NET_ADMIN`) to create the network interface (`wgcf-profile`), it is blocked from modifying core system files (`/etc/resolv.conf`) and denied permission to send kill signals to system daemons (like `avahi-daemon`).

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
