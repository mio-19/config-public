# when importing this file, please put it at the last one after nixos-base-den.nix
{
  config,
  inputs,
  lib,
  pkgs,
  _include,
  ...
}@args:
with _include;
/*
  let
    pkgs'' = import inputs.nixpkgs {
      config = config.nixpkgs.config;
      system = config.nixpkgs.system;
      overlays = [
        (final: prev: {
          pkgsi686Linux = pkgs'.pkgsi686Linux;
        })
        inputs.nur.overlays.default
      ];
    };
  in
*/
{
  # https://discourse.nixos.org/t/where-are-options-like-config-cudasupport-documented/17805/2
  # https://wiki.nixos.org/wiki/CUDA#Setting_up_CUDA_Binary_Cache
  # https://github.com/nixified-ai/flake/issues/125#issuecomment-3677550159
  # https://github.com/nixos-cuda/infra?tab=readme-ov-file#binary-cache
  nix.settings = {
    substituters = [
      "https://cache.nixos-cuda.org"
    ];
    trusted-public-keys = [
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
    ];
  };

  nixpkgs.config.cudaSupport =
    config.hardware.nvidia.enabled
    && (!(builtins.any (tag: tag == "battery-saver") config.system.nixos.tags));

  nixpkgs.overlays = [
    (final: prev: {
      pkgsi686Linux = pkgs-nocuda.pkgsi686Linux;
      #nur = pkgs''.nur;
      #librewolf = pkgs-nocuda.librewolf; # for binary cache
    })
  ];
}
