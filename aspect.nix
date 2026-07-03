# Generic Den aspect entrypoint factory.
#
# Usage:
#   (import ./aspect.nix "options")
#   (import ./aspect.nix "desktop-basic")
#   (import ./aspect.nix den.aspects.selector4nix)
#
# Resolves the aspect for nixos or darwin from `system`. When the aspect defines
# a homeManager branch, merges its imports into home-manager.sharedModules.
aspect:
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

  resolvedAspect =
    if builtins.isString aspect then denConfig.config.den.aspects.${aspect} else aspect;

  homeManagerImports =
    if class == "nixos" && resolvedAspect ? homeManager then
      (denConfig.config.den.lib.aspects.resolveImports "homeManager" resolvedAspect).imports
    else
      [ ];
in
{
  imports = [
    (denConfig.config.den.lib.aspects.resolve class resolvedAspect)
  ];
}
// lib.optionalAttrs (homeManagerImports != [ ]) {
  home-manager.sharedModules = homeManagerImports;
}
