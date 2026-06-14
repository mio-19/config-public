{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.skip_lockscreen_click {
    /*
      # Enforce concurrent PAM evaluation for kscreenlocker
      security.pam.services.kde-fingerprint = lib.mkIf config.services.fprintd.enable {
        fprintAuth = true;
        unixAuth = true; # Retains standard UNIX password verification as a parallel fallback
      };
    */

    environment.systemPackages = [
      # SDDM Theme Override (hiPrio forces this file to overlay the original breeze theme)
      (lib.hiPrio (
        pkgs.runCommand "sddm-theme-breeze-override" { } ''
          mkdir -p $out/share/sddm/themes
          cp -r ${pkgs.kdePackages.plasma-desktop}/share/sddm/themes/breeze $out/share/sddm/themes/breeze
          chmod -R u+w $out

          # Apply patch to disable idle fadeout
          patch $out/share/sddm/themes/breeze/Main.qml < ${./sddm-breeze.patch}
        ''
      ))

      # Plasma Lockscreen Shield Bypass
      # Must copy ALL files — QML resolves relative imports (MainBlock, WallpaperFader, etc.)
      # from the file's store path, not the symlink location
      (lib.hiPrio (
        pkgs.runCommand "plasma-lockscreen-bypass" { } ''
          mkdir -p $out/share/plasma/shells/org.kde.plasma.desktop/contents
          cp -r ${pkgs.kdePackages.plasma-desktop}/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen $out/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen
          chmod -R u+w $out

          # Apply patch to disable fadeouts and auto-trigger uiVisible after launch animation
          patch $out/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen/LockScreenUi.qml < ${./lockscreenui.patch}
        ''
      ))
    ];
  };
}
