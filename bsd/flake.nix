{
  inputs = {
    nixbsd.url = "github:nix-community/nixbsd";
    nixpkgs.follows = "nixbsd/nixpkgs";
    # pin niche inputs to avoid bad people taking over.
    import-tree.url = "github:denful/import-tree/eb1b52eaecc57f7c136d07ae8a93e724dfecac46";
    # pin niche inputs to avoid bad people taking over.
    den.url = "github:denful/den/bf2504f9f2e8621fee091335132ab3ae698cf808";
  };
  outputs =
    inputs:
    let
      system = "x86_64-linux";
      den =
        (inputs.nixpkgs.lib.evalModules {
          modules = [
            (inputs.import-tree ../modules)
            ({ lib, ... }: {
              options.flake.nixbsdConfigurations = lib.mkOption {
                default = { };
                type = lib.types.lazyAttrsOf lib.types.raw;
              };
            })
            ({ den, lib, ... }: {
              den.hosts.x86_64-freebsd.fw13 = {
                instantiate = inputs.nixbsd.lib.nixbsdSystem;
                intoAttr = [
                  "nixbsdConfigurations"
                  "fw13"
                ];
              };
            })
          ];
          specialArgs = {
            inherit inputs system;
          };
        }).config;
    in
    {
      inherit (den.flake) nixbsdConfigurations;
      nixosConfigurations = den.flake.nixbsdConfigurations;
    };
}
