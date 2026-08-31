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
      inputsFor = system: withSystem system ({ inputs-patched, ... }: inputs-patched);
      the =
        system:
        let
          inputs = inputsFor system;
        in
        inputs;
      nixosSystem =
        { system, ... }@args:
        let
          inputs = inputsFor system;
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
          system = "x86_64-linux";
          inherit (inputsFor system) nixpkgs deploy-rs;
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
      denFor =
        system:
        import ../den-config.nix {
          inherit system;
          inputs = inputsFor system;
        };
      denX86 = denFor "x86_64-linux";
      denA64 = denFor "aarch64-linux";
      inherit (denX86.hosts.x86_64-linux) fw13 ipc deck;
      inherit (denA64.hosts.aarch64-linux) husky macvirt;
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
      nixosConfigurations.deck = nixosSystem {
        system = "x86_64-linux";
        modules = [
          deck.mainModule
        ];
      };
      nixosConfigurations.husky = nixosSystem {
        system = "aarch64-linux";
        modules = [
          husky.mainModule
        ];
      };
      nixosConfigurations.macvirt = nixosSystem {
        system = "aarch64-linux";
        modules = [
          macvirt.mainModule
        ];
      };
      # DETAILS REMOVED
    };
}
