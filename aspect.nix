# Generic Den aspect entrypoint factory.
#
# Usage:
#   (import ./aspect.nix "options")
#   (import ./aspect.nix "desktop-basic")
#   (import ./aspect.nix den.aspects.selector4nix)
#
# Resolves the aspect for nixos or darwin from `system`. When the aspect defines
# a homeManager branch, merges its imports into home-manager.sharedModules.
#
# Den is evaluated via den-config.nix so this shares one evalModules result with
# nixos/nixos.nix and mac/flake.nix (import memoization by canonical path).
aspect:
{
  inputs,
  system,
  lib,
  ...
}:
let
  class = if lib.hasSuffix "darwin" system then "darwin" else "nixos";
  den = import ./den-config.nix { inherit inputs system; };
  inherit (den.lib) aspects;
  resolvedAspect = if builtins.isString aspect then den.aspects.${aspect} else aspect;
  homeManagerImports =
    if class == "nixos" && resolvedAspect ? homeManager then
      (aspects.resolveImports "homeManager" resolvedAspect).imports
    else
      [ ];
in
{
  imports = [
    (aspects.resolve class resolvedAspect)
  ];
}
// lib.optionalAttrs (homeManagerImports != [ ]) {
  home-manager.sharedModules = homeManagerImports;
}
