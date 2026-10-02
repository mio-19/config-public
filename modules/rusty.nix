{ den, ... }:
{
  den.aspects.rusty = {
    description = "installing Rusty utilities";
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
            uutils-acl
            uutils-tar
            uutils-login
            uutils-procps
            uutils-hostname
            uutils-findutils
            uutils-diffutils
            uutils-util-linux
          ];
      };
  };
}
