{ den, ... }: {
  den.aspects.desktop-offline = {
    description = "Rarely-used offline desktop packages and flatpaks";
    includes = [
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
            jetbrains.idea-oss
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
            imhex
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
            pkgs-chaotic.firefox_nightly
            inputs.nix-software-center.packages.${pkgs.stdenv.hostPlatform.system}.nix-software-center
            #quickemu
            #whatsapp-chat-exporter
            #wlvncc
            #gpt4all
            #figma-linux
            #scribus # can edit pdf? - https://www.reddit.com/r/opensource/comments/1bu1gdi/adobe_acrobat_foss_alternative_to_end_all/
            #xournalpp # can draw on pdf? - https://www.reddit.com/r/opensource/comments/1bu1gdi/adobe_acrobat_foss_alternative_to_end_all/
            super-productivity
            # unfree:
            lightworks # maybe doesn't support wayland well # maybe consider https://github.com/kekkoudesu/lightworks-flatpak
            binaryninja-free
            inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.bilibili # how safe is it? we clicked into it once on razer # TODO: wrap it with nixwrap or similar
            bitwig-studio
          ])
          ++ [
            # breaks with wrapper
            android-translation-layer
          ]
          ++ lib.optionals pkgs.stdenv.isx86_64 (
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
