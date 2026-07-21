# Full desktop packages and apps (den.aspects.desktop-full).
{ den, inputs, ... }:
let
  # cross-platform apps shared between the NixOS desktop-full body and the darwin
  # common branch (modules/common.nix). Defined once so both stay in sync: NixOS
  # applies hardenedPkg/cleanPkg and gates x86_64-only ones,
  # darwin installs them plain/unconditional.
  sharedApps =
    { pkgs, progs }:
    {
      hardened = with pkgs; [
        inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.omnimux
        localsend
        inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.pear-desktop_patched # pear-desktop
        element-desktop
        qbittorrent-enhanced
        progs.materialgram
      ];
      clean = [
        progs.librewolf' # progs.librewolf'_for_firejail
      ];
      cleanX86 = with pkgs; [
      ];
    };
in
{
  den.aspects.thunderbird = {
    description = "thunderbird";
    darwin =
      args@{ pkgs, _include, ... }:
      with _include;
      {
        environment.systemPackages = [
          pkgs.thunderbird-esr
        ];
      };
    nixos =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        _include,
        ...
      }:
      with _include;
      {
        environment.systemPackages =
          with pkgs;
          (map cleanPkg [
            (if config.use_betterbird then progs.betterbird else progs.thunderbird-esr')
          ]);
        programs.firejail.wrappedBinaries = (
          if config.use_betterbird then
            {
              betterbird = {
                executable = "${cleanPkg progs.betterbird}/bin/betterbird";
                profile = "${pkgs.firejail}/etc/firejail/thunderbird.profile";
                extraArgs = [
                  # https://github.com/netblue30/firejail/issues/5062 - light/dark theme switching
                  "--dbus-user.talk=org.freedesktop.portal.Desktop"
                  "--ignore=noroot"
                ];
              };
            }
          else
            {
              thunderbird = {
                executable = "${cleanPkg progs.thunderbird-esr'}/bin/thunderbird";
                profile = "${pkgs.firejail}/etc/firejail/thunderbird.profile";
                extraArgs = [
                  # https://github.com/netblue30/firejail/issues/5062 - light/dark theme switching
                  "--dbus-user.talk=org.freedesktop.portal.Desktop"
                  "--ignore=noroot"
                ];
              };
            }
        );
        # Open http(s) via xdg-open + portal (same as Telegram/materialgram).
        # policies.json sets Handlers to xdg-open; firejail must allow the script
        # and portal dbus so the browser starts outside this sandbox.
        environment.etc."firejail/thunderbird.local".text = ''
          include allow-bin-sh.inc
          noblacklist ${"$"}{PATH}/xdg-open
          dbus-user.talk org.freedesktop.portal.Desktop
          dbus-user.talk org.freedesktop.portal.OpenURI
          ignore noroot
          whitelist /run/current-system
          whitelist /run/wrappers
          ignore private-bin
        '';

      };
  };
  den.aspects.telegram = {
    description = "Telegram";
    darwin =
      args@{ pkgs, ... }:
      let
        _include = args._include or import ../mac/include.nix args;
      in
      with _include;
      {
        environment.systemPackages = [
          progs.telegram
        ];
      };
    nixos =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        ...
      }:
      let
        _include = args._include or (import ../nixos/include.nix args);
      in
      with _include;
      {
        environment.systemPackages = with pkgs; [
          (hardenedPkg progs.telegram)
        ];

        programs.firejail.wrappedBinaries = {
          Telegram = {
            executable = "${hardenedPkg progs.telegram}/bin/Telegram";
            profile = "${pkgs.firejail}/etc/firejail/Telegram.profile";
            extraArgs = [
              # https://github.com/netblue30/firejail/issues/5062 - light/dark theme switching
              "--dbus-user.talk=org.freedesktop.portal.Desktop"
              "--ignore=noroot"
            ];
          };
        };
        # for opening web links:
        environment.etc."firejail/Telegram.local".text = ''
          dbus-user.talk org.freedesktop.portal.Desktop
          dbus-user.talk org.freedesktop.portal.OpenURI
          ignore noroot
          whitelist /run/current-system
          whitelist /run/wrappers
          ignore private-bin
        '';
      };
  };
  den.aspects.desktop-full = {
    description = "Full desktop packages, firejail, flatpak, and chromium";
    includes = [
      den.aspects.telegram
      den.aspects.thunderbird
      den.aspects.desktop-basic
      den.aspects.tkg
      den.aspects.printing
      den.aspects.scan
    ];
    nixos =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        ...
      }:
      let
        _include = args._include or (import ../nixos/include.nix args);
      in
      with _include;
      let
        apps = sharedApps { inherit pkgs progs; };
        apps' = apps // {
          clean = [
            (if config.librewolf_firejail then progs.librewolf'_for_firejail else progs.librewolf')
          ];
        };
      in
      {
        # https://search.nixos.org/packages
        environment.systemPackages =
          with pkgs;
          (map hardenedPkg [
            simple-scan
            trayscale
            (wrapPrio gnome-calculator)
            (wrapPrio gnome-system-monitor)
            chromium
            krita
            gimp
            saber
            gparted
            vlc
            bitwarden-desktop
            joplin-desktop
            prusa-slicer
            #ytmdesktop # no: this one cannot block ad
            fluffychat
            progs.zulip
            normcap
            (if qtIsPreferred then libreoffice-qt6-fresh else libreoffice-fresh)
            #bottles
            #kdePackages.sddm-kcm
            remmina
            kdePackages.kweather
            (wrapPrio gnome-clocks)
            #ventoy-full
            #ventoy-full-qt # qt version looks broken under kde plasma
            ventoy-full-gtk
            nextcloud-client
            inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.prospect-mail
            nur.repos.mio.icloud-mail
            (nix-webapps-lib.mkChromiumApp {
              appName = "chatgpt";
              desktopName = "ChatGPT";
              icon = pkgs.fetchurl {
                url = "https://web.archive.org/web/20260516193252if_/https://upload.wikimedia.org/wikipedia/commons/thumb/6/66/OpenAI_logo_2025_%28symbol%29.svg/1280px-OpenAI_logo_2025_%28symbol%29.svg.png";
                sha256 = "sha256-+QlDubjI8MLTnpK2Sy3eAKgn2/jTIkNdFUk8rtfYU7k=";
              };
              url = "https://chatgpt.com";
              class = "chrome-chatgpt.com__-Default";
            })
            (nix-webapps-lib.mkChromiumApp {
              appName = "findmy";
              desktopName = "Find My";
              icon = pkgs.fetchurl {
                url = "https://web.archive.org/web/20260513135036if_/https://upload.wikimedia.org/wikipedia/en/thumb/5/5a/Find_My_logo.svg/330px-Find_My_logo.svg.png";
                sha256 = "sha256-daZyk/2r43YdoasXaeclhJy+f5mkmd58j4IRbUkoEhA=";
              };
              url = "https://www.icloud.com/find/";
              class = "chrome-www.icloud.com__find_-Default";
            })
            # unfree:
            obsidian
            #cider-2 # paid
            #parsec-bin
            sublime4-dev # sublime4 broken, need -dev # (callPackage ./sublime-text.nix { })
            sublime-merge # (callPackage ./sublime-merge.nix { })
          ])
          ++ (map cleanPkg [
            firefox-esr
            (wrapPrio gnome-console)
            # unfree:
            progs.vscode
          ])
          ++ lib.optionals pkgs.stdenv.isx86_64 (
            (map hardenedPkg [
              inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.apple-music-desktop
              #inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.cider
              handbrake
              tuxguitar # TODO: maybe try firejail for this
              #fluidsynth
              #lilypond
              lmms-full
              (inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.notepad-plus-plus.override {
                wine = config.wine64_package;
              })
              # open source but from binary
              onlyoffice-desktopeditors
              # unfree:
              inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.adobe-acrobat-reader
              (offloadPkg (
                inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.insta360-studio.override {
                  wine = config.wine64_package;
                }
              ))
              (inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.affinity-v3.override {
                wine = config.wine64_package;
              })
              progs.discord
            ])
            ++ (map cleanPkg [
              zed-editor-fhs

              # https://nixos.wiki/wiki/Steam
              (lib.hiPrio config.programs.steam.package.run) # override the non cleanPkg one
            ])
          )
          ++ (map hardenedPkg apps'.hardened)
          ++ (map cleanPkg apps'.clean)
          ++ lib.optionals pkgs.stdenv.isx86_64 (
            map cleanPkg (
              apps'.cleanX86
              ++ [
                zotero # segfault with hardenedPkg on NixOS
              ]
            )
          );
        programs.localsend.package = hardenedPkg pkgs.localsend;

        programs.firejail.wrappedBinaries =
          with pkgs;
          {
            # librewolf firejail difficult to fix, still: cannot directly opening downloaded files
            # firejail for wine apps is still wip
            /*
              notepad-plus-plus = {
                executable = "${
                  hardenedPkg inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.notepad-plus-plus
                }/bin/notepad-plus-plus";
                profile = "${
                  inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.firejail-profiles
                }/etc/firejail/notepad-plus-plus.profile";
              };
            */
            obsidian = {
              executable = "${hardenedPkg obsidian}/bin/obsidian";
              profile = "${pkgs.firejail}/etc/firejail/obsidian.profile";
            };
            remmina = {
              executable = "${hardenedPkg remmina}/bin/remmina";
              profile = "${pkgs.firejail}/etc/firejail/remmina.profile";
            };
            # recently fluffychat broken with firejail
            /*
              fluffychat = {
                executable = "${hardenedPkg fluffychat}/bin/fluffychat";
                profile = "${pkgs.firejail}/etc/firejail/fluffychat.profile";
              };
            */
            # element-desktop: kwallet keyring broken with firejail
            /*
              element-desktop = {
                executable = "${hardenedPkg element-desktop}/bin/element-desktop";
                profile = "${pkgs.firejail}/etc/firejail/element-desktop.profile";
              };
            */
            qbittorrent = {
              executable = "${hardenedPkg qbittorrent-enhanced}/bin/qbittorrent";
              profile = "${pkgs.firejail}/etc/firejail/qbittorrent.profile";
            };
            gnome-calculator = {
              executable = "${hardenedPkg gnome-calculator}/bin/gnome-calculator";
              profile = "${pkgs.firejail}/etc/firejail/gnome-calculator.profile";
            };
            gnome-clocks = {
              executable = "${hardenedPkg gnome-clocks}/bin/gnome-clocks";
              profile = "${pkgs.firejail}/etc/firejail/gnome-clocks.profile";
            };
            # https://github.com/librephoenix/nixos-config/blob/0c3b676ab9d3e93780f06dbe5e084048eeed9a32/modules/system/security/firejail/default.nix#L21
            discord = lib.mkIf pkgs.stdenv.isx86_64 {
              executable = "${hardenedPkg progs.discord}/bin/discord";
              profile = "${pkgs.firejail}/etc/firejail/discord.profile";
            };
            /*
              ytmdesktop = {
                executable = "${hardenedPkg pkgs.ytmdesktop}/bin/ytmdesktop";
                profile = "${pkgs.firejail}/etc/firejail/ytmdesktop.profile";
              };
            */
            bitwarden-desktop = {
              executable = "${hardenedPkg pkgs.bitwarden-desktop}/bin/bitwarden";
              profile = "${pkgs.firejail}/etc/firejail/bitwarden.profile";
            };
            zulip = {
              executable = "${hardenedPkg pkgs.zulip}/bin/zulip";
              profile = ../nixos/zulip.profile;
              extraArgs = [
                # https://github.com/netblue30/firejail/issues/6681#issuecomment-2725161673
                "--ignore=private-dev"
              ];
            };
            # https://github.com/legendofmiracles/dotnix/blob/ea678c780a1944e32c94ded1b58ce3a28be553d9/hosts/pain/configuration.nix#L110
            # disable firejail for chromium if we want to use webflasher WebSerial
            # disable firajail as it might break Antigravity? https://antigravity.google/docs/browser NO: antigravity's integration still doesn't work even without firejail
            chromium = {
              executable = "${hardenedPkg pkgs.chromium}/bin/chromium";
              profile = "${pkgs.firejail}/etc/firejail/chromium.profile";
              extraArgs = [
                # https://github.com/netblue30/firejail/issues/3170#issuecomment-576266164
                # also webflasher WebSerial
                "--ignore=private-dev"
                "--ignore=nogroups" # dialout group for serial devices
              ];
            };
            # test on filesystem permission: for example /run/wrappers/bin/firejail '--whitelist=/run/pipewire' '--profile=/nix/store/sfnvg7fpq26ckdb7dl1bxr7j366ii84c-source/nixos/wiliwili.profile' -- $(readlink /run/current-system/sw/bin/ls) Pictures
            wiliwili = {
              executable = "${hardenedPkg pkgs.wiliwili}/bin/wiliwili";
              profile = ../nixos/wiliwili.profile;
            };
            materialgram = {
              executable = "${hardenedPkg progs.materialgram}/bin/materialgram";
              profile = ../nixos/materialgram.profile;
              extraArgs = [
                # https://github.com/netblue30/firejail/issues/5062 - light/dark theme switching
                "--dbus-user.talk=org.freedesktop.portal.Desktop"
                "--ignore=noroot"
              ];
            };
          }
          // lib.optionalAttrs config.librewolf_firejail {
            librewolf = {
              executable = "${progs.librewolf_for_firejail}/bin/librewolf";
              profile = "${pkgs.firejail}/etc/firejail/librewolf.profile";
              extraArgs = [
                #"--dbus-user.talk=org.kde.dolphin.FileManager1"
                "--dbus-user.talk=org.freedesktop.FileManager1"
                # Required for U2F USB stick
                "--ignore=private-dev"
                # Enable system notifications
                "--dbus-user.talk=org.freedesktop.Notifications"
                # https://github.com/netblue30/firejail/issues/5062 - light/dark theme switching
                "--dbus-user.talk=org.freedesktop.portal.Desktop"
                "--ignore=noroot"
              ];
            };
          };
        environment.etc."firejail/librewolf.local" = lib.mkIf config.librewolf_firejail {
          text = ''
            whitelist ${"$"}{PICTURES}
            noblacklist ${"$"}{PICTURES}
          '';
        };
        # for opening web links:
        environment.etc."firejail/materialgram.local".text = ''
          dbus-user.talk org.freedesktop.portal.Desktop
          dbus-user.talk org.freedesktop.portal.OpenURI
          ignore noroot
          whitelist /run/current-system
          whitelist /run/wrappers
          ignore private-bin
        '';

        # xone causes issues that controller is blank after reboot until replugged. default driver xpad works fine.
        /*
          hardware.xone.enable = lib.mkIf novirt true; # support for the xbox controller USB dongle
          boot.kernelModules = lib.optionals config.hardware.xone.enable [ "xone" ]; # does thie help need replugging after reboot issue
          hardware.xpad-noone.enable = lib.mkIf novirt true;
        */

        /*
          # https://t.me/chaotic_nyx_sac/27154
          boot.extraModulePackages = lib.mkIf (novirt && config.hardware.bluetooth.enable) [
            (config.boot.kernelPackages.xpadneo.override { bluez = pkgs.bluez; })
          ];
        */
        # cannot condition on config.hardware.bluetooth.enable as of https://github.com/NixOS/nixpkgs/pull/483838
        hardware.xpadneo.enable = lib.mkIf novirt true;

        services.gvfs.enable = true;

        services.flatpak = lib.mkIf pkgs.stdenv.isx86_64 {
          # please update manually and take care of Spotify (SpotX)
          /*
            update.auto = {
              enable = true;
              onCalendar = "daily";
            };
          */
          enable = true;
          packages = [
            #"sh.cider.Cider" # doesn't work
            "com.microsoft.Edge" # Download Documents Music Pictures Videos ...
            #"com.google.Chrome" # Download Documents Music Pictures Videos ...
            #"com.discordapp.Discord" # Download Pictures Videos and more
            "tv.plex.PlexDesktop"
            "com.spotify.Client"
            "com.qq.QQ" # Download folder read/write access and more
            "com.tencent.WeChat" # Download folder read access and more
            "com.baidu.NetDisk" # EOL and file system access
            "com.parsecgaming.parsec"
            # followings are built from source by flathub:
            "com.usebottles.bottles" # is it really from source? not very sure
            #"com.gitlab.bitseater.meteo"
            #"io.github.archisman_panigrahi.typhoon"
            #"cn.xfangfang.wiliwili"
            #"org.musescore.MuseScore"
            #"org.prismlauncher.PrismLauncher"
            #"eu.betterbird.Betterbird"
            /*
              # https://github.com/cross-platform/icloud-for-linux/pull/105 -> https://github.com/PercevalSA/icloud-for-linux/actions/runs/19347254109
              rec {
                appId = "io.github.crossplatform.icloud-for-linux";
                sha256 = "sha256-2MvGVZclrlogqQI317HG0dmodZlQ2iRowyGWrbR9RfI=";
                bundle = "${pkgs.fetchurl {
                  url = "https://github.com/mio-19/upload/raw/refs/heads/main/icloud-for-linux.flatpak";
                  inherit sha256;
                }}";
              }
            */
          ];
          remotes = lib.mkOptionDefault [
            {
              name = "flathub-beta";
              location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
            }
          ];
        };

        programs.chromium = {
          enable = true;
          enablePlasmaBrowserIntegration = true;
          plasmaBrowserIntegrationPackage = lib.mkDefault pkgs.kdePackages.plasma-browser-integration;
          /*
            extraOpts = {
              #RestoreOnStartup = 1;
              BrowserSignin = 1;
              SyncDisabled = false;
            };
          */
        };

        programs.sniffnet.enable = true;
      };
    # darwin reuses only the cross-platform apps shared with the NixOS desktop-full
    # (sharedApps above). The firejail/flatpak/chromium and other Linux-only bits
    # stay in the nixos branch.
    darwin =
      args@{
        pkgs,
        ...
      }:
      let
        _include = args._include or import ../mac/include.nix args;
        apps = sharedApps {
          inherit pkgs;
          inherit (_include) progs;
        };
      in
      with _include;
      {
        environment.systemPackages =
          apps.hardened
          ++ apps.clean
          ++ apps.cleanX86
          ++ [
            pkgs-pin3.trayscale
          ];
        homebrew.casks = [
          "zotero" # version from nixpkgs does not work
          "discord"
          "iterm2"
          "google-chrome"
          #"element"
        ];
      };
  };
}
