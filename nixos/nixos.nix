{
  withSystem,
  inputs,
  self,
  ...
}:
let
  inherit (inputs)
    mobile-nixos
    deploy-rs
    ;
in
{
  flake =
    let
      the =
        system:
        let
          inputs = withSystem system ({ inputs-patched, ... }: inputs-patched);
        in
        inputs;
      nixosSystem =
        { system, ... }@args:
        let
          inputs = withSystem system ({ inputs-patched, ... }: inputs-patched);
          inherit (inputs) nixpkgs;
        in
        nixpkgs.lib.nixosSystem (
          args
          // {
            specialArgs = {
              inherit inputs system;
            }
            // (args.specialArgs or { });
          }
        );
      deployPkgs =
        let
          inherit (inputs) nixpkgs deploy-rs;
          system = "x86_64-linux";
          # Unmodified nixpkgs
          pkgs = import nixpkgs { inherit system; };
          # nixpkgs with deploy-rs overlay but force the nixpkgs package
          deployPkgs = import nixpkgs {
            inherit system;
            overlays = [
              deploy-rs.overlays.default
              (self: super: {
                deploy-rs = {
                  inherit (pkgs) deploy-rs;
                  lib = super.deploy-rs.lib;
                };
              })
            ];
          };
        in
        deployPkgs;
      denFor = system: import ../den-config.nix { inherit inputs system; };
      denX86 = denFor "x86_64-linux";
      inherit (denX86.hosts.x86_64-linux) fw13 ipc;
    in
    {
      # DETAILS REMOVED
      nixosConfigurations.ipc = nixosSystem {
        system = "x86_64-linux";
        modules = [
          ipc.mainModule
        ];
      };
      nixosConfigurations.fw13 = nixosSystem {
        system = "x86_64-linux";
        modules = [
          fw13.mainModule
        ];
      };
      # DETAILS REMOVED
    };
}
