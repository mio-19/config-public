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
  # disable emacs to work around https://github.com/hraban/mac-app-util/issues/43
  #home-manager.sharedModules = [
  #  ../extradeusers.nix
  #];

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =
    with pkgs;
    [
      #(inputs.chester.packages."${pkgs.stdenv.hostPlatform.system}".default)

      markdownlint-cli
      nur.repos.mio.mdbook-generate-summary
      nur.repos.mio.aria2
      nur.repos.mio.aria2-wrapped
      nur.repos.mio.pdf2pptx
      uv
      gh
      codex
      #pkgs'.openclaw
      opencode
      claude-code
      ollama
      rustscan
      #onefetch
      nurl
      nh
      unixtools.watch
      cargo
      rustc
      opam
      # unfree:
      p7zip-rar

      wrangler
      (ammonite.override { jre = program.jre; })
      (sbt.override { jre = program.jre; })
      program.nodejs
      program.jdk
      program.pnpm
      program.yarn-berry
      emacs-31
      agda
      lean4
      #isabelle # cli only; use brew cask then
      nixpkgs-review
      nix-update
      diffnav
      gef
      gdb
      llvmPackages.bintools # provides readelf that gef needs
      program.antlr
      yt-dlp
      btop
      #easyeda2kicad
      #interactive-html-bom
      inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.forester
      inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.sem-cli
      # unfree:
      gemini-cli
      cursor-cli

      joplin-desktop
      #qdiskinfo # needs more patches
      #kdiskmark # needs more patches
      imhex
      luanti-client
      nur.repos.mio.minetest591client
      pkgs-pin3.nur.repos.mio.telegram-desktop
      nur.repos.mio.materialgram
      nur.repos.mio.beammp-launcher
      downkyicore
      musescore-evolution
      nur.repos.mio.musescore-alex
      #thonny
      ghidra
      #mousecape
      # Good Linux GUI packages:
      pympress
      jadx
      blender
      #gnome-calculator
      #gnome-text-editor
      #remmina
      #inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.evince
      baobab # inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.baobab # Disk Usage Analyzer
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
      zoom-us
      jetbrains-toolbox
      jetbrains.idea
      #jetbrains.clion
      jetbrains.gateway
      obsidian
      antigravity
      github-copilot-cli
      #code-cursor # in app updater, better with cask.
    ]
    ++ lib.optionals pkgs.stdenv.isAarch64 [
      # unsupported on x86_64 macOS:
      tuxguitar
      inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.ryubing
    ]
    ++ (with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
      oh-my-opencode
      oh-my-codex
      (lib.hiPrio antigravity-cli) # higher prio than gui app for cli command "antigravity"
    ]);
  homebrew.casks = [
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
    "filosottile/musl-cross" # dependencies of anylinuxfs right?
    "nohajc/anylinuxfs"
    "66HEX/frame"
  ];
  homebrew.masApps = {
    Meshtastic = 1586432531;
  };
  /*
    system.activationScripts.extraActivation.text = lib.optionalString mac-app-util-enabled ''

      fromDir="/Applications"
      mkdir -p "$fromDir"

      ${inputs.mac-app-util.packages.${pkgs.stdenv.system}.default}/bin/mac-app-util mktrampoline \
        "${pkgs.baobab}/bin/baobab" \
        "$fromDir/Baobab.app"
    '';
  */
}
