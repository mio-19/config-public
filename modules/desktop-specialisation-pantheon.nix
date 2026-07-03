{ den, ... }: {
  den.aspects.desktop-specialisation-pantheon = {
    description = "Pantheon boot specialisation on top of desktop-basic";
    includes = [
      den.aspects.desktop-basic
    ];
    nixos =
      {
        config,
        lib,
        ...
      }:
      {
        specialisation.pantheon.configuration =
          lib.mkIf (!config.services.xserver.displayManager.lightdm.enable)
            {
              # https://wiki.nixos.org/wiki/Pantheon
              services.desktopManager.pantheon.enable = true;
              services.pantheon.apps.enable = true;
              services.pantheon.contractor.enable = true;
              system.nixos.tags = [ "pantheon" ];
              services.xserver.displayManager.lightdm.enable = lib.mkForce true;
              services.displayManager.gdm.enable = lib.mkForce false;
              services.displayManager.sddm.enable = lib.mkForce false;
              services.displayManager.plasma-login-manager.enable = lib.mkForce false;
              services.displayManager.cosmic-greeter.enable = lib.mkForce false;
              services.xserver.enable = true; # required by lightdm
            };
      };
  };
}
