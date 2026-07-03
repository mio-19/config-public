# Shared NixOS baseline: HM defaults, nix registry, cachix substituters (den.aspects.basic).
{ den, ... }: {
  den.aspects.basic = {
    description = "Shared NixOS baseline: HM defaults, nix registry, and cachix substituters";
    nixos =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        system,
        ...
      }:
      import ./_basic/default.nix args;
  };
}
