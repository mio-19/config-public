{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (pkgs) stdenv;
in
{
  options.v4 = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "v4";
  };
  options.v2 = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "x86-64-v2 : legacy cpu i5-2410M";
  };
  options.wine64_package = lib.mkOption {
    type = lib.types.package;
    default = pkgs.wineWow64Packages.full;
    description = "The wine 32/64 package to use.";
  };
  options.hdr_very_bright = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "if default brightness will result in very bright so dark background must be used in login/bootloader";
  };
  options.thunderbird_instead = lib.mkOption {
    type = lib.types.bool;
    default = pkgs.stdenv.isx86_64; # didn't cache on aarch64-linux
    description = "thunderbird instead.";
  };
  options.compile_gram = lib.mkOption {
    type = lib.types.bool;
    default = stdenv.isLinux && stdenv.isx86_64 && !config.v2;
    description = "compile our custom materialgram&telegram";
  };
  options.mio_openssh_hpn = lib.mkOption {
    type = lib.types.bool;
    default = !config.v2;
    description = "use mio hpn patched openssh";
  };
  options.mio_aria2 = lib.mkOption {
    type = lib.types.bool;
    default = !config.v2;
    description = "use mio patched aria2";
  };
  config.assertions = [
    {
      assertion = config.v2 -> !config.mio_aria2;
      message = "no mio aria2 for v2";
    }
    {
      assertion = config.v2 -> !config.mio_openssh_hpn;
      message = "no mio hpn openssh for v2";
    }
    {
      assertion = config.v2 -> !config.compile_gram;
      message = "no gram compile for v2";
    }
  ];
}
