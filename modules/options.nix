{ den, ... }:
let
  mkOptions =
    isDarwin:
    args@{
      lib,
      pkgs,
      config,
      ...
    }:
    let
      inherit (pkgs) stdenv;
      nixosInclude = if isDarwin then null else (args._include or (import ../nixos/include.nix args));
      microarchDefault = if stdenv.isAarch64 then "v4" else "v3";
      microarchValue = if isDarwin then null else (config.microarch or microarchDefault);
      inc =
        if isDarwin then
          {
            # microarch doesn't exist for darwin; assume mio-patched variants are acceptable.
            atleastV3 = true;
            atleastV4 = true;
          }
        else
          nixosInclude.scopeFor (config // { microarch = microarchValue; });
    in
    {
      options = {
        hdr_very_bright = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "if default brightness will result in very bright so dark background must be used in login/bootloader";
        };
        use_betterbird = lib.mkOption {
          type = lib.types.bool;
          default = pkgs.stdenv.isx86_64;
          description = "use betterbird instead of thunderbird.";
        };
        system_background = lib.mkOption {
          type = lib.types.either lib.types.package lib.types.path;
          description = "path to system background image";
        };
        use_librewolf_bin = lib.mkOption {
          type = lib.types.bool;
          default = if isDarwin then false else !pkgs.stdenv.isx86_64;
          description = "use librewolf-bin instead of building from source.";
        };
        mio_openssh_hpn = lib.mkOption {
          type = lib.types.bool;
          default = if isDarwin then false else inc.atleastV3;
          description = "use mio hpn patched openssh";
        };
        mio_aria2 = lib.mkOption {
          type = lib.types.bool;
          default = if isDarwin then true else inc.atleastV3;
          description = "use mio patched aria2";
        };
      }
      // lib.optionalAttrs (!isDarwin) {
        microarch = lib.mkOption {
          type = lib.types.enum [
            "v2"
            "v3"
            "v4"
            "zen4"
          ];
          default = microarchDefault;
          description = "x86-64 microarchitecture level (v2: legacy e.g. i5-2410M)";
        };
        wine64_package = lib.mkPackageOption pkgs [ "wineWow64Packages" "full" ] {
          extraDescription = "The wine 32/64 package to use.";
        };
        compile_gram = lib.mkOption {
          type = lib.types.bool;
          default = stdenv.isLinux && stdenv.isx86_64 && inc.atleastV3;
          description = "compile our custom materialgram&telegram";
        };
        adhocNetworks = lib.mkOption {
          type = lib.types.bool;
          default = nixosInclude.boot-to-steam;
          description = "enable adhoc network connections. but might make network unusable";
        };
        plasma-login-manager_instead = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "plasma login manager instead of sddm";
        };
        skip_lockscreen_click = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "[WIP] skip click/key press to go to passwordenter/fingerprint screen";
        };
        vicinaeHm.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Include vicinae in home-manager.sharedModules (off for home-manager-7074 / WSL).";
        };
      };

      config = {
        assertions = [
          {
            assertion = inc.atleastV3 || !config.mio_aria2;
            message = "no mio aria2 for v2";
          }
          {
            assertion = inc.atleastV3 || !config.mio_openssh_hpn;
            message = "no mio hpn openssh for v2";
          }
        ]
        ++ lib.optionals (!isDarwin) [
          {
            assertion = inc.atleastV3 || !config.compile_gram;
            message = "no gram compile for v2";
          }
        ];
        nix.settings.system-features = lib.mkIf stdenv.isx86_64 (
          [
            "big-parallel"
          ]
          ++ lib.optionals inc.atleastV3 [
            "gccarch-x86-64-v3"
          ]
          ++ lib.optionals inc.atleastV4 [
            "gccarch-x86-64-v4"
          ]
        );
      };
    };
in
{
  den.aspects.options = {
    nixos = mkOptions false;
    darwin = mkOptions true;
  };

  den.default.includes = [ den.aspects.options ];
}
