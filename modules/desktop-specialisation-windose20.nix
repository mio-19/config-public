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
        windose20Wallpaper = "${plasmaOverdose}/share/wallpapers/Plasma-Overdose/tile.png";
        windose20Font = "fusion-pixel-10px-proportional-latin,10,-1,5,50,0,0,0,0,0";
        windose20PlasmaloginKdeglobals = pkgs.writeText "windose20-plasmalogin-kdeglobals" ''
          [KDE]
          LookAndFeelPackage=Plasma-Overdose

          [General]
          font=${windose20Font}
          fixed=${windose20Font}
        '';
        # Beat per-user mkForce (priority 50) when the windose20 specialisation is active.
        windose20Prio = lib.mkOverride 0;
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

            programs.plasma =
              lib.recursiveUpdate
                {
                  workspace = {
                    lookAndFeel = windose20Prio "Plasma-Overdose";
                    cursor = {
                      theme = windose20Prio "Plasma-Overdose";
                      size = 24;
                    };
                    wallpaper = windose20Prio windose20Wallpaper;
                  };
                  fonts = {
                    general = {
                      family = windose20Prio "fusion-pixel-10px-proportional-latin";
                      pointSize = 10;
                    };
                    fixedWidth = {
                      family = windose20Prio "fusion-pixel-10px-proportional-latin";
                      pointSize = 10;
                    };
                  };
                }
                (
                  lib.optionalAttrs (osConfig.windose20_automate_kickoff or false) {
                    panels = [
                      {
                        location = "bottom";
                        widgets = [
                          {
                            kickoff = {
                              icon = "${windose20}/share/windose20/pngs/logo.png";
                              label = "Start";
                            };
                          }
                          "org.kde.plasma.pager"
                          "org.kde.plasma.icontasks"
                          "org.kde.plasma.marginsseparator"
                          "org.kde.plasma.systemtray"
                          "org.kde.plasma.digitalclock"
                          "org.kde.plasma.showdesktop"
                        ];
                      }
                    ];
                  }
                );

            xdg.configFile = {
              "fastfetch/config.jsonc".source = "${windose20}/share/windose20/configs/fastfetch.jsonc";
              "neofetch/config.conf".source = "${windose20}/share/windose20/configs/neofetch.conf";
              "cava/config".source = "${windose20}/share/windose20/configs/cava.conf";
              "konsole/Plasma-Overdose.profile".text = ''
                [Appearance]
                ColorScheme=Plasma-Overdose
                Font=${windose20Font}

                [Background]
                BackgroundImage=${windose20}/share/windose20/pngs/JINEBG.png
                BackgroundImageStyle=1
              '';
            };
          };
        windose20RestoreHomeModule =
          {
            osConfig,
            config,
            lib,
            pkgs,
            ...
          }:
          let
            inWindose20 = builtins.elem "windose20" osConfig.system.nixos.tags;
            systemBackground = toString osConfig.system_background;
            windose20RestoreScript = ''
              set -eu
              config_home="${config.xdg.configHome}"

              windose20_config_detected() {
                for f in "$config_home/kdeglobals" "$config_home/plasma-org.kde.plasma.desktop-appletsrc"; do
                  [ -f "$f" ] || continue
                  if grep -qE 'Plasma-Overdose|fusion-pixel-10px-proportional-latin|windose20' "$f" 2>/dev/null; then
                    return 0
                  fi
                done
                [ -f "$config_home/konsole/Plasma-Overdose.profile" ] && return 0
                return 1
              }

              if ! windose20_config_detected; then
                exit 0
              fi

              kdeglobals="$config_home/kdeglobals"
              if [ -f "$kdeglobals" ]; then
                ${pkgs.gnused}/bin/sed -i \
                  -e 's/LookAndFeelPackage=Plasma-Overdose/LookAndFeelPackage=org.kde.breeze.desktop/g' \
                  -e 's/ColorScheme=Plasma-Overdose/ColorScheme=BreezeLight/g' \
                  -e 's|theme=Plasma-Overdose|theme=breeze_cursors|g' \
                  "$kdeglobals"
              fi

              rm -f "$config_home/konsole/Plasma-Overdose.profile"
              for rel in fastfetch/config.jsonc neofetch/config.conf cava/config; do
                target="$config_home/$rel"
                if [ -e "$target" ] && grep -qF 'share/windose20/' "$target" 2>/dev/null; then
                  rm -f "$target"
                fi
              done
            '';
          in
          lib.mkIf (!inWindose20 && osConfig.services.desktopManager.plasma6.enable) {
            # Eval-time gate uses only the boot specialisation tag. Detection and
            # restore run during home-manager activation on the live profile.
            home.activation.windose20RestoreBeforePlasma = lib.hm.dag.entryBefore [
              "writeBoundary"
            ] windose20RestoreScript;

            home.activation.windose20RestoreAfterPlasma = lib.hm.dag.entryAfter [ "writeBoundary" ] (
              windose20RestoreScript
              + ''
                if [ -n "''${DBUS_SESSION_BUS_ADDRESS:-}" ] && [ -x "${pkgs.kdePackages.plasma-workspace}/bin/plasma-apply-lookandfeel" ]; then
                  ${pkgs.kdePackages.plasma-workspace}/bin/plasma-apply-lookandfeel org.kde.breeze.desktop || true
                  ${pkgs.kdePackages.plasma-workspace}/bin/plasma-apply-cursortheme breeze_cursors || true
                  ${pkgs.kdePackages.plasma-workspace}/bin/plasma-apply-wallpaperimage \
                    --fill-mode preserveAspectCrop "${systemBackground}" || true
                fi
              ''
            );
          };
      in
      {
        home-manager.sharedModules = [
          windose20HomeModule
          windose20RestoreHomeModule
        ];

        system.activationScripts.windose20PlasmaloginRestore =
          lib.mkIf
            (
              config.services.displayManager.plasma-login-manager.enable
              && !(builtins.elem "windose20" config.system.nixos.tags)
              && !(builtins.elem "windose20-xfce" config.system.nixos.tags)
            )
            {
              text = ''
                kdeglobals=/var/lib/plasmalogin/.config/kdeglobals
                if [ -e "$kdeglobals" ] && grep -qE 'Plasma-Overdose|fusion-pixel-10px-proportional-latin' "$kdeglobals" 2>/dev/null; then
                  rm -f "$kdeglobals"
                fi
              '';
            };

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
                  FillMode = 1; # tiled, matching the Plasma workspace wallpaper
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
