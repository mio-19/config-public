# VSCode Title Unfocus in KDE

**Problem**: VSCode window loses focus randomly in KDE Plasma. Clicking on it doesn't restore focus. It requires relaunching VSCode to fix the issue. This problem appears randomly (sometimes it happens, sometimes it doesn't).

**Symptoms**:
- VSCode title bar shows it's unfocused.
- Mouse clicks do not focus the window.
- Relaunching VSCode is required to restore functionality.

**Context**:
- Desktop Environment: KDE Plasma

## Workarounds & Research
Based on web and nixpkgs issue searches, this is a known issue with Electron apps (like VSCode) running natively on Wayland with KDE Plasma. It is often related to Electron's integration with Wayland (`ozone-platform=wayland`) and KDE Plasma window management policies.

### Potential Fixes:
1. **Force XWayland (X11) Mode**:
   Running VSCode under XWayland avoids the native Wayland bugs.
   - Command line: `code --ozone-platform=x11`
   - Or configure it in `~/.config/code-flags.conf` by adding `--ozone-platform=x11`.
   *(This is the most widely reported and stable workaround for focus stealing/menu sticking bugs).*

2. **Check KDE Window Management Settings**:
   - Sometimes KDE's "Focus stealing prevention" can interfere with Electron's modal dialogs or menus. Check **System Settings > Window Management > Window Behavior**.

3. **Check NixOS Ozone Wayland Flags**:
   - If `NIXOS_OZONE_WL="1"` is set globally, it forces Electron apps to use Wayland natively, which triggers this bug. You could try removing it or overriding it for VSCode specifically to fall back to XWayland.

### Fractional Scaling & Electron Updates
If fractional scaling is required, the XWayland (X11) workaround will result in blurry fonts or incorrect UI scaling, meaning Wayland is mandatory. 

Unfortunately, recent Electron version bumps inside VSCode (and other Electron apps like Discord) have introduced regressions with the `xdg-activation` protocol that Wayland uses to negotiate focus stealing. Because Wayland intentionally prevents windows from stealing focus for security reasons, applications have to request focus in a very specific way. Recent Electron updates seem to break this handshake with KDE (KWin), causing the window to think it has lost focus while the OS doesn't allow it to regain it.

To troubleshoot on native Wayland, you can try explicitly tweaking the ozone platform flags, though there is no silver bullet until Electron patches this upstream:
```bash
code --ozone-platform-hint=auto
# or 
code --ozone-platform=wayland --enable-features=WaylandWindowDecorations
```

### Upstream Bug Tracking
- **Electron (Root Cause):** [Issue #32857: [Feature Request]: Support Wayland window activation (`xdg-activation-v1`)](https://github.com/electron/electron/issues/32857)
- **VS Code (Downstream Effect):** [Issue #202720: VSCode under Wayland loses focus intermittently](https://github.com/microsoft/vscode/issues/202720)
