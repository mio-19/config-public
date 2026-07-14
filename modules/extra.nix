{ den, ... }:
let
  # Common CLI tools, split by packaging intent:
  # - nixos: hardenedPkg vs cleanPkg
  # - darwin: no wrapping needed, so just concatenate
  commonCliHardened =
    {
      pkgs,
      progs,
      inputs,
      ...
    }:
    with pkgs;
    [
      lynx
      #herdr
      nh
      nurl
      jadx
      cachix
      wrangler
      btop
      markdownlint-cli
      gh
      rustscan
      cargo
      rustc
      diffnav
      gef
      gdb
      progs.antlr
      nur.repos.mio.pdf2pptx
    ]
    ++ lib.optional (
      inputs.mio.packages.${pkgs.stdenv.hostPlatform.system} ? forester
    ) inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.forester
    ++ lib.optional (
      inputs.mio.packages.${pkgs.stdenv.hostPlatform.system} ? sem-cli
    ) inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.sem-cli;

  commonCliClean =
    { pkgs, ... }:
    with pkgs;
    [
      codex
      opencode
      github-copilot-cli
    ];

  commonCliDarwin = args: commonCliHardened args ++ commonCliClean args;

  nixosExtra =
    {
      config,
      inputs,
      lib,
      pkgs,
      _include,
      ...
    }@args:
    with _include;
    {
      programs.java.package = hardenedPkg progs.jdk;
      # https://search.nixos.org/packages
      environment.systemPackages =
        with pkgs;
        (map hardenedPkg (
          commonCliHardened {
            inherit
              pkgs
              progs
              inputs
              ;
          }
          ++ [
            wgcf
            fdroidcl
            (sbt.override { jre = progs.jre; })
            mill
            (pkgs.scala_3.override { jre = progs.jre; })
            (maven.override { jdk_headless = progs.jdk_headless; })
            (ammonite.override { jre = progs.jre; })
            progs.jdk
            agda
            lean4
            yarn-berry
            update-nix-fetchgit
            jujutsu
            nvfetcher
            #git-repo
            pmbootstrap
            #clang
            gnumake
            texliveFull
            poppler-utils
            qpdf # decrypt pdf
            #julia # https://github.com/NixOS/nixpkgs/issues/475534
            baidupcs-go
            nix-init
            nixd
            mediainfo
            img2pdf
            vulnix
            jq
            s-tui
            eza
            #bat
            ffmpeg-full
            #onefetch
            #fresh-editor
            nixpkgs-reviewFull
            nix-update
            #code2prompt
            yazi
            nix-tree
            matugen
            polarity
            haskell-language-server
            ghc
            easyeda2kicad
            interactive-html-bom
            diffoscope
          ]
        ))
        ++ (map cleanPkg (
          commonCliClean { inherit pkgs; }
          ++ [
            cursor-cli
            #claude-code
            distrobox
            gcc
          ]
        ))
        ++ [
          antigravity-cli
        ];
      virtualisation.podman.enable = true;

      # https://discourse.nixosstag.fcio.net/t/how-to-fix-cursor-size/2938/8
      # trying to fix steam session small cursor
      #services.xserver.upscaleDefaultCursor = true;
      #services.xserver.dpi = lib.mkDefault 162; # required by services.xserver.upscaleDefaultCursor
      #environment.variables.XCURSOR_SIZE = "64";

      #virtualisation.docker.enable = true;
      #virtualisation.docker.enableOnBoot = false;
    };

  darwinExtra =
    {
      pkgs,
      inputs,
      lib,
      config,
      _include,
      ...
    }@args:
    with _include;
    {
      imports = [
        (import ../aspect.nix "desktopextra") # cross-platform desktop apps shared with NixOS desktopextra
      ];

      # disable emacs to work around https://github.com/hraban/mac-app-util/issues/43
      #home-manager.sharedModules = [
      #  ../extradeusers.nix
      #];

      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        with pkgs;
        commonCliDarwin {
          inherit
            pkgs
            progs
            inputs
            ;
        }
        ++ [
          nur.repos.mio.mdbook-generate-summary
          python314Packages.pdf2docx
          uv
          claude-code
          ollama
          #onefetch
          unixtools.watch
          opam
          # unfree:
          p7zip-rar

          (ammonite.override { jre = progs.jre; })
          (sbt.override { jre = progs.jre; })
          mill
          progs.nodejs
          progs.jdk
          progs.pnpm
          progs.yarn-berry
          emacs-31
          agda
          lean4
          #isabelle # cli only; use brew cask then
          nixpkgs-review
          nix-update
          llvmPackages.bintools # provides readelf that gef needs
          yt-dlp
          #easyeda2kicad
          #interactive-html-bom
          # unfree:
          cursor-cli

          joplin-desktop
          #qdiskinfo # needs more patches
          #kdiskmark # needs more patches
          imhex
          luanti-client
          pkgs-pin3.nur.repos.mio.minetest591client
          nur.repos.mio.beammp-launcher
          #thonny
          #mousecape
          # Good Linux GUI packages:
          pympress
          #gnome-calculator
          #gnome-text-editor
          #remmina
          #inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.evince
          pkgs-pin3.baobab # inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.baobab # Disk Usage Analyzer
          thunderbird-esr
          #adwaita-icon-theme
          #hicolor-icon-theme
          #gsettings-desktop-schemas
          #gtk3
          hicolor-icon-theme # can this fix icons?
          #xournalpp
          #helix
          #jellyfin-desktop
          koodo-reader
          # open source but downloaded as binary - binaryNativeCode:
          #(inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".default)
          #waveterm
          #aerospace
          # unfree:
          #zoom-us # recording scrren permission problems. use homebrew version then
          jetbrains-toolbox
          jetbrains.idea
          #jetbrains.clion
          obsidian
          antigravity
          #code-cursor # in app updater, better with cask.
        ]
        ++ lib.optionals config.mio_aria2 [
          nur.repos.mio.aria2
          nur.repos.mio.aria2-wrapped
        ]
        ++ lib.optionals (!config.mio_aria2) [
          aria2
        ]
        ++ lib.optionals pkgs.stdenv.isAarch64 [
          # unsupported on x86_64 macOS:
          tuxguitar
        ]
        ++ lib.optional (
          pkgs.stdenv.isAarch64 && inputs.mio.packages.${pkgs.stdenv.hostPlatform.system} ? ryubing
        ) inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.ryubing
        ++ (with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
          oh-my-opencode
          #oh-my-codex # no binary cache
        ])
        ++ [
          (lib.hiPrio antigravity-cli) # higher prio than gui app for cli command "antigravity"
        ];

      homebrew.casks = [
        "sublime-merge"
        "inmusic-software-center"
        "native-access"
        "zoom"
        "racket"
        "cursor"
        "mullvad-vpn"
        "66HEX/frame/frame" # https://github.com/66HEX/frame
        "affinity"
        "microsoft-teams"
        "adobe-acrobat-pro"
        "adobe-creative-cloud"
        "duckduckgo"
        "sdformatter"
        "graalvm-jdk"
        "signal"
        #"rider"
        "wave"
        "lm-studio"
        "rclone-ui"
        #"android-commandlinetools"
        "prusaslicer"
        "plex"
        "steam"
        "microsoft-office"
        "microsoft-auto-update"
        "electerm"
        #"chromium"
        "calibre"
        "prismlauncher"
        "openzfs"
        "betterdisplay"
        "tabby"
        "balenaetcher"
        "microsoft-edge"
        "cleanshot"
        "cloudflare-warp"
        "utm"
        "chatgpt"
        "only-switch"
        "zulip"
        #"raycast"
        "orbstack"
        "isabelle"
        "parsec"
        #"localsend"
        #"zen"
        "karabiner-elements"
        "logi-options+"
        "rustdesk"
        "alienator88-sentinel"
        # Good Linux GUI packages:
        "kicad"
        "kdenlive"
        "krita"
        "gimp"
        "freecad"
        "inkscape"
      ];
      homebrew.brews = [
        # https://github.com/nohajc/anylinuxfs
        "nohajc/anylinuxfs/anylinuxfs"
      ];
      homebrew.taps = [
        "nohajc/anylinuxfs"
        "66HEX/frame"
      ];
      homebrew.masApps = {
        Meshtastic = 1586432531;
      };
    };
in
{
  den.aspects.extra = {
    nixos = nixosExtra;
    darwin = darwinExtra;
  };
}
