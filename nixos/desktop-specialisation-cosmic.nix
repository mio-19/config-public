{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:
{
  imports = [ ./desktop-basic.nix ];
  specialisation.cosmic.configuration =
    lib.mkIf (!config.services.displayManager.cosmic-greeter.enable)
      {
        # https://wiki.nixos.org/wiki/COSMIC
        services.displayManager.cosmic-greeter.enable = true;
        services.desktopManager.cosmic.enable = true;
        system.nixos.tags = [ "cosmic" ];
        services.xserver.displayManager.lightdm.enable = lib.mkForce false;
        services.displayManager.gdm.enable = lib.mkForce false;
        services.displayManager.sddm.enable = lib.mkForce false;
        services.displayManager.plasma-login-manager.enable = lib.mkForce false;
      };

}
