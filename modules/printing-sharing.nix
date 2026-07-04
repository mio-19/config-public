{ den, ... }:
{
  den.aspects.printing-sharing = {
    description = "Shared network printing and Avahi publish (gated by novirt)";
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
            publish = {
              enable = true;
              userServices = true;
            };
          };
          services.printing = {
            listenAddresses = [ "*:631" ];
            allowFrom = [ "all" ];
            browsing = true;
            defaultShared = true;
            openFirewall = true;
          };
        };
      };
  };
}
