{
  lib,
  pkgs,
  config,
  _include,
  ...
}:
let
  inherit (pkgs) stdenv;
in
with _include;
{
  options.microarch = lib.mkOption {
    type = lib.types.enum [
      "v2"
      "v3"
      "v4"
    ];
    default = "v3";
    description = "x86-64 microarchitecture level (v2: legacy e.g. i5-2410M)";
  };
  options.wine64_package = lib.mkPackageOption pkgs [ "wineWow64Packages" "full" ] {
    extraDescription = "The wine 32/64 package to use.";
  };
  options.hdr_very_bright = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "if default brightness will result in very bright so dark background must be used in login/bootloader";
  };
  options.use_betterbird = lib.mkOption {
    type = lib.types.bool;
    default = pkgs.stdenv.isx86_64;
    description = "use betterbird instead of thunderbird.";
  };
  options.use_librewolf_bin = lib.mkOption {
    type = lib.types.bool;
    # used to be  # pkgs.librewolf == pkgs.librewolf-bin
    default = !pkgs.stdenv.isx86_64; # just about having  binary cache or not
    description = "use librewolf-bin instead of building from source.";
  };
  options.compile_gram = lib.mkOption {
    type = lib.types.bool;
    default = stdenv.isLinux && stdenv.isx86_64 && config.microarch != "v2";
    description = "compile our custom materialgram&telegram";
  };
  options.mio_openssh_hpn = lib.mkOption {
    type = lib.types.bool;
    default = config.microarch != "v2";
    description = "use mio hpn patched openssh";
  };
  options.mio_aria2 = lib.mkOption {
    type = lib.types.bool;
    default = config.microarch != "v2";
    description = "use mio patched aria2";
  };
  options.adhocNetworks = lib.mkOption {
    type = lib.types.bool;
    default = boot-to-steam;
    description = "enable adhoc network connections. but might make network unusable";
  };
  options.system_background = lib.mkOption {
    type = lib.types.either lib.types.package lib.types.path;
    description = "path to system background image";
  };
  options.plasma-login-manager_instead = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "plasma login manager instead of sddm";
  };
  options.skip_lockscreen_click = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "[WIP] skip click/key press to go to passwordenter/fingerprint screen";
  };
  config.assertions = [
    {
      assertion = config.microarch != "v2" || !config.mio_aria2;
      message = "no mio aria2 for v2";
    }
    {
      assertion = config.microarch != "v2" || !config.mio_openssh_hpn;
      message = "no mio hpn openssh for v2";
    }
    {
      assertion = config.microarch != "v2" || !config.compile_gram;
      message = "no gram compile for v2";
    }
  ];
  config.nix.settings.system-features = lib.mkIf stdenv.isx86_64 (
    [
      "big-parallel"
    ]
    ++ lib.optionals (config.microarch == "v3") [
      "gccarch-x86-64-v3"
    ]
    ++ lib.optionals (config.microarch == "v4") [
      "gccarch-x86-64-v4"
    ]
  );
}
