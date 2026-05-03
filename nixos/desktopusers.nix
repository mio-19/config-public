{
  inputs,
  config,
  pkgs,
  lib,
  osConfig,
  _include,
  ...
}@args:
with _include;
let
  # DETAILS REMOVED
in
{
  imports = [
    inputs.steam-config-nix.homeModules.default
  ];

  # https://docs.vicinae.com/nixos
  services.vicinae = {
    enable = osConfig.services.desktopManager.plasma6.enable;
    package = pkgs.vicinae;
    systemd = {
      enable = true; # default: false
      autoStart = true; # default: false
    };
    settings = {
      close_on_focus_loss = true;
    };
    # https://github.com/vicinaehq/extensions/tree/main/extensions
    extensions =
      with inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system};
      [
        bluetooth
        nix
        process-manager
        fuzzy-files
      ]
      ++ lib.optionals osConfig.services.pulseaudio.enable [
        pulseaudio
      ]
      ++ lib.optionals osConfig.services.power-profiles-daemon.enable [
        power-profile
      ]
      ++ lib.optionals osConfig.services.desktopManager.gnome.enable [
        gnome-settings
        gnome-dnd
      ]
      ++ lib.optionals osConfig.services.desktopManager.plasma6.enable [
        kde-system-settings
      ];
  };

  # https://discuss.kde.org/t/plasma-6-1-3-pinned-kde-application-icons-go-blank-after-gc-nixos/19444/3
  # https://github.com/NixOS/nixpkgs/issues/308252#issuecomment-2543048917
  home.activation.plasmaPinned = lib.mkIf osConfig.services.desktopManager.plasma6.enable (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -f ~/.config/plasma-org.kde.plasma.desktop-appletsrc ]; then
        ${pkgs.gnused}/bin/sed -i 's|file:///nix/store/[^/]*/share/applications/|applications:|' ~/.config/plasma-org.kde.plasma.desktop-appletsrc
      fi
    ''
  );
  systemd.user.services.plasmaPinnedFix = lib.mkIf osConfig.services.desktopManager.plasma6.enable {
    Unit = {
      Description = "Fix Plasma pinned launcher paths on boot";
      ConditionPathExists = "%h/.config/plasma-org.kde.plasma.desktop-appletsrc";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.gnused}/bin/sed -i 's|file:///nix/store/[^/]*/share/applications/|applications:|' %h/.config/plasma-org.kde.plasma.desktop-appletsrc";
      # Could cause problems when connected to another user with ego!
      #ExecStartPost = "${osConfig.systemd.package}/bin/systemctl --user restart plasma-plasmashell.service";
    };
    Install.WantedBy = [ "default.target" ];
  };

  # https://www.reddit.com/r/ManjaroLinux/comments/12fgj3o/kde_plasma_bluetooth_not_automatically_powered_on/
  #home.activation.nobluedevilglobalrc = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  #  rm -f ~/.config/bluedevilglobalrc
  #'';
  home.file.".config/bluedevilglobalrc".text = "";

  programs.plasma = lib.mkIf osConfig.services.desktopManager.plasma6.enable {
    enable = osConfig.services.desktopManager.plasma6.enable;
    workspace = {
      # DETAILS REMOVED
      enableMiddleClickPaste = false;
    };
    # https://github.com/0xDracula/nixos-config/blob/2ad1447c5e636122e0da2bc7ccaea9438f5c912c/home/plasma.nix#L9C7-L17C7
    hotkeys.commands = {
      "vicinae" = {
        name = "Vicinae Toggle";
        key = "Meta+Space";
        command = "vicinae toggle";
        logs.enabled = false;
      };
    };
    powerdevil = {
      AC = {
        powerButtonAction = "lockScreen";
        autoSuspend = {
          action = "nothing";
        };
        whenLaptopLidClosed = "lockScreen";
      };
      battery = {
        powerButtonAction = "sleep";
        autoSuspend = {
          action = "sleep";
        };
        whenLaptopLidClosed = "sleep";
      };
    };

    kscreenlocker = {
      timeout = 10;
      autoLock = true;
      lockOnResume = true;
      # DETAILS REMOVED
    };
    session = {
      sessionRestore.restoreOpenApplicationsOnLogin = "startWithEmptySession";
    };
    configFile = {
      # https://github.com/nix-community/plasma-manager/blob/6a7d78cebd9a0f84a508bec9bc47ac504c5f51f4/examples/homeManager/home.nix#L70
      "baloofilerc"."Basic Settings"."Indexing-Enabled" = false;
    };

    # https://github.com/9dkc/dotfiles/blob/cbbfeb63729a97d735edf033eaf1f99f6ac957e7/modules/home/desktop/kde/kwin.nix#L7
    kwin.effects.blur.enable = true;
  };

  # https://github.com/keenanweaver/nix-config/blob/78fa3cb210be76a64241def0e788edfdab03df6e/modules/apps/steam/default.nix#L117
  home.file.steam-slow-fix = {
    enable = has-steam;
    text = ''
      @nClientDownloadEnableHTTP2PlatformLinux 0
      @fDownloadRateImprovementToAddAnotherConnection 1.0
      unShaderBackgroundProcessingThreads 8
    '';
    target = "${config.xdg.dataHome}/Steam/steam_dev.cfg";
  };

  # already configured at system level
  # https://wiki.archlinux.org/title/Chromium
  # https://gist.github.com/foutrelis/14e339596b89813aa9c37fd1b4e5d9d5
  #home.sessionVariables.GOOGLE_DEFAULT_CLIENT_ID = "77185425430.apps.googleusercontent.com";
  #home.sessionVariables.GOOGLE_DEFAULT_CLIENT_SECRET = "OTJgUOQcT7lO7GsGZq2G4IlT";

  # https://nixos.wiki/wiki/Cursor_Themes
  # https://github.com/Remedan/dotfiles/blob/c23a1648e1165aa1061aa2e79b77858f46580f42/modules/user/gtk.nix#L11
  #home.pointerCursor = {
  #  x11.enable = true;
  #  gtk.enable = true;
  #  package = pkgs.adwaita-icon-theme;
  #  name = "Adwaita";
  #  size = 48;
  #};

  # https://www.reddit.com/r/NixOS/comments/1htxgly/comment/m5ioyg0
  # but with home manager you can go further, by doing this in addition:
  home.file.".icons/default" = lib.mkIf (
    osConfig.services.displayManager.defaultSession == "plasma" && kdeDMEnabled
  ) { source = "${pkgs.kdePackages.breeze}/share/icons/breeze_cursors"; };

  services.kdeconnect.enable = lib.mkIf (osConfig.services.desktopManager.plasma6.enable) true;

  # https://discourse.nixos.org/t/enabling-gnome-extensions-with-home-manager/59701/2
  home.packages = lib.mkIf osConfig.services.desktopManager.gnome.enable (
    with pkgs.gnomeExtensions;
    [
      blur-my-shell
      light-style # conflicts with blur-my-shell; choose one.
      #quick-settings-tweaker # broken
      gsconnect
      vitals
      vicinae
      paperwm
      appindicator
      # easyeffects-preset-selector # people say it is broken https://extensions.gnome.org/extension/4907/easyeffects-preset-selector/
    ]
  );
  dconf = lib.mkIf osConfig.services.desktopManager.gnome.enable {
    enable = true;
    settings = {
      "org/gnome/shell" = {
        # `gnome-extensions list` for a list
        enabled-extensions = [
          #"blur-my-shell@aunetx"
          "light-style@gnome-shell-extensions.gcampax.github.com" # conflicts with blur-my-shell; choose one.
          #"quick-settings-tweaks@qwreey"
          "gsconnect@andyholmes.github.io"
          #"Vitals@CoreCoding.com"
        ]
        ++ lib.optionals (config.home.username == "user" || config.home.username == "mio") [
          "paperwm@paperwm.github.com"
        ];
      };
    };
  };

  # https://github.com/NixOS/nixpkgs/issues/488709
  home.activation.iconWorkaround = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -f /run/current-system/sw/share/icons/hicolor/1024x1024/apps/bombsquad.png ]; then
      mkdir -p ~/.local/share/icons/hicolor/256x256/apps
      rm -f ~/.local/share/icons/hicolor/256x256/apps/bombsquad.png
      cp /run/current-system/sw/share/icons/hicolor/1024x1024/apps/bombsquad.png ~/.local/share/icons/hicolor/256x256/apps/bombsquad.png
    fi
  '';

  # DETAILS REMOVED

  home.pointerCursor = lib.mkIf osConfig.services.desktopManager.pantheon.enable {
    package = pkgs.pantheon.elementary-icon-theme;
    name = "elementary";
    gtk.enable = true;
    x11.enable = true;
  };

  # https://discourse.nixos.org/t/icons-missing-in-gnome-applications/49835/7
  gtk = {
    gtk2.force = true;
    enable = true;
    # https://github.com/gburd/nix-config/blob/48b81de32994da370346005788672c0fb47d6d72/home-manager/_mixins/desktop/pantheon.nix#L229C1-L233C7
    theme = lib.mkIf osConfig.services.desktopManager.pantheon.enable {
      name = "io.elementary.stylesheet.bubblegum";
      package = pkgs.pantheon.elementary-gtk-theme;
    };
    iconTheme =
      if osConfig.services.desktopManager.pantheon.enable then
        {
          # TODO: WHY IS THIS NOT WORKING - workaround: gnome-tweaks
          package = pkgs.pantheon.elementary-icon-theme;
          name = "elementary";
        }
      else
        {
          package = pkgs.adwaita-icon-theme;
          name = "Adwaita";
        };
  };

  xdg.userDirs.enable = true;
  xdg.userDirs.createDirectories = true;
}
