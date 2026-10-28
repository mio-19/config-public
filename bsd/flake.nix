{
  inputs = {
    nixbsd.url = "github:nix-community/nixbsd";
    nixpkgs.follows = "nixbsd/nixpkgs";
    # pin niche inputs to avoid bad people taking over.
    import-tree.url = "github:denful/import-tree/eb1b52eaecc57f7c136d07ae8a93e724dfecac46";
    # pin niche inputs to avoid bad people taking over.
    den.url = "github:denful/den/436350eea1cde7d059877ed04bbd5d35852e3097";
  };
  outputs =
    inputs:
    let
      den =
        (inputs.nixpkgs.lib.evalModules {
          modules = [ (inputs.import-tree ../modules) ];
          specialArgs.inputs = inputs;
        }).config;
    in
    {
      inherit (den.flake) nixbsdConfigurations;
    };
}
