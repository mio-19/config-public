{
  withSystem,
  inputs,
  ...
}:
let
  inherit (inputs)
    mobile-nixos
    ;
in
{
  perSystem =
    { pkgs, ... }:
    let
      nixpkgs-drv = pkgs.applyPatches {
        name = "nixpkgs-patched";
        src = inputs.nixpkgs;
        patches = with pkgs; [
          (fetchpatch {
            name = "grub-module-keep-booted-system-entry-option.patch";
            url = "https://github.com/NixOS/nixpkgs/pull/487895.patch";
            hash = "sha256-ys6bro8F3fmxc4yvHgB3+LbnrU7yB8c/5RQ+NZMQCEI=";
          })
          (fetchpatch {
            name = "linuxPackages.ntfs: init at 0-unstable-2026-05-03, nixos/ntfs: add option to use new NTFS(NTFSPLUS) module";
            url = "https://github.com/NixOS/nixpkgs/pull/519075.patch";
            hash = "sha256-RFOdrUolXKJ2xCHTma5bL515Z6CSeBOKVD91xwpvETw=";
          })
          (fetchpatch {
            name = "linuxPackages.apfs: 0.3.18 -> 0.3.20";
            url = "https://github.com/NixOS/nixpkgs/pull/520905.patch";
            hash = "sha256-2QjagADdcIJNhLxXPMJBnmFy88/hGrA97dLLOCiTayU=";
          })
        ];
      };
      # what is self - https://discourse.nixos.org/t/who-is-self-in-flake-outputs/31859
      nixpkgs =
        (import "${nixpkgs-drv}/flake.nix").outputs {
          self = nixpkgs;
        }
        // {
          outPath = toString nixpkgs-drv;
        };
      nixos-avf-drv = pkgs.applyPatches {
        name = "nixos-avf-patched";
        src = inputs.nixos-avf;
        patches = with pkgs; [
          (fetchpatch {
            name = "Get rid of deprecation warnings on nixos-unstable";
            url = "https://github.com/nix-community/nixos-avf/pull/39.patch";
            hash = "sha256-PGd0Bk+tgkXXWAcUyJg7f+XREvMo84/tdGWk2auAgM0=";
          })
        ];
      };
      nixos-avf =
        (import "${nixos-avf-drv}/flake.nix").outputs {
          self = nixos-avf;
          nixpkgs = nixpkgs;
        }
        // {
          outPath = toString nixos-avf-drv;
        };
      inputs-patched = inputs // {
        inherit nixpkgs nixos-avf;
      };
    in
    {
      _module.args.inputs-patched = inputs-patched;
    };
  flake =
    let
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
    in
    {
      # DETAILS REMOVED
      # Terminal app
      nixosConfigurations.husky = nixosSystem {
        system = "aarch64-linux";
        modules = [
          ./husky
        ];
      };
      # DETAILS REMOVED
      nixosConfigurations.ipc = nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./ipc2
          #./nixremote.nix
          #./desktop-specialisation.nix
          #./netbird.nix
          #./rc.nix
          #inputs.determinate.nixosModules.default
        ];
      };
      # DETAILS REMOVED
    };
}
