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
          ../0001-hide-x86_64DarwinDeprecationWarning.patch
          (fetchpatch {
            name = "musescore-evolution: 3.7.0-unstable-2026-03-03 -> 3.7.0-unstable-2026-06-10";
            url = "https://github.com/NixOS/nixpkgs/pull/530469.patch";
            hash = "sha256-1oHDn8THBGTx55uTmQs12nGOdueqqGK4gfstKKqBElM=";
          })
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
            name = "update nixos/hardware.fw-fanctrl + package fw-fanctrl";
            url = "https://github.com/NixOS/nixpkgs/pull/526318.diff";
            hash = "sha256-fycyXDGD8tcFFZyQyFUgkRCbQPzENS6HcwKFzyRl0p8=";
          })
          (fetchpatch {
            name = "nixos/wireless: add support for setting wireless regdom";
            url = "https://github.com/NixOS/nixpkgs/pull/528908.patch";
            hash = "sha256-C/NMN+/l6W01HKOBib9RJiJt7+0AvIVlmNWXwC/oKAk=";
          })
          (fetchpatch {
            name = "nixos/systemd-boot: defer boot file garbage collection";
            url = "https://github.com/NixOS/nixpkgs/pull/531008.diff";
            hash = "sha256-H4NMS9eDsJ1zM6gLQdZtyyBYumjKArrCFDcWeE+IOJQ=";
          })
          (fetchpatch {
            name = "mousam: 1.4.2 -> 2.0.2";
            url = "https://github.com/NixOS/nixpkgs/pull/531624.patch";
            hash = "sha256-euYP3ROWV0kBKQB2tgSUvFuxldcnRXOpwvGsma5sFwY=";
          })
          (fetchpatch {
            name = "switch-to-configuration-ng: Handle dbus errors & lack of messages";
            url = "https://github.com/NixOS/nixpkgs/pull/528308.patch";
            hash = "sha256-n0Czi4Kr3Mutu+cEbadpMp63Bx4A9iwKF7CevOBKccI=";
          })
          (fetchpatch {
            name = "librewolf-unwrapped: 151.0.2-1 -> 152.0-1";
            url = "https://github.com/NixOS/nixpkgs/pull/527571.patch";
            hash = "sha256-f122Yd4h3d53bR7Y5FDe9iaApNUkgOd3X4+YguqDxs0=";
          })
          (fetchpatch {
            name = "librewolf-bin-unwrapped: 151.0.1-2 -> 151.0.4-1";
            url = "https://github.com/NixOS/nixpkgs/pull/531055.patch";
            hash = "sha256-BVszJcxP7uoccGqDFzV5idl8ierDkomz5JmKwAc6lqI=";
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
      nixpkgs =
        (import "${nixpkgs-drv}/flake.nix").outputs {
          self = nixpkgs;
        }
        // {
          outPath = toString nixpkgs-drv;
          # for https://github.com/hercules-ci/flake-parts/blob/f7c1a2d347e4c52d5fb8d10cb4d94b5884e546fb/modules/perSystem.nix#L113
          _type = "flake";
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
      mio =
        let
          inputs' = inputs.mio.inputs // {
            self = mio;
            nixpkgs = nixpkgs;
          };
        in
        (import "${inputs.mio}/flake.nix").outputs inputs'
        // {
          outPath = inputs.mio.outPath;
          inputs = inputs';
        };
      nur =
        let
          inputs' = inputs.nur.inputs // {
            self = nur;
            nixpkgs = nixpkgs;
          };
        in
        (import "${inputs.nur}/flake.nix").outputs inputs'
        // {
          outPath = inputs.nur.outPath;
          inputs = inputs';
        };
      inputs-patched = inputs // {
        inherit
          nixpkgs
          nixos-avf
          mio
          nur
          ;
        nixpkgs-unpatched = inputs.nixpkgs;
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
      nixosConfigurations.fw13 = nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./fw13
        ];
      };
      # DETAILS REMOVED
    };
}
