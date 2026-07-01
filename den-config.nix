# Evaluate Den config once; import from nixos/nixos.nix and mac flake.
{ inputs, system ? "x86_64-linux", ... }:
let
  denEval = (import inputs.nixpkgs { inherit system; }).lib.evalModules {
    modules = [
      (inputs.import-tree ./modules)
      inputs.den.flakeOutputs.flake
    ];
    specialArgs.inputs = inputs;
  };
in
denEval.config.den
