{
  pkgs,
  inputs,
  lib,
  config,
  ...
}@args:
let
  _include = (args._include or import ./include.nix args);
in
with _include;
{
  _module.args._include = _include;

  imports = [
    ./modules
    inputs.nix-index-database.darwinModules.nix-index
    inputs.mac-app-util.darwinModules.default
    inputs.home-manager.darwinModules.home-manager
    #./lix.nix
    #inputs.stylix.darwinModules.stylix
    ../token.nix
    ./nixpkgs-workaround.nix
  ];

  nixpkgs.overlays = [
    #inputs.chaotic.overlays.cache-friendly
    inputs.darwin-emacs.overlays.emacs
    #inputs.emacs-overlay.overlays.package
    inputs.nur.overlays.default
    inputs.nix-vscode-extensions.overlays.default
    (final: prev: {
      #nur = pkgs'.nur; # this is more pure than applying inputs.nur.overlays.default on nixpkgs directly
      #zed-editor = pkgs-stable.zed-editor; # we from time to time don't have binary cache on unstable. but this time: stable no cache
      #nix-output-monitor = inputs.mio.packages."${pkgs.stdenv.hostPlatform.system}".nix-output-monitor; # final.nur.repos.mio.nix-output-monitor;
      inherit (pkgs-openclaw) openclaw openclawPackages;
      inherit (pkgs-pin) thunderbird-esr;
      inherit (pkgs-pin5) zotero;
      inherit (pkgs-pin6) koodo-reader;
      inherit (pkgs-pin7) wrangler;
      inherit (pkgs-pin3) ollama;
      #inherit (pkgs-pin4) agda;
    })
  ];
  home-manager.sharedModules = [
    inputs.nix-index-database.homeModules.nix-index
    #inputs.chaotic.homeManagerModules.default
    #inputs.zen-browser.homeModules.default
    ./users.nix
    inputs.mac-app-util.homeManagerModules.default
    ../users.nix
  ];
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "hm-backup";
  home-manager.extraSpecialArgs = { inherit inputs; };

  services.mac-app-util.enable = mac-app-util-enabled;

  nixpkgs.config.permittedInsecurePackages =
    with pkgs';
    [
      "electron-36.9.5" # for joplin-desktop
      #"jitsi-meet-1.0.8792" # for element-desktop - see https://github.com/NixOS/nixpkgs/pull/426541
    ]
    ++ map (pkg: pkg.name) [
      openclaw
    ];
  nixpkgs.config.allowUnfree = false;
  nixpkgs.config.allowNonSource = false;
  nixpkgs.config.allowUnfreePredicate = allowUnfreePredicate;
  nixpkgs.config.allowNonSourcePredicate = allowNonSourcePredicate;
  nixpkgs.config.allowDeprecatedx86_64Darwin = true; # hide deprecation warning. we aleady know.

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    script.upgrade
    script.switch

    # DON'T OVERRIDE MACOS COREUTILS!
    #coreutils
    #findutils
    #gnutar
    #gzip
    #gnused

    # Only timeout from coreutils (no man pages available in nixpkgs coreutils)
    (pkgs.runCommand "timeout-only" { } ''
      mkdir -p $out/bin
      ln -s ${pkgs.coreutils}/bin/timeout $out/bin/timeout
    '')

    nano
    lz4
    nixd
    fd
    typstyle
    typst
    wget
    smartmontools
    nmap
    #nix-output-monitor
    android-tools
    update-nix-fetchgit
    nvfetcher
    #git-repo
    #ccache
    dust
    gnumake
    nur.repos.mio.cb
    texliveFull
    poppler-utils # it provides pdfunite
    img2pdf
    immich-cli
    catimg
    eza
    ripgrep
    bat
    cachix
    fresh-editor
    nix-output-monitor

    moonlight-qt
    pear-desktop
    spin
    program.librewolf'
    nixfmt
    nixfmt-tree
    #pkgs-95376.blender
    rectangle
    zed-editor
    firebird-emu
    localsend
    #element-desktop # use element-desktop from homebrew then as nixpkgs's one broken - https://github.com/NixOS/nixpkgs/issues/485589
    zotero
    inputs.mio.packages."${pkgs.stdenv.hostPlatform.system}".trayscale
    qbittorrent-enhanced
    #firefox_nightly
    famistudio
    octaveFull
    ice-bar
    #iina
    maccy
    keka
    libreoffice-bin
    vlc-bin
    #whisky
    #stats
    #normcap # https://github.com/NixOS/nixpkgs/issues/457668
    #karabiner-elements # not adding login items when installed via nix
    # unfree:
    raycast
    #teams#doesn't work
    vscode
    discord
    #google-chrome # Out of date, because the updater (pkgs/by-name/go/google-chrome/update.sh) has stopped working, and there does not seem to be another way to get stable URLs to particular Chrome versions.

    # DETAILS REMOVED
  ];
  nix = {
    #daemonIOLowPriority = true;
    #daemonProcessType = "Background";
    gc = {
      automatic = true;
      # https://nixos.wiki/wiki/Storage_optimization
      interval = {
        Weekday = 0;
        Hour = 0;
        Minute = 0;
      };
      options = "--delete-older-than 30d";
    };
    optimise = {
      automatic = true;
    };
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [
        #"https://chaotic-nyx.cachix.org/"
        "https://mio.cachix.org/"
        "https://mio-cache.cachix.org/"
        #"https://staging.cachix.org/"
        #"https://cache.garnix.io"
        #"https://nix-community.cachix.org"
        "https://cache.numtide.com" # https://github.com/numtide/llm-agents.nix
      ];
      trusted-public-keys = [
        #"chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
        "mio.cachix.org-1:FlupyyLPURqwdRqtPT/LBWKsXY7JKsDkzZQo2K6LeMM="
        "mio-cache.cachix.org-1:ouuIJZ59HIflYjpLW6DRyMc1c+6r3kC/LHuqGUsWigg="
        #"staging.cachix.org-1:WX63nyFdVdWGn6n59pIYwkcH/AtjJGjvMQFKlI2z00w="
        #"cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
        #"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];
    };
    # https://github.com/KornelJahn/nixos-disko-zfs-test/blob/673ed629a7ef80efd99ad3b1676d9e4c62829c21/hosts/testhost.nix#L37
    # Credits: Misterio77
    # https://raw.githubusercontent.com/Misterio77/nix-config/e227d8ac2234792138753a0153f3e00aec154c39/hosts/common/global/nix.nix
    # Add each flake input as a registry
    registry = lib.mapAttrs (_: v: { flake = v; }) (lib.removeAttrs inputs [ "nixpkgs" ]);
    # Map registries to channels (useful when using legacy commands)
    nixPath = lib.mapAttrsToList (n: v: "${n}=${v.to.path}") config.nix.registry;
    extraOptions = ''
      trusted-users = @admin root
    '';
  };

  environment.shells = [
    pkgs.bashInteractive
    pkgs.zsh
  ];

  homebrew.enable = true;
  #homebrew.caskArgs.no_quarantine = true; # Error: Calling the `--[no-]quarantine` switch is disabled! There is no replacement.
  homebrew.global.autoUpdate = false;
  homebrew.caskArgs.language = "en-US";
  homebrew.casks = [
    "iterm2"
    "google-chrome"
    "element"
  ];
  homebrew.brews = [
    #"openjdk@11"
    "mas"
    #"typst"
    #"pympress"
    "Dr-Emann/homebrew-tap/applesauce"
    {
      # brew services start tailscale
      name = "tailscale"; # tailscale from homebrew is working better than cask dmg store version when interacting with cloudflare warp
      start_service = true;
      restart_service = "changed";
    }
  ];
  homebrew.masApps = {
    Amphetamine = 937984704;
  };
  homebrew.taps = [
    "Dr-Emann/homebrew-tap"
    "buo/homebrew-cask-upgrade"
  ];

  programs.bash.completion.enable = true;
  # https://github.com/nix-darwin/nix-darwin/blob/master/modules/programs/zsh/default.nix
  programs.zsh = {
    enable = true;
    # zsh configured per user. disable everything systemwide.
    # workaround for homebrew insecure - https://stackoverflow.com/questions/13762280/zsh-compinit-insecure-directories
    #promptInit = ''autoload -Uz compinit && compinit -u'';
    promptInit = ""; # remember to do ''autoload -Uz compinit && compinit -u'' per user
    enableGlobalCompInit = false;
    enableBashCompletion = false;
  };
  programs.fish.enable = true;

  environment.extraInit =
    if pkgs.stdenv.isx86_64 then
      "eval \"$(/usr/local/bin/brew shellenv)\""
    else
      "eval \"$(/opt/homebrew/bin/brew shellenv)\"";

  programs.tmux = {
    enable = true;
    enableMouse = true;
  };

  services.openssh.extraConfig = ''
    PasswordAuthentication no
    PermitRootLogin prohibit-password
  '';

  # https://github.com/BeamMP/BeamMP-Launcher/issues/186#issuecomment-3481687387 https://github.com/Andy3153/nixos-rice/blob/a278f7bacddbf326a95de4ec69ddba061aca4265/hosts/sparkle/configuration.nix#L12-L19
  # {{{ BeamMP certificate problem
  security.pki.certificateFiles = [
    (pkgs.stdenvNoCC.mkDerivation {
      name = "beammp-cert";
      nativeBuildInputs = [ pkgs.curl ];
      builder = (
        pkgs.writeScript "beammp-cert-builder" "curl -w %{certs} https://auth.beammp.com/userlogin -k > $out"
      );
      outputHash = "sha256-P5zS3PQMZhU5zxAhpzEsADytZYzIgIcuxnvcoSZZxhc=";
    })
  ];
  # }}}

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    nerd-fonts.noto
    source-code-pro
    nerd-fonts.sauce-code-pro
  ];
  # Create/refresh .app trampolines system-wide
  # https://github.com/nix-darwin/nix-darwin/blob/8df64f819698c1fee0c2969696f54a843b2231e8/modules/system/activation-scripts.nix#L156C30-L156C44
  system.activationScripts.extraActivation.text = lib.optionalString mac-app-util-enabled ''

    fromDir="/Applications"
    mkdir -p "$fromDir"

    ${inputs.mac-app-util.packages.${pkgs.stdenv.system}.default}/bin/mac-app-util mktrampoline \
      "${pkgs.famistudio}/bin/famistudio" \
      "$fromDir/FamiStudio.app"
    ${inputs.mac-app-util.packages.${pkgs.stdenv.system}.default}/bin/mac-app-util mktrampoline \
      "${octaveGui}/bin/octave" \
      "$fromDir/Octave.app"
  '';

  # Firewall settings - https://carette.xyz/posts/going_immutable_macos/
  networking.applicationFirewall = {
    enable = true;
    enableStealthMode = true;
    allowSigned = true;
    allowSignedApp = true;
  };
  # https://carette.xyz/posts/going_immutable_macos/
  system.defaults = {
    CustomUserPreferences = {
      # Disable siri
      "com.apple.Siri" = {
        "UAProfileCheckingStatus" = 0;
        "siriEnabled" = 0;
      };
      # Disable personalized ads
      "com.apple.AdLib" = {
        allowApplePersonalizedAdvertising = false;
      };
    };
    # Allow touch to click
    trackpad.Clicking = true;
  };

  # Set Git commit hash for darwin-version.
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  # https://github.com/EmergentMind/nix-config/blob/9a9fefd9ab5ebbaf9530dafdb6d45b734606f645/hosts/common/core/nixos.nix#L25
  security.sudo.extraConfig = "Defaults timestamp_timeout=120";
}
