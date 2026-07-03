# Den aspect entrypoints: shared NixOS base + selector4nix (replaces nixos/common.nix imports).
{ inputs, system, ... }:
{
  imports = [
    ./common-den.nix
    ./selector4nix-den.nix
  ];
}
