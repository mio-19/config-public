{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:
{
  imports = [
    ../../nixos/baremetal.nix
    (import ../../aspect.nix "desktop-basic")
  ];
  services.displayManager.plasma-login-manager.enable = config.plasma-login-manager_instead;
  services.displayManager.sddm.enable = !config.plasma-login-manager_instead;
  services.displayManager.gdm.enable = false;
  services.xserver.displayManager.lightdm.enable = false;
}
