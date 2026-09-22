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
The fundamental issue is that `wireguird` is a GUI wrapper around `wg-quick`, which is an inherently root-level administration script. 
1. **The Permission Paradox**: To run `wg-quick` as a standard user, it requires injecting excessive capabilities (`CAP_DAC_OVERRIDE`, `CAP_KILL`). This effectively grants passwordless root equivalent access, completely bypassing your desired "limited permissions" security model.
2. **Silent System Corruption**: `wg-quick` aggressively forces DNS changes via `resolvconf`. When Tailscale MagicDNS is running, it symlinks `/etc/resolv.conf` to its own internal state. The injected `CAP_DAC_OVERRIDE` capability allows `wg-quick` to forcefully overwrite Tailscale's internal files, silently breaking network routing.
3. **Waydroid Conflicts**: While `wg-quick` could be made safe by switching the system to `systemd-resolved`, `systemd-resolved` breaks Android container networking inside `waydroid`.

## Workarounds / Solutions

**DEPRECATED**: Do not use `wireguird` or `wg-quick` wrappers on NixOS.

**RECOMMENDED FIX**: 
Use the native **NetworkManager** daemon. NetworkManager runs as a secure system daemon and natively integrates with KDE Plasma (`plasma-nm`). 
- It requires zero capabilities or `sudo` hacks because you interact with it securely via Polkit.
- It safely merges WireGuard DNS with existing connections (like Tailscale) without destructive file overwrites.

To migrate:
1. Remove `programs.wireguird.enable = true;` from your NixOS configuration.
2. Import your WireGuard config into NetworkManager:
   `nmcli connection import type wireguard file wgcf-profile.conf`
3. Manage the tunnel natively from your KDE Plasma Wi-Fi applet.
