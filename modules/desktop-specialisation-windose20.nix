{ den, ... }: {
  den.aspects.desktop-specialisation-windose20 = {
    description = "Windose20 KDE boot specialisation (Needy Girl Overdose rice)";
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
        windose20HomeModule =
          {
            osConfig,
            ...
          }:
          let
            enabled = builtins.elem "windose20" osConfig.system.nixos.tags;
          in
          lib.mkIf enabled {
            home.packages = [
              windose20
              plasmaOverdose
            ];

            programs.plasma = {
              workspace = {
                lookAndFeel = lib.mkForce "Plasma-Overdose";
                cursor = {
                  theme = lib.mkForce "Plasma-Overdose";
                  size = 24;
                };
                wallpaper = lib.mkForce "${plasmaOverdose}/share/wallpapers/Plasma-Overdose/tile.png";
              };
              fonts = {
                general = {
                  family = lib.mkForce "fusion-pixel-10px-proportional-latin";
                  pointSize = 10;
                };
                fixedWidth = {
                  family = lib.mkForce "fusion-pixel-10px-proportional-latin";
                  pointSize = 10;
                };
              };
            };

            xdg.configFile = {
              "fastfetch/config.jsonc".source = "${windose20}/share/windose20/configs/fastfetch.jsonc";
              "neofetch/config.conf".source = "${windose20}/share/windose20/configs/neofetch.conf";
              "cava/config".source = "${windose20}/share/windose20/configs/cava.conf";
              "konsole/Plasma-Overdose.profile".text = ''
                [Appearance]
                ColorScheme=Plasma-Overdose
                Font=fusion-pixel-10px-proportional-latin,10,-1,5,50,0,0,0,0,0

                [Background]
                BackgroundImage=${windose20}/share/windose20/pngs/JINEBG.png
                BackgroundImageStyle=1
              '';
            };
          };
      in
      {
        home-manager.sharedModules = [ windose20HomeModule ];

        specialisation.windose20.configuration = {
          system.nixos.tags = [ "windose20" ];
          system.nixos.distroName = lib.mkForce "Windose20";
          system.nixos.extraOSReleaseArgs = {
            HOME_URL = "https://angelkawaii.com/";
            DOCUMENTATION_URL = "https://angelkawaii.com/";
            LOGO = "${windose20}/share/windose20/pngs/logo_with_name.png";
          };

          fonts.packages = [ windose20 ];

          environment.systemPackages = [
            windose20
            plasmaOverdose
          ];

          environment.etc."xdg/fastfetch/config.jsonc".source =
            "${windose20}/share/windose20/configs/fastfetch.jsonc";

          boot.plymouth = {
            enable = lib.mkForce true;
            theme = lib.mkForce "windose20";
            themePackages = lib.mkForce [ windose20 ];
          };
        };
      };
  };
}
