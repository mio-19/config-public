# Evaluate Den config once; imported by aspect.nix, nixos/nixos.nix, and mac/flake.nix.
{
  inputs,
  system ? "x86_64-linux",
  ...
}:
let
  pkgs = import inputs.nixpkgs { inherit system; };
  denEval = pkgs.lib.evalModules {
    modules = [
      (inputs.import-tree ./modules)
      inputs.den.flakeOutputs.flake
    ];
    specialArgs.inputs = inputs;
  };
in
denEval.config.den
