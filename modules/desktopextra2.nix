{ den, ... }:
{
  den.aspects.desktopextra2 = {
    description = "Snap + extra desktop apps and flatpaks on top of extra2";
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
        imports = [
          inputs.nix-snapd.nixosModules.default
          (import ../aspect.nix "extra2")
        ];
        services.snap.enable = true;
        # sudo snap install icloud-for-linux

        # https://search.nixos.org/packages
        environment.systemPackages =
          with pkgs;
          (map hardenedPkg [
            rustdesk-flutter
            isabelle
            (fixTauriPkg rclone-ui)
            inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.rclone-browser
            #gnome-frog # https://github.com/NixOS/nixpkgs/issues/457538
            #textsnatcher
            #gImageReader
            #dissent
            heimdall-gui
            koreader
            signal-desktop
            #lan-mouse
            #transmission_4-qt
            #(lib.hiPrio transmission_4-gtk)
            libresprite
            famistudio
            audacity
            powertabeditor
            koreader
            guitarix
            gxplugins-lv2
            tamgamp-lv2
            (wrapPrio gnome-software)
            firebird-emu
            octaveFull
            #kdePackages.merkuro # crashed
            gnome-sound-recorder
            (wrapPrio gnome-maps)
            czkawka-full
            #(fixTauriPkg gitbutler)
            kicad
            freac
            inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.rain
            inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.gifcurry
            # unfree:
            inputs.claude-desktop.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop-fhs
            bambu-studio
          ])
          ++ (map cleanPkg [
            #firefox_nightly
            # binaryNativeCode:
            tor-browser # need non flatpak version for the sandbox - https://github.com/flathub/org.torproject.torbrowser-launcher/issues/67
          ]);

        services.flatpak = {
          enable = true;
          packages = [
            #"io.github.amit9838.mousam" # fonts all broken
            rec {
              appId = "com.fender.studio";
              sha256 = "06a082v083q275ycgj5fkz5n84l2q03hyx8405p6bpkh6nvvhnvw";
              bundle = "${pkgs.fetchurl {
                url = "https://github.com/mio-19/upload/raw/refs/heads/main/fenderstudio.flatpak";
                inherit sha256;
              }}";
            }
            # followings are built from source by flathub:
            #"io.github.nyre221.kiview" # mostly build from source. full filesystem permission
            # binaryNativeCode:
            #"org.torproject.torbrowser-launcher" # no - Some of Tor Browser's security features may offer less protection on your current operating system - https://github.com/flathub/org.torproject.torbrowser-launcher/issues/67
          ];
        };

        # Partition Manager (KDE)
        programs.partition-manager.enable = true;
      };
  };
}
