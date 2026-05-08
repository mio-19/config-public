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
    ./hardened.nix # does this break waydroid?
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
    "ntfs"
    "exfat"
  ]
  ++ lib.optionals (!(builtins.any (tag: tag == "rc") config.system.nixos.tags)) [
    # also need to check if kernel is too old. not supported on kernel 6.12 lts
    #"bcachefs"
  ];

  # https://search.nixos.org/packages
  environment.systemPackages = with pkgs; [
    lm_sensors
    cryptsetup
    parted
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
  systemd.user.extraConfig = "DefaultLimitNOFILE=1048576";
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
  # DETAILS REMOVED
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

  # polkit-127 testing failed in WSL. don't include this for WSL.
  # https://github.com/NixOS/nixpkgs/issues/483867
  # revert https://github.com/NixOS/nixpkgs/commit/92848a8fa03d4f0cee162876e570eac934b8a769 in staging https://github.com/NixOS/nixpkgs/commit/701f311414c3fecbddf6d9c4457d87e467e760ed#diff-25e457105e4437a83fba5ddcaa0bd524a26c0fb6247369c89a3da38e7f51bcea
  # DETAILS REMOVED
  security.wrappers.polkit-agent-helper-1 = lib.mkIf config.security.polkit.enable {
    setuid = true;
    owner = "root";
    group = "root";
    source = "${config.security.polkit.package.out}/lib/polkit-1/polkit-agent-helper-1";
  };
  systemd.sockets."polkit-agent-helper".wantedBy = lib.mkIf config.security.polkit.enable (
    lib.mkForce [ ]
  );
  security.polkit.package = inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.polkit126; # pkgs-pin.polkit;

  # Dirty Frag Mitigation
  boot.blacklistedKernelModules = [
    "esp4"
    "esp6"
    "rxrpc"
  ];
  boot.extraModprobeConfig = ''
    install esp4 /run/current-system/sw/bin/false
    install esp6 /run/current-system/sw/bin/false
    install rxrpc /run/current-system/sw/bin/false
  '';
}
