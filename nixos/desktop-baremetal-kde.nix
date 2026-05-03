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
  services.displayManager.plasma-login-manager.enable = false;
  services.displayManager.sddm.enable = true;
  services.displayManager.gdm.enable = false;
  services.xserver.displayManager.lightdm.enable = false;
}
