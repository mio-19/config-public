{
  description = "Mio's darwin configuration";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    # https://github.com/NixOS/nixpkgs/pull/449689
    #nixpkgs-staging.url = "github:NixOS/nixpkgs/staging";
    #nixpkgs-new.url = "github:NixOS/nixpkgs/master";
    #nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-unstable.url = "https://nixos.org/channels/nixpkgs-unstable/nixexprs.tar.xz";
    #nixpkgs-unstable.url = "github:NixOS/nixpkgs/e1c1b84752fb"; # https://hydra.nixos.org/job/nixpkgs/unstable/unstable#tabs-constituents
    nixpkgs.follows = "nixpkgs-unstable";
    #nixpkgs.url = "github:NixOS/nixpkgs/master";
    #nixpkgs-pin.url = "github:NixOS/nixpkgs/b86751bc4085f48661017fa226dee99fab6c651b"; # a commit from nixpkgs-unstable
    nixpkgs-pin2.url = "github:NixOS/nixpkgs/b579d443b37c9c5373044201ea77604e37e748c8"; # a commit from nixpkgs-unstable
    nixpkgs-pin3.url = "github:NixOS/nixpkgs/b3c092d3c36d91e2f61f3dfb39a159f180a56659"; # a commit from nixpkgs-unstable
    nixpkgs-pin4.url = "github:NixOS/nixpkgs/b3c092d3c36d91e2f61f3dfb39a159f180a56659"; # a commit from nixpkgs-unstable
    #nixpkgs-pin5.url = "github:NixOS/nixpkgs/d99b013d5d1931ad77fe3912ed218170dec5d9a4"; # a commit from nixpkgs-unstable
    #nixpkgs-pin6.url = "github:NixOS/nixpkgs/6dedf69f94d03cbe7bdde106f2d4c23ae2a853bf"; # a commit from nixpkgs-unstable
    #nixpkgs-pin7.url = "github:NixOS/nixpkgs/4100e830e085863741bc69b156ec4ccd53ab5be0"; # a commit from nixpkgs-unstable
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
    #chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    #chaotic.url = "github:chaotic-cx/nyx/main";
    nur = {
      #url = "github:mio-19/NUR";
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin-emacs = {
      # pin to avoid frequent updates and building emacs
      url = "github:nix-giant/nix-darwin-emacs/59ab9eb4433da6da81561c0d1cd79e5dfbe71cfc";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    #nixpkgs-stable.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";
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
      inputs.cl-nix-lite.inputs.flake-parts.follows = "nur/flake-parts";
      inputs.treefmt-nix.inputs.nixpkgs.follows = "mac-app-util/nixpkgs";
      inputs.cl-nix-lite.inputs.nixpkgs.follows = "mac-app-util/nixpkgs";
      inputs.cl-nix-lite.inputs.treefmt-nix.follows = "mac-app-util/treefmt-nix";
    };
    #  --option 'extra-substituters' 'https://cache.numtide.com' --option extra-trusted-public-keys "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      #inputs.nixpkgs.follows = "nixpkgs"; # no overide to have binary cache.
      inputs.blueprint.inputs.systems.follows = "flake-utils/systems";
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
    chester = {
      url = "git+https://codeberg.org/chester-lang/chester.git";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    mio = {
      url = "git+https://github.com/mio-19/nurpkgs.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-openclaw = {
      url = "github:openclaw/nix-openclaw";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nix-steipete-tools.inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    selector4nix = {
      url = "github:StarryReverie/selector4nix";
      # has cache on garnix
      #inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs0@{ self, ... }:
    let
      the = (
        system:
        let
          pkgs0 = import inputs0.nixpkgs {
            inherit system;
            config.allowDeprecatedx86_64Darwin = true;
          };
          nixpkgs-drv = pkgs0.applyPatches {
            name = "nixpkgs-patched";
            src = inputs0.nixpkgs.outPath;
            patches = with pkgs0; [
              /*
                # merge conflicts?
                (fetchpatch {
                  name = "supertuxkart: updates for darwin and app experience";
                  url = "https://github.com/NixOS/nixpkgs/pull/520901.diff";
                  hash = "sha256-mtMxithwskTtp0tnBaFBSI3+Q8OuG6xCNEDYILNx/Kw=";
                  derivationArgs.allowSubstitutes = false;
                })
              */
              /*
                # conflicts
                (fetchpatch {
                  name = "gimp3: fix Darwin build";
                  url = "https://github.com/NixOS/nixpkgs/pull/513484.diff";
                  hash = "sha256-Y9nqZTtq77SiSSCiqzXEB3+n8MPmDmjjhoB79QpPenc=";
                  derivationArgs.allowSubstitutes = false;
                })
              */
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
                name = "koodo-reader: fix darwin build";
                url = "https://github.com/NixOS/nixpkgs/pull/536592.diff";
                hash = "sha256-Z/m4UqkHsCm5iLyE65g9XVL+xMSgWCNZwPECmGcT3Vc=";
                derivationArgs.allowSubstitutes = false;
              })
              (fetchpatch {
                name = "trayscale: add macOS application bundle";
                url = "https://github.com/NixOS/nixpkgs/pull/536595.diff";
                hash = "sha256-DP2+sr5DQtslEjJMfSueNfmpMeRAPdmfUW8dDnq9SYk=";
                derivationArgs.allowSubstitutes = false;
              })
              /*
                # unsure
                (fetchpatch {
                  name = "lib.options: several small performance cleanups";
                  url = "https://github.com/NixOS/nixpkgs/pull/517802.diff";
                  hash = "sha256-sVrOQJdfTz4ar5aNZDEAIWY+fHj0BI+U2yuOzBigBAA=";
                  derivationArgs.allowSubstitutes = false;
                })
              */
              (fetchpatch {
                name = "vscode-with-extensions: respect macos package bundle's CFBundleExecutable value when generating the wrapper";
                url = "https://github.com/NixOS/nixpkgs/pull/507766.patch";
                hash = "sha256-aL8a0Q0nGtioTKmdmZGh9BUWE8pMxc/e0DjcbVFqh6Y=";
                derivationArgs.allowSubstitutes = false;
              })
              (fetchpatch {
                name = "wrangler: fix build on darwin";
                url = "https://github.com/NixOS/nixpkgs/pull/536602.diff";
                hash = "sha256-nVyL5C11GnB9p8ABGL0whGfzj+Gq5aMvsUfl0dG/3Ss=";
              })
              # related to appstream : https://github.com/NixOS/nixpkgs/issues/514566
              (fetchpatch {
                name = "libfyaml: fixed building issues";
                url = "https://github.com/NixOS/nixpkgs/pull/515614.patch";
                hash = "sha256-lPg+NKhTJVCDLuuDaKF9o7evPxjcGxD9Gh/M1X3yqag=";
                derivationArgs.allowSubstitutes = false;
              })
              /*
                  (fetchpatch {
                    name = "64gram: fix darwin build with Qt 6.11";
                    url = "https://github.com/NixOS/nixpkgs/pull/520733.diff";
                    hash = "sha256-NfKYs4lC4xrtnLlqjShvkLVKERShGczWg7kqKut95oM=";
                    derivationArgs.allowSubstitutes = false;
                  })
                  (fetchpatch {
                    name = "keepassxc: fix pcsc for darwin";
                    url = "https://github.com/NixOS/nixpkgs/pull/520328.diff";
                    hash = "sha256-amWCahSLE6Lvru9R3IesKr1no5Gc+kd+XyBuKGc/j3Q=";
                    derivationArgs.allowSubstitutes = false;
                  })
                (fetchpatch {
                  name = "remmina: fix missing sidebar icons on macOS";
                  url = "https://github.com/NixOS/nixpkgs/pull/514651.patch";
                  hash = "sha256-T5mr9fzVAyH4SZOpP4wv3TliGBEKdLQI8jwafJuLbKU=";
                  derivationArgs.allowSubstitutes = false;
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
          darwin =
            (import "${inputs0.darwin}/flake.nix").outputs {
              inherit nixpkgs;
              self = darwin;
            }
            // {
              outPath = inputs0.darwin.outPath;
            };
          pkgs = import nixpkgs {
            inherit system;
            config.allowDeprecatedx86_64Darwin = true;
          };
          deploy-rs =
            (import "${inputs0.deploy-rs}/flake.nix").outputs (
              inputs0.deploy-rs.inputs
              // {
                self = deploy-rs;
                inherit nixpkgs;
              }
            )
            // {
              outPath = inputs0.deploy-rs.outPath;
            };
          # nixpkgs with deploy-rs overlay but force the nixpkgs package
          deployPkgs = import nixpkgs {
            inherit system;
            config.allowDeprecatedx86_64Darwin = true;
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
          mio =
            (import "${inputs0.mio}/flake.nix").outputs (
              inputs0.mio.inputs
              // {
                self = mio;
                inherit nixpkgs;
              }
            )
            // {
              outPath = inputs0.mio.outPath;
            };
        in
        {
          inputs = inputs0 // {
            inherit nixpkgs darwin mio;
            nixpkgs-unpatched = inputs0.nixpkgs;
          };
          inherit darwin deployPkgs deploy-rs;
          inherit (inputs0) self;
        }
      );
    in
    {
      # DETAILS REMOVED
      darwinConfigurations."NixMac" =
        with the "aarch64-darwin";
        darwin.lib.darwinSystem {
          specialArgs = {
            inherit inputs;
          };
          modules = [
            ./nixmac.nix
            #./builder-uninstall.nix
            #./builder-firstinstall.nix
          ];
        };
      darwinConfigurations.NixMac-2 = self.darwinConfigurations."NixMac";
    };
}
