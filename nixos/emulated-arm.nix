{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:
{
  # https://nixos.wiki/wiki/NixOS_on_ARM
  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
    "armv7l-linux"
  ];
  # https://github.com/nix-community/infra/blob/fb92a8e571b639fc30501e2a9188b420e41ed0de/modules/nixos/common/armv7l.nix#L28
  nix.settings.system-features = [
    "gccarch-armv7-a"
    "gccarch-armv8-a"
  ];
}
