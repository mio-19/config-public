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
  services.orca.enable = lib.mkForce false; # workaround build failure bug related to gnome
  home-manager.sharedModules = [
    ./desktopusers.nix
  ];
  nixpkgs.overlays = [
    # https://discourse.nixos.org/t/gdm-background-image-and-theme/12632/10
    (self: super: {
      gnome-shell =
        if false then
          super.gnome-shell
        else
          super.gnome-shell.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [
              (pkgs.writeText "bg.patch" ''
                --- a/data/theme/gnome-shell-sass/widgets/_login-lock.scss
                +++ b/data/theme/gnome-shell-sass/widgets/_login-lock.scss
                @@ -15,4 +15,5 @@ $_gdm_dialog_width: 23em;
                 /* Login Dialog */
                 .login-dialog {
                   background-color: $_gdm_bg;
                +  background-image: url('file:///etc/nixos/lockscreen.jpg');
                 }
              '')
            ];
          });
    })
  ];

  environment.etc."nixos/lockscreen.jpg".source =
    pkgs.runCommand "lockscreen-jpg" { buildInputs = [ pkgs.imagemagick ]; }
      ''
        magick convert ${if config.hdr_very_bright then ./black.png else config.system_background} $out
      '';

  programs.localsend.openFirewall = true;
  programs.localsend.enable = true;

  programs.dconf.enable = true;
  # https://wiki.nixos.org/wiki/GNOME
  programs.dconf.profiles.user.databases = [
    {
      settings = {
        "org/gnome/mutter" = {
          experimental-features = [
            "scale-monitor-framebuffer" # Enables fractional scaling (125% 150% 175%)
            "variable-refresh-rate" # Enables Variable Refresh Rate (VRR) on compatible displays
            "xwayland-native-scaling" # Scales Xwayland applications to look crisp on HiDPI screens
          ];
        };
        #"org/gnome/login-screen" = {
        #  # doesn't seem to work?
        #  "users-welcome-order" = "linux,user,zdmin";
        #};
      };
    }
  ];

  systemd.tmpfiles.rules = lib.mkIf config.services.displayManager.gdm.enable [
    # type  target                    link-to-path                mode uid  gid  age  argument
    "F /var/log/wtmp 0664 root utmp -" # for gdm user order
  ];

  #services.displayManager.gdm.settings.greeter.RememberLastUser = false; # doesn't work qwq
  services.displayManager.sddm.wayland.enable = lib.mkDefault true;
  services.displayManager.sddm.enableHidpi = true;
  #services.displayManager.sessionPackages = [ pkgs.kdePackages.plasma-mobile ];
  # https://github.com/leo60228/dotfiles/blob/b797fd05121f77425d971c8d68c510feed980ab6/systems/aftermath/default.nix#L18
  services.displayManager.sddm.wayland.compositorCommand = lib.concatStringsSep " " [
    "${lib.getBin pkgs.kdePackages.kwin}/bin/kwin_wayland"
    "--no-global-shortcuts"
    "--no-kactivities"
    "--no-lockscreen"
    "--locale1"
    "--inputmethod"
    "maliit-keyboard"
  ];
  # lockscreen of gnome is only working with gdm
  services.desktopManager.gnome.enable = config.services.displayManager.gdm.enable;
  services.desktopManager.plasma6.enable = true;
  environment.plasma6.excludePackages =
    lib.optionals config.services.displayManager.plasma-login-manager.enable [
      pkgs.kdePackages.kwin-x11 # https://github.com/NixOS/nixpkgs/pull/479797#issuecomment-3748683491
    ]
    ++ [
      pkgs.kdePackages.baloo-widgets
    ];
  # note: consider null - https://discourse.nixos.org/t/help-i-cant-have-pantheon-gnome-and-plasma-installed-on-my-system-at-the-same-time/47346/4
  services.displayManager.defaultSession = (
    if config.services.displayManager.gdm.enable then
      "gnome"
    else if config.services.xserver.displayManager.lightdm.enable then
      "pantheon-wayland"
    else
      lib.mkDefault "plasma"
  );
  #services.xserver.desktopManager.phosh.enable = true;
  #services.xserver.desktopManager.phosh.group = "users";
  services.gnome.core-apps.enable = config.services.desktopManager.gnome.enable;
  services.gnome.core-developer-tools.enable = lib.mkDefault false;
  services.gnome.games.enable = false;
  environment.gnome.excludePackages = with pkgs; [
    # https://github.com/mwlaboratories/phoneputer/blob/13070a74737bd184f4814c056571862f80036c5b/configuration.nix#L36C51-L47C35
    baobab # disk usage analyzer
    cheese # photo booth
    eog # image viewer
    epiphany # web browser
    simple-scan # document scanner
    totem # video player
    yelp # help viewer
    evince # document viewer
    file-roller # archive manager
    geary # email client
    #seahorse    # password manager
  ];
  # https://discourse.nixos.org/t/unable-to-start-x-after-update-to-25-05-nvidia-open-drivers/60854/2
  services.xserver.displayManager.startx.enable = config.services.xserver.enable;
  #programs.ssh.askPassword = lib.mkForce "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass"; # lightdm.configuration.programs.ssh.askPassword has conflicting values between seahorse and plasma6

  # https://wiki.nixos.org/wiki/Fingerprint_scanner
  # sddm and plasma and lightdm are broken with fprint. https://github.com/sddm/sddm/issues/1840
  # plasma supports fingerprint without fprintAuth but plasma is broken when fprintAuth is enabled
  security.pam.services.login.fprintAuth = false;
  # they are buggy with fprint! can we disable them by this?
  security.pam.services.kde.fprintAuth = false;
  #security.pam.services.kde-fingerprint.fprintAuth = false;
  security.pam.services.passwd.fprintAuth = false;
  security.pam.services.polkit-1.fprintAuth = false;
  # only enable for gdm as suggested by wiki - https://wiki.nixos.org/wiki/Fingerprint_scanner
  security.pam.services.gdm-fingerprint = lib.mkIf (config.services.fprintd.enable) {
    text = ''
      auth       required                    pam_shells.so
      auth       requisite                   pam_nologin.so
      auth       requisite                   pam_faillock.so      preauth
      auth       required                    ${pkgs.fprintd}/lib/security/pam_fprintd.so
      auth       optional                    pam_permit.so
      auth       required                    pam_env.so
      auth       [success=ok default=1]      ${pkgs.gdm}/lib/security/pam_gdm.so
      auth       optional                    ${pkgs.gnome-keyring}/lib/security/pam_gnome_keyring.so

      account    include                     login

      password   required                    pam_deny.so

      session    include                     login
      session    optional                    ${pkgs.gnome-keyring}/lib/security/pam_gnome_keyring.so auto_start
    '';
  };

  nixpkgs.config.chromium.enableWideVine = true;

  # https://nixos.wiki/wiki/Chromium
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  # https://github.com/search?q=GTK_USE_PORTAL+language%3ANix+&type=code
  environment.sessionVariables.GTK_USE_PORTAL = 1;
  # https://wiki.archlinux.org/title/Chromium
  # https://gist.github.com/foutrelis/14e339596b89813aa9c37fd1b4e5d9d5
  environment.sessionVariables.GOOGLE_DEFAULT_CLIENT_ID = "77185425430.apps.googleusercontent.com";
  environment.sessionVariables.GOOGLE_DEFAULT_CLIENT_SECRET = "OTJgUOQcT7lO7GsGZq2G4IlT";
  # https://wiki.archlinux.org/title/DaVinci_Resolve
  environment.sessionVariables.QT_AUTO_SCREEN_SCALE_FACTOR = "1";
  # https://github.com/gvolpe/nix-config/blob/5a13709be967173e1f47c254d705c45c139976fe/home/wm/niri/default.nix#L98
  environment.sessionVariables.MOZ_ENABLE_WAYLAND = "1";

  # https://search.nixos.org/packages
  environment.systemPackages =
    with pkgs;
    (map hardenedPkg [
      xhost

      mission-center
      (wrapPrio gnome-disk-utility)

      maliit-keyboard
      maliit-framework
      #squeekboard
      #wvkbd
      #kdePackages.qtvirtualkeyboard

      # https://discourse.nixos.org/t/system-cursor-theme-and-scaling-not-being-followed-by-some-apps-system-packages-flatpak/49917
      xsettingsd
      (wrapPrio (pkgs.xrdb or pkgs.xorg.xrdb))
    ])
    ++ lib.optionals config.services.displayManager.plasma-login-manager.enable [
      # plasma-login-manager is broken with plasma x11 session.
      # but it is still showing plasma (X11) as default with this?
      /*
        (lib.hiPrio (
          runCommand "empty-plasmax11-desktop" { } ''
            mkdir -p $out/share/xsessions
            touch $out/share/xsessions/plasmax11.desktop
          ''
        ))
      */
    ]
    ++ lib.optionals (config.services.displayManager.sddm.enable) [
      # https://discourse.nixos.org/t/sddm-background-on-default-theme/46263
      (pkgs.writeTextDir "share/sddm/themes/breeze/theme.conf.user" ''
        [General]
        background=${if config.hdr_very_bright then ./black.png else config.system_background}
      '')
    ]
    ++
      lib.optionals
        (builtins.any (s: s.kwallet.enable) (builtins.attrValues config.security.pam.services))
        [
          kdePackages.kwallet
          kdePackages.kwalletmanager
          kdePackages.kwallet-pam
        ]
    ++ lib.optionals (config.services.displayManager.defaultSession == "plasma" && kdeDMEnabled) [

      # https://www.reddit.com/r/NixOS/comments/1htxgly/comment/m5ioyg0
      (lib.hiPrio breeze-cursor-default-theme)
    ]
    ++ lib.optionals config.services.desktopManager.plasma6.enable [
      # https://github.com/9dkc/dotfiles/blob/cbbfeb63729a97d735edf033eaf1f99f6ac957e7/modules/home/desktop/kde/kwin.nix#L2C26-L2C45
      #kde-rounded-corners # no: broken with vicinae dialog
      #whitesur-kde # no: buggy
      plasma-overdose-kde-theme
      # https://github.com/tdortman/dotfiles/blob/c6811906d5c5c775b45a772e5e71bab3a305bef2/nix/modules/nixos/hdr/default.nix#L91
      vulkan-hdr-layer-kwin6
    ]
    ++ lib.optionals config.services.desktopManager.gnome.enable [
      # https://github.com/shrynx/config/blob/29d6a5ad6c76da01ef5e81540c75c393c410388b/modules/nixos/kde.nix#L81-L83
      whitesur-gtk-theme
      whitesur-cursors
    ]
    ++ lib.optionals (config.programs.steam.enable && config.hardware.nvidia.prime.offload.enable) [
      (lib.hiPrio (offloadPkg config.programs.steam.package))
    ]
    ++ lib.optionals config.services.desktopManager.pantheon.enable [
      pantheon-tweaks
    ];

  programs.kdeconnect.enable = lib.mkIf (
    config.services.desktopManager.plasma6.enable || config.services.desktopManager.gnome.enable
  ) true;
  programs.kdeconnect.package = lib.mkDefault (
    if config.services.displayManager.gdm.enable then
      pkgs.gnomeExtensions.gsconnect
    else
      hardenedPkg pkgs.kdePackages.kdeconnect-kde
  );

  # CANNOT SET WALLPEPER
  /*
    # https://github.com/ShadowRZ/flakes/commit/f455512b6270c5841a8a533b38bc68cff01b8f65
    # https://github.com/Green-D-683/NixOS_Config/blob/851aa57ec97e98d71e6e117d8b5dfc608ff79e85/nixos/components/general/graphical.nix#L31-L46
    services.displayManager.plasma-login-manager.settings = {
      Greeter = {
        WallpaperPlugin = "org.kde.image";
      };

      # This injects the path to your Nix-store image into the plugin settings
      "Greeter/Wallpaper/org.kde.image/General" = {
        Image = "file://${if config.hdr_very_bright then ./black.png else config.system_background}";

        # Options: 0 = Scaled&Cropped, 1 = Tiled, 2 = Stretched, 3 = Centered
        #FillMode = "0";
      };
    };
    # https://github.com/Green-D-683/NixOS_Config/blob/851aa57ec97e98d71e6e117d8b5dfc608ff79e85/nixos/components/general/graphical.nix#L11-L16
    # https://github.com/HalcyonOmega/nixos/blob/77c28b403f643f6296818181bdda7abd1bab783d/modules/desktop-environments/kde/plasma-manager.nix#L615-L622
    environment.etc."plasmalogin.conf.d/98-bg.conf".text = ''
      [Greeter]
      WallpaperPluginId=org.kde.image

      [Greeter][Wallpaper][org.kde.image][General]
      Image=file://${if config.hdr_very_bright then ./black.png else config.system_background}
    '';
  */

  xdg.portal.enable = true; # useful for firejailed telegram launching firejailed librewolf
  xdg.portal.xdgOpenUsePortal = true;
  /*
    xdg.portal.config = {
      kde = {
        # https://github.com/mochouaaaaa/nix-config/blob/6f7efe9239a73348e55498c0859fc2d3ff896b22/modules/home/linux/desktop/window/kde/config/xdg.nix#L15
        default = [ "kde" ];
      };
      gnome = {
        default = [
          "gtk"
        ];
      };
    };
  */
  security.apparmor.enable = true; # maybe this break waydroid?
  services.dbus.apparmor = lib.mkDefault "enabled"; # maybe this break waydroid?
  # https://wiki.nixos.org/wiki/Firejail
  programs.firejail = {
    enable = true;
    wrappedBinaries = {
    };
  };
  # DETAILS REMOVED
  # https://github.com/netblue30/firejail/issues/3170#issuecomment-576266164
  # also webflasher WebSerial for chromium?
  environment.etc."firejail/firejail.config".text = ''
    browser-disable-u2f no
    allow-tray yes
  '';

  # https://wiki.nixos.org/wiki/Audio_production
  environment.variables =
    with lib;
    let
      makePluginPath =
        format:
        (makeSearchPath format [
          "$HOME/.nix-profile/lib"
          "/run/current-system/sw/lib"
          "/etc/profiles/per-user/$USER/lib"
        ])
        + ":$HOME/.${format}";
    in
    {
      DSSI_PATH = makePluginPath "dssi";
      LADSPA_PATH = makePluginPath "ladspa";
      LV2_PATH = makePluginPath "lv2";
      LXVST_PATH = makePluginPath "lxvst";
      VST_PATH = makePluginPath "vst";
      VST3_PATH = makePluginPath "vst3";
    };

  # TODO: https://github.com/NixOS/nixpkgs/issues/149812#issuecomment-3647060694

  # https://github.com/paaradiso/nixos/blob/3f16553a6bc397288e15e61cb4f19b133db078c8/modules/packages/xmousepasteblock.nix#L2
  systemd.user.services.xmousepasteblock = {
    enable = true;
    wantedBy = [ "graphical-session.target" ];
    description = "XmousePasteBlock - Userspace tool to disable middle mouse button paste in Xorg";
    after = [ "graphical-session.target" ];
    serviceConfig = {
      RestartSec = "5s";
    };
  };

  # not sure what cosmic actually needs to enable kwallet!!
  security.pam.services.login.kwallet = lib.mkIf config.services.desktopManager.cosmic.enable {
    enable = true;
    #forceRun = true;
  };
  security.pam.services.login.enableGnomeKeyring = false;
  security.pam.services.kde.enableGnomeKeyring = false;
  /*
    security.pam.services.gnome.kwallet = {
      enable = true;
      #forceRun = true;
    };
  */
  security.pam.services.gnome.enableGnomeKeyring = false;
  services.gnome.gnome-keyring.enable =
    if (config.services.desktopManager.pantheon.enable) then lib.mkForce false else false;
  security.pam.services.sddm.enableGnomeKeyring = false;
  security.pam.services.gdm.enableGnomeKeyring = false;
  security.pam.services.gdm.kwallet = {
    enable = true;
    #forceRun = true;
  };
  security.pam.services.cosmic-greeter.kwallet = {
    enable = true;
  };
  security.pam.services.cosmic.kwallet = {
    enable = true;
  };
  security.pam.services.greetd.enableGnomeKeyring = false;
  security.pam.services.greetd.kwallet = {
    enable = true;
  };
  xdg.portal.config.gnome."org.freedesktop.impl.portal.Secret" = [ "kwallet" ];
  # copied from plasma6 from nixpkgs
  xdg.portal.extraPortals = with pkgs; [
    kdePackages.kwallet
    kdePackages.xdg-desktop-portal-kde
    xdg-desktop-portal-gtk
  ];

  qt = lib.mkIf kdeDMEnabled {
    # https://github.com/olafkfreund/nixos-template/blob/19b47e0faa2229224f5daf37fdea944fdc5d9b3b/home/profiles/kde.nix#L34-L38
    enable = true;
    platformTheme = "kde6";
    style = "breeze";
  };

  # TODO: solve https://discussion.fedoraproject.org/t/correct-way-to-theme-kde-apps-on-gnome/133996
}
