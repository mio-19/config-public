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
  imports = [ ./desktop-basic.nix ];
  specialisation.kde = lib.mkIf (!kdeDMEnabled) {
    configuration = {
      system.nixos.tags = [ "kde" ];
      services.displayManager.plasma-login-manager.enable = lib.mkForce false; # currently default to plasma-x11 see https://github.com/NixOS/nixpkgs/pull/479797#issuecomment-3828791470 https://github.com/NixOS/nixpkgs/pull/479797#issuecomment-3789819294
      services.displayManager.sddm.enable = lib.mkForce true;
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
