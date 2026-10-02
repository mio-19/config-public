{ den, ... }:
{
  den.aspects.rusty = {
    description = "installing Rusty utilities";
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
            uutils-diffutils
          ];
      };
  };
}
