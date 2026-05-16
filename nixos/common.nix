{
  config,
  inputs,
  lib,
  pkgs,
  system,
  ...
}@args:
let
  _include = (args._include or import ./include.nix args);
in
with _include;
{
  _module.args._include = _include;

  imports = [
    ./selector4nix.nix
    ./bandaid.nix
    ./ccache.nix
    ./options.nix
    ./basic.nix
    #./lix.nix
    #inputs.determinate.nixosModules.default
    "${inputs.nix-flatpak}/modules/nixos.nix"
    #inputs.musnix.nixosModules.musnix
    inputs.nix-index-database.nixosModules.nix-index
    #inputs.copyparty.nixosModules.default
    #inputs.chaotic.nixosModules.default
    inputs.impermanence.nixosModules.impermanence
    inputs.nixpkgs.nixosModules.notDetected
    #inputs.stylix.nixosModules.stylix
    inputs.nur.legacyPackages."${system}".repos.mio.modules.zfs-impermanence-on-shutdown
    inputs.mio.legacyPackages."${system}".modules.darling
    ./nixbuild.nix
    ../token.nix
  ];
  home-manager.sharedModules = [
    inputs.plasma-manager.homeModules.plasma-manager
    inputs.vscode-server.homeModules.default
    inputs.zen-browser.homeModules.default
    #inputs.android-nixpkgs.hmModule
    ../users.nix
    inputs.vicinae.homeManagerModules.default
    (
      {
        inputs,
        config,
        pkgs,
        lib,
        osConfig,
        ...
      }@args:
      let
        _include = (args._include or import ./include.nix args);
      in
      {
        _module.args._include = _include;
      }
    )
    (
      { ... }:
      {
        programs.vscode.package = progs.vscode;
      }
    )
  ];
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "hm-backup-" + config.system.configurationRevision;

  # https://discourse.nixos.org/t/gdm-background-image-and-theme/12632/10
  nixpkgs.overlays = [
    inputs.nur.overlays.default
    #inputs.copyparty.overlays.default
    #inputs.android-nixpkgs.overlays.default
    inputs.nix-vscode-extensions.overlays.default
    #inputs.emacs-overlay.overlays.package
    (final: prev: {
      #nur = pkgs'.nur; # this is more pure than applying inputs.nur.overlays.default on nixpkgs directly
      grub2 = final.nur.repos.mio.grub2;
      #zed-editor = pkgs-pin2.zed-editor;
      #nix-output-monitor = inputs.mio.packages."${system}".nix-output-monitor; # final.nur.repos.mio.nix-output-monitor;
      darling = inputs.mio.packages."${system}".darling;
      #librewolf = if cudaSupport then prev.librewolf else final.librewolf-bin; # third time only cuda has librewolf cache. did librewolf break again?
      librewolf = final.librewolf-bin; # no cache
      inherit (pkgs-openclaw) openclaw openclawPackages;
      inherit (pkgs-pin2)
        openssl_1_1
        sublime4
        sublime-merge
        lutris
        ;
      # hash mismatch in fixed-output derivation '/nix/store/7sj663dx4vl5n972s0825n6c3xxsvk7d-source.drv'
      inherit (pkgs-pin3) wireshark-cli;
    })
    inputs.chaotic.overlays.default
    inputs.mac-style-plymouth.overlays.default
    inputs.nix-bwrapper.overlays.default
    inputs.nix-webapps.overlays.lib
  ];

  boot.zfs.forceImportRoot = true; # It is highly recommended to set it to `false`, the new default from 26.11 on, to reduce the risk of data loss. Alternatively, you can silence this warning by explicitly setting it to `true`.

  security.rtkit.enable = config.services.pipewire.enable || config.services.pulseaudio.enable;
  services.pulseaudio.support32Bit = config.services.pulseaudio.enable && pkgs.stdenv.isx86_64;
  services.pipewire.alsa.support32Bit = config.services.pipewire.alsa.enable && pkgs.stdenv.isx86_64;
  services.jack.alsa.support32Bit = config.services.jack.alsa.enable && pkgs.stdenv.isx86_64;
  services.pipewire.pulse.enable = config.services.pipewire.enable;
  services.pipewire.alsa.enable = config.services.pipewire.enable;

  hardware.enableRedistributableFirmware = true;

  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
  # https://github.com/oxalica/nixos-config/blob/03e0de362290bbfae8615192cdfc03f903f5f583/flake.nix#L78-L85
  # https://github.com/dramforever/config/blob/63be844019b7ca675ea587da3b3ff0248158d9fc/flake.nix#L24-L28
  system.nixos.label =
    with builtins;
    with inputs;
    lib.concatStringsSep "-" (
      (lib.sort (x: y: x < y) config.system.nixos.tags)
      ++ [
        (
          if self.sourceInfo ? lastModifiedDate then
            "${substring 0 8 self.sourceInfo.lastModifiedDate}.${
              self.sourceInfo.shortRev or self.dirtyShortRev or "dirty"
            }"
          else
            self.sourceInfo.shortRev or self.dirtyShortRev or "dirty"
        )
      ]
    );

  programs.ssh.package =
    if config.mio_openssh_hpn then pkgs.nur.repos.mio.openssh_hpn else pkgs.openssh_hpn;

  services.gnome.gnome-remote-desktop.enable = !config.services.pulseaudio.enable; # doesn't work with pulseaudio

  # https://wiki.nixos.org/wiki/GNOME - GDM does not show user
  environment.shells = with pkgs; [ zsh ];

  # https://github.com/nix-community/home-manager/issues/108#issuecomment-340397178
  programs.zsh.enable = lib.mkDefault false;

  #stylix = {
  #  enable = true;
  # DETAILS REMOVED
  #};

  networking = {
    # Generate host ID from hostname
    hostId = builtins.substring 0 8 (builtins.hashString "sha256" config.networking.hostName);
  };

  nix = {
    nrBuildUsers = 128;
    #gc = {
    #  automatic = true;
    #  dates = "weekly";
    #};
    settings = {
      # https://github.com/NixOS/nixpkgs/blob/b103220c1aabc21529a02a8b52106d451d10cef6/nixos/modules/profiles/hardened.nix#L38C1-L40C1
      allowed-users = [ "@users" ];
      #lazy-trees = true;
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        # "root" # root is already trusted by default
        "@wheel"
      ];
    };
    # https://determinate.systems/blog/changelog-determinate-nix-3111/
    # lazy-tree: Lazy trees are currently stable in Determinate Nix and enabled by default for all users. https://docs.determinate.systems/determinate-nix/#determinate-nix-configuration
    #extraOptions = ''
    #  eval-cores = 0 # Evaluate across all cores
    #'';
  };

  nixpkgs.config.allowUnfree = false;
  nixpkgs.config.allowUnfreePredicate = allowUnfreePredicate;
  nixpkgs.config.allowNonSource = false;
  nixpkgs.config.allowNonSourcePredicate = allowNonSourcePredicate;
  #nixpkgs.config.allowAliases = false;

  nixpkgs.config.permittedInsecurePackages =
    with pkgs';
    [
      "electron-37.10.3"
      "openssl-1.1.1w" # for sublime-text
    ]
    ++ map (pkg: pkg.name) [
      #  Ventoy uses binary blobs which can't be trusted to be free of malware or compliant to their licenses.
      librewolf-bin
      librewolf-bin-unwrapped
      ventoy
      ventoy-full-gtk
      ventoy-full-qt
      openclaw
    ];

  i18n.defaultLocale = "en_AU.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_AU.UTF-8";
    LC_IDENTIFICATION = "en_AU.UTF-8";
    LC_MEASUREMENT = "en_AU.UTF-8";
    LC_MONETARY = "en_AU.UTF-8";
    LC_NAME = "en_AU.UTF-8";
    LC_NUMERIC = "en_AU.UTF-8";
    LC_PAPER = "en_AU.UTF-8";
    LC_TELEPHONE = "en_AU.UTF-8";
    LC_TIME = "en_AU.UTF-8";
  };

  # https://search.nixos.org/packages
  environment.systemPackages =
    with pkgs;
    (map hardenedPkg [
      program.git
      program.openssh
      #nix-output-monitor

      curl
      wget
      proto
      smartmontools
      mdbook
      dust
      iotop
      nmap
      nixfmt
      nixfmt-tree
      #caddy # caddy file-server --browse
      #copyparty
      typst
      #dmidecode
      pciutils
      usbutils
      unzip
      zip
      #nvd # https://discourse.nixos.org/t/nvd-simple-nix-nixos-version-diff-tool/12397/21
      uv
      python3
      fd
      fzf
      file
      (lib.hiPrio btrfs-progs) # higher prio than builtin btrfs-progs when btrfs is enabled
      inputs.nm2nix.packages.${pkgs.stdenv.hostPlatform.system}.default
      #inputs.pinix.packages.${pkgs.stdenv.hostPlatform.system}.default
      dos2unix
      openssl
      nur.repos.mio.cb
      catimg
      psmisc
      lz4
      android-tools
      difftastic
      nix-output-monitor
      lsof
      imagemagick
      waypipe
      ripgrep
      # unfree:
      p7zip-rar
    ])
    ++ [
      script.upgrade
      script.switch
      script.boot
      script.upboot
    ]
    ++ lib.optionals config.mio_aria2 (
      map hardenedPkg [
        nur.repos.mio.aria2
        nur.repos.mio.aria2-wrapped
      ]
    )
    ++ lib.optionals (!config.mio_aria2) (map hardenedPkg [ aria2 ])
    ++ (map cleanPkg [
      ego
      #  they might execute some binary that doesn't like the grapheneos malloc
      program.nodejs
      program.pnpm
    ])
    ++ lib.optionals config.services.desktopManager.plasma6.enable (
      with pkgs.kdePackages;
      map (pkg: hardenedPkg (lib.hiPrio pkg)) [
        # Note: some packages are broken with hardenedPkg. Only list those known to work here.
        # https://github.com/NixOS/nixpkgs/blob/74a6c30612152d8b186f55f9c8b998f978afd6eb/nixos/modules/services/desktop-managers/plasma6.nix#L70-L218
        kwalletmanager
        kwin
        plasma-systemmonitor
        systemsettings
        # optionalPackages
        ark
        elisa
        gwenview
        okular
        dolphin
        spectacle
      ]
    );

  programs.nano.package = lib.mkDefault (cleanPkg pkgs.nano);
  programs.nano.enable = true;

  programs.fuse.enable = true;
  programs.fuse.userAllowOther = true;

  # https://zhuanlan.zhihu.com/p/671801498
  fonts = {
    packages = with pkgs; [
      #nerd-fonts.ubuntu-mono
      #nerd-fonts.jetbrains-mono
      #noto-fonts
      #nerd-fonts.noto
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      nerd-fonts.fira-code
      #nerd-fonts.sauce-code-pro
      #source-code-pro
      # flatpak com.baidu.NetDisk https://tieba.baidu.com/p/8889052162 https://github.com/qier222/YesPlayMusic/issues/2121
      source-han-sans
      #source-han-mono
      source-han-serif
      wqy_zenhei
      wqy_microhei
    ];
    fontconfig = {
      antialias = true;
      hinting.enable = true;
      defaultFonts = {
        emoji = [ "Noto Color Emoji" ];
        monospace = [ "FiraCode Nerd Font" ];
        sansSerif = [ "Noto Sans CJK SC" ];
        serif = [ "Noto Serif CJK SC" ];
      };
    };
  };

  programs.tmux.package = lib.mkDefault (cleanPkg pkgs.tmux);
  programs.tmux.enable = true;
  programs.tmux.extraConfig = ''
    set -g mouse on
  '';

  # https://github.com/nix-community/home-manager/blob/9e3a33c0bcbc25619e540b9dfea372282f8a9740/modules/programs/zsh/default.nix#L166
  #environment.pathsToLink = [ "/share/zsh" ];

  programs.fish.enable = true;
  programs.fish.useBabelfish = true;

  documentation.enable = false;
  # https://discourse.nixos.org/t/solve-slow-man-cache-the-content-addressed-way-but-not-ca-derivation/58463/2
  documentation.man.cache.enable = lib.mkOverride (-1) false; # higher proiority than nixos/modules/programs/fish.nix': true

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };

  # https://github.com/EmergentMind/nix-config/blob/9a9fefd9ab5ebbaf9530dafdb6d45b734606f645/hosts/common/core/nixos.nix#L25
  security.sudo.extraConfig = "Defaults timestamp_timeout=120";

  # https://discourse.nixos.org/t/logrotate-config-fails-due-to-missing-group-30000/28501/9
  security.unprivilegedUsernsClone = true;

  # https://saylesss88.github.io/nix/hardening_NixOS.html
  systemd.coredump.enable = false;
  # ➡️ Sets the kernel's resource limit (ulimit -c 0)
  security.pam.loginLimits = [
    {
      domain = "*"; # Applies to all users/sessions
      type = "-"; # Set both soft and hard limits
      item = "core"; # The soft/hard limit item
      value = "0"; # Core dumps size is limited to 0 (effectively disabled)
    }
  ];

  # /nix/store/9m6xh63j8mvragnhra8k7rchwxldcrry-systemd-258.2/share/polkit-1/rules.d/10-systemd-logind-root-ignore-inhibitors.rules.example
  security.polkit.extraConfig = ''
    // SPDX-License-Identifier: MIT-0
    //
    // This config file is installed as part of systemd.
    // It may be freely copied and edited (following the MIT No Attribution license).
    //
    // This example can be enabled by symlinking this file to
    // /etc/polkit-1/rules.d/10-systemd-logind-root-ignore-inhibitors.rules

    // Allow the root user to ignore inhibitors when calling reboot etc.
    polkit.addRule(function(action, subject) {
        if ((action.id == "org.freedesktop.login1.power-off-ignore-inhibit" ||
             action.id == "org.freedesktop.login1.reboot-ignore-inhibit" ||
             action.id == "org.freedesktop.login1.halt-ignore-inhibit" ||
             action.id == "org.freedesktop.login1.suspend-ignore-inhibit" ||
             action.id == "org.freedesktop.login1.hibernate-ignore-inhibit") &&
            subject.user == "root") {

            return polkit.Result.YES;
        }
    });
  '';

  security.sudo.execWheelOnly = lib.mkDefault true;

  # https://www.reddit.com/r/NixOS/comments/1cot084/comment/ngqsyg8/
  systemd.tmpfiles.rules =
    let
      # DETAILS REMOVED
    in
    [
      "f /tmp/vscode-skip-server-requirements-check 0644 root root -"
    ]
  # DETAILS REMOVED
  ;

  #services.flatpak.update.onActivation = true; # maybe need this if we always don't use nixos-rebuild switch - https://github.com/gmodena/nix-flatpak/issues/191
  services.flatpak.uninstallUnmanaged = true;

  services.flatpak.overrides = {
    global = {
      # Force Wayland by default
      Context.sockets = lib.mkIf (!config.services.xserver.enable) [
        "wayland"
        "!x11"
        "!fallback-x11"
      ];
    };
  };

  # DETAILS REMOVED
  /*
    # https://github.com/NixOS/nixpkgs/issues/483867
    systemd.services."polkit-agent-helper@".serviceConfig = {
      PrivateDevices = "no";
      DeviceAllow = [
        "char-mem"
        "char-hidraw"
        "char-video4linux"
      ];
      ProtectHome = "read-only";
    };
  */

  # who changed it from nixpkgs 0726a0ecb6d4e08f6adced58726b95db924cef57 to nixpkgs 1c3fe55ad329cbcb28471bb30f05c9827f724c76 - https://github.com/NixOS/nixpkgs/pull/420889
  # zfs pam fix by chatgpt
  security.pam.services.sddm.rules.auth.zfs_key = {
    enable = config.security.pam.zfs.enable;
    # sddm has: auth substack login
    # Put this immediately after that, in the parent sddm PAM service.
    order = config.security.pam.services.sddm.rules.auth.login.order + 10;
    control = "optional";
    modulePath = "${config.boot.zfs.package}/lib/security/pam_zfs_key.so";
    settings = {
      homes = config.security.pam.zfs.homes;
      mount_recursively = config.security.pam.zfs.mountRecursively;
    };
  };
}
