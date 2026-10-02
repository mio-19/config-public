{ den, ... }:
{
  den.aspects.rusty_extreme = {
    description = "installing Rusty utilities, excluding sudo-rs, replaceDependencies";
    includes = [
      den.aspects.rusty_more
    ];
    nixos =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        ...
      }:
      {
        system.replaceDependencies.replacements =
          # https://github.com/overby-me/overby-me/blob/11e252a0a44c7d69d90a2950786f880cca453562/safety/oxidized/nixos/coreutils.nix#L4
          let
            uutils = pkgs.uutils-coreutils-noprefix;
          in
          [
            {
              original = pkgs.coreutils;
              replacement = uutils.overrideAttrs { name = pkgs.coreutils.name; };
            }
            {
              original = pkgs.coreutils-full;
              replacement = uutils.overrideAttrs { name = pkgs.coreutils-full.name; };
            }
          ];
      };
  };
  den.aspects.rusty_more = {
    description = "installing Rusty utilities, more, excluding sudo-rs";
    includes = [
      den.aspects.rusty
    ];

    nixos =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        ...
      }:
      {
        environment.systemPackages =
          with pkgs;
          map lib.hiPrio [
            uutils-procps # I do not like top by uutils-procps
          ];
      };
    darwin =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        ...
      }:
      {
        environment.systemPackages =
          with pkgs;
          map lib.hiPrio [
            uutils-coreutils-noprefix
            uutils-tar
            uutils-findutils
          ];
      };
    };
  den.aspects.rusty = {
    description = "installing Rusty utilities, excluding sudo-rs";
    nixos =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        ...
      }:
      {
        environment.systemPackages =
          with pkgs;
          map lib.hiPrio [
            uutils-acl
            uutils-util-linux
            # darwin: they break scripts written for darwin!
            uutils-coreutils-noprefix
            uutils-tar
            uutils-findutils
          ];
      };
    os =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        ...
      }:
      {
        environment.systemPackages =
          with pkgs;
          map lib.hiPrio [
            uutils-diffutils
            uutils-sed
            uutils-login
            uutils-hostname
          ];
      };
  };
}
