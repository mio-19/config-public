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
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.follows = "nixpkgs-unstable";
    # https://github.com/NixOS/nixpkgs/issues/500198
    #nixpkgs-pin.url = "github:NixOS/nixpkgs/b40629efe5d6ec48dd1efba650c797ddbd39ace0"; # a commit from nixos-unstable
    #nixpkgs-pin2.url = "github:NixOS/nixpkgs/4bd9165a9165d7b5e33ae57f3eecbcb28fb231c9"; # a commit from nixos-unstable
    #nixpkgs-pin3.url = "github:NixOS/nixpkgs/ebc08544afa77957cc348ba72dc490ec73b87f68"; # a commit from nixos-unstable
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
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.jovian.follows = "jovian";
      inputs.rust-overlay.follows = "rust-overlay";
      inputs.home-manager.follows = "home-manager";
    };
    #chaotic.url = "git+https://github.com/mio-19/nyx-loner.git";
    flake-utils.url = "github:numtide/flake-utils";
    rust-fp = {
      url = "git+https://github.com/ChocolateLoverRaj/rust-fp.git?shallow=1";
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
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
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
      url = "git+https://github.com/vinceliuice/grub2-themes.git?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nm2nix = {
      url = "git+https://github.com/Janik-Haag/nm2nix.git?shallow=1";
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
      url = "github:zhaofengli/rosetta-spice";
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
      #url = "github:JosuGZ/razer-laptop-control";
      url = "git+https://github.com/JosuGZ/razer-laptop-control.git";
      #url = "git+https://github.com/mio-19/razer-laptop-control.git?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    stable-diffusion-webui-nix = {
      url = "github:Janrupf/stable-diffusion-webui-nix/main";
      #url = "github:mio-19/stable-diffusion-webui-nix/patch-1";
      #inputs.nixpkgs.follows = "nixpkgs";
      # needs python3.11. needs outdated nixpkgs
      inputs.nixpkgs.url = "github:NixOS/nixpkgs/3ca49aa290e92b6a885e8c0045033fe2538a4977"; # a commit from nixos-unstable-small
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
      url = "github:SergioRibera/s4rchiso-plymouth-theme";
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
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    steam-config-nix = {
      url = "github:different-name/steam-config-nix";
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
      url = "github:snowfallorg/nix-software-center";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "flake-utils";
    };
    claude-desktop = {
      url = "github:k3d3/claude-desktop-linux-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
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
      url = "github:yuezk/GlobalProtect-openconnect";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.naersk.inputs.nixpkgs.follows = "nixpkgs";
    };
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
