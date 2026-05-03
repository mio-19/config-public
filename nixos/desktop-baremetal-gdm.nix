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
    ./desktop-full.nix
  ];
  services.displayManager.sddm.enable = false;
  services.displayManager.plasma-login-manager.enable = false;
  services.displayManager.gdm.enable = true;
  services.xserver.displayManager.lightdm.enable = false;
}
