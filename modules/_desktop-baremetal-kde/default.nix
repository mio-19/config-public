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
    (import ../../aspect.nix "desktop-full")
  ];
}
