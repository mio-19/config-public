{
  lib,
  pkgs,
  config,
  ...
}:
{
  # https://github.com/chaotic-cx/nyx/issues/957
  nix.settings.system-features = [
    "big-parallel"
    "gccarch-x86-64-v3"
  ];
}
