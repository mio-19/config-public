# Den aspect entrypoint: shared base config (den.aspects.common).
# Use `system` from specialArgs, not `pkgs` — accessing pkgs here runs during imports and causes infinite recursion.
{ inputs, system, ... }:
let
  denConfig = (import inputs.nixpkgs { inherit system; }).lib.evalModules {
    modules = [
      (inputs.import-tree ./modules)
      inputs.den.flakeOutputs.flake
    ];
    specialArgs.inputs = inputs;
  };
in
{
  imports = [
    (denConfig.config.den.lib.aspects.resolve "nixos" denConfig.config.den.aspects.common)
  ];
}
