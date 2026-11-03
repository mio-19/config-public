{ den, ... }:
{
  den.aspects.desktop-specialisation-cutefish = {
    description = "Cutefish Wayland boot specialisation on top of desktop-basic";
    includes = [
      den.aspects.desktop-basic
    ];
    nixos =
      {
        config,
        inputs,
        lib,
        pkgs,
        ...
      }:
      {
        imports = [
          # https://github.com/mio-19/nurpkgs/blob/main/modules/cutefish.nix
          inputs.mio.nixosModules.cutefish
        ];

        # The session is "Cutefish (Wayland)" on the display manager already in
        # use (SDDM or plasma-login). cutefish-dm stays unused.
        specialisation.cutefish.configuration = lib.mkIf (!config.services.desktopManager.cutefish.enable) {
          services.desktopManager.cutefish.enable = true;
          system.nixos.tags = [ "cutefish" ];
          services.displayManager.defaultSession = lib.mkForce "cutefish-wayland";
          # Plasma stays enabled and also sets this with mkDefault. The
          # Cutefish module ships the same portals.conf as this attrset
          # (data/cutefish-portals.conf); /etc is what the session looks up
          # after lowercasing XDG_CURRENT_DESKTOP=Cutefish.
          xdg.portal.configPackages = lib.mkForce [ pkgs.kdePackages.plasma-workspace ];
          xdg.portal.config.cutefish = {
            default = [ "gtk" ];
            "org.freedesktop.impl.portal.Settings" = [
              "cutefish"
              "gtk"
            ];
            "org.freedesktop.impl.portal.FileChooser" = [ "cutefish" ];
            "org.freedesktop.impl.portal.Inhibit" = [ "cutefish" ];
            "org.freedesktop.impl.portal.ScreenCast" = [ "cutefish" ];
            # desktop-basic leaves gnome-keyring off and sends secrets to kwallet.
            # Upstream cutefish-portals.conf asks for gnome-keyring here.
            "org.freedesktop.impl.portal.Secret" = [ "kwallet" ];
          };
          services.xserver.displayManager.lightdm.enable = lib.mkForce false;
          services.displayManager.gdm.enable = lib.mkForce false;
          services.displayManager.cosmic-greeter.enable = lib.mkForce false;
        };
      };
  };
}
