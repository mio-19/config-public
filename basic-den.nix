# Den aspect entrypoint: shared baseline (den.aspects.basic) for NixOS and nix-darwin.
# Use `system` from specialArgs, not `pkgs` — accessing pkgs here runs during imports and causes infinite recursion.
{
  inputs,
  system,
  lib,
  ...
}:
let
  class = if lib.hasSuffix "darwin" system then "darwin" else "nixos";
  denConfig = (import inputs.nixpkgs { inherit system; }).lib.evalModules {
    modules = [
      inputs.den.flakeModule
      ./modules/basic.nix
    ];
    specialArgs.inputs = inputs;
  };
in
{
  imports = [
    (denConfig.config.den.lib.aspects.resolve class denConfig.config.den.aspects.basic)
  ];
}
