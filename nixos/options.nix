{
  lib,
  pkgs,
  config,
  ...
}:
{
  options.v4 = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "v4";
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
    default = false;
    description = "compile our custom materialgram&telegram";
  };
  options.mio_openssh_hpn = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "use mio hpn patched openssh";
  };
}
