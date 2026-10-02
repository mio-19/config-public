{ den, ... }:
{
  den.aspects.rusty_extreme = {
    description = "installing Rusty utilities, excluding sudo-rs, replaceDependencies";
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
            uutils-procps
            uutils-acl
            uutils-util-linux
            uutils-diffutils
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
            uutils-coreutils-noprefix
            uutils-sed
            uutils-tar
            uutils-login
            uutils-hostname
            uutils-findutils
          ];
      };
  };
}
