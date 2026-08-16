{ den, ... }: {
  den.aspects.offline-tools = {
    description = "Rarely-used packages ";
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
        # https://search.nixos.org/packages
        environment.systemPackages =
          with pkgs;
          (map hardenedPkg (
            [
              python314Packages.pdf2docx
              rustscan
              nur.repos.mio.pdf2pptx
              #herdr
              #git-repo
              pmbootstrap
              #clang
              baidupcs-go
              nix-init
              mediainfo
              img2pdf
              vulnix
              #julia # https://github.com/NixOS/nixpkgs/issues/475534
              matugen
              polarity
              easyeda2kicad
              interactive-html-bom
              jujutsu
              s-tui
              eza
              #code2prompt
              yazi
              #onefetch
              #fresh-editor
              #bat
            ]
            ++ lib.optional (
              inputs.mio.packages.${pkgs.stdenv.hostPlatform.system} ? sem-cli
            ) inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.sem-cli
          ));
      };
  };
  den.aspects.desktop-offline = {
    description = "Rarely-used offline desktop packages and flatpaks";
    includes = [
      den.aspects.offline-tools
      den.aspects.desktopextra2
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
      {
        boot.supportedFilesystems = [
          "apfs"
        ]
        ++ lib.optionals (!(builtins.any (tag: tag == "rc") config.system.nixos.tags)) [
          "bcachefs"
        ];

        # https://search.nixos.org/packages
        environment.systemPackages =
          with pkgs;
          (map hardenedPkg [
            inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.jetbrains_idea-oss # jetbrains.idea-oss
            openshot-qt
            inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.freesmlauncher
            mpv # https://gist.github.com/arch1t3cht/b5b9552633567fa7658deee5aec60453/
            mediainfo-gui
            mkvtoolnix
            #haruna
            jan
            okteta
            dune3d
            lingot
            gmetronome
            #piliplus # bluescreen
            millisecond
            audacious
            splayer
            netease-cloud-music-gtk
            notepad-next
            qpwgraph
            carla
            popsicle # alternative to Balena Etcher - https://github.com/NixOS/nixpkgs/issues/371992#issuecomment-2576548039
            jellyfin-desktop
            cpu-x
            giada
            motrix-next
            xfce4-terminal
            alacritty
            #kdePackages.tokodon
            ardour
            #whalebird
            sioyek
            thonny
            friture
            wayland-bongocat
            kdePackages.kdenlive
            shotcut
            flowblade
            mousam # always buggy
            #emote # no we already have plasma-emojier with meta+.
            nur.repos.mio.altus
            wiliwili
            wxhexeditor
            jabref
            penpot-desktop
            reco
            kdePackages.glaxnimate
            #qmplay2
            smplayer
            easyeffects
            pixelorama
            plezy
            inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.komi-store
            inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.nix-software-center
            brave-origin
            #quickemu
            #whatsapp-chat-exporter
            #wlvncc
            #gpt4all
            #figma-linux
            #scribus # can edit pdf? - https://www.reddit.com/r/opensource/comments/1bu1gdi/adobe_acrobat_foss_alternative_to_end_all/
            #xournalpp # can draw on pdf? - https://www.reddit.com/r/opensource/comments/1bu1gdi/adobe_acrobat_foss_alternative_to_end_all/
            super-productivity
            inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.discordchatexporter-desktop_patched
            # unfree:
            #jetbrains.idea
            lightworks # maybe doesn't support wayland well # maybe consider https://github.com/kekkoudesu/lightworks-flatpak
            binaryninja-free
            inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.bilibili # how safe is it? we clicked into it once on razer # TODO: wrap it with nixwrap or similar
            bitwig-studio
          ])
          ++ (map cleanPkg [
            #pkgs-chaotic-ff-nightly'.firefox_nightly
          ])
          ++ [
            # breaks with wrapper
            android-translation-layer
          ]
          ++ lib.optionals pkgs.stdenv.hostPlatform.isx86_64 (
            map hardenedPkg [
              # unfree:
              (inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.line.override {
                wine = config.wine64_package;
              })
            ]
          )
          ++ [ papirus-icon-theme ];

        services.flatpak = {
          enable = true;
          packages = [
            "cn.lceda.LCEDAPro"
            "app.organicmaps.desktop"
            "io.github.rinigus.PureMaps" # difficult to use
            "com.google.EarthPro"
            # followings are built from source by flathub:
            #"com.giadamusic.Giada" # Home folder read/write access!
          ];
        };

        programs.firejail.wrappedBinaries = with pkgs; {
          # same pattern as chromium in desktop-full; brave.profile includes chromium-common
          brave-origin = {
            executable = "${hardenedPkg brave-origin}/bin/brave-origin";
            profile = "${pkgs.firejail}/etc/firejail/brave.profile";
            extraArgs = [
              # https://github.com/netblue30/firejail/issues/3170#issuecomment-576266164
              "--ignore=private-dev"
              "--ignore=nogroups" # dialout group for serial devices
            ];
          };
          # no network with bilibili.profile?
          /*
            bilibili = {
              executable = "${hardenedPkg inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.bilibili}/bin/bilibili";
              profile = ./bilibili.profile;
            };
          */
        };
      };
  };
}
