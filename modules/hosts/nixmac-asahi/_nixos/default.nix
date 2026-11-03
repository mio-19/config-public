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
    inputs.nixos-apple-silicon.nixosModules.apple-silicon-support
    ./disk.nix
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

  hardware.asahi.enable = true;
  # Load non-redistributable firmware from the Asahi ESP at boot.
  hardware.asahi.peripheralFirmwareDirectory = null;

  nixpkgs.config.allowUnfree = true;

  # desktop-full enables OnlyOffice, whose binary is available only on x86 Linux.
  # Keep the shared LibreOffice package on this ARM host.
  programs.onlyoffice.enable = lib.mkForce false;

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
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [
      "subvol=/root"
      "nofail"
      "compress-force=zstd"
      "noatime"
    ];
  };
  # From https://github.com/nix-community/impermanence/blob/4b3e914cdf97a5b536a889e939fb2fd2b043a170/README.org
  # Run after LUKS unlock, before mounting /; systemd replaces postResumeCommands.
  boot.initrd.systemd.services.rollback-root = {
    description = "Roll back the ephemeral Btrfs root";
    requiredBy = [ "sysroot.mount" ];
    before = [ "sysroot.mount" ];
    after = [
      "systemd-modules-load.service"
      "dev-mapper-cryptroot.device"
    ];
    requires = [
      "systemd-modules-load.service"
      "dev-mapper-cryptroot.device"
    ];
    unitConfig.DefaultDependencies = false;
    serviceConfig.Type = "oneshot";
    path = with pkgs; [
      btrfs-progs
      coreutils
      findutils
      gawk
      util-linux
    ];
    script = ''
      set -eu
      mkdir -p /btrfs_tmp
      mount -t btrfs -o subvolid=5 /dev/mapper/cryptroot /btrfs_tmp
      trap 'umount /btrfs_tmp' EXIT
      mkdir -p /btrfs_tmp/old_roots
      if [[ -e /btrfs_tmp/root ]]; then
          # Use the archive time, with subsecond precision, to avoid name collisions.
          timestamp=$(date "+%Y-%m-%d_%H:%M:%S.%N")
          mv -T /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
          # Retain each archived root for 30 days after archiving.
          touch "/btrfs_tmp/old_roots/$timestamp"
      fi

      delete_subvolume_recursively() {
          local subvolume="$1"
          local child
          while IFS= read -r child; do
              if [[ -e "/btrfs_tmp/$child" ]]; then
                  delete_subvolume_recursively "/btrfs_tmp/$child"
              fi
          done < <(btrfs subvolume list -o "$subvolume" | cut -f 9- -d ' ')
          btrfs subvolume delete "$subvolume"
      }

      while IFS= read -r old_root; do
          delete_subvolume_recursively "$old_root"
      done < <(find /btrfs_tmp/old_roots/ -mindepth 1 -maxdepth 1 -mtime +30)
      btrfs subvolume create /btrfs_tmp/root
    '';
  };

  # Previously the VM selected linux-asahi directly (or pkgs.linuxPackages_6_16)
  # and disabled hardware.deviceTree. The Asahi module now manages both.
  #boot.kernelPackages = pkgs.linuxPackages_6_16;
  boot.kernelParams = [
    "nohibernate" # Current rollback command will break hibernate
  ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = false;
  };

  fileSystems = {
    "/home".neededForBoot = true;
    "/var/log".neededForBoot = true;
    "/nix".neededForBoot = true;
    "/.swapvol".neededForBoot = true;
    "/persistent".neededForBoot = true;
  };
  networking = {
    hostName = "nixmac-asahi"; # Define your hostname.
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
