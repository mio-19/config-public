{
  config,
  lib,
  pkgs,
  ...
}:
let
  pool = "razer";
in
{
  # Upstream NixBSD PAM assertion compatibility
  options.boot.zfs.enabled = lib.mkOption {
    type = lib.types.bool;
    default = config.boot.zfs.enable;
  };
  options.boot.zfs.enableUnstable = lib.mkOption {
    type = lib.types.bool;
    default = false;
  };

  config = {
    nixpkgs.hostPlatform = "x86_64-freebsd";
    nixpkgs.config.allowUnsupportedSystem = true;
    nixpkgs.overlays = [
      (final: prev: {
        sdnotify-wrapper = prev.s6;
      })
    ];
    # Bootloader & Loader Configuration
    boot.loader.stand-freebsd.enable = true;
    boot.loader.stand-freebsd.configurationLimit = 10;
    boot.kernelEnvironment = {
      "kern.vty" = "vt";
      "hw.amdgpu.dc" = "1";
      "compat.linuxkpi.skb.mem_limit" = "1";
      "vfs.zfs.arc_max" = "${toString (70000 * 1024 * 1024)}";
    };

    # ZFS Storage (reusing pool "razer" from Linux setup)
    boot.zfs.enable = true;
    networking.hostName = "fw13";
    networking.hostId = builtins.substring 0 8 (
      builtins.hashString "sha256" config.networking.hostName
    );

    # Persistent Root (no ephemeral/impermanence)
    fileSystems."/" = {
      device = "${pool}/nixbsd/root";
      fsType = "zfs";
    };

    # Shared /nix store with Linux
    fileSystems."/nix" = {
      device = "${pool}/nixos/local/nix";
      fsType = "zfs";
      options = [ "noatime" ];
    };

    # Shared unencrypted home
    fileSystems."/home" = {
      device = "${pool}/nixos/safe/home";
      fsType = "zfs";
    };

    # Shared persistent dataset
    fileSystems."/persistent" = {
      device = "${pool}/nixos/safe/persistent";
      fsType = "zfs";
      options = [ "noatime" ];
    };

    # Shared EFI System Partition
    fileSystems."/boot" = {
      device = "/dev/gpt/ESP";
      fsType = "msdosfs";
    };

    # Shared encrypted home via PAM ZFS (unlocks ${pool}/nixos/safe/encrypted/${user} on login)
    security.pam.zfs.enable = true;
    security.pam.zfs.homes = "${pool}/nixos/safe/encrypted";

    services.zfs.trim.enable = true;

    # Framework Laptop 13 AMD Ryzen 7040 hardware drivers
    boot.kernelModules = [
      "amdgpu"
      "snd_hda"
      "iichid"
      "amdtemp"
      "acpi_video"
    ];

    hardware.opengl = {
      enable = true;
      driSupport = true;
    };

    nixpkgs.config.allowUnfreePredicate =
      pkg: ((pkg.meta or { }).sourceProvenance or [ ]) == [ lib.sourceTypes.binaryFirmware ];

    # Framework Touchpad (PIXA)
    services.xserver.libinput = {
      enable = true;
      touchpad = {
        tapping = true;
        naturalScrolling = true;
        accelSpeed = "0.2";
      };
    };

    # Networking & Services
    networking.dhcpcd.wait = "background";
    services.sshd.enable = true;
    services.dbus.enable = true;

    services.xserver = {
      enable = true;
      displayManager.lightdm.enable = true;
      desktopManager.xfce.enable = true;
      exportConfiguration = true;
    };

    # Users
    users.users.root = {
      shell = pkgs.fish;
    };
    users.users.user = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "video"
        "operator"
      ];
      shell = pkgs.fish;
    };
  };
}
