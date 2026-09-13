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
        windose20Wallpaper = "${windose20}/share/windose20/pngs/bg.png";
        windose20Logo = "${windose20}/share/windose20/pngs/logo.png";
        # Real fontconfig family names from the TTFs (not the filenames).
        windose20FontFamily = "Fusion Pixel 10px Prop latin";
        windose20MonoFamily = "Fusion Pixel 10px Mono latin";
        windose20Font = "${windose20FontFamily},10,-1,5,50,0,0,0,0,0";
        windose20SmallFont = "${windose20FontFamily},8,-1,5,50,0,0,0,0,0";
        windose20MonoFont = "${windose20MonoFamily},10,-1,5,50,0,0,0,0,0";
        # Accent used by Plymouth/NGO splash (#FF70A6) for SDDM solid fallback / chrome.
        windose20Accent = "#FF70A6";
        # Remap common UI / web font families to Fusion Pixel (system lookups + site fallbacks).
        # Downloaded @font-face (e.g. GitHub Mona Sans woff2) still bypasses fontconfig —
        # browsers also get use_document_fonts=0 / --disable-remote-fonts below.
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
        # LibreWolf: ignore page @font-face so GitHub Mona Sans etc. cannot bypass fontconfig.
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
        # Greeter theming: PLM reads kdedefaults/* (not only ~/.config/kdeglobals).
        windose20PlasmaloginKdeglobals = pkgs.writeText "windose20-plasmalogin-kdeglobals" ''
          [KDE]
          LookAndFeelPackage=Plasma-Overdose
          widgetStyle=Breeze

          [General]
          ColorScheme=PlasmaOverdose
          font=${windose20Font}
          fixed=${windose20MonoFont}
          smallestReadableFont=${windose20SmallFont}
          toolBarFont=${windose20Font}
          menuFont=${windose20Font}
          windowTitleFont=${windose20Font}

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
        # Beat per-user mkForce (priority 50) when the windose20 specialisation is active.
        windose20Prio = lib.mkOverride 0;
        windose20HomeModule =
          {
            osConfig,
            config,
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

            # NGO Plasma-Overdose is a light pink scheme; keep GTK from flipping dark.
            # Beat baseline Adwaita iconTheme when this specialisation is active.
            gtk = {
              enable = true;
              font = {
                name = windose20FontFamily;
                size = 10;
              };
              iconTheme = {
                name = windose20Prio "breeze";
                package = windose20Prio pkgs.kdePackages.breeze-icons;
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
                # kgx (GNOME Console) follows this when use-system-font is true.
                monospace-font-name = "${windose20MonoFamily} 10";
              };
              "org/gnome/Console" = {
                use-system-font = true;
                custom-font = "${windose20MonoFamily} 10";
              };
            };

            programs.plasma = {
              workspace = {
                lookAndFeel = windose20Prio "Plasma-Overdose";
                # Match ColorScheme= id inside PlasmaOverdose.colors (not the hyphenated filename).
                colorScheme = windose20Prio "PlasmaOverdose";
                # Directory name is lowercase; capital "Breeze" misses icons on case-sensitive FS.
                iconTheme = windose20Prio "breeze";
                cursor = {
                  theme = windose20Prio "Plasma-Overdose";
                  size = 24;
                };
                wallpaper = windose20Prio windose20Wallpaper;
                wallpaperFillMode = windose20Prio "preserveAspectCrop";
              };
              fonts = {
                general = {
                  family = windose20Prio windose20FontFamily;
                  pointSize = 10;
                };
                fixedWidth = {
                  family = windose20Prio windose20MonoFamily;
                  pointSize = 10;
                };
                small = {
                  family = windose20Prio windose20FontFamily;
                  pointSize = 8;
                };
                toolbar = {
                  family = windose20Prio windose20FontFamily;
                  pointSize = 10;
                };
                menu = {
                  family = windose20Prio windose20FontFamily;
                  pointSize = 10;
                };
                windowTitle = {
                  family = windose20Prio windose20FontFamily;
                  pointSize = 10;
                };
              };
            };
            home.activation.windose20ApplyTaskbar = config.lib.dag.entryBefore [ "writeBoundary" ] ''
              appletsrc="''${config.xdg.configHome}/plasma-org.kde.plasma.desktop-appletsrc"
              if [ -f "$appletsrc" ]; then
                kickoffs=$(${lib.getExe pkgs.gawk} -F'[][]' '/plugin=org\.kde\.plasma\.kickoff/ {
                    split(prev, a, /\]\[|\[|\]/)
                    print a[3] " " a[5]
                }
                /^\[/ { prev=$0 }' "$appletsrc")

                echo "$kickoffs" | while read -r c_id a_id; do
                  if [ -n "$c_id" ] && [ -n "$a_id" ]; then
                    ${lib.getExe' pkgs.kdePackages.kconfig "kwriteconfig6"} --file "$appletsrc" --group Containments --group "$c_id" --group Applets --group "$a_id" --group Configuration --group General --key icon "${windose20}/share/windose20/pngs/logo.png"
                    ${lib.getExe' pkgs.kdePackages.kconfig "kwriteconfig6"} --file "$appletsrc" --group Containments --group "$c_id" --group Applets --group "$a_id" --group Configuration --group General --key menuLabel "Start"
                  fi
                done

                icontasks=$(${lib.getExe pkgs.gawk} -F'[][]' '/plugin=org\.kde\.plasma\.icontasks/ {
                    split(prev, a, /\]\[|\[|\]/)
                    print a[3] " " a[5]
                }
                /^\[/ { prev=$0 }' "$appletsrc")

                echo "$icontasks" | while read -r c_id a_id; do
                  if [ -n "$c_id" ] && [ -n "$a_id" ]; then
                    ${lib.getExe' pkgs.kdePackages.kconfig "kwriteconfig6"} --file "$appletsrc" --group Containments --group "$c_id" --group Applets --group "$a_id" --key plugin "org.kde.plasma.taskmanager"
                    ${lib.getExe' pkgs.kdePackages.kconfig "kwriteconfig6"} --file "$appletsrc" --group Containments --group "$c_id" --group Applets --group "$a_id" --group Configuration --group General --key windose20_was_icontasks "true"
                  fi
                done
              fi
            '';

            xdg.configFile = {
              "fastfetch/config.jsonc".source = "${windose20}/share/windose20/configs/fastfetch.jsonc";
              "neofetch/config.conf".source = "${windose20}/share/windose20/configs/neofetch.conf";
              "cava/config".source = "${windose20}/share/windose20/configs/cava.conf";
              "konsole/Plasma-Overdose.profile".text = ''
                [Appearance]
                ColorScheme=Plasma-Overdose
                Font=${windose20MonoFont}

                [Background]
                BackgroundImage=${windose20}/share/windose20/pngs/JINEBG.png
                BackgroundImageStyle=1
              '';
              "fontconfig/conf.d/99-windose20.conf".text = windose20FontconfigFileText;
            };

            # LibreWolf: ignore GitHub/other @font-face so Fusion Pixel wins in the browser.
            home.file.".librewolf/librewolf.overrides.cfg".text = windose20LibrewolfOverrides;
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
            plasmaWallpaper = config.programs.plasma.workspace.wallpaper or null;
            plasmaApplyWallpaper = lib.getExe' pkgs.kdePackages.plasma-workspace "plasma-apply-wallpaperimage";
            plasmaApplyLookAndFeel = lib.getExe' pkgs.kdePackages.plasma-workspace "plasma-apply-lookandfeel";
            plasmaApplyColorScheme = lib.getExe' pkgs.kdePackages.plasma-workspace "plasma-apply-colorscheme";
            plasmaApplyCursorTheme = lib.getExe' pkgs.kdePackages.plasma-workspace "plasma-apply-cursortheme";
            plasmaChangeIcons = "${pkgs.kdePackages.plasma-workspace}/libexec/plasma-changeicons";
            dconfBin = lib.getExe pkgs.dconf;
            grepBin = lib.getExe' pkgs.gnugrep "grep";
            sedBin = lib.getExe' pkgs.gnused "sed";
            awkBin = lib.getExe pkgs.gawk;
            kwriteconfig6Bin = lib.getExe' pkgs.kdePackages.kconfig "kwriteconfig6";
            plasmaWallpaperApplyScript =
              if plasmaWallpaper == null then
                ""
              else
                ''
                  if [ -n "''${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
                    ${plasmaApplyWallpaper} "${plasmaWallpaper}" || true
                  fi
                '';
            windose20RestoreScript = ''
              set -eu
              config_home="${config.xdg.configHome}"

              windose20_config_detected() {
                for f in "$config_home/kdeglobals" "$config_home/plasma-org.kde.plasma.desktop-appletsrc" "$config_home/kcminputrc" "$config_home/gtk-3.0/settings.ini" "$config_home/gtk-4.0/settings.ini" "$config_home/gtkrc-2.0" "$HOME/.icons/default/index.theme" "$HOME/.local/share/icons/default/index.theme"; do
                  [ -f "$f" ] || continue
                  if ${grepBin} -qiE 'Plasma-Overdose|Fusion Pixel 10px|fusion-pixel-10px|windose20' "$f" 2>/dev/null; then
                    return 0
                  fi
                done
                [ -f "$config_home/konsole/Plasma-Overdose.profile" ] && return 0
                [ -f "$config_home/fontconfig/conf.d/99-windose20.conf" ] && return 0
                [ -f "$HOME/.librewolf/librewolf.overrides.cfg" ] && ${grepBin} -q 'Windose20' "$HOME/.librewolf/librewolf.overrides.cfg" 2>/dev/null && return 0
                if ${dconfBin} dump /org/gnome/ 2>/dev/null | ${grepBin} -qiE 'Fusion Pixel'; then
                  return 0
                fi
                return 1
              }

              if windose20_config_detected; then
                kdeglobals="$config_home/kdeglobals"
                if [ -f "$kdeglobals" ]; then
                  ${sedBin} -i \
                    -e 's/LookAndFeelPackage=Plasma-Overdose/LookAndFeelPackage=org.kde.breeze.desktop/ig' \
                    -e 's/ColorScheme=Plasma-Overdose/ColorScheme=BreezeLight/ig' \
                    -e 's/ColorScheme=PlasmaOverdose/ColorScheme=BreezeLight/ig' \
                    -e 's|[tT]heme=Plasma-Overdose|Theme=breeze_cursors|ig' \
                    -e '/.*[fF]ont=Fusion Pixel 10px/Id' \
                    -e '/^fixed=Fusion Pixel 10px/Id' \
                    -e '/.*[fF]ont=fusion-pixel-10px/Id' \
                    -e '/^fixed=fusion-pixel-10px/Id' \
                    "$kdeglobals"
                fi

                kcminputrc="$config_home/kcminputrc"
                if [ -f "$kcminputrc" ]; then
                  ${sedBin} -i \
                    -e 's/[cC]ursor[tT]heme=Plasma-Overdose/cursorTheme=breeze_cursors/ig' \
                    "$kcminputrc"
                fi

                for gtk in "$config_home/gtk-3.0/settings.ini" "$config_home/gtk-4.0/settings.ini" "$config_home/gtkrc-2.0"; do
                  if [ -f "$gtk" ]; then
                    ${sedBin} -i 's/Plasma-Overdose/breeze_cursors/ig' "$gtk"
                  fi
                done

                appletsrc="$config_home/plasma-org.kde.plasma.desktop-appletsrc"
                if [ -f "$appletsrc" ]; then
                  icontasks_to_restore=$(${awkBin} -F'[][]' '/windose20_was_icontasks=true/ {
                      split(prev, a, /\]\[|\[|\]/)
                      print a[3] " " a[5]
                  }
                  /^\[/ { prev=$0 }' "$appletsrc")

                  echo "$icontasks_to_restore" | while read -r c_id a_id; do
                    if [ -n "$c_id" ] && [ -n "$a_id" ]; then
                      ${kwriteconfig6Bin} --file "$appletsrc" --group Containments --group "$c_id" --group Applets --group "$a_id" --key plugin "org.kde.plasma.icontasks"
                      ${kwriteconfig6Bin} --file "$appletsrc" --group Containments --group "$c_id" --group Applets --group "$a_id" --group Configuration --group General --key windose20_was_icontasks --delete
                    fi
                  done

                  ${sedBin} -i \
                    -e '/Plasma-Overdose/Id' \
                    -e '/windose20/Id' \
                    -e '/^menuLabel=Start$/d' \
                    "$appletsrc"
                fi

                rm -f "$config_home/konsole/Plasma-Overdose.profile"
                rm -f "$config_home/fontconfig/conf.d/99-windose20.conf"
                rm -f "$HOME/.librewolf/librewolf.overrides.cfg"
                for rel in fastfetch/config.jsonc neofetch/config.conf cava/config; do
                  target="$config_home/$rel"
                  if [ -e "$target" ] && { ${grepBin} -qF 'share/windose20/' "$target" 2>/dev/null || readlink "$target" 2>/dev/null | ${grepBin} -q 'share/windose20/'; }; then
                    rm -f "$target"
                  fi
                done

                # Clean up ~/.icons/default if plasma-apply-cursortheme made it a directory
                if [ -d "$HOME/.icons/default" ] && ! [ -L "$HOME/.icons/default" ]; then
                  if ${grepBin} -q "Plasma-Overdose" "$HOME/.icons/default/index.theme" 2>/dev/null; then
                    rm -rf "$HOME/.icons/default"
                  fi
                fi

                ${dconfBin} reset -f /org/gnome/Console/ 2>/dev/null || true
                ${dconfBin} reset /org/gnome/desktop/interface/font-name 2>/dev/null || true
                ${dconfBin} reset /org/gnome/desktop/interface/document-font-name 2>/dev/null || true
                ${dconfBin} reset /org/gnome/desktop/interface/monospace-font-name 2>/dev/null || true
                ${dconfBin} reset /org/gnome/desktop/interface/color-scheme 2>/dev/null || true

                # Signal AfterPlasma to run dbus commands
                touch "$config_home/.windose20_restore_pending"
              fi
            '';
          in
          lib.mkIf (!inWindose20) {
            # Eval-time gate uses only the boot specialisation tag. Detection and
            # Breeze restore run during home-manager activation on the live profile.
            home.activation.windose20RestoreBeforePlasma = lib.hm.dag.entryBefore [
              "writeBoundary"
            ] windose20RestoreScript;

            home.activation.windose20RestoreAfterPlasma = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              config_home="${config.xdg.configHome}"
              if [ -f "$config_home/.windose20_restore_pending" ]; then
                rm -f "$config_home/.windose20_restore_pending"
                if [ -n "''${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
                  ${plasmaApplyLookAndFeel} org.kde.breeze.desktop || true
                  ${plasmaApplyColorScheme} BreezeLight || true
                  ${plasmaApplyCursorTheme} breeze_cursors || true
                  ${plasmaChangeIcons} breeze || true
                fi
                ${plasmaWallpaperApplyScript}
              fi
            '';
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
            )
            {
              text = ''
                plm_home=/var/lib/plasmalogin
                for f in \
                  "$plm_home/.config/kdeglobals" \
                  "$plm_home/.config/kdedefaults/kdeglobals" \
                  "$plm_home/.config/kdedefaults/kcminputrc" \
                  "$plm_home/.config/kdedefaults/plasmarc" \
                  "$plm_home/.config/kcminputrc"; do
                  if [ -e "$f" ] && ${lib.getExe' pkgs.gnugrep "grep"} -qE 'Plasma-Overdose|PlasmaOverdose|Fusion Pixel 10px|fusion-pixel-10px|windose20' "$f" 2>/dev/null; then
                    rm -f "$f"
                  fi
                done
              '';
            };

        system.activationScripts.windose20SddmRestore =
          lib.mkIf
            (
              config.services.displayManager.sddm.enable && !(builtins.elem "windose20" config.system.nixos.tags)
            )
            {
              text = ''
                sddm_home=/var/lib/sddm
                for f in "$sddm_home/.config/kdeglobals" "$sddm_home/.config/kcminputrc"; do
                  if [ -e "$f" ] && ${lib.getExe' pkgs.gnugrep "grep"} -qE 'Plasma-Overdose|PlasmaOverdose|Fusion Pixel 10px|fusion-pixel-10px|windose20' "$f" 2>/dev/null; then
                    rm -f "$f"
                  fi
                done
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

          environment.systemPackages = [
            windose20
            plasmaOverdose
            # Chromium: block remote @font-face (GitHub Mona Sans) without rebuilding chromium.
            (lib.hiPrio (
              pkgs.writeShellScriptBin "chromium" ''
                exec ${lib.getExe pkgs.chromium} --disable-remote-fonts "$@"
              ''
            ))
          ]
          ++ lib.optionals config.services.displayManager.sddm.enable [
            # Beat baseline theme.conf.user from desktop-basic.
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
                  FillMode = 2; # PreserveAspectCrop — full README bg.png, not tiled
                };
              };

          systemd.tmpfiles.rules =
            (lib.optionals config.services.displayManager.plasma-login-manager.enable [
              "d /var/lib/plasmalogin/.config/kdedefaults 0755 plasmalogin plasmalogin"
              "L+ /var/lib/plasmalogin/.config/kdeglobals - - - - ${windose20PlasmaloginKdeglobals}"
              "L+ /var/lib/plasmalogin/.config/kdedefaults/kdeglobals - - - - ${windose20PlasmaloginKdeglobals}"
              "L+ /var/lib/plasmalogin/.config/kcminputrc - - - - ${windose20PlasmaloginKcminputrc}"
              "L+ /var/lib/plasmalogin/.config/kdedefaults/kcminputrc - - - - ${windose20PlasmaloginKcminputrc}"
              "L+ /var/lib/plasmalogin/.config/kdedefaults/plasmarc - - - - ${windose20PlasmaloginPlasmarc}"
            ])
            ++ (lib.optionals config.services.displayManager.sddm.enable [
              "d /var/lib/sddm/.config 0755 sddm sddm"
              "L+ /var/lib/sddm/.config/kdeglobals - - - - ${windose20PlasmaloginKdeglobals}"
              "L+ /var/lib/sddm/.config/kcminputrc - - - - ${windose20PlasmaloginKcminputrc}"
            ]);

          boot.plymouth = {
            enable = lib.mkForce true;
            theme = lib.mkForce "windose20";
            themePackages = lib.mkForce [ windose20 ];
          };
        };
      };
  };
}
