{
  inputs = {
    flake-compat.url = "github:NixOS/flake-compat";
    # --option extra-substituters https://niri.cachix.org --option extra-trusted-public-keys niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964=
    #niri.url = "github:sodiboo/niri-flake";
    # --option extra-substituters https://install.determinate.systems --option extra-trusted-public-keys cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM=
    #determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*"; # https://docs.determinate.systems/guides/advanced-installation#nixos
    nixpkgs-2511.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-2505.url = "github:NixOS/nixpkgs/release-25.05";
    #nixpkgs-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    nixpkgs-small.url = "github:NixOS/nixpkgs/8dc49b8b206a683d1f6605e0fd993c0f5d49c98d"; # a commit from nixos-unstable-small
    #nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-unstable.follows = "chaotic/nixpkgs";
    nixpkgs.follows = "nixpkgs-small";
    nixpkgs-pin.url = "github:NixOS/nixpkgs/331800de5053fcebacf6813adb5db9c9dca22a0c"; # a commit from nixos-unstable
    nixpkgs-pin2.url = "github:NixOS/nixpkgs/9ae611a455b90cf061d8f332b977e387bda8e1ca"; # a commit from nixos-unstable
    nixpkgs-pin3.url = "github:NixOS/nixpkgs/567a49d1913ce81ac6e9582e3553dd90a955875f"; # a commit from nixos-unstable
    #nixpkgs-new.url = "github:NixOS/nixpkgs/master";
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko.url = "git+https://github.com/nix-community/disko.git?shallow=1";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    impermanence = {
      url = "git+https://github.com/nix-community/impermanence.git?shallow=1";
      inputs.home-manager.follows = "home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "git+https://github.com/nix-community/home-manager.git?shallow=1&ref=master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-2511 = {
      url = "git+https://github.com/nix-community/home-manager.git?shallow=1&ref=release-25.11";
      inputs.nixpkgs.follows = "nixpkgs-2511";
    };
    home-manager-7074 = {
      # based on https://github.com/nix-community/home-manager/pull/7074
      # default set to copy, so homemanager inside WSL can kind of manage windows home files!
      # known problem: a lot of hm-backup-* files created
      url = "git+https://github.com/mio-19/home-manager.git?shallow=1&ref=file-mode";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "git+https://github.com/0xc000022070/zen-browser-flake.git?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    rust-overlay = {
      url = "git+https://github.com/oxalica/rust-overlay.git?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    #jovian.follows = "chaotic/jovian";
    jovian = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
      #url = "git+https://github.com/Jovian-Experiments/Jovian-NixOS.git?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    chaotic = {
      #url = "github:lonerOrz/nyx-loner";
      url = "github:chaotic-cx/nyx";
      #inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    #chaotic.url = "git+https://github.com/mio-19/nyx-loner.git";
    flake-utils.url = "github:numtide/flake-utils";
    rust-fp = {
      # pin niche inputs to avoid bad people taking over.
      url = "github:ChocolateLoverRaj/rust-fp/2d0b547e8800eea66d06fb52ed946f52cab30e37";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "rust-overlay";
      inputs.flake-utils.follows = "flake-utils";
    };
    /*
      musnix = {
        url = "git+https://github.com/musnix/musnix.git";
        inputs.nixpkgs.follows = "nixpkgs";
      };
    */
    # pin niche inputs to avoid bad people taking over.
    # v0.7.0
    nix-flatpak.url = "github:gmodena/nix-flatpak/440818969ac2cbd77bfe025e884d0aa528991374";
    #pinix = {
    #  url = "git+https://github.com/remi-dupre/pinix.git";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};
    /*
      lix-module = {
        #url = "https://git.lix.systems/lix-project/nixos-module/archive/release-2.93.tar.gz";
        url = "https://git.lix.systems/lix-project/nixos-module/archive/main.tar.gz";
        inputs.nixpkgs.follows = "nixpkgs";
        inputs.flake-utils.follows = "flake-utils";
      };
    */
    #copyparty = {
    #  url = "github:9001/copyparty";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #  inputs.flake-utils.follows = "flake-utils";
    #};
    grub2-themes = {
      # pin niche inputs to avoid bad people taking over.
      url = "github:vinceliuice/grub2-themes/80dd04ddf3ba7b284a7b1a5df2b1e95ee2aad606";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nm2nix = {
      # pin niche inputs to avoid bad people taking over.
      url = "github:Janik-Haag/nm2nix/6d018aaad4093097fd647f867425a15f294e483e";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "git+https://github.com/NixOS/nixos-hardware.git?shallow=1&ref=master";
    plasma-manager = {
      url = "git+https://github.com/nix-community/plasma-manager.git?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    vscode-server = {
      #url = "git+https://github.com/nix-community/nixos-vscode-server.git";
      # https://github.com/nix-community/nixos-vscode-server/issues/90
      url = "github:Hyffer/nixos-vscode-server/fix-vsce-sign";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    nixos-wsl = {
      url = "git+https://github.com/nix-community/NixOS-WSL.git?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
    };
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/master";
      inputs.nixpkgs.follows = "nixpkgs-2511";
      inputs.nixpkgs-docs.follows = "nix-on-droid/nixpkgs";
      inputs.nixpkgs-for-bootstrap.follows = "nix-on-droid/nixpkgs";
      inputs.home-manager.follows = "home-manager-2511";
    };
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    #stylix = {
    #  url = "github:nix-community/stylix";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};
    #android-nixpkgs = {
    #  #url = "github:tadfisher/android-nixpkgs";
    #  url = "github:mio-19/android-nixpkgs";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #  inputs.flake-utils.follows = "flake-utils";
    #};
    # https://discourse.nixos.org/t/adding-experimental-i915-driver-to-nixos-for-use-as-guest-vm-with-sr-iov-passthrough/27123
    #i915-sriov = {
    #  url = "github:strongtz/i915-sriov-dkms/master";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};
    rosetta-spice = {
      # pin niche inputs to avoid bad people taking over.
      url = "github:zhaofengli/rosetta-spice/fefbca8a554290e54311c1d5cf7354f318ff1c16";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.flake-compat.follows = "flake-compat";
    };
    # --option extra-substituters https://nixos-apple-silicon.cachix.org --option extra-trusted-public-keys nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20=
    nixos-apple-silicon = {
      url = "github:nix-community/nixos-apple-silicon";
      #inputs.nixpkgs.follows = "nixpkgs"; # needs to comment out this to use binary cache
      inputs.flake-compat.follows = "flake-compat";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };
    nur = {
      #url = "github:nix-community/NUR";
      url = "git+https://github.com/nix-community/NUR.git?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    #nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
    #emacs-overlay = {
    #  url = "github:nix-community/emacs-overlay";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #  inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    #};
    razerdaemon = {
      # pin niche inputs to avoid bad people taking over.
      url = "github:JosuGZ/razer-laptop-control/2c224ef0cda712f826056450d89e12c5f7bf3d0d";
      #url = "git+https://github.com/mio-19/razer-laptop-control.git?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    stable-diffusion-webui-nix = {
      # pin niche inputs to avoid bad people taking over.
      url = "github:Janrupf/stable-diffusion-webui-nix/034b3e961f9c22a62e97b8c7f5d4698b318c23f8";
      #url = "github:mio-19/stable-diffusion-webui-nix/patch-1";
      #inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    nixified-ai = {
      url = "github:nixified-ai/flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.hercules-ci-effects.follows = "hercules-ci-effects";
    };
    hercules-ci-effects = {
      url = "github:hercules-ci/hercules-ci-effects";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    /*
      chester = {
        url = "git+https://codeberg.org/chester-lang/chester.git?shallow=1";
        inputs.nixpkgs.follows = "nixpkgs";
        inputs.flake-utils.follows = "flake-utils";
      };
    */
    mio = {
      url = "git+https://github.com/mio-19/nurpkgs.git?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mac-style-plymouth = {
      # pin niche inputs to avoid bad people taking over.
      url = "github:SergioRibera/s4rchiso-plymouth-theme/2f782f4b68ce1c00cef3fde6970d7b4241bb97d4";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    mac-style-plymouth-b = {
      #url = "github:SergioRibera/s4rchiso-plymouth-theme";
      url = "github:mio-19/s4rchiso-plymouth-theme/b";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    vicinae = {
      #url = "git+https://github.com/vicinaehq/vicinae.git?shallow=1";
      url = "github:vicinaehq/vicinae";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "flake-utils/systems";
    };
    vicinae-extensions = {
      url = "github:vicinaehq/extensions";
      inputs.vicinae.follows = "vicinae";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "flake-utils/systems";
    };
    #ucodenix.url = "github:e-tho/ucodenix";
    #noctalia = {
    #  url = "github:noctalia-dev/noctalia-shell";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};
    steam-config-nix = {
      # pin niche inputs to avoid bad people taking over.
      url = "github:different-name/steam-config-nix/7b8021b2739733c547e2fe02739e6b8452813aa7";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.systems.follows = "flake-utils/systems";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      #inputs.nixpkgs.follows = "nixpkgs"; # no overide to have binary cache.
      inputs.blueprint.inputs.systems.follows = "flake-utils/systems";
    };
    /*
      nurl = {
        url = "github:nix-community/nurl";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      nix-init = {
        url = "github:nix-community/nix-init";
        inputs.nixpkgs.follows = "nixpkgs";
        inputs.flake-parts.follows = "flake-parts";
        inputs.treefmt-nix.follows = "llm-agents/treefmt-nix";
      };
    */
    nix-snapd = {
      url = "github:nix-community/nix-snapd";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.flake-compat.follows = "flake-compat";
    };
    nix-software-center = {
      # pin niche inputs to avoid bad people taking over.
      url = "github:snowfallorg/nix-software-center/181c1c61eab79130879257550dba0b36bd6bb8c9";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "flake-utils";
    };
    claude-desktop = {
      # last commit failed to build
      url = "github:aaddrick/claude-desktop-debian/e85450c90ba38159f89f02bdd0f6c6d7e6bce065";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    nix-bwrapper = {
      url = "github:Naxdy/nix-bwrapper";
      inputs.nixpkgs.follows = "nixpkgs";
      #inputs.treefmt-nix.follows = "llm-agents/treefmt-nix";
      inputs.treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
      inputs.nuschtosSearch.inputs.nixpkgs.follows = "nixpkgs";
      inputs.nuschtosSearch.inputs.flake-utils.follows = "flake-utils";
    };
    nixpak = {
      url = "github:nixpak/nixpak";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.hercules-ci-effects.follows = "hercules-ci-effects";
    };
    # --option extra-substituters https://nix-gaming.cachix.org --option extra-trusted-public-keys nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4=
    nix-gaming = {
      url = "github:fufexan/nix-gaming";
      inputs.flake-parts.follows = "flake-parts";
      inputs.git-hooks.inputs.flake-compat.follows = "flake-compat";
      inputs.flake-compat.follows = "flake-compat";
    };
    pkgs-by-name-for-flake-parts.url = "github:drupol/pkgs-by-name-for-flake-parts";
    nix-webapps = {
      url = "github:TLATER/nix-webapps";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "flake-utils/systems";
      inputs.pkgs-by-name-for-flake-parts.follows = "pkgs-by-name-for-flake-parts";
    };
    # https://github.com/mwlaboratories/phoneputer/blob/13070a74737bd184f4814c056571862f80036c5b/flake.nix#L11
    # Mobile-NixOS repository - provides mobile-specific modules and device support
    mobile-nixos = {
      url = "github:mobile-nixos/mobile-nixos";
      flake = false; # We import it directly, not as a flake
    };
    nix-openclaw = {
      url = "github:openclaw/nix-openclaw";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nix-steipete-tools.inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-avf = {
      url = "github:nix-community/nixos-avf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    repo.url = "github:mio-19/repo";
    selector4nix = {
      url = "github:StarryReverie/selector4nix";
      # has cache on garnix
      #inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-mineral = {
      url = "github:cynicsketch/nix-mineral/";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
      inputs.flake-parts.follows = "flake-parts";
      inputs.ndg.inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    globalprotect-openconnect = {
      # pin niche inputs to avoid bad people taking over.
      url = "github:yuezk/GlobalProtect-openconnect/fe55d11fc49bf30341ddc3ac8784b7f49be3ae9c";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.naersk.inputs.nixpkgs.follows = "nixpkgs";
    };
    mio-betterbird.url = "github:mio-19/nurpkgs/42db0171f07527f8bc61d0c0cc9b5de99c0d974c";
    /*
      zsh-patina = {
        url = "github:michel-kraemer/zsh-patina";
        inputs.nixpkgs.follows = "nixpkgs";
      };
    */
  };

  outputs =
    inputs@{
      nix-on-droid,
      ...
    }:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      imports = [ ./nixos.nix ];
      flake = rec {
        /*
          # https://gist.github.com/FlakM/0535b8aa7efec56906c5ab5e32580adf?permalink_comment_id=5167381#gistcomment-5167381
          apps = {
            x86_64-linux = {
              vm-ego = {
                type = "app";
                program = "${vms.ego}/bin/run-nixos-vm";
              };
            };
          };
          # https://gist.github.com/FlakM/0535b8aa7efec56906c5ab5e32580adf?permalink_comment_id=5148581#gistcomment-5148581
          vms.ego = nixosConfigurations.vm-ego.config.system.build.vm;
          nixosConfigurations.vm-ego =
            let
              nixpkgs = inputs.nixpkgs-2511;
            in
            nixpkgs.lib.nixosSystem rec {
              system = "x86_64-linux";
              specialArgs = {
                inherit inputs system nixpkgs;
              };
              modules = [
                ./vm-ego
              ];
            };
        */
        # nix-on-droid switch --flake ~/config/nixos
        nixOnDroidConfigurations.default = nix-on-droid.lib.nixOnDroidConfiguration {
          modules = [
            ./nix-on-droid.nix
          ];
          extraSpecialArgs = {
            inherit inputs;
            system = "aarch64-linux";
          };
          # https://github.com/nix-community/nix-on-droid/issues/495
          pkgs = import inputs.nixpkgs-2511 {
            system = "aarch64-linux";
            overlays = [
              nix-on-droid.overlays.default
              inputs.nur.overlays.default
              #(final: prev: { lix = prev.lixPackageSets.latest.lix; })
              #lix-module.overlays.lixFromNixpkgs
            ];
          };
          home-manager-path = inputs.home-manager-2511.outPath;
        };
      };
    };
}
