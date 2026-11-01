# Mount existing partitions only: never repartition an Apple Silicon disk here.
# See README.md for the partition-only LUKS/Btrfs installation steps.
{ ... }:
let
  mountOptions = [
    "compress-force=zstd"
    "noatime"
  ];
  btrfs = subvolume: {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = mountOptions ++ [ "subvol=/${subvolume}" ];
  };
in
{
  boot.initrd.luks.devices.cryptroot.device = "/dev/disk/by-label/NIXMAC_CRYPT";
  fileSystems = {
    "/" = btrfs "root";
    "/home" = btrfs "home";
    "/nix" = btrfs "nix";
    "/persistent" = btrfs "persistent";
    "/var/log" = btrfs "varlog";
    "/.swapvol" = btrfs "swap";
    "/boot" = {
      device = "/dev/disk/by-label/NIXMAC_EFI";
      fsType = "vfat";
      options = [ "umask=0077" ];
    };
  };
  # The swapfile is inside LUKS. Create it with btrfs filesystem mkswapfile.
  swapDevices = [ { device = "/.swapvol/swapfile"; } ];
  services.btrfs.autoScrub.enable = true;
}
