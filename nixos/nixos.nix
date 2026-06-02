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
  perSystem =
    { pkgs, ... }:
    let
      nixpkgs-drv = pkgs.applyPatches {
        name = "nixpkgs-patched";
        src = inputs.nixpkgs;
        patches = with pkgs; [
          (fetchpatch {
            name = "master backport 1ac3c5dc9969eb532bc5fb22bfedaa4f2b4293c0";
            url = "https://github.com/NixOS/nixpkgs/commit/1ac3c5dc9969eb532bc5fb22bfedaa4f2b4293c0.diff";
            hash = "sha256-jh2CyPjYIPn+AtcO7jz6u/iPiLFd46ibZvVEdiK/MxQ=";
          })
          (fetchpatch {
            name = "Reinstate boot counting (#447173)";
            url = "https://github.com/NixOS/nixpkgs/commit/ef79cc68463a7f6961edf835307c18cfcdd23462.patch";
            hash = "sha256-JVuym6hQgC2QYlHn0fDVIFo3x8qirNEVzSbzm/DBVSU=";
          })
          ../0001-hide-x86_64DarwinDeprecationWarning.patch
          (fetchpatch {
            name = "grub-module-keep-booted-system-entry-option.patch";
            url = "https://github.com/NixOS/nixpkgs/pull/487895.patch";
            hash = "sha256-q4vOJ2BcNa+K0uWvhzuFvmOV7eVyWnKvD/CY3cGh5XI=";
          })
          (fetchpatch {
            name = "nixos/hardware/printers: make ensure-printers partOf cups";
            url = "https://github.com/NixOS/nixpkgs/pull/525012.diff";
            hash = "sha256-cnGOdoUPZ1EMB4gO/eGu6m9/KRLpPNymLionMPrkM5U=";
          })
          # systemd-boot: add options for entry naming and date format
          # https://github.com/NixOS/nixpkgs/pull/516959
          # manually rebased on top of boot counting commit (ef79cc68)
          ./516959-rebased.patch
          (fetchpatch {
            name = "nixos/antigravity: init module";
            url = "https://github.com/NixOS/nixpkgs/pull/510915.diff";
            hash = "sha256-lIltTsEyk05p84h4Iml/aGHiWivI1YIM3k0u7O4rr6w=";
          })
          (fetchpatch {
            name = "doc: add NFS file systems documentation";
            url = "https://github.com/NixOS/nixpkgs/pull/509169.diff";
            hash = "sha256-Hg2auaXO47mnKKUrpXqcmrCcuLk9eJ6CqEZsOvDXTrc=";
          })
          (fetchpatch {
            name = "ryzenadj: 0.17.0 -> 0.19.0";
            url = "https://github.com/NixOS/nixpkgs/pull/527120.diff";
            hash = "sha256-aGZQ8l+i/78muMnxq59zQylEkDTAuTjxkx3INqtET7k=";
          })
          /*
            # unsure
            (fetchpatch {
              name = "lib.options: several small performance cleanups";
              url = "https://github.com/NixOS/nixpkgs/pull/517802.diff";
              hash = "sha256-sVrOQJdfTz4ar5aNZDEAIWY+fHj0BI+U2yuOzBigBAA=";
            })
            (fetchpatch {
              name = "lib.modules: small optimizations";
              url = "https://github.com/NixOS/nixpkgs/pull/517881.diff";
              hash = "sha256-PQoIfuw+GjtN8nHqc/vUEpbrIS+3IUxkxHzx2Ctjolw=";
            })
          */
          /*
            # unsure
            (fetchpatch {
              name = "linuxPackages.ntfs: init at 0-unstable-2026-05-03, nixos/ntfs: add option to use new NTFS(NTFSPLUS) module";
              url = "https://github.com/NixOS/nixpkgs/pull/519075.patch";
              hash = "sha256-E6ZRUd3nXN6AxNzUt1MC3jE1AVL7py/tnLUkd7UgN+o=";
            })
          */
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
      nixosConfigurations.macvirt = nixosSystem {
        system = "aarch64-linux";
        modules = [
          ./macvirt
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
