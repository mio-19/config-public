{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:
{
  imports = [
    ./baremetal.nix
    ./desktop-basic.nix
  ];
  services.displayManager.plasma-login-manager.enable = config.plasma-login-manager_instead;
  services.displayManager.sddm.enable = !config.plasma-login-manager_instead;
  services.displayManager.gdm.enable = false;
  services.xserver.displayManager.lightdm.enable = false;
}
