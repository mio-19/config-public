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
    ./keepBootedSystemEntry.nix
    inputs.grub2-themes.nixosModules.default
    ./wifi.nix
    ./common.nix
    ./stockhm.nix
    inputs.disko.nixosModules.disko
  ];

  # does this break waydroid?
  /*
    system.nixos-init.enable = true;
    system.etc.overlay.enable = true;
    services.userborn.enable = true;
    # https://discourse.nixos.org/t/migrating-to-boot-initrd-systemd-and-debugging-stage-1-systemd-services/54444
    # https://blog.decent.id/post/nixos-systemd-initrd/
    boot.initrd.systemd.enable = true;
  */

  boot.supportedFilesystems = [
    "btrfs"
    "exfat"
    "ntfs-3g"
  ];

  # https://search.nixos.org/packages
  environment.systemPackages = with pkgs; [
    lm_sensors
    cryptsetup
    parted
    dmidecode
  ];

  networking = {
    # Configure network connections interactively with nmcli or nmtui.
    networkmanager.enable = true;
    networkmanager.wifi.backend = lib.mkDefault "iwd";
    useNetworkd = true; # break infinite recursion
  };
  systemd.network.wait-online.enable = false;
  # systemd.services.NetworkManager-wait-online.enable = false;

  # https://github.com/lutris/docs/blob/master/HowToEsync.md
  # https://discourse.nixos.org/t/unable-to-fix-too-many-open-files-error/27094/7
  systemd.settings.Manager = {
    DefaultLimitNOFILE = 1048576;
  };
  # https://discourse.nixos.org/t/unable-to-fix-too-many-open-files-error/27094/10
  # conflict with musnix : musnix is 99999 but we want more
  security.pam.loginLimits = [
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "1048576";
    }
    {
      domain = "*";
      type = "hard";
      item = "nofile";
      value = "1048576";
    }
  ];

  boot.tmp.cleanOnBoot = true;

  # https://github.com/NixOS/nixpkgs/blob/b103220c1aabc21529a02a8b52106d451d10cef6/nixos/modules/profiles/hardened.nix
  # TODO: some flag cause razer to have no wifi
  /*
    boot.kernelParams = [
      # Enable page allocator randomization
      "page_alloc.shuffle=1"

      # Disable debugfs
      "debugfs=off"
    ]
    ++ lib.optionals hardened-slow [
      # Don't merge slabs
      "slab_nomerge"

      # Overwrite free'd pages
      "page_poison=1"
    ];
  */

  # https://saylesss88.github.io/nix/hardening_NixOS.html#replace-timesyncd-with-a-chron-job-that-enables-network-time-security-nts
  # https://gist.github.com/jauderho/2ad0d441760fc5ed69d8d4e2d6b35f8d -> https://github.com/jauderho/nts-servers
  services.timesyncd.enable = false;
  services.chrony = {
    enable = true;
    enableNTS = true;
    servers = [
      # https://github.com/GrapheneOS/infrastructure/blob/dff07fbb3dc4aecaf4f57c42277627bd6b4fbf2e/etc/chrony.conf#L1-L6
      "time.cloudflare.com"
      "ntppool1.time.nl"
      "nts.netnod.se"
      "ptbtime1.ptb.de"
      "time.dfm.dk"
      "time.cifelli.xyz"
    ];
  };
  networking.timeServers = config.services.chrony.servers;
}
