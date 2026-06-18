{
  config,
  inputs,
  lib,
  pkgs,
  system,
  _include,
  ...
}@args:
let
  pool = "razer";
in
with _include;
{
  imports = [
    # DETAILS REMOVED
    ./fw13.nix
    ../bios.nix
    #../desktop-specialisation-cosmic.nix
    ../hidpi.nix
    #../desktop-specialisation-pantheon.nix # broken: lightdm didn't show up
    #../betterbird.nix # tired of compiling
    #../secure.nix
    ../keep.nix
    ../music.nix
    ../privacy.nix
    ../careless.nix
    ../boot.nix
    #../xrdp.nix
    ../v3.nix
    #../v3opt.nix # needs too many time to compile
    #../wheel-nopasswd.nix
    #../safe.nix
    ../zfs.nix
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    ./disk.nix
    ../persistent.nix
    ../desktop-baremetal-kde.nix
    ../zswap.nix
    ../games.nix
    ../games-extra.nix
    ../extra.nix
    ../desktopextra.nix
    ../desktop-offline.nix
    #../genai.nix # too much time to compile
    ../devcommand.nix
    ../persistentkde.nix
    #../niri
    ../scx.nix
    ../emulated-arm.nix
    ../harmonia_lan_only_not_public_ip.nix
    ../rc.nix
  ];
  nixpkgs.overlays = [
    #inputs.chaotic-pin.overlays.default # try older kernel
  ];
  v4 = true;
  compile_gram = true;
  # DETAILS REMOVED # hardware.facter.reportPath = ./facter.json;

  zfs_arc_max_mib = 70000;
  security.pam.zfs.enable = true;
  security.pam.zfs.homes = "${pool}/nixos/safe/encrypted";
  chaotic.zfs-impermanence-on-shutdown.volume = "${pool}/nixos/local/ephemeral";

  plasma-login-manager_instead = true;

  security.allowSimultaneousMultithreading = true;

  virtualisation.virtualbox.host.enable = true; # once stuck on boot

  boot.zfs.package = pkgs.zfs_cachyos;
  #boot.kernelPackages = pkgs.linuxPackages_cachyos-lto.cachyOverride { mArch = "ZEN4"; }; # gnugrep-x86_64-unknown-linux-gnu-3.12 failed
  boot.kernelPackages = pkgs.linuxPackages_cachyos-gcc;
  #boot.kernelPackages = pkgs.linuxPackages_cachyos-lts.cachyOverride { mArch = "ZEN4"; }; # recent many freezes. why? ssd problem again? 6.19.x kernel issue? 6.18 (lts) also has same problem!
  #boot.kernelPackages = pkgs.linuxPackages_6_12;

  home-manager.users.user = ../home-user.nix;
  # DETAILS REMOVED
  home-manager.extraSpecialArgs = {
    enable-fcitx = true;
  };

  boot.kernel.sysctl = {
    "vm.swappiness" = lib.mkForce 1;
  };

  users.mutableUsers = false;
  users.users.root = {
    shell = pkgs.fish;
    hashedPasswordFile = "/persistent/etc/pass-user-user";
    openssh.authorizedKeys.keys = (import ../../sshkeys.nix);
  };
  # DETAILS REMOVED
  users.users.user = {
    hashedPasswordFile = "/persistent/etc/pass-user-user";
    uid = 1001;
    isNormalUser = true;
    shell = pkgs.zsh;
    ignoreShellProgramCheck = true; # https://github.com/nix-community/home-manager/issues/108#issuecomment-2569823607
    openssh.authorizedKeys.keys = import ../../sshkeys.nix;
    extraGroups = extraAdminGroups;
  };
  # DETAILS REMOVED

  boot.kernelParams = [
    "nohibernate" # no hibernate swap configured
  ];

  boot.loader = {
    timeout = 3;
    grub.enable = true;
    grub.memtest86.enable = true;
    grub.configurationLimit = 5;
    # https://nixos.wiki/wiki/Dual_Booting_NixOS_and_Windows
    grub.useOSProber = true;
    # https://discourse.nixos.org/t/question-about-grub-and-nodev/37867
    grub.device = "nodev";
    # https://www.reddit.com/r/NixOS/comments/klahwf/comment/kt10tt8
    grub.default = "saved";
    #sagrub.default = "'Windows Boot Manager'";
    grub.efiSupport = true;
    efi.canTouchEfiVariables = true;
    grub2-theme = {
      enable = true;
      #splashImage = config.system_background; # unable to see menu clearly with this image
      splashImage = ../black.png;
      theme = "stylish";
      #theme = "whitesur";
      #icon = "whitesur";
      footer = true;
      screen = "4k";
    };
  };

  # neededForBoot flag is not settable from disko
  fileSystems = {
    "/nix".neededForBoot = true;
    "/home".neededForBoot = true;
    "/var/log".neededForBoot = true;
    "/var/cache".neededForBoot = true;
    "/persistent".neededForBoot = true;
  };
  networking.hostName = "fw13";

  networking.firewall.allowedTCPPorts = [ 8080 ]; # temp file share with $ nix run nixpkgs#caddy -- file-server --browse --debug --listen :8080

  #virtualisation.docker.rootless.enable = true;
  #virtualisation.docker.rootless.setSocketVariable = true;

  services.xserver.enable = true;

  # https://search.nixos.org/packages
  environment.systemPackages = with pkgs; ([
    /*
      (
        if
          (
            config.hardware.nvidia.enabled
            && (!(builtins.any (tag: tag == "battery-saver") config.system.nixos.tags))
          )
        then
          mathematica-cuda
        else
          mathematica
      )
    */
    #kdePackages.kamoso # doesn't work with our camera? also snapshot doesn't work too
    #cheese
    guvcview # more smooth than cheese
    webcamoid # smooth and user friendly gui
    ollama
    #pkgs-qtwebengine5.globalprotect-openconnect # does not work
    openconnect
    inputs.globalprotect-openconnect.packages.${pkgs.stdenv.hostPlatform.system}.default
  ]);

  # https://discourse.nixos.org/t/globalprotect-vpn/24014/5
  networking.networkmanager.plugins = with pkgs; [
    networkmanager-openconnect
  ];

  #services.blueman.enable = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true; # Show battery charge of Bluetooth devices
      };
    };
  };

  nix-mineral.enable = false; # this breaks sddm

  #musnix.enable = true; # has conflicts with our limit settings for wine esync!
  # https://wiki.nixos.org/wiki/PipeWire
  services.pipewire = {
    systemWide = true;
    # If you want to use JACK applications, uncomment the following
    jack.enable = true;
  };
  services.pipewire.enable = lib.mkDefault true;
  services.pulseaudio.systemWide = true; # does this break waydroid?

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  #services.guix.enable = true;

  # https://github.com/search?q=programs.captive-browser.enable&type=code
  programs.captive-browser.enable = true;
  # https://github.com/Atemu/nixos-config/blob/ebee2da72f7881bef4166699d2664329901b73d9/hardware/FW16.nix#L83
  programs.captive-browser.interface = "wlan0";

  programs.darling.enable = true;

  services.openssh.enable = true;
  services.openssh.openFirewall = true;
  services.openssh.settings.PasswordAuthentication = false;
  services.openssh.settings.X11Forwarding = true;

  networking.nftables.enable = true;

  services.tailscale.enable = true;
  services.tailscale.useRoutingFeatures = "both";

  system.stateVersion = "25.11";

  # INTERFERE WITH KDE PLASMA's NOTIFICATION PROVIDER
  #services.xserver.desktopManager.xfce.enable = true;
  #services.xserver.desktopManager.xfce.enableWaylandSession = true;

  # documentation.man.cache.enable = true;
  # documentation.enable = true;

  # DETAILS REMOVED
}
