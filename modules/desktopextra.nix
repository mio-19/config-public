{ den, ... }:
{
  den.aspects.desktopextra = {
    description = "Extra desktop packages, firejail wrappers, and wireshark";
    includes = [
      den.aspects.gemini-desktop
      den.aspects.games
    ];
    os =
      args@{ pkgs, inputs, ... }:
      let
        _include =
          args._include or (
            if pkgs.stdenv.hostPlatform.isDarwin then
              (import ../mac/include.nix args)
            else
              (import ../nixos/include.nix args)
          );
        inherit (_include) progs;
      in
      {
        systemPackages_hardened = with pkgs; [
          inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.chatbox
          progs.bifrost
          downkyicore
          ghidra
          blender
          mailspring
          nur.repos.mio.musescore-alex
          musescore-evolution
          joplin-desktop
          imhex
          pympress
          remmina
          baobab
          #hicolor-icon-theme
          koodo-reader
          # unfree:
          jetbrains.gateway
          jetbrains-toolbox
          obsidian
          chatgpt
        ];
      };
    nixos =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        ...
      }:
      let
        _include = args._include or (import ../nixos/include.nix args);
      in
      with _include;
      {

        home-manager.sharedModules = [
          ../extradeusers.nix
        ];

        systemPackages_hardened = with pkgs; [
          rclone

          # may need `xhost si:localuser:root` - https://www.reddit.com/r/linux4noobs/comments/lu1plx/hi_i_get_this_authorization_required_but_no/
          #inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.wireguird
          progs.inkscape
          #gg-jj
          kdiskmark
          #gsmartcontrol
          qdiskinfo
          obs-studio
          freecad
          #openscad
          #nemo
          #qcm
          teams-for-linux
          nur.repos.mio.waveterm
          #pianotrans
          # binaryNativeCode:
          spotube
          inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
          # unfree:
          (lib.hiPrio pkgs.aseprite) # lib.hiPrio: a file colliding with libresprite
          #davinci-resolve
          lmstudio
          google-chrome # does antigravity only work with google-chrome?
          code-cursor
        ];
        systemPackages_clean = with pkgs; [
          # unfree:
          android-studio
          antigravity-ide-fhs
          # DETAILS REMOVED
        ];

        #programs.throne.enable = true;
        #programs.throne.tunMode.enable = true;

        programs.zoom-us.enable = true;

        programs.firejail.wrappedBinaries = with pkgs; {
          mscore = {
            executable = "${hardenedPkg nur.repos.mio.musescore-alex}/bin/mscore";
            profile = "${pkgs.firejail}/etc/firejail/musescore.profile";
          };
          mscore-evo = {
            executable = "${hardenedPkg musescore-evolution}/bin/mscore-evo";
            profile = "${pkgs.firejail}/etc/firejail/musescore.profile";
          };
          xournalpp = {
            executable = "${hardenedPkg xournalpp}/bin/xournalpp";
            profile = "${pkgs.firejail}/etc/firejail/xournalpp.profile";
          };
          scribus = {
            executable = "${hardenedPkg scribus}/bin/scribus";
            profile = "${pkgs.firejail}/etc/firejail/scribus.profile";
          };
          blender = {
            executable = "${hardenedPkg blender}/bin/blender";
            profile = "${pkgs.firejail}/etc/firejail/blender.profile";
          };
          inkscape = {
            executable = "${hardenedPkg progs.inkscape}/bin/inkscape";
            profile = "${pkgs.firejail}/etc/firejail/inkscape.profile";
          };
        };

        # cloudflare-warp could cause problems when mobile devices want to access public wifi login page.
        /*
          # see common commands: https://gist.github.com/arafays/619c2fd24db34592b1626c51544d719f
          services.cloudflare-warp.enable = true;
          services.cloudflare-warp.openFirewall = true;
        */

        programs.wireshark.enable = true;
      };
    # darwin reuses only the cross-platform apps shared with the NixOS desktopextra
    # (sharedApps above). The firejail/wireshark and other Linux-only bits stay in
    # the nixos branch.
    darwin =
      { inputs, pkgs, ... }@args:
      let
        _include = args._include or import ../mac/include.nix args;
      in
      with _include;
      {
        environment.systemPackages = with pkgs; [
          nur.repos.mio.telegram-mac

          #qdiskinfo # needs more patches
          #kdiskmark # needs more patches
          #thonny
          #mousecape
          #gnome-calculator
          #gnome-text-editor
          #inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.evince
          #adwaita-icon-theme
          #hicolor-icon-theme
          #gsettings-desktop-schemas
          #gtk3
          #xournalpp
          #helix
          #jellyfin-desktop
          # open source but downloaded as binary - binaryNativeCode:
          #(inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".default)
          #waveterm
          #aerospace
          # unfree:
          #zoom-us # recording scrren permission problems. use homebrew version then
          #jetbrains.clion
          antigravity-ide
          #code-cursor # in app updater, better with cask.
        ];

        homebrew.casks = [
          "sublime-merge"
          "inmusic-software-center"
          "native-access"
          "zoom"
          "racket"
          "cursor"
          "affinity"
          "microsoft-teams"
          "adobe-acrobat-pro"
          "adobe-creative-cloud"
          "signal"
          #"rider"
          "wave"
          "lm-studio"
          "rclone-ui"
          #"android-commandlinetools"
          "prusaslicer"
          "steam"
          "microsoft-office"
          "microsoft-auto-update"
          "electerm"
          #"chromium"
          "calibre"
          "prismlauncher"
          "openzfs" # or manually upgrade with https://github.com/openzfsonosx/openzfs-fork/releases
          "betterdisplay"
          "balenaetcher"
          "microsoft-edge"
          "cleanshot"
          "cloudflare-warp"
          "utm"
          #"chatgpt"
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
      };
  };
}
