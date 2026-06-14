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
  imports = [
    ./desktop-basic.nix
    ./options.nix
    ./tkg.nix
    ./printing.nix
    ./desktop-office.nix
  ];

  home-manager.sharedModules = [
  ];

  # https://search.nixos.org/packages
  environment.systemPackages =
    with pkgs;
    (map hardenedPkg [
      (wrapPrio gnome-calculator)
      (wrapPrio gnome-system-monitor)
      trayscale
      chromium
      wiliwili
      krita
      gimp
      saber
      localsend
      gparted
      mpv # https://gist.github.com/arch1t3cht/b5b9552633567fa7658deee5aec60453/
      mediainfo-gui
      mkvtoolnix
      #haruna
      vlc
      bitwarden-desktop
      joplin-desktop
      prusa-slicer
      pear-desktop
      #ytmdesktop # no: this one cannot block ad
      element-desktop
      fluffychat
      progs.zulip
      normcap
      (if qtIsPreferred then libreoffice-qt6-fresh else libreoffice-fresh)
      qbittorrent-enhanced
      #bottles
      #kdePackages.sddm-kcm
      remmina
      kdePackages.kweather
      (wrapPrio gnome-clocks)
      #ventoy-full
      #ventoy-full-qt # qt version looks broken under kde plasma
      ventoy-full-gtk
      nextcloud-client
      #emote # no we already have plasma-emojier with meta+.
      nur.repos.mio.altus
      progs.materialgram
      progs.telegram
      inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.prospect-mail
      nur.repos.mio.icloud-mail
      obsidian
      #cider-2 # paid
      (nix-webapps-lib.mkChromiumApp {
        appName = "chatgpt";
        desktopName = "ChatGPT";
        icon = pkgs.fetchurl {
          url = "https://web.archive.org/web/20260516193252if_/https://upload.wikimedia.org/wikipedia/commons/thumb/6/66/OpenAI_logo_2025_%28symbol%29.svg/1280px-OpenAI_logo_2025_%28symbol%29.svg.png";
          sha256 = "sha256-+QlDubjI8MLTnpK2Sy3eAKgn2/jTIkNdFUk8rtfYU7k=";
        };
        url = "https://chatgpt.com";
        class = "chrome-chatgpt.com__-Default";
      })
      (nix-webapps-lib.mkChromiumApp {
        appName = "findmy";
        desktopName = "Find My";
        icon = pkgs.fetchurl {
          url = "https://web.archive.org/web/20260513135036if_/https://upload.wikimedia.org/wikipedia/en/thumb/5/5a/Find_My_logo.svg/330px-Find_My_logo.svg.png";
          sha256 = "sha256-daZyk/2r43YdoasXaeclhJy+f5mkmd58j4IRbUkoEhA=";
        };
        url = "https://www.icloud.com/find/";
        class = "chrome-www.icloud.com__find_-Default";
      })
      # unfree:
      #parsec-bin
      sublime4 # (callPackage ./sublime-text.nix { })
      sublime-merge # (callPackage ./sublime-merge.nix { })
    ])
    ++ (map cleanPkg [
      program.librewolf' # progs.librewolf'_for_firejail
      firefox-esr
      (wrapPrio gnome-console)
      # unfree:
      progs.vscode
    ])
    ++ lib.optionals config.thunderbird_instead (
      map cleanPkg [
        thunderbird-esr
      ]
    )
    ++ lib.optionals pkgs.stdenv.isx86_64 (
      (map hardenedPkg [
        inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.apple-music-desktop
        inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.cider
        handbrake
        tuxguitar # TODO: maybe try firejail for this
        #fluidsynth
        #lilypond
        inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.lmms
        (inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.notepad-plus-plus.override {
          wine = config.wine64_package;
        })
        # open source but from binary
        onlyoffice-desktopeditors
        # unfree:
        inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.adobe-acrobat-reader
        (offloadPkg (
          inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.insta360-studio.override {
            wine = config.wine64_package;
          }
        ))
        (inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.affinity-v3.override {
          wine = config.wine64_package;
        })
        progs.discord
      ])
      ++ (map cleanPkg [
        zotero # segfault with hardenedPkg
        zed-editor-fhs

        # https://nixos.wiki/wiki/Steam
        (lib.hiPrio config.programs.steam.package.run) # override the non cleanPkg one
      ])
    );
  programs.localsend.package = hardenedPkg pkgs.localsend;

  programs.firejail.enable = true;
  programs.firejail.wrappedBinaries = with pkgs; {
    # librewolf firejail difficult to fix, still: cannot directly opening downloaded files
    /*
      librewolf = {
        executable = "${progs.librewolf_for_firejail}/bin/librewolf";
        profile = "${pkgs.firejail}/etc/firejail/librewolf.profile";
        extraArgs = [
          #"--dbus-user.talk=org.kde.dolphin.FileManager1"
          "--dbus-user.talk=org.freedesktop.FileManager1"
          # Required for U2F USB stick
          "--ignore=private-dev"
          # Enable system notifications
          "--dbus-user.talk=org.freedesktop.Notifications"
          # https://github.com/netblue30/firejail/issues/5062 - light/dark theme switching
          "--dbus-user.talk=org.freedesktop.portal.Desktop"
          "--ignore=noroot"
        ];
      };
    */
    # firejail for wine apps is still wip
    /*
      notepad-plus-plus = {
        executable = "${
          hardenedPkg inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.notepad-plus-plus
        }/bin/notepad-plus-plus";
        profile = "${
          inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.firejail-profiles
        }/etc/firejail/notepad-plus-plus.profile";
      };
    */
    obsidian = {
      executable = "${hardenedPkg obsidian}/bin/obsidian";
      profile = "${pkgs.firejail}/etc/firejail/obsidian.profile";
    };
    remmina = {
      executable = "${hardenedPkg remmina}/bin/remmina";
      profile = "${pkgs.firejail}/etc/firejail/remmina.profile";
    };
    # recently fluffychat broken with firejail
    /*
      fluffychat = {
        executable = "${hardenedPkg fluffychat}/bin/fluffychat";
        profile = "${pkgs.firejail}/etc/firejail/fluffychat.profile";
      };
    */
    # element-desktop: kwallet keyring broken with firejail
    /*
      element-desktop = {
        executable = "${hardenedPkg element-desktop}/bin/element-desktop";
        profile = "${pkgs.firejail}/etc/firejail/element-desktop.profile";
      };
    */
    qbittorrent = {
      executable = "${hardenedPkg qbittorrent-enhanced}/bin/qbittorrent";
      profile = "${pkgs.firejail}/etc/firejail/qbittorrent.profile";
    };
    gnome-calculator = {
      executable = "${hardenedPkg gnome-calculator}/bin/gnome-calculator";
      profile = "${pkgs.firejail}/etc/firejail/gnome-calculator.profile";
    };
    gnome-clocks = {
      executable = "${hardenedPkg gnome-clocks}/bin/gnome-clocks";
      profile = "${pkgs.firejail}/etc/firejail/gnome-clocks.profile";
    };
    # https://github.com/librephoenix/nixos-config/blob/0c3b676ab9d3e93780f06dbe5e084048eeed9a32/modules/system/security/firejail/default.nix#L21
    discord = lib.mkIf pkgs.stdenv.isx86_64 {
      executable = "${hardenedPkg progs.discord}/bin/discord";
      profile = "${pkgs.firejail}/etc/firejail/discord.profile";
    };
    /*
      ytmdesktop = {
        executable = "${hardenedPkg pkgs.ytmdesktop}/bin/ytmdesktop";
        profile = "${pkgs.firejail}/etc/firejail/ytmdesktop.profile";
      };
    */
    bitwarden-desktop = {
      executable = "${hardenedPkg pkgs.bitwarden-desktop}/bin/bitwarden";
      profile = "${pkgs.firejail}/etc/firejail/bitwarden.profile";
    };
    # https://github.com/legendofmiracles/dotnix/blob/ea678c780a1944e32c94ded1b58ce3a28be553d9/hosts/pain/configuration.nix#L110
    # disable firejail for chromium if we want to use webflasher WebSerial
    # disable firajail as it might break Antigravity? https://antigravity.google/docs/browser NO: antigravity's integration still doesn't work even without firejail
    chromium = lib.mkIf (!boot-to-steam) {
      executable = "${hardenedPkg pkgs.chromium}/bin/chromium";
      profile = "${pkgs.firejail}/etc/firejail/chromium.profile";
      extraArgs = [
        # https://github.com/netblue30/firejail/issues/3170#issuecomment-576266164
        # also webflasher WebSerial
        "--ignore=private-dev"
        "--ignore=nogroups" # dialout group for serial devices
      ];
    };
    # test on filesystem permission: for example /run/wrappers/bin/firejail '--whitelist=/run/pipewire' '--profile=/nix/store/sfnvg7fpq26ckdb7dl1bxr7j366ii84c-source/nixos/wiliwili.profile' -- $(readlink /run/current-system/sw/bin/ls) Pictures
    wiliwili = lib.mkIf (!boot-to-steam) {
      executable = "${hardenedPkg pkgs.wiliwili}/bin/wiliwili";
      profile = ./wiliwili.profile;
    };
    Telegram = lib.mkIf novirt {
      executable = "${hardenedPkg progs.telegram}/bin/Telegram";
      profile = "${pkgs.firejail}/etc/firejail/Telegram.profile";
      extraArgs = [
        # https://github.com/netblue30/firejail/issues/5062 - light/dark theme switching
        "--dbus-user.talk=org.freedesktop.portal.Desktop"
        "--ignore=noroot"
      ];
    };
    materialgram = lib.mkIf novirt {
      executable = "${hardenedPkg progs.materialgram}/bin/materialgram";
      profile = ./materialgram.profile;
      extraArgs = [
        # https://github.com/netblue30/firejail/issues/5062 - light/dark theme switching
        "--dbus-user.talk=org.freedesktop.portal.Desktop"
        "--ignore=noroot"
      ];
    };
  };
  environment.etc."firejail/librewolf.local".text = ''
    whitelist ${"$"}{PICTURES}
    noblacklist ${"$"}{PICTURES}
  '';
  # for opening web links:
  environment.etc."firejail/materialgram.local".text = ''
    dbus-user.talk org.freedesktop.portal.Desktop
    dbus-user.talk org.freedesktop.portal.OpenURI
    ignore noroot
    whitelist /run/current-system
    whitelist /run/wrappers
    ignore private-bin
  '';
  environment.etc."firejail/Telegram.local".text = ''
    dbus-user.talk org.freedesktop.portal.Desktop
    dbus-user.talk org.freedesktop.portal.OpenURI
    ignore noroot
    whitelist /run/current-system
    whitelist /run/wrappers
    ignore private-bin
  '';

  # xone causes issues that controller is blank after reboot until replugged. default driver xpad works fine.
  /*
    hardware.xone.enable = lib.mkIf novirt true; # support for the xbox controller USB dongle
    boot.kernelModules = lib.optionals config.hardware.xone.enable [ "xone" ]; # does thie help need replugging after reboot issue
    hardware.xpad-noone.enable = lib.mkIf novirt true;
  */

  /*
    # https://t.me/chaotic_nyx_sac/27154
    boot.extraModulePackages = lib.mkIf (novirt && config.hardware.bluetooth.enable) [
      (config.boot.kernelPackages.xpadneo.override { bluez = pkgs.bluez; })
    ];
  */
  # cannot condition on config.hardware.bluetooth.enable as of https://github.com/NixOS/nixpkgs/pull/483838
  hardware.xpadneo.enable = lib.mkIf novirt true;

  services.gvfs.enable = true;

  services.flatpak = lib.mkIf pkgs.stdenv.isx86_64 {
    # please update manually and take care of Spotify (SpotX)
    /*
      update.auto = {
        enable = true;
        onCalendar = "daily";
      };
    */
    enable = true;
    packages = [
      #"sh.cider.Cider" # doesn't work
      "com.microsoft.Edge" # Download Documents Music Pictures Videos ...
      #"com.google.Chrome" # Download Documents Music Pictures Videos ...
      #"com.discordapp.Discord" # Download Pictures Videos and more
      "tv.plex.PlexDesktop"
      "com.spotify.Client"
      "com.qq.QQ" # Download folder read/write access and more
      "com.tencent.WeChat" # Download folder read access and more
      "com.baidu.NetDisk" # EOL and file system access
      "com.parsecgaming.parsec"
      # followings are built from source by flathub:
      "com.usebottles.bottles" # is it really from source? not very sure
      #"com.gitlab.bitseater.meteo"
      #"io.github.archisman_panigrahi.typhoon"
      #"cn.xfangfang.wiliwili"
      #"org.musescore.MuseScore"
      #"org.prismlauncher.PrismLauncher"
      #"eu.betterbird.Betterbird"
      /*
        # https://github.com/cross-platform/icloud-for-linux/pull/105 -> https://github.com/PercevalSA/icloud-for-linux/actions/runs/19347254109
        rec {
          appId = "io.github.crossplatform.icloud-for-linux";
          sha256 = "sha256-2MvGVZclrlogqQI317HG0dmodZlQ2iRowyGWrbR9RfI=";
          bundle = "${pkgs.fetchurl {
            url = "https://github.com/mio-19/upload/raw/refs/heads/main/icloud-for-linux.flatpak";
            inherit sha256;
          }}";
        }
      */
    ];
    remotes = lib.mkOptionDefault [
      {
        name = "flathub-beta";
        location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
      }
    ];
  };

  programs.chromium = {
    enable = true;
    enablePlasmaBrowserIntegration = true;
    plasmaBrowserIntegrationPackage = lib.mkDefault pkgs.kdePackages.plasma-browser-integration;
    /*
      extraOpts = {
        #RestoreOnStartup = 1;
        BrowserSignin = 1;
        SyncDisabled = false;
      };
    */
  };

  programs.sniffnet.enable = true;
}
