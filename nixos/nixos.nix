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
        # PR .patch URLs track branch head, so the hash changes when the PR is updated.
        # That is intentional: a hash mismatch surfaces PR updates at rebuild time.
        patches = with pkgs; [
          (fetchpatch {
            name = "grub-module-keep-booted-system-entry-option.patch";
            url = "https://github.com/NixOS/nixpkgs/pull/487895.patch";
            hash = "sha256-q4vOJ2BcNa+K0uWvhzuFvmOV7eVyWnKvD/CY3cGh5XI=";
            derivationArgs.allowSubstitutes = false;
          })
          (fetchpatch {
            name = "nixos/hardware/printers: make ensure-printers partOf cups";
            url = "https://github.com/NixOS/nixpkgs/pull/525012.diff";
            hash = "sha256-cnGOdoUPZ1EMB4gO/eGu6m9/KRLpPNymLionMPrkM5U=";
            derivationArgs.allowSubstitutes = false;
          })
          (fetchpatch {
            name = "systemd-boot: add options for entry naming and date format";
            url = "https://github.com/NixOS/nixpkgs/pull/516959.diff";
            hash = "sha256-cpe1V1wm9jWk/D8vNlXeOHdBlxptmte2gUX3YjyLczE=";
            derivationArgs.allowSubstitutes = false;
          })
          (fetchpatch {
            name = "nixos/antigravity: init module";
            url = "https://github.com/NixOS/nixpkgs/pull/510915.diff";
            hash = "sha256-lIltTsEyk05p84h4Iml/aGHiWivI1YIM3k0u7O4rr6w=";
            derivationArgs.allowSubstitutes = false;
          })
          (fetchpatch {
            name = "doc: add NFS file systems documentation";
            url = "https://github.com/NixOS/nixpkgs/pull/509169.diff";
            hash = "sha256-Hg2auaXO47mnKKUrpXqcmrCcuLk9eJ6CqEZsOvDXTrc=";
            derivationArgs.allowSubstitutes = false;
          })
          (fetchpatch {
            name = "update nixos/hardware.fw-fanctrl + package fw-fanctrl";
            #url = "https://github.com/NixOS/nixpkgs/pull/526318.diff";
            url = "https://github.com/mio-19/nixpkgs/pull/1.diff";
            hash = "sha256-8ja+DroRYUPww/Z6IjQuN2oWEGUHTk4H2j8Nze62V1o=";
            derivationArgs.allowSubstitutes = false;
          })
          (fetchpatch {
            name = "nixos/wireless: add support for setting wireless regdom";
            url = "https://github.com/NixOS/nixpkgs/pull/528908.patch";
            hash = "sha256-C/NMN+/l6W01HKOBib9RJiJt7+0AvIVlmNWXwC/oKAk=";
            derivationArgs.allowSubstitutes = false;
          })
          (fetchpatch {
            name = "nixos/security/wrappers: avoid linux-headers in closure";
            url = "https://github.com/NixOS/nixpkgs/pull/532581.patch";
            hash = "sha256-Tf3Lz9iQGqVVkviGg3FF2UyNVig8vhcYrMG+tIT2zA0=";
            derivationArgs.allowSubstitutes = false;
          })
          (fetchpatch {
            name = "nixos/systemd-boot: defer boot file garbage collection";
            url = "https://github.com/NixOS/nixpkgs/pull/531008.diff";
            hash = "sha256-H4NMS9eDsJ1zM6gLQdZtyyBYumjKArrCFDcWeE+IOJQ=";
            derivationArgs.allowSubstitutes = false;
          })
          (fetchpatch {
            name = "nixos/nix-remote-build: permit non-integer speed factors";
            url = "https://github.com/NixOS/nixpkgs/pull/532764.patch";
            hash = "sha256-8Sc0mj515Y2VspYoPmWppNjj4OkiqnAqEJ9VfsfeaT0=";
            derivationArgs.allowSubstitutes = false;
          })
          (fetchpatch {
            name = "nixos/btrfs: add services.btrfs.autoReclaim option";
            url = "https://github.com/NixOS/nixpkgs/pull/527555.patch";
            hash = "sha256-/fm1s8WnmZmGZ9pN/qBj/4998cBjShPVTii4qXsLZvE=";
            derivationArgs.allowSubstitutes = false;
          })
          (fetchpatch {
            name = "nixos/bash: Reset title bar only for interactive shells";
            url = "https://github.com/NixOS/nixpkgs/pull/521688.patch";
            hash = "sha256-sD9sjD+GVoAjMe6gQjJ18Z4pYvWi2xjTdukaQBSm/Ao=";
            derivationArgs.allowSubstitutes = false;
          })
          (fetchpatch {
            name = "nixos/fwupd: add enableGrubHook option";
            url = "https://github.com/NixOS/nixpkgs/pull/521378.patch";
            hash = "sha256-gzu5MAWLnzqaDafJx4Yc0gc7OmQqsTRxA0N/9lotdbI=";
            derivationArgs.allowSubstitutes = false;
          })
          (fetchpatch {
            name = "nixos/tailscale: order tailscaled after network-online.target";
            url = "https://github.com/NixOS/nixpkgs/pull/529035.patch";
            hash = "sha256-ejSZR/46qHycDVwbVV4UjESICT2CTBbJ4J51hasgRs4=";
            derivationArgs.allowSubstitutes = false;
          })
          (fetchpatch {
            name = "onlyoffice-desktopeditors: 9.1.0 -> 9.4.0";
            url = "https://github.com/NixOS/nixpkgs/pull/526315.patch";
            hash = "sha256-KDoNbXwwZoz6guOzK4I3bK4shYL+8Mb9YE3TK+819jI=";
            derivationArgs.allowSubstitutes = false;
          })
          # https://github.com/NixOS/nixpkgs/issues/442117
          (fetchpatch {
            name = "Add deny fprintd PAM auth for su/sudo without tty";
            url = "https://github.com/joshperry/nixpkgs/commit/e256ef2283759082941ddb6dd422b7d885378db4.patch";
            hash = "sha256-WeKRwcAvQNhcRAjLtjX+kYX8Mp59TYBjrTQqh7znEkU=";
          })
          /*
            # unsure
            (fetchpatch {
              name = "lib.options: several small performance cleanups";
              url = "https://github.com/NixOS/nixpkgs/pull/517802.diff";
              hash = "sha256-sVrOQJdfTz4ar5aNZDEAIWY+fHj0BI+U2yuOzBigBAA=";
              derivationArgs.allowSubstitutes = false;
            })
            (fetchpatch {
              name = "lib.modules: small optimizations";
              url = "https://github.com/NixOS/nixpkgs/pull/517881.diff";
              hash = "sha256-PQoIfuw+GjtN8nHqc/vUEpbrIS+3IUxkxHzx2Ctjolw=";
              derivationArgs.allowSubstitutes = false;
            })
          */
          /*
            # unsure
            (fetchpatch {
              name = "linuxPackages.ntfs: init at 0-unstable-2026-05-03, nixos/ntfs: add option to use new NTFS(NTFSPLUS) module";
              url = "https://github.com/NixOS/nixpkgs/pull/519075.patch";
              hash = "sha256-E6ZRUd3nXN6AxNzUt1MC3jE1AVL7py/tnLUkd7UgN+o=";
              derivationArgs.allowSubstitutes = false;
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
            derivationArgs.allowSubstitutes = false;
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
        nixpkgs-patched = nixpkgs;
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
      den = import ../den-config.nix { inherit inputs; };
      inherit (den.hosts.x86_64-linux) fw13;
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
          fw13.mainModule
        ];
      };
      # DETAILS REMOVED
    };
}
