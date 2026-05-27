{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:
{
  imports = [
    ./desktop-baremetal-kde-basic.nix
    ./desktop-full.nix
  ];
}
