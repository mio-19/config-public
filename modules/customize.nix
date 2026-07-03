{ den, ... }:
{
  den.aspects.customize = {
    description = "Default system background";
    nixos =
      args@{
        ...
      }:
      let
        _include = args._include or (import ../nixos/include.nix args);
      in
      with _include;
      {
        system_background = ../nixos/black.png; # DETAILS REMOVED
      };
  };
}
