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
  # https://github.com/Jovian-Experiments/Jovian-NixOS/issues/490#issuecomment-3182129429 -> https://github.com/kahlstrm/nixos-config/commit/bf94ebc812d8c18ce880bcf914c63865fd3f3340
  compatPaths = lib.makeSearchPathOutput "steamcompattool" "" (
    with pkgs;
    [
      pkgs-chaotic.proton-cachyos_x86_64_v3
      pkgs-chaotic.proton-cachyos_x86_64_v4
      pkgs-chaotic.proton-ge-custom
      steam-play-none
    ]
  );
in
{
  imports = [
    # Feature aspects: den.aspects.deck-host.includes (modules/deck.nix)
    inputs.jovian.nixosModules.default
    ./disk-config.nix
  ];
  # DETAILS REMOVED # hardware.facter.reportPath = ./facter.json;
  microarch = "v4";

  zfs_arc_max_mib = 8192;
  security.pam.zfs.enable = true;
  security.pam.zfs.homes = "deck/nixos/safe/encrypted";
  chaotic.zfs-impermanence-on-shutdown.volume = "deck/nixos/local/ephemeral";

  users.mutableUsers = false;
  users.users.root = {
    shell = pkgs.fish;
    hashedPasswordFile = "/persistent/etc/pass-user-root";
  };
  users.users.deck = {
    # DETAILS REMOVED # hashedPasswordFile = "/persistent/etc/pass-user-deck";
    uid = 1000;
    isNormalUser = true;
    extraGroups = commonGroups;
  };
  users.users.user = {
    # DETAILS REMOVED # hashedPasswordFile = "/persistent/etc/pass-user-user";
    uid = 1001;
    isNormalUser = true;
    extraGroups = extraAdminGroups;
  };
  users.users.zdmin = {
    # DETAILS REMOVED # hashedPasswordFile = "/persistent/etc/pass-user-user";
    uid = 1002;
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = extraAdminGroups;
  };

  services.displayManager.autoLogin.user = "deck";

  # https://nixos.wiki/wiki/Jovian_NixOS
  jovian.hardware.has.amd.gpu = true;
  services.desktopManager.plasma6.enable = true;
  # https://github.com/Jovian-Experiments/Jovian-NixOS/blob/development/docs/steam.md?plain=1
  jovian.steam = {
    enable = true;
    autoStart = config.system.nixos.tags == [ ];
    user = "deck";
    desktopSession = lib.mkIf config.jovian.steam.autoStart "plasma";
  };
  # https://github.com/chaotic-cx/nyx/blob/6b903a4dce0df00bc715da071f6c20a2c5060915/README.md?plain=1#L334
  jovian.devices.steamdeck.enable = true;
  # autoUpdate seems to cause issues when rebooting
  #jovian.devices.steamdeck.autoUpdate = true;
  #jovian.devices.steamdeck.enableFwupdBiosUpdates = true;
  # https://github.com/Jovian-Experiments/Jovian-NixOS/blob/development/docs/in-depth/decky-loader.md
  #  $ touch ~/.steam/steam/.cef-enable-remote-debugging
  jovian.decky-loader = {
    enable = true;
  };
  jovian.steamos.enableSysctlConfig = true;
  jovian.steamos.enableProductSerialAccess = true;
  jovian.steamos.enableEarlyOOM = true;

  programs.steam = {
    package = pkgs.steam.override {
      extraEnv = {
        # https://github.com/keenanweaver/nix-config/blob/78fa3cb210be76a64241def0e788edfdab03df6e/modules/apps/steam/default.nix#L82
        PROTON_ENABLE_WAYLAND = true;
        PROTON_ENABLE_HDR = true;
        PROTON_USE_WOW64 = true;
      };
    };
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
    fontPackages = with pkgs; [
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      source-han-sans
      source-han-serif
      wqy_zenhei
      wqy_microhei
    ];
  };

  # https://github.com/Jovian-Experiments/Jovian-NixOS/issues/490#issuecomment-3182129429 -> https://github.com/kahlstrm/nixos-config/commit/bf94ebc812d8c18ce880bcf914c63865fd3f3340
  environment.sessionVariables.STEAM_EXTRA_COMPAT_TOOLS_PATHS = compatPaths;

  jovian.steamos.enableBluetoothConfig = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true; # Show battery charge of Bluetooth devices
      };
    };
  };

  jovian.steamos.enableDefaultCmdlineConfig = true;
  jovian.steamos.enableZram = false;
  #boot.kernelPackages = pkgs.jovian-chaotic.linuxPackages_jovian;
  boot.kernelPackages = pkgs.linuxPackages_jovian;
  #boot.kernelPackages = pkgs-unstable.linuxPackages_cachyos-lto;
  #boot.zfs.package = pkgs.zfs_cachyos;
  # https://wiki.nixos.org/wiki/Swap#Zswap_swap_cache
  zramSwap.enable = false;
  boot.kernelParams = [
    "nohibernate"
    #"amd_pstate=active" # https://nixos.wiki/wiki/Jovian_NixOS
  ];

  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = 5;
    systemd-boot.consoleMode = "5"; # https://github.com/NixOS/nixpkgs/pull/340597
    efi.canTouchEfiVariables = true;
  };

  # neededForBoot flag is not settable from disko
  fileSystems = {
    "/nix".neededForBoot = true;
    "/home".neededForBoot = true;
    "/var/log".neededForBoot = true;
    "/persistent".neededForBoot = true;
  };
  networking = {
    hostName = "deck"; # Define your hostname.
    # Generate host ID from hostname
    # DETAILS REMOVED # hostId = builtins.substring 0 8 (builtins.hashString "sha256" config.networking.hostName);
    # Configure network connections interactively with nmcli or nmtui.
    networkmanager.enable = true;
    networkmanager.wifi.backend = "iwd";
    networkmanager.wifi.powersave = true;
    useNetworkd = true; # break infinite recursion
  };
  systemd.network.wait-online.enable = false;

  services.touchegg.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  #musnix.enable = true; # has conflicts with our limit settings for wine esync!
  # https://wiki.nixos.org/wiki/PipeWire
  services.pipewire = {
    # If you want to use JACK applications, uncomment the following
    jack.enable = true;
  };
  services.pipewire.enable = true;

  services.openssh.enable = true;
  services.openssh.openFirewall = true;
  services.openssh.settings.PasswordAuthentication = false;
  services.openssh.settings.X11Forwarding = true;

  networking.nftables.enable = true;

  services.tailscale.enable = true;
  services.tailscale.useRoutingFeatures = "both";

  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "25.11"; # Did you read the comment?

  services.flatpak = {
    enable = true;
    uninstallUnmanaged = true;
    packages = [
      #"com.google.Chrome"
      # followings are built from source by flathub:
      "org.prismlauncher.PrismLauncher"
    ];
    remotes = lib.mkOptionDefault [
      {
        name = "flathub-beta";
        location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
      }
    ];
  };

  # https://github.com/lutris/docs/blob/master/HowToEsync.md
  environment.etc."security/limits.conf".text = ''
    deck soft nofile 524288
    deck hard nofile 524288
  '';
  security.pam.loginLimits = [
    {
      domain = "deck";
      type = "soft";
      item = "nofile";
      value = "524288";
    }
    {
      domain = "deck";
      type = "hard";
      item = "nofile";
      value = "524288";
    }
  ];
}
