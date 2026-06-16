{
  config,
  inputs,
  lib,
  pkgs,
  _include,
  ...
}@args:
with _include;
let
  jovian = config.jovian.steam.enable or false;
in
{
  # https://github.com/Electrostasy/dots/blob/6438185e9de14610ff4e8a9a82d0079a82a647ec/hosts/terra/gaming.nix#L8C1-L12C5
  boot.kernelModules = [ "ntsync" ];

  # https://search.nixos.org/packages
  environment.systemPackages =
    with pkgs;
    (map cleanPkg [
      (offloadPkg prismlauncher)
      (offloadPkg ryubing)
      (offloadPkg luanti-client)
      (lib.hiPrio (offloadPkg nur.repos.mio.minetest580client))
      (offloadPkg (wrapPrio supertuxkart))
      (offloadPkg inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.supertuxkart-evolution)
      supertux
      the-powder-toy
      ludusavi
      (offloadPkg vdrift)
      zeroad
      jumpnbump
      linthesia
      boilr
      celeste64
    ])
    ++ lib.optionals pkgs.stdenv.isx86_64 (
      [
        nur.repos.mio.beammp-launcher # cannot have more wrapper
      ]
      ++ map cleanPkg [
        (offloadPkg bombsquad)
        lutris
        heroic
        rare
        /*
          (lutris.override {
            extraPkgs =
              pkgs': with pkgs'; [
                zenity
              ];
            extraLibraries =
              pkgs': with pkgs'; [
                libadwaita
                gtk4
              ];
          })
        */
      ]
    );

  # https://github.com/librephoenix/nixos-config/blob/0c3b676ab9d3e93780f06dbe5e084048eeed9a32/modules/system/security/firejail/default.nix#L24
  programs.firejail.enable = true;
  programs.firejail.wrappedBinaries = {
    # cannot launch from steam if sandboxed
    prismlauncher = lib.mkIf (!boot-to-steam) {
      executable = "${cleanPkg (offloadPkg pkgs.prismlauncher)}/bin/prismlauncher";
      # https://github.com/librephoenix/nixos-config/raw/0c3b676ab9d3e93780f06dbe5e084048eeed9a32/modules/system/security/firejail/profiles/prismlauncher.profile
      profile = ./prismlauncher.profile;
    };
    # won't work as lutris in nixos has its own bwrap
    /*
      lutris = lib.mkIf pkgs.stdenv.isx86_64 {
        executable = "${cleanPkg pkgs.lutris}/bin/lutris";
        profile = "${pkgs.firejail}/etc/firejail/lutris.profile";
      };
    */
    luanti = lib.mkIf (!boot-to-steam) {
      executable = "${cleanPkg (offloadPkg pkgs.luanti-client)}/bin/luanti";
      profile = "${pkgs.firejail}/etc/firejail/minetest.profile";
    };
    minetest = lib.mkIf (!boot-to-steam) {
      executable = "${cleanPkg (offloadPkg pkgs.nur.repos.mio.minetest580client)}/bin/minetest";
      profile = "${pkgs.firejail}/etc/firejail/minetest.profile";
    };
    supertuxkart = lib.mkIf (!boot-to-steam) {
      executable = "${cleanPkg (offloadPkg pkgs.supertuxkart)}/bin/supertuxkart";
      profile = "${pkgs.firejail}/etc/firejail/supertuxkart.profile";
    };
    supertuxkart-evolution = lib.mkIf (!boot-to-steam) {
      executable = "${
        cleanPkg (offloadPkg inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.supertuxkart-evolution)
      }/bin/supertuxkart-evolution";
      profile = "${pkgs.firejail}/etc/firejail/supertuxkart.profile";
    };
    supertux2 = lib.mkIf (!boot-to-steam) {
      executable = "${cleanPkg pkgs.supertux}/bin/supertux2";
      profile = "${pkgs.firejail}/etc/firejail/supertux2.profile";
    };
  };
  # still doesn't work. failed to open web links from prismlauncher
  /*
    # for opening web links:
    environment.etc."firejail/prismlauncher.local".text = ''
      dbus-user.talk org.freedesktop.portal.Desktop
      dbus-user.talk org.freedesktop.portal.OpenURI
      ignore noroot
      whitelist /run/current-system
      whitelist /run/wrappers
      ignore private-bin
    '';
  */

  programs.gamescope = lib.mkIf (!jovian && pkgs.stdenv.isx86_64) {
    package = pkgs.gamescope; # _git;
    enable = true;
    # TODO: do we need to disable this or not?
    capSysNice = true;
    #capSysNice = false; # https://github.com/keenanweaver/nix-config/blob/78fa3cb210be76a64241def0e788edfdab03df6e/modules/apps/gamescope/default.nix#L22 https://github.com/NixOS/nixpkgs/issues/292620#issuecomment-2143529075
  };

  # https://nixos.wiki/wiki/Steam
  programs.steam = lib.mkIf (!jovian && pkgs.stdenv.isx86_64) {
    enable = true;
    gamescopeSession.enable = true;
    #protontricks.enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
    extraCompatPackages = [
      inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.proton-cachyos_x86_64_v3
      pkgs.steam-play-none
      pkgs.nur.repos.mio.proton-ge-custom
      #pkgs.luxtorpeda
    ]
    ++ lib.optionals config.v4 [
      inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.proton-cachyos_x86_64_v4
    ];
    extraPackages =
      with pkgs;
      [
        pulseaudio # pactl command might be needed
        # https://github.com/kleinercubs/nix-config/blob/332ec781ddf50dda7e167d8451213e368f87491b/nixos/game.nix#L13
        gamescope-wsi
      ]
      ++ lib.optionals (config.services.displayManager.defaultSession == "plasma" && kdeDMEnabled) [
        # https://www.reddit.com/r/NixOS/comments/1htxgly/comment/m5ioyg0
        breeze-cursor-default-theme
      ];
    package = pkgs.steam.override {
      extraEnv = {
        PROTON_USE_NTSYNC = 1;
        PROTON_FSR4_UPGRADE = 1;
        # https://github.com/Rexcrazy804/Zaphkiel/blob/71405a1459402b2c054d8282b94a7a74e615ecf8/modules/programs/proton.nix#L4
        #PROTON_USE_WOW64 = 1; # CAN BREAK GAMES -> Elden Ring
        # https://github.com/Electrostasy/dots/blob/6438185e9de14610ff4e8a9a82d0079a82a647ec/hosts/terra/gaming.nix#L86C21-L89C33
        #PROTON_ENABLE_HDR = 1;
        #PROTON_ENABLE_WAYLAND = 1;
      };
    };
    fontPackages = with pkgs; [
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      source-han-sans
      source-han-serif
      wqy_zenhei
      wqy_microhei
    ];
  };

  #programs.opengamepadui.enable = true;
  #programs.opengamepadui.gamescopeSession.enable = true;

  #programs.gamemode.enable = true;

  # https://nixos.wiki/wiki/Games
  # for Intellij IDEA remote development? and BeamNG?
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # https://github.com/zsedem/nixos-configuration/blob/18e01a1991769a9141354363dcbe5a419f044481/commons/nix-ld.nix#L4
      SDL
      SDL2
      SDL2_image
      SDL2_mixer
      SDL2_ttf
      SDL_image
      SDL_mixer
      SDL_ttf
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      bzip2
      cairo
      cups
      curlWithGnuTls
      dbus
      dbus-glib
      desktop-file-utils
      e2fsprogs
      expat
      flac
      fontconfig
      freeglut
      freetype
      fribidi
      fuse
      fuse3
      gdk-pixbuf
      glew_1_10
      glib
      gmp
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-ugly
      gst_all_1.gstreamer
      gtk2
      harfbuzz
      icu
      keyutils.lib
      libGL
      libGLU
      libappindicator-gtk2
      libcaca
      libcanberra
      libcap
      libclang.lib
      libdbusmenu
      libdrm
      libgcrypt
      libgpg-error
      libidn
      libjack2
      libjpeg
      libmikmod
      libogg
      libpng12
      libpulseaudio
      librsvg
      libsamplerate
      libthai
      libtheora
      libtiff
      libudev0-shim
      libusb1
      libuuid
      libvdpau
      libvorbis
      libvpx
      libxcrypt-legacy
      libxkbcommon
      libxml2
      mesa
      nspr
      nss
      openssl
      p11-kit
      pango
      pixman
      python3
      speex
      stdenv.cc.cc
      onetbb
      udev
      vulkan-loader
      wayland
      libICE
      libSM
      libx11
      libxscrnsaver
      libxcomposite
      libxcursor
      libxdamage
      libxext
      libxfixes
      libxft
      libxi
      libxinerama
      libxmu
      libxrandr
      libxrender
      libxt
      libxtst
      libxxf86vm
      libpciaccess
      libxcb
      xcbutil
      xcbutilimage
      xcbutilkeysyms
      xcbutilrenderutil
      xcbutilwm
      xkeyboard-config
      xz
      zlib
      # https://github.com/wuX4an/.dotfiles/blob/cb37f6b6a240f483d2b8de2ad2fe567a01a81e00/README.md?plain=1#L139
      libx11
      libxext
      libxinerama
      libxrandr
      libxcursor
      libxrender
      alsa-lib
      libpulseaudio
      libGL
      SDL2
      libxkbcommon
      libxi
      # https://github.com/yjpark/dotnix/blob/43fe7babf9e6c1a6693a8f11459c70e844f82ab6/nixos/services/dev/nix-ld.nix#L6
      #stdenv.cc.cc
      zlib
      fuse3
      icu
      zlib
      nss
      openssl
      curl
      expat
      # https://github.com/acuteaura/universe/blob/14b1311a2669948b6290bce9a848cf636ef8f857/systems/_modules/base.nix#L42
      icu
      libgcc
      libz
      stdenv.cc.cc.lib
      libxcb
      zlib
      libgbm
    ];
  };

}
