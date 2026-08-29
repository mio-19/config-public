{ den, ... }: {
  den.aspects.desktop-specialisation-windose20-xfce = {
    description = "Windose20 XFCE boot specialisation (Needy Girl Overdose rice)";
    nixos =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        system,
        ...
      }:
      let
        mio = inputs.mio.packages.${system};
        windose20 = mio.windose20 or (lib.throw "windose20 package missing from inputs.mio");
        plasmaOverdose = mio.plasma-overdose-kde-theme or pkgs.plasma-overdose-kde-theme;
        needyGirlOverdoseTheme =
          mio.needy-girl-overdose-theme
            or (lib.throw "needy-girl-overdose-theme package missing from inputs.mio");
        gtkThemeName = "NEEDY-GIRL-OVERDOSE";
        windose20Wallpaper = "${plasmaOverdose}/share/wallpapers/Plasma-Overdose/tile.png";
        windose20Font = "fusion-pixel-10px-proportional-latin,10,-1,5,50,0,0,0,0,0";
        windose20PlasmaloginKdeglobals = pkgs.writeText "windose20-plasmalogin-kdeglobals" ''
          [KDE]
          LookAndFeelPackage=Plasma-Overdose

          [General]
          font=${windose20Font}
          fixed=${windose20Font}
        '';
        windose20XfceHomeModule =
          {
            osConfig,
            ...
          }:
          let
            enabled = builtins.elem "windose20-xfce" osConfig.system.nixos.tags;
          in
          lib.mkIf enabled {
            home.packages = [
              windose20
              plasmaOverdose
              needyGirlOverdoseTheme
            ];

            programs.plasma.enable = lib.mkForce false;

            gtk = {
              enable = true;
              font = {
                name = "fusion-pixel-10px-proportional-latin";
                size = 10;
              };
              theme = {
                name = gtkThemeName;
                package = needyGirlOverdoseTheme;
              };
            };

            home.pointerCursor = {
              enable = true;
              package = plasmaOverdose;
              name = "Plasma-Overdose";
              size = 24;
              gtk.enable = true;
              x11.enable = true;
            };

            xfconf = {
              enable = true;
              settings = {
                xfwm4 = {
                  "general/theme" = gtkThemeName;
                };
                xfce4-desktop = {
                  "backdrop/screen0/monitor0/workspace0/last-image" = windose20Wallpaper;
                  "backdrop/screen0/monitor0/workspace0/image-style" = 3;
                  "backdrop/screen0/monitor0/workspace1/last-image" = windose20Wallpaper;
                  "backdrop/screen0/monitor0/workspace1/image-style" = 3;
                  "backdrop/screen0/monitor0/workspace2/last-image" = windose20Wallpaper;
                  "backdrop/screen0/monitor0/workspace2/image-style" = 3;
                  "backdrop/screen0/monitor0/workspace3/last-image" = windose20Wallpaper;
                  "backdrop/screen0/monitor0/workspace3/image-style" = 3;
                };
                xsettings = {
                  "Gtk/FontName" = windose20Font;
                  "Gtk/CursorThemeName" = "Plasma-Overdose";
                  "Gtk/CursorThemeSize" = 24;
                  "Net/ThemeName" = gtkThemeName;
                };
              };
            };

            xdg.configFile = {
              "fastfetch/config.jsonc".source = "${windose20}/share/windose20/configs/fastfetch.jsonc";
              "neofetch/config.conf".source = "${windose20}/share/windose20/configs/neofetch.conf";
              "cava/config".source = "${windose20}/share/windose20/configs/cava.conf";
            };
          };
      in
      {
        home-manager.sharedModules = [ windose20XfceHomeModule ];

        specialisation.windose20-xfce.configuration = {
          system.nixos.tags = [ "windose20-xfce" ];
          system.nixos.distroName = lib.mkForce "Windose20 XFCE";
          system.nixos.extraOSReleaseArgs = {
            HOME_URL = "https://angelkawaii.com/";
            DOCUMENTATION_URL = "https://angelkawaii.com/";
            LOGO = "${windose20}/share/windose20/pngs/logo_with_name.png";
          };

          fonts.packages = [ windose20 ];
          programs.xfconf.enable = true;

          services.desktopManager.plasma6.enable = lib.mkForce false;
          services.xserver.desktopManager.xfce.enable = lib.mkForce true;
          services.displayManager.defaultSession = lib.mkForce "xfce";

          environment.systemPackages = [
            windose20
            plasmaOverdose
            needyGirlOverdoseTheme
          ]
          ++ lib.optionals config.services.displayManager.sddm.enable [
            (pkgs.writeTextDir "share/sddm/themes/breeze/theme.conf.user" ''
              [General]
              background=${windose20Wallpaper}
            '')
          ];

          environment.etc."xdg/fastfetch/config.jsonc".source =
            "${windose20}/share/windose20/configs/fastfetch.jsonc";

          services.displayManager.plasma-login-manager.settings =
            lib.mkIf config.services.displayManager.plasma-login-manager.enable
              {
                Greeter.WallpaperPluginId = "org.kde.image";
                "Greeter/Wallpaper/org.kde.image/General" = {
                  Image = "file://${windose20Wallpaper}";
                  FillMode = 1;
                };
              };

          system.activationScripts.windose20Plasmalogin =
            lib.mkIf config.services.displayManager.plasma-login-manager.enable
              {
                text = ''
                  if [ -d /var/lib/plasmalogin ]; then
                    mkdir -p /var/lib/plasmalogin/.config
                    ln -sfn ${windose20PlasmaloginKdeglobals} /var/lib/plasmalogin/.config/kdeglobals
                  fi
                '';
              };

          boot.plymouth = {
            enable = lib.mkForce true;
            theme = lib.mkForce "windose20";
            themePackages = lib.mkForce [ windose20 ];
          };
        };
      };
  };
}
