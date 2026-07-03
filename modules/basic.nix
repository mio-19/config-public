# Shared baseline: HM defaults, nix registry, cachix substituters (den.aspects.basic).
{ den, ... }: {
  den.aspects.basic = {
    description = "Shared baseline: HM defaults, nix registry, and cachix substituters";
    nixos =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        system,
        ...
      }:
      import ./_basic/nixos.nix args;
    darwin =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        ...
      }:
      import ./_basic/darwin.nix args;
  };
}
