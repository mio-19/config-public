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
              patches = (old.patches or [ ]) ++ [
                ./skip-lockscreen-click/lockscreenui.patch
                ./skip-lockscreen-click/sddm-breeze.patch
              ];
            });
          }
        );
      })
    ];
  };
}
