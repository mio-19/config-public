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
        windose20Wallpaper = "${windose20}/share/windose20/pngs/bg.png";
        windose20Logo = "${windose20}/share/windose20/pngs/logo.png";
        windose20FontFamily = "Fusion Pixel 10px Prop latin";
        windose20MonoFamily = "Fusion Pixel 10px Mono latin";
        windose20Font = "${windose20FontFamily} 10";
        windose20KdeFont = "${windose20FontFamily},10,-1,5,50,0,0,0,0,0";
        windose20KdeSmallFont = "${windose20FontFamily},8,-1,5,50,0,0,0,0,0";
        windose20KdeMonoFont = "${windose20MonoFamily},10,-1,5,50,0,0,0,0,0";
        windose20Accent = "#FF70A6";
        windose20FontconfigSansFamilies = [
          "Open Sans"
          "OpenSans"
          "Segoe UI"
          "Tahoma"
          "MS Sans Serif"
          "Mona Sans"
          "Hubot Sans"
          "Arial"
          "Helvetica"
          "Noto Sans"
          "system-ui"
          "ui-sans-serif"
          "-apple-system"
          "BlinkMacSystemFont"
          "SF Pro"
          "Cantarell"
          "Ubuntu"
          "Roboto"
          "Inter"
          "DejaVu Sans"
          "Liberation Sans"
        ];
        windose20FontconfigMonoFamilies = [
          "Mona Sans Mono"
          "ui-monospace"
          "SFMono-Regular"
          "SF Mono"
          "Menlo"
          "Consolas"
          "Liberation Mono"
          "Courier New"
          "DejaVu Sans Mono"
        ];
        windose20FontconfigMatch = targetFamily: replaceFamily: ''
          <match target="pattern">
            <test name="family" qual="any" compare="contains">
              <string>${targetFamily}</string>
            </test>
            <edit name="family" mode="assign" binding="strong">
              <string>${replaceFamily}</string>
            </edit>
          </match>
        '';
        windose20FontconfigRules =
          lib.concatMapStrings (
            f: windose20FontconfigMatch f windose20FontFamily
          ) windose20FontconfigSansFamilies
          + lib.concatMapStrings (
            f: windose20FontconfigMatch f windose20MonoFamily
          ) windose20FontconfigMonoFamilies;
        windose20FontconfigFileText = ''
          <?xml version="1.0"?>
          <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
          <fontconfig>
            <!-- Windose20: remap UI/web fonts to Fusion Pixel (Telegram, GitHub fallbacks, etc.) -->
            ${windose20FontconfigRules}
          </fontconfig>
        '';
        windose20LibrewolfOverrides = ''
          // Windose20: force browser UI fonts; ignore document/webfonts (GitHub Mona Sans, etc.)
          defaultPref("browser.display.use_document_fonts", 0);
          defaultPref("gfx.downloadable_fonts.enabled", false);
          defaultPref("font.name.serif.x-western", "${windose20FontFamily}");
          defaultPref("font.name.sans-serif.x-western", "${windose20FontFamily}");
          defaultPref("font.name.monospace.x-western", "${windose20MonoFamily}");
          defaultPref("font.name.serif.x-cyrillic", "${windose20FontFamily}");
          defaultPref("font.name.sans-serif.x-cyrillic", "${windose20FontFamily}");
          defaultPref("font.name.monospace.x-cyrillic", "${windose20MonoFamily}");
        '';
        windose20PlasmaloginKdeglobals = pkgs.writeText "windose20-plasmalogin-kdeglobals" ''
          [KDE]
          LookAndFeelPackage=Plasma-Overdose
          widgetStyle=Breeze

          [General]
          ColorScheme=PlasmaOverdose
          font=${windose20KdeFont}
          fixed=${windose20KdeMonoFont}
          smallestReadableFont=${windose20KdeSmallFont}
          toolBarFont=${windose20KdeFont}
          menuFont=${windose20KdeFont}
          windowTitleFont=${windose20KdeFont}

          [Icons]
          Theme=breeze
        '';
        windose20PlasmaloginKcminputrc = pkgs.writeText "windose20-plasmalogin-kcminputrc" ''
          [Mouse]
          cursorTheme=Plasma-Overdose
          cursorSize=24
        '';
        windose20PlasmaloginPlasmarc = pkgs.writeText "windose20-plasmalogin-plasmarc" ''
          [Theme]
          name=Plasma-Overdose
        '';
        windose20SddmThemeConf = pkgs.writeTextDir "share/sddm/themes/breeze/theme.conf.user" ''
          [General]
          background=${windose20Wallpaper}
          type=image
          showlogo=shown
          logo=${windose20Logo}
          color=${windose20Accent}
          fontSize=10
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
                name = windose20FontFamily;
                size = 10;
              };
              theme = {
                name = gtkThemeName;
                package = needyGirlOverdoseTheme;
              };
              iconTheme = {
                name = "breeze";
                package = pkgs.kdePackages.breeze-icons;
              };
              gtk3.extraConfig = {
                gtk-application-prefer-dark-theme = 0;
              };
              gtk4.extraConfig = {
                gtk-application-prefer-dark-theme = 0;
              };
            };

            dconf.settings = {
              "org/gnome/desktop/interface" = {
                color-scheme = "prefer-light";
                font-name = "${windose20FontFamily} 10";
                document-font-name = "${windose20FontFamily} 10";
                monospace-font-name = "${windose20MonoFamily} 10";
              };
              "org/gnome/Console" = {
                use-system-font = true;
                custom-font = "${windose20MonoFamily} 10";
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
                  "backdrop/screen0/monitor0/workspace0/image-style" = 5;
                  "backdrop/screen0/monitor0/workspace1/last-image" = windose20Wallpaper;
                  "backdrop/screen0/monitor0/workspace1/image-style" = 5;
                  "backdrop/screen0/monitor0/workspace2/last-image" = windose20Wallpaper;
                  "backdrop/screen0/monitor0/workspace2/image-style" = 5;
                  "backdrop/screen0/monitor0/workspace3/last-image" = windose20Wallpaper;
                  "backdrop/screen0/monitor0/workspace3/image-style" = 5;
                };
                xsettings = {
                  "Gtk/FontName" = windose20Font;
                  "Gtk/MonospaceFontName" = "${windose20MonoFamily} 10";
                  "Gtk/CursorThemeName" = "Plasma-Overdose";
                  "Gtk/CursorThemeSize" = 24;
                  "Gtk/IconThemeName" = "breeze";
                  "Net/ThemeName" = gtkThemeName;
                  "Net/IconThemeName" = "breeze";
                };
              };
            };

            xdg.configFile = {
              "fastfetch/config.jsonc".source = "${windose20}/share/windose20/configs/fastfetch.jsonc";
              "neofetch/config.conf".source = "${windose20}/share/windose20/configs/neofetch.conf";
              "cava/config".source = "${windose20}/share/windose20/configs/cava.conf";
              "fontconfig/conf.d/99-windose20.conf".text = windose20FontconfigFileText;
            };

            home.file.".librewolf/librewolf.overrides.cfg".text = windose20LibrewolfOverrides;
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

          fonts.fontconfig = {
            defaultFonts = {
              sansSerif = lib.mkForce [
                windose20FontFamily
                "Noto Sans CJK SC"
              ];
              serif = lib.mkForce [
                windose20FontFamily
                "Noto Serif CJK SC"
              ];
              monospace = lib.mkForce [
                windose20MonoFamily
                "FiraCode Nerd Font"
              ];
            };
            localConf = ''
              <!-- Windose20: remap UI/web fonts to Fusion Pixel (Telegram, GitHub fallbacks, etc.) -->
              ${windose20FontconfigRules}
            '';
          };
          programs.xfconf.enable = true;

          services.desktopManager.plasma6.enable = lib.mkForce false;
          services.xserver.desktopManager.xfce.enable = lib.mkForce true;
          services.displayManager.defaultSession = lib.mkForce "xfce";

          environment.systemPackages = [
            windose20
            plasmaOverdose
            needyGirlOverdoseTheme
            (lib.hiPrio (
              pkgs.writeShellScriptBin "chromium" ''
                exec ${lib.getExe pkgs.chromium} --disable-remote-fonts "$@"
              ''
            ))
          ]
          ++ lib.optionals config.services.displayManager.sddm.enable [
            (lib.hiPrio windose20SddmThemeConf)
          ];

          environment.etc."xdg/fastfetch/config.jsonc".source =
            "${windose20}/share/windose20/configs/fastfetch.jsonc";

          services.displayManager.sddm = lib.mkIf config.services.displayManager.sddm.enable {
            theme = lib.mkForce "breeze";
            settings = {
              Theme = {
                Current = "breeze";
                CursorTheme = "Plasma-Overdose";
                CursorSize = "24";
                Font = windose20FontFamily;
              };
            };
          };

          services.displayManager.plasma-login-manager.settings =
            lib.mkIf config.services.displayManager.plasma-login-manager.enable
              {
                Greeter.WallpaperPluginId = "org.kde.image";
                "Greeter/Wallpaper/org.kde.image/General" = {
                  Image = "file://${windose20Wallpaper}";
                  FillMode = 2;
                };
              };

          system.activationScripts.windose20Plasmalogin =
            lib.mkIf config.services.displayManager.plasma-login-manager.enable
              {
                text = ''
                  plm_home=/var/lib/plasmalogin
                  if [ -d "$plm_home" ]; then
                    mkdir -p "$plm_home/.config/kdedefaults"
                    ln -sfn ${windose20PlasmaloginKdeglobals} "$plm_home/.config/kdeglobals"
                    ln -sfn ${windose20PlasmaloginKdeglobals} "$plm_home/.config/kdedefaults/kdeglobals"
                    ln -sfn ${windose20PlasmaloginKcminputrc} "$plm_home/.config/kdedefaults/kcminputrc"
                    ln -sfn ${windose20PlasmaloginKcminputrc} "$plm_home/.config/kcminputrc"
                    ln -sfn ${windose20PlasmaloginPlasmarc} "$plm_home/.config/kdedefaults/plasmarc"
                    chown -R plasmalogin:plasmalogin "$plm_home/.config" || true
                  fi
                '';
              };

          system.activationScripts.windose20Sddm = lib.mkIf config.services.displayManager.sddm.enable {
            text = ''
              sddm_home=/var/lib/sddm
              if [ -d "$sddm_home" ]; then
                mkdir -p "$sddm_home/.config"
                ln -sfn ${windose20PlasmaloginKdeglobals} "$sddm_home/.config/kdeglobals"
                ln -sfn ${windose20PlasmaloginKcminputrc} "$sddm_home/.config/kcminputrc"
                chown -R sddm:sddm "$sddm_home/.config" 2>/dev/null || true
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
