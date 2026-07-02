# Den aspect entrypoint: den.aspects.desktop-basic in modules/desktop-basic.nix.
# Use `system` from specialArgs, not `pkgs`.
{ inputs, system, ... }:
let
  den = import ./den-config.nix { inherit inputs system; };
  aspect = den.aspects.desktop-basic;
in
{
  imports = [
    (den.lib.aspects.resolve "nixos" aspect)
  ];
  home-manager.sharedModules = (den.lib.aspects.resolveImports "homeManager" aspect).imports;
}
