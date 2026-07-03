{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:
{
  imports = [
    (import ../../aspect.nix "desktop-baremetal-kde-basic")
    ../../nixos/desktop-full.nix
  ];
}
