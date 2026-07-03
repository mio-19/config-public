{
  config,
  inputs,
  lib,
  pkgs,
  _include,
  ...
}@args:
with _include;
{
  imports = [ (import ../aspect.nix "desktop-basic") ];
  specialisation.kde = lib.mkIf (!kdeDMEnabled) {
    configuration = {
      system.nixos.tags = [ "kde" ];
      services.displayManager.plasma-login-manager.enable = lib.mkForce config.plasma-login-manager_instead;
      services.displayManager.sddm.enable = lib.mkForce (!config.plasma-login-manager_instead);
      services.displayManager.gdm.enable = lib.mkForce false;
      services.xserver.displayManager.lightdm.enable = lib.mkForce false;
      services.displayManager.cosmic-greeter.enable = lib.mkForce false;
    };
  };
  specialisation.gnome = lib.mkIf (!config.services.displayManager.gdm.enable) {
    configuration = {
      system.nixos.tags = [ "gnome" ];
      services.displayManager.gdm.enable = lib.mkForce true;
      services.displayManager.sddm.enable = lib.mkForce false;
      services.displayManager.plasma-login-manager.enable = lib.mkForce false;
      services.xserver.displayManager.lightdm.enable = lib.mkForce false;
      services.displayManager.cosmic-greeter.enable = lib.mkForce false;
    };
  };

}
