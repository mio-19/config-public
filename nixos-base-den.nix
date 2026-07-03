# Den aspect entrypoints: shared NixOS base + selector4nix (replaces nixos/common.nix imports).
{ inputs, system, ... }:
{
  imports = [
    (import ./aspect.nix "common")
    (import ./aspect.nix "selector4nix")
  ];
}
