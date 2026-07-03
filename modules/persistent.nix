# Impermanence baseline: persist selected paths under /persistent.
{ den, ... }:
{
  den.aspects.persistent = {
    description = "Impermanence persistence baseline for /persistent";
    nixos =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        ...
      }:
      let
        _include = args._include or import ../nixos/include.nix args;
      in
      import ../nixos/persistent.nix (args // { inherit _include; });
  };
}
