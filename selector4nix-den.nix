# Den aspect entrypoint: resolves per host platform (x86_64-linux, aarch64-linux, aarch64-darwin, …).
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
      (inputs.import-tree ./modules)
      inputs.den.flakeOutputs.flake
    ];
    specialArgs.inputs = inputs;
  };
in
{
  imports = [
    (denConfig.config.den.lib.aspects.resolve class denConfig.config.den.aspects.selector4nix)
  ];
}
