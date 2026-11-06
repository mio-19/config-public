{ den, ... }: {
  den.aspects.overlays = {
    os =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        ...
      }:
      {
        nixpkgs.overlays = [
        ];
      };
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
        _include = (args._include or import ../nixos/include.nix args);
      in
      with _include;
      {
        nixpkgs.overlays = [
          inputs.nur.overlays.default
          #inputs.copyparty.overlays.default
          #inputs.android-nixpkgs.overlays.default
          inputs.nix-vscode-extensions.overlays.default
          #inputs.emacs-overlay.overlays.package
          (
            final: prev:
            let
              mio = inputs.mio.legacyPackages."${system}";
              inherit (final) patchelf fetchurl;
            in
            {
              grub2 = mio.grub2_patched;
              starship = mio.starship_patched;
              #harmonia = mio.harmonia_patched;
              inherit (mio) wireguird darling miodroid;
              sniffnet = mio.sniffnet-patched;
              xfce4-terminal = mio.xfce4-terminal-patched;
              android-translation-layer = mio.android-translation-layer_patched;
              # build failed/depdendency build failed with cuda
              inherit (pkgs')
                ffmpeg-full
                krita
                gimp
                blender
                jadx
                ;
              inherit (pkgs') freecad handbrake; # no binary cache with cuda and no binary cache with rocm
              inherit (pkgs') firefox-esr firefox-esr-unwrapped;
              inherit (pkgs-pin2)
                openshot-qt
                stuntrally
                ;
              inherit (pkgs-pin3)
                diffoscope # depending on fuse2
                ;
              # https://github.com/NixOS/nixpkgs/issues/579143#issue-6036505477
              cursor-cli = prev.cursor-cli.overrideAttrs (old: {
                nativeBuildInputs = [
                  (patchelf.overrideAttrs (
                    finalAttrs: previousAttrs: {
                      version = "0.15.2";
                      src = fetchurl {
                        url = "https://github.com/NixOS/patchelf/releases/download/${finalAttrs.version}/patchelf-${finalAttrs.version}.tar.bz2";
                        hash = "sha256-F3RfVkFZyOIo/EEtplogSLhGxLa0Igt3y/IkFuAvLXw=";
                      };
                    }
                  ))
                ]
                ++ (old.nativeBuildInputs or [ ]);
              });
            }
          )
          inputs.chaotic.overlays.default
          inputs.mac-style-plymouth.overlays.default
          inputs.nix-bwrapper.overlays.default
          inputs.nix-webapps.overlays.lib
        ];
      };
    darwin =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        ...
      }:
      let
        _include = args._include or import ../mac/include.nix args;
      in
      with _include;
      {
        nixpkgs.overlays = [
          #inputs.chaotic.overlays.cache-friendly
          inputs.darwin-emacs.overlays.emacs
          #inputs.emacs-overlay.overlays.package
          inputs.nur.overlays.default
          inputs.nix-vscode-extensions.overlays.default
          (
            final: prev:
            let
              mio = inputs.mio.legacyPackages."${pkgs.stdenv.hostPlatform.system}";
            in
            {
              starship = mio.starship_patched;
              raycast = mio.raycast_macos15;
              #harmonia = mio.harmonia_patched;
              inherit (mio.patched) qbittorrent-enhanced jadx uutils-diffutils;
            }
          )
        ];
      };
  };
}
