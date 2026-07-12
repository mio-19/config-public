{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:
let
  filterExistingGroups =
    groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
  commonGroups = [
    "users"
  ]
  ++ filterExistingGroups [
    "networkmanager"
    "audio"
    "jackaudio"
    "adbusers"
  ];
  commonAdminGroups =
    commonGroups
    ++ [
      "wheel"
    ]
    ++ filterExistingGroups [
      "kvm"
      "docker"
      "corectrl"
    ];
in
{

  imports = [
    inputs.disko.nixosModules.disko
    inputs.rosetta-spice.nixosModules.rosetta-spice
    ../../../../nixos-base-den.nix
    ./disk.nix
    (import ../../../../aspect.nix "desktop-full")
    (import ../../../../aspect.nix "alwayson")
  ];
  services.displayManager.sddm.enable = lib.mkDefault true;
  services.displayManager.gdm.enable = lib.mkDefault false;

  nix.settings = {
    extra-substituters = [
      "https://nixos-apple-silicon.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20="
    ];
  };

  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  nixpkgs.config.allowUnfree = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = false;
  };

  users.mutableUsers = false;
  users.users.root = {
    hashedPasswordFile = "/persistent/etc/pass-user-user";
  };
  users.users.user = {
    hashedPasswordFile = "/persistent/etc/pass-user-user";
    uid = 1000;
    isNormalUser = true;
    extraGroups = commonAdminGroups;
  };

  # this is to see what files might need to be persisted
  fileSystems."/.root" = {
    device = "/dev/vda2";
    fsType = "btrfs";
    options = [
      "subvol=/root"
      "nofail"
      "compress-force=zstd"
      "noatime"
    ];
  };
  boot.initrd.systemd.enable = false; # systemd stage 1 does not support `boot.initrd.postResumeCommands`
  # from https://github.com/nix-community/impermanence/blob/4b3e914cdf97a5b536a889e939fb2fd2b043a170/README.org
  boot.initrd.postResumeCommands = lib.mkAfter ''
    mkdir /btrfs_tmp
    mount /dev/vda2 /btrfs_tmp
    if [[ -e /btrfs_tmp/root ]]; then
        mkdir -p /btrfs_tmp/old_roots
        timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
        mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
    fi

    delete_subvolume_recursively() {
        IFS=$'\n'
        for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
            delete_subvolume_recursively "/btrfs_tmp/$i"
        done
        btrfs subvolume delete "$1"
    }

    for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
        delete_subvolume_recursively "$i"
    done

    btrfs subvolume create /btrfs_tmp/root
    umount /btrfs_tmp
  '';

  #boot.kernelPackages = pkgs.linuxPackages_6_16;
  boot.kernelPackages = pkgs.lib.recurseIntoAttrs (
    pkgs.linuxPackagesFor
      inputs.nixos-apple-silicon.packages.${pkgs.stdenv.hostPlatform.system}.linux-asahi
  );
  hardware.deviceTree.enable = false;
  boot.kernelParams = [
    "nohibernate" # Current rollback command will break hibernate
  ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  fileSystems = {
    "/home".neededForBoot = true;
    "/var/log".neededForBoot = true;
    "/nix".neededForBoot = true;
    "/.swapvol".neededForBoot = true;
    "/persistent".neededForBoot = true;
  };
  networking = {
    hostName = "macvirt"; # Define your hostname.
    # Generate host ID from hostname
    # zfs wants hostId to be persistent right?
    hostId = builtins.substring 0 8 (builtins.hashString "sha256" config.networking.hostName);
    # Configure network connections interactively with nmcli or nmtui.
    networkmanager.enable = true;
  };

  systemd.network.wait-online.enable = false;

  virtualisation.docker.enable = true;

  services.openssh.enable = true;
  services.openssh.openFirewall = true;
  services.openssh.settings.PasswordAuthentication = false;
  services.openssh.settings.X11Forwarding = true;

  networking.nftables.enable = true;
  services.tailscale.enable = true;
  services.tailscale.useRoutingFeatures = "both";

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    nur.repos.mio.materialgram_patched # materialgram
  ];
  system.stateVersion = "25.11";
}
