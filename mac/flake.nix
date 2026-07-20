{
  description = "Mio's darwin configuration";

  inputs = {
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };
    flake-utils.url = "github:numtide/flake-utils";
    # https://github.com/NixOS/nixpkgs/pull/449689
    #nixpkgs-staging.url = "github:NixOS/nixpkgs/staging";
    #nixpkgs-new.url = "github:NixOS/nixpkgs/master";
    nixpkgs-stable.url = "https://nixos.org/channels/nixpkgs-26.05-darwin/nixexprs.tar.xz"; # for /etc/nix/registry.json
    #nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-unstable.url = "https://nixos.org/channels/nixpkgs-unstable/nixexprs.tar.xz";
    #nixpkgs-unstable.url = "github:NixOS/nixpkgs/767b0d3ec98a143ad9ed7dfc0d5553510ac27133"; # https://hydra.nixos.org/job/nixpkgs/unstable/unstable#tabs-constituents
    nixpkgs.follows = "nixpkgs-unstable";
    #nixpkgs.url = "github:NixOS/nixpkgs/master";
    #nixpkgs-pin.url = "github:NixOS/nixpkgs/b86751bc4085f48661017fa226dee99fab6c651b"; # a commit from nixpkgs-unstable
    nixpkgs-pin2.url = "github:NixOS/nixpkgs/b579d443b37c9c5373044201ea77604e37e748c8"; # a commit from nixpkgs-unstable
    nixpkgs-pin3.url = "https://releases.nixos.org/nixpkgs/nixpkgs-26.11pre1028110.f205b5574fd0/nixexprs.tar.xz"; # a commit from nixpkgs-unstable
    #nixpkgs-pin4.url = "github:NixOS/nixpkgs/b3c092d3c36d91e2f61f3dfb39a159f180a56659"; # a commit from nixpkgs-unstable
    #nixpkgs-pin5.url = "github:NixOS/nixpkgs/e52c192be9d7b2c4bd4aed326c8731b35f8bb75c"; # a commit from nixpkgs-unstable
    #nixpkgs-pin6.url = "github:NixOS/nixpkgs/6dedf69f94d03cbe7bdde106f2d4c23ae2a853bf"; # a commit from nixpkgs-unstable
    nixpkgs-pin7.url = "https://releases.nixos.org/nixpkgs/nixpkgs-26.11pre1036836.20535e48e12c/nixexprs.tar.xz"; # a commit from nixpkgs-unstable
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    #pinix = {
    #  url = "git+https://github.com/remi-dupre/pinix.git";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    /*
      zen-browser = {
        url = "github:0xc000022070/zen-browser-flake";
        #inputs.nixpkgs.follows = "nixpkgs";
        inputs.nixpkgs.follows = "nixpkgs";
        inputs.home-manager.follows = "home-manager";
      };
    */
    #  --option 'extra-substituters' 'https://chaotic-nyx.cachix.org/' --option extra-trusted-public-keys "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
    chaotic = {
      #url = "github:lonerOrz/nyx-loner";
      url = "github:chaotic-cx/nyx";
      #inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    nur = {
      #url = "github:mio-19/NUR";
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    darwin-emacs = {
      # pin to avoid frequent updates and building emacs
      url = "github:nix-giant/nix-darwin-emacs/59ab9eb4433da6da81561c0d1cd79e5dfbe71cfc";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    #nixpkgs-2505.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
    #emacs-overlay = {
    #  url = "github:nix-community/emacs-overlay";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #  inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    #};
    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.nixpkgs.follows = "nixpkgs-pin2";
      inputs.flake-utils.follows = "flake-utils";
      inputs.cl-nix-lite.inputs.flake-parts.follows = "flake-parts";
      inputs.treefmt-nix.inputs.nixpkgs.follows = "mac-app-util/nixpkgs";
      inputs.cl-nix-lite.inputs.nixpkgs.follows = "mac-app-util/nixpkgs";
      inputs.cl-nix-lite.inputs.treefmt-nix.follows = "mac-app-util/treefmt-nix";
    };
    #  --option 'extra-substituters' 'https://cache.numtide.com' --option extra-trusted-public-keys "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      #inputs.nixpkgs.follows = "nixpkgs"; # no overide to have binary cache.
      inputs.blueprint.inputs.systems.follows = "flake-utils/systems";
      inputs.flake-parts.follows = "flake-parts";
    };
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    #stylix = {
    #  url = "github:nix-community/stylix";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};
    #nix-rosetta-builder = {
    #  url = "github:cpick/nix-rosetta-builder";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};
    mio = {
      url = "git+https://github.com/mio-19/nurpkgs.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    selector4nix = {
      url = "github:StarryReverie/selector4nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    import-tree.url = "github:denful/import-tree";
    den.url = "github:denful/den";
    apple-fonts = {
      # pin niche inputs to avoid bad people taking over.
      url = "github:Lyndeno/apple-fonts.nix/ce044f6829c6b3ccde9624116577ba2c173ca49d";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    chinese-fonts-overlay = {
      # pin niche inputs to avoid bad people taking over.
      url = "github:brsvh/chinese-fonts-overlay/da90d47fa1a6f8fbfcc5795bc9351c98142f37ea";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs0@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inputs = inputs0; } (
      { withSystem, ... }: {
        systems = [
          "x86_64-darwin"
          "aarch64-darwin"
        ];
        imports = [
          inputs0.den.flakeModule
        ];
        perSystem =
          {
            system,
            pkgs,
            config,
            lib,
            ...
          }:
          let
            pkgs0 = import inputs0.nixpkgs {
              inherit system;
              config.allowDeprecatedx86_64Darwin = "force";
            };
            nixpkgs-drv = pkgs0.applyPatches {
              name = "nixpkgs-patched";
              src = inputs0.nixpkgs.outPath;
              patches = with pkgs0; [
                # possible to consider patches
                # supertuxkart: updates for darwin and app experience - https://github.com/NixOS/nixpkgs/pull/520901.diff
                # gimp3: fix Darwin build - https://github.com/NixOS/nixpkgs/pull/513484.diff
                # lib.options: several small performance cleanups - https://github.com/NixOS/nixpkgs/pull/517802.diff
                # 64gram: fix darwin build with Qt 6.11 - https://github.com/NixOS/nixpkgs/pull/520733.diff
                # keepassxc: fix pcsc for darwin - https://github.com/NixOS/nixpkgs/pull/520328.diff
                # remmina: fix missing sidebar icons on macOS - https://github.com/NixOS/nixpkgs/pull/514651.patch
                (fetchpatch {
                  name = "types.path.check: Avoid derivation instantiation";
                  url = "https://github.com/NixOS/nixpkgs/pull/540399.patch";
                  hash = "sha256-rJ+c2Wvwt5fr1c4HdQR8QAyhdfXfrDtiAnONnNgEuIo=";
                  derivationArgs.allowSubstitutes = false;
                })
                (fetchurl {
                  name = "flyline: init at 1.3.0";
                  url = "https://github.com/NixOS/nixpkgs/pull/538842.patch";
                  hash = "sha256-2SJqaw/rP3Cny5Hm2rjXI5iP+SEZVTNySgE/2yfsVK0=";
                  derivationArgs.allowSubstitutes = false;
                })
                (fetchpatch {
                  name = "musescore-evolution: fix darwin build";
                  url = "https://github.com/NixOS/nixpkgs/pull/538827.patch";
                  hash = "sha256-q3V+g9BB1y9U3kp2HbwYa0XD/sH5zRPfBc0xwNM7WpY=";
                  derivationArgs.allowSubstitutes = false;
                })
                (fetchpatch {
                  name = "tuxguitar: fix launch on darwin when app bundle path contains space";
                  url = "https://github.com/NixOS/nixpkgs/pull/487108.diff";
                  hash = "sha256-MHbE/UY/Rey8a7/zCEQEvvgVH4E4V4CYEm7dqdH6ZGM=";
                  derivationArgs.allowSubstitutes = false;
                })
                (fetchpatch {
                  name = "makeBinaryWrapper: fix passthru.extractCmd on darwin";
                  url = "https://github.com/NixOS/nixpkgs/pull/483719.diff";
                  hash = "sha256-7mcSsAboehuksmXeSiP13SFDItZ24icjeyehRZiOg8s=";
                  derivationArgs.allowSubstitutes = false;
                })
                (fetchpatch {
                  name = "trayscale: add macOS application bundle";
                  url = "https://github.com/NixOS/nixpkgs/pull/536595.diff";
                  hash = "sha256-L+KmuCFum4hvK5kwQJvdr1ueJQ6tJSfEEfw1vOtmr/4=";
                  derivationArgs.allowSubstitutes = false;
                })
                (fetchpatch {
                  name = "github-copilot-cli: 1.0.26 -> 1.0.70";
                  url = "https://github.com/NixOS/nixpkgs/pull/534884.diff";
                  hash = "sha256-6U6qYZ0WD/GNkWvLUpchTCHRNUm0VYSorE8oi9aK9LE=";
                  derivationArgs.allowSubstitutes = false;
                })
                (fetchpatch {
                  name = "mailspring: fix linux desktop file, package using darwin .app";
                  url = "https://github.com/NixOS/nixpkgs/pull/539093.diff";
                  hash = "sha256-NY+9atjNnQ/DCv+H8n7oK5BWYNSthe/JZwCrNZupgQw=";
                  derivationArgs.allowSubstitutes = false;
                })
                (fetchpatch {
                  name = "baobab: add desktopToDarwinBundle override";
                  url = "https://github.com/NixOS/nixpkgs/pull/536603.diff";
                  hash = "sha256-OTgYDCP9PsldoFGarL9NB7WEyB3jAjeVxeZo20M6HWE=";
                  derivationArgs.allowSubstitutes = false;
                })
              ];
            };
            nixpkgs =
              (import "${nixpkgs-drv}/flake.nix").outputs {
                self = nixpkgs;
              }
              // {
                outPath = toString nixpkgs-drv;
                _type = "flake";
              };
          in
          {
            _module.args.pkgs = import nixpkgs {
              inherit system;
              config.allowDeprecatedx86_64Darwin = "force";
            };
            packages.nixpkgs-patched = nixpkgs;
          };

        flake =
          let
            the = (
              system:
              withSystem system (
                { config, pkgs, ... }:
                let
                  nixpkgs = config.packages.nixpkgs-patched;
                  inputs-patched = builtins.mapAttrs (
                    name: input:
                    if input ? inputs && input.inputs ? nixpkgs && input.inputs.nixpkgs == inputs0.nixpkgs then
                      let
                        inputs' = input.inputs // {
                          inherit nixpkgs;
                          self = patched-input;
                        };
                        patched-input = (import "${input.outPath}/flake.nix").outputs inputs' // {
                          outPath = input.outPath;
                          inputs = inputs';
                          inherit (input) sourceInfo;
                          _type = "flake";
                        };
                      in
                      patched-input
                    else
                      input
                  ) inputs0;
                  inherit (inputs-patched) darwin deploy-rs mio;

                  pkgs = import nixpkgs {
                    inherit system;
                    config.allowDeprecatedx86_64Darwin = "force";
                  };
                  # nixpkgs with deploy-rs overlay but force the nixpkgs package
                  deployPkgs = import nixpkgs {
                    inherit system;
                    config.allowDeprecatedx86_64Darwin = "force";
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
                {
                  inputs = inputs-patched // {
                    inherit nixpkgs;
                    nixpkgs-unpatched = inputs0.nixpkgs;
                    nixpkgs-patched = nixpkgs;
                  };
                  inherit
                    darwin
                    deployPkgs
                    deploy-rs
                    system
                    ;
                  inherit (inputs0) self;
                }
              )
            );
          in
          {
            # DETAILS REMOVED
            darwinConfigurations."NixMac" =
              with the "aarch64-darwin";
              let
                den = import ../den-config.nix { inherit inputs system; };
                inherit (den.hosts.aarch64-darwin) NixMac;
              in
              darwin.lib.darwinSystem {
                specialArgs = {
                  inherit inputs system;
                };
                modules = [
                  NixMac.mainModule
                  #./builder-uninstall.nix
                  #./builder-firstinstall.nix
                ];
              };
            darwinConfigurations.NixMac-2 = self.darwinConfigurations."NixMac";
          };
      }
    );
}
