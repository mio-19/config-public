{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.skip_lockscreen_click {
    # Enforce concurrent PAM evaluation for kscreenlocker
    security.pam.services.kde-fingerprint = lib.mkIf config.services.fprintd.enable {
      fprintAuth = true;
      unixAuth = true; # Retains standard UNIX password verification as a parallel fallback
    };

    nixpkgs.overlays = [
      (final: prev: {
        kdePackages = prev.kdePackages.overrideScope (
          kfinal: kprev: {
            plasma-desktop = kprev.plasma-desktop.overrideAttrs (old: {
              postPatch = (old.postPatch or "") + ''
                # Inject 'visible: false' into the WallpaperFader component block of the lockscreen
                substituteInPlace desktoppackage/contents/lockscreen/LockScreenUi.qml \
                  --replace-warn "clock: clock" "clock: clock; visible: false"

                # Remove WallpaperFader from SDDM theme breeze
                sed -i -z '/WallpaperFader {[^}]*}/,''${s///;b};$q1' sddm-theme/Main.qml
              '';
            });
          }
        );
      })
    ];
  };
}
