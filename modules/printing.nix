{ den, ... }:
{
  den.aspects.printing = {
    description = "Local printing and Avahi (gated by novirt)";
    nixos =
      args@{
        lib,
        pkgs,
        config,
        ...
      }:
      let
        _include = args._include or (import ../nixos/include.nix args);
      in
      with _include;
      {
        # https://wiki.nixos.org/wiki/Printing
        config = lib.mkIf novirt {
          services.avahi = {
            enable = true;
            nssmdns4 = true;
            openFirewall = true;
          };

          services.printing = {
            enable = true;
          };
        };
      };
  };
}
