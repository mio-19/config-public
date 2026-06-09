{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:
{
  # https://matrix.to/#/!lheuhImcToQZYTQTuI:nixos.org/$lCw6Se27FiLLStQhuWNase7O3bPVYX6OnlBhjQxmoxc?via=nixos.org&via=matrix.org&via=nixos.dev
  # use lix 2.93 as https://github.com/maralorn/nix-output-monitor/issues/230
  nix.package = pkgs.lix; # pkgs.lixPackageSets.stable.lix;
  /*
    nixpkgs.overlays = [
      (final: prev: { lix = prev.lixPackageSets.latest.lix; })
    ];
    imports = [
      #inputs.lix-module.nixosModules.lixFromNixpkgs
      inputs.lix-module.darwinModules.lixFromNixpkgs
    ];
  */

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
}
