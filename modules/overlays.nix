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
                gimp
                blender
                ;
              inherit (pkgs') freecad; # no binary cache with cuda and no binary cache with rocm
              inherit (pkgs') firefox-esr firefox-esr-unwrapped;
              #vscode = mio.vscode1133;
              #vscode-fhs = mio.vscode-fhs1133;
              #vscode-extensions = mio.vscode-extensions1133;
              inherit (pkgs-pin2) lean4;
            }
          )
          inputs.chaotic.overlays.default
          inputs.mac-style-plymouth.overlays.default
          inputs.nix-bwrapper.overlays.default
          inputs.nix-webapps.overlays.lib
          # https://github.com/GreepTheSheep/nixos-config/commit/9da31efa2517982ab9f1943c9d98af65fa95b53d
          # Node.js 26 runs test-fs-cp-async-file-modes, which chmods the setuid
          # and setgid bits. Those chmods return EPERM inside the Nix build
          # sandbox, so the test can never pass and the whole nodejs build fails.
          # Upstream skips it too: https://github.com/NixOS/nixpkgs/issues/564449
          # Drop this overlay once nixpkgs-unstable carries the upstream fix.
          (_: prev: {
            nodejs-slim_26 = prev.nodejs-slim_26.overrideAttrs (old: {
              checkFlags = map (
                flag: if lib.hasPrefix "CI_SKIP_TESTS=" flag then "${flag},test-fs-cp-async-file-modes" else flag
              ) old.checkFlags;
            });
          })
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
              inherit (pkgs-pin5) lean4;
            }
          )
        ];
      };
  };
}
