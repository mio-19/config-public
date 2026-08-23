# Bare-metal KDE baseline: SDDM or plasma-login-manager (den.aspects.desktop-baremetal-kde-basic).
{ den, ... }: {
  den.aspects.desktop-baremetal-kde-basic = {
    description = "Bare-metal KDE baseline with SDDM or plasma-login-manager";
    includes = [
      den.aspects.baremetal
      den.aspects."desktop-basic"
    ];
    nixos =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        system,
        ...
      }:
      {
        services.displayManager.plasma-login-manager.enable = config.plasma-login-manager_instead;
        services.displayManager.sddm.enable = !config.plasma-login-manager_instead;
        services.displayManager.gdm.enable = false;
        services.xserver.displayManager.lightdm.enable = false;
      };
  };
}
