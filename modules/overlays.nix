{ den, ... }: {
  den.aspects.overlays = {
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
              mio = inputs.mio.packages."${system}";
            in
            {
              grub2 = mio.grub2_patched;
              starship = mio.starship_patched;
              #harmonia = mio.harmonia_patched;
              inherit (mio) wireguird darling;
              sniffnet = mio.sniffnet-patched;
              xfce4-terminal = mio.xfce4-terminal-patched;
              android-translation-layer = mio.android-translation-layer_patched;
              # build failed/depdendency build failed with cuda
              inherit (pkgs')
                ffmpeg-full
                krita
                handbrake
                ;
              inherit (pkgs') freecad; # no binary cache with cuda and no binary cache with rocm
              inherit (pkgs') firefox-esr firefox-esr-unwrapped;
              inherit (pkgs-pin2) jabref;
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
              mio = inputs.mio.packages."${pkgs.stdenv.hostPlatform.system}";
            in
            {
              starship = mio.starship_patched;
              raycast = mio.raycast_macos15;
              #harmonia = mio.harmonia_patched;
              inherit (pkgs-pin5) blender;
            }
          )
        ];
      };
  };
}
