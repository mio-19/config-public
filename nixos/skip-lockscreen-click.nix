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

    services.displayManager.sddm.theme = "breeze-user";

    environment.systemPackages = [
      # SDDM Theme Override
      (pkgs.runCommand "sddm-theme-breeze-user" { } ''
        mkdir -p $out/share/sddm/themes
        cp -r ${pkgs.kdePackages.plasma-desktop}/share/sddm/themes/breeze $out/share/sddm/themes/breeze-user
        chmod -R u+w $out

        # Apply patch to remove WallpaperFader
        patch $out/share/sddm/themes/breeze-user/Main.qml < ${./skip-lockscreen-click/sddm-breeze.patch}

        # Rename the theme so SDDM can find it
        substituteInPlace $out/share/sddm/themes/breeze-user/metadata.desktop \
          --replace-fail 'Name=Breeze' 'Name=Breeze (user)' \
          --replace-fail 'Theme-Id=breeze' 'Theme-Id=breeze-user'
      '')

      # Plasma Lockscreen Shield Bypass
      (lib.hiPrio (
        pkgs.runCommand "plasma-lockscreen-bypass" { } ''
          mkdir -p $out/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen
          cp ${pkgs.kdePackages.plasma-desktop}/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen/LockScreenUi.qml $out/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen/LockScreenUi.qml
          chmod +w $out/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen/LockScreenUi.qml

          # Apply patch to default uiVisible to true and auto-start authenticator
          patch $out/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen/LockScreenUi.qml < ${./skip-lockscreen-click/lockscreenui.patch}
        ''
      ))
    ];
  };
}
