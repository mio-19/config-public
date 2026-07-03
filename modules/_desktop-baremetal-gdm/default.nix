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
    ../../nixos/desktop-full.nix
  ];
  services.displayManager.sddm.enable = false;
  services.displayManager.plasma-login-manager.enable = false;
  services.displayManager.gdm.enable = true;
  services.xserver.displayManager.lightdm.enable = false;
}
