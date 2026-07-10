{
  inputs = {
    flake-compat.url = "github:NixOS/flake-compat";
    # --option extra-substituters https://niri.cachix.org --option extra-trusted-public-keys niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964=
    #niri.url = "github:sodiboo/niri-flake";
    # --option extra-substituters https://install.determinate.systems --option extra-trusted-public-keys cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM=
    #determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*"; # https://docs.determinate.systems/guides/advanced-installation#nixos
    #nixpkgs-2511.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-2511.url = "github:NixOS/nixpkgs/release-25.11";
    nixpkgs-2505.url = "github:NixOS/nixpkgs/release-25.05";
    #nixpkgs-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    #nixpkgs-small.url = "github:NixOS/nixpkgs/8dc49b8b206a683d1f6605e0fd993c0f5d49c98d"; # a commit from nixos-unstable-small
    nixpkgs-stable.url = "https://nixos.org/channels/nixos-26.05/nixexprs.tar.xz"; # for /etc/nix/registry.json
    #nixpkgs-unstable.url = "https://nixos.org/channels/nixos-unstable/nixexprs.tar.xz";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/0bb7ec54c8483066ec9d7720e780a5caa71f8612"; # https://hydra.nixos.org/job/nixos/unstable/tested#tabs-constituents
    #nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.follows = "nixpkgs-unstable";
    nixpkgs-pin.url = "github:NixOS/nixpkgs/331800de5053fcebacf6813adb5db9c9dca22a0c"; # a commit from nixos-unstable
    nixpkgs-pin2.url = "https://releases.nixos.org/nixos/unstable/nixos-26.11pre1027867.d407951447dc/nixexprs.tar.xz"; # a commit from nixos-unstable
    #nixpkgs-pin3.url = "github:NixOS/nixpkgs/567a49d1913ce81ac6e9582e3553dd90a955875f"; # a commit from nixos-unstable
    #nixpkgs-pin4.url = "github:NixOS/nixpkgs/8dc49b8b206a683d1f6605e0fd993c0f5d49c98d"; # a commit from nixos-unstable-small
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
    systems.url = "github:nix-systems/triplet";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
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
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    nixos-wsl = {
      url = "git+https://github.com/nix-community/NixOS-WSL.git?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
    };
    nix-on-droid = {
      #url = "github:nix-community/nix-on-droid/master";
      # https://github.com/nix-community/nix-on-droid/pull/523
      url = "github:petm5/nix-on-droid/aede3d553095e22404bf4966d4faf865f32614db";
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
      # pin niche inputs to avoid bad people taking over.
      url = "github:hercules-ci/hercules-ci-effects/86c7c78a840b44b1a0a5cbc7e9baa0154c0d0f3f";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
      url = "github:vicinaehq/vicinae";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };
    vicinae-extensions = {
      url = "github:vicinaehq/extensions";
      inputs.vicinae.follows = "vicinae";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
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
      inputs.systems.follows = "systems";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.blueprint.inputs.systems.follows = "systems";
      inputs.flake-parts.follows = "flake-parts";
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
      # pin niche inputs to avoid bad people taking over.
      url = "github:nix-community/nix-snapd/f7694a0e26d890e285137e1b726b1b44038805c4";
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
      # pin slop to avoid many rebuilds
      url = "github:aaddrick/claude-desktop-debian/4ef1cd86d48bdcc16c92c10a94952f297208886c";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    nix-bwrapper = {
      # pin niche inputs to avoid bad people taking over.
      url = "github:Naxdy/nix-bwrapper/ad48298ec8f582b2362fea1765973c163c3d038a";
      inputs.nixpkgs.follows = "nixpkgs";
      #inputs.treefmt-nix.follows = "llm-agents/treefmt-nix";
      inputs.treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
      inputs.nuschtosSearch.inputs.nixpkgs.follows = "nixpkgs";
      inputs.nuschtosSearch.inputs.flake-utils.follows = "flake-utils";
    };
    nixpak = {
      # pin niche inputs to avoid bad people taking over.
      url = "github:nixpak/nixpak/be97295fa81fe743b9753449143dd4931e51d63c";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.hercules-ci-effects.follows = "hercules-ci-effects";
    };
    # --option extra-substituters https://nix-gaming.cachix.org --option extra-trusted-public-keys nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4=
    nix-gaming = {
      url = "github:fufexan/nix-gaming";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.git-hooks.inputs.flake-compat.follows = "flake-compat";
      inputs.flake-compat.follows = "flake-compat";
    };
    # pin niche inputs to avoid bad people taking over.
    pkgs-by-name-for-flake-parts.url = "github:drupol/pkgs-by-name-for-flake-parts/7ba1cd4a9a72c9c6c272018a63f090f2c912a171";
    nix-webapps = {
      # pin niche inputs to avoid bad people taking over.
      url = "github:TLATER/nix-webapps/1bb9ee8e3f428575c1c6898ae7af8d96416d696a";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
      inputs.pkgs-by-name-for-flake-parts.follows = "pkgs-by-name-for-flake-parts";
    };
    /*
      # https://github.com/mwlaboratories/phoneputer/blob/13070a74737bd184f4814c056571862f80036c5b/flake.nix#L11
      # Mobile-NixOS repository - provides mobile-specific modules and device support
      mobile-nixos = {
        url = "github:mobile-nixos/mobile-nixos";
        flake = false; # We import it directly, not as a flake
      };
    */
    nixos-avf = {
      url = "github:nix-community/nixos-avf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    repo = {
      url = "github:mio-19/repo";
      inputs.flake-parts.follows = "flake-parts";
    };
    selector4nix = {
      url = "github:StarryReverie/selector4nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-mineral = {
      # pin niche inputs to avoid bad people taking over.
      url = "github:cynicsketch/nix-mineral/16c219cdf9c7349591e4570779092d86c9bfbaec";
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
    # pin niche inputs to avoid bad people taking over.
    import-tree.url = "github:denful/import-tree/d321337efd0f23a9eb14a42adb7b2c29313ab274";
    # pin niche inputs to avoid bad people taking over.
    den.url = "github:denful/den/1614f6f8ed435c5bb257408bf91fd662f9aac43e";
    # pin to avoid rebuild
    mio-betterbird.url = "github:mio-19/nurpkgs/20876484d4e71203aaa00519e11ca8b1a4a80861";
    # pin niche inputs to avoid bad people taking over.
    chinese-fonts-overlay = {
      url = "github:brsvh/chinese-fonts-overlay/da90d47fa1a6f8fbfcc5795bc9351c98142f37ea";
      inputs.nixpkgs.follows = "nixpkgs";
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
      perSystem =
        { pkgs, ... }:
        let
          nixpkgs-drv = pkgs.applyPatches {
            name = "nixpkgs-patched";
            src = inputs.nixpkgs;
            # PR .patch URLs track branch head, so the hash changes when the PR is updated.
            # That is intentional: a hash mismatch surfaces PR updates at rebuild time.
            patches = with pkgs; [
              # to consider:
              # maven: provide default plugins per Maven version to buildMavenPackage https://github.com/NixOS/nixpkgs/pull/527061
              # nixos/firefox: make variant librewolf https://github.com/NixOS/nixpkgs/pull/467398
              (fetchurl {
                name = "flyline: init at 1.3.0";
                url = "https://github.com/NixOS/nixpkgs/pull/538842.patch";
                hash = "sha256-XQddmMMoPhtXhQGRjWhTNc9lOHQMxLohtO4hNpgpl+g=";
                derivationArgs.allowSubstitutes = false;
              })
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
                url = "https://github.com/NixOS/nixpkgs/pull/526318.patch";
                hash = "sha256-nAx/qqnbV4lAVBVKxifSoPOj9S/HJ7jW88Ve4y+Yu50=";
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
                name = "github-copilot-cli: 1.0.26 -> 1.0.65";
                url = "https://github.com/NixOS/nixpkgs/pull/534884.patch";
                hash = "sha256-Lt43nR05fVXsFekFxVQPg8r6Y3AD5JiQpCAbDH6BPkw=";
              })
              /*
                (fetchpatch {
                  name = "nixos/systemd-boot: defer boot file garbage collection";
                  url = "https://github.com/NixOS/nixpkgs/pull/531008.diff";
                  hash = "sha256-H4NMS9eDsJ1zM6gLQdZtyyBYumjKArrCFDcWeE+IOJQ=";
                  derivationArgs.allowSubstitutes = false;
                })
              */
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
                hash = "sha256-JJ3VrEbsWm4Qq1uTRbPtzLKkly5vxOmEZU/fw+DzcZo=";
                derivationArgs.allowSubstitutes = false;
              })
              (fetchpatch {
                name = "ONLYOFFICE DesktopEditors: updates";
                url = "https://github.com/NixOS/nixpkgs/pull/526315.patch";
                hash = "sha256-FgZ4u8NB0fwLqDfHDHtGvNqYaNO/OEJIBuV7tHjX8p0=";
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
          inputs1 = inputs // {
            nixpkgs-unpatched = inputs.nixpkgs;
            nixpkgs-patched = nixpkgs;
            inherit nixpkgs nixos-avf;
          };
          inputs-patched = builtins.mapAttrs (
            name: input:
            if input ? inputs && input.inputs ? nixpkgs && input.inputs.nixpkgs == inputs.nixpkgs then
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
          ) inputs1;
        in
        {
          _module.args.inputs-patched = inputs-patched;
        };
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
