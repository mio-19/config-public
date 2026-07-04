{ den, ... }:
{
  den.aspects.lix = {
    description = "Lix nix package and nix-output-monitor overlay";
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
        /*
          nixpkgs.overlays = [
            #(final: prev: { lix = prev.lixPackageSets.latest.lix; })
            (final: prev: { lix = pkgs.nur.repos.mio.lix; })
          ];
          imports = [
            inputs.lix-module.nixosModules.lixFromNixpkgs
          ];
        */

        nix = {
          package = pkgs.lix;
          # use lix 2.93 as https://github.com/maralorn/nix-output-monitor/issues/230
          #package = inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.lix_2_93;  # did this break nix-shell
        };

        # https://github.com/maralorn/nix-output-monitor/issues/230#issuecomment-4654412970
        nixpkgs.overlays = [
          (_final: prev: {
            nix-output-monitor = prev.nix-output-monitor.overrideAttrs {
              version = "0-unstable-2026-06-08";
              src = prev.fetchFromGitHub {
                owner = "maralorn";
                repo = "nix-output-monitor";
                rev = "388f56120f655a9cf4512e697b2c2afa06fe7434";
                hash = "sha256-3N+PVFpsnBtQ11Vk9OKm1q9dE0d5fxGsEDyfwoxpYaE=";
              };
              propagatedBuildInputs = (prev.nix-output-monitor.propagatedBuildInputs or [ ]) ++ [
                prev.haskellPackages.hinotify
              ];
            };
          })
        ];
      };
  };
}
