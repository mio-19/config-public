# sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount  ~/Documents/config/nixos/ipc2/disk.nix
# NOTE: CONSIDER --root-mountpoint IF THE SYSTEM HAS SOMETHING UNDER /mnt
{ lib, ... }:
{
  disko.devices = {
    disk = {
      zta = {
        type = "disk";
        device = "/dev/disk/by-id/device-moved-please-use-new-path-if-formatting";
        content = {
          type = "gpt";
          partitions = {
            # first letter to specify order
            ESP = {
              size = "1024M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            aZfs = {
              size = "1000G"; # later increased size using parted and `sudo zpool online -e zta <device>`
              content = {
                type = "zfs";
                pool = "zta";
              };
            };
            encryptedSwap = {
              size = "128G";
              content = {
                type = "swap";
                discardPolicy = "both"; # it is fine for our use cases to expose some information that might reduce security of encrypted swap
                randomEncryption = true;
              };
            };
            # remaining space: for ntfs
          };
        };
      };
    };
    zpool = {
      zta = {
        type = "zpool";
        # Workaround: cannot import 'zta': I/O error in disko tests
        options.cachefile = "none";
        rootFsOptions = {
          acltype = "posixacl";
          dnodesize = "auto";
          xattr = "sa";
          normalization = "formD";
          compression = "zstd";
          atime = "off";
          "com.sun:auto-snapshot" = "false";
          canmount = "off";
          copies = "3";
        };
        postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^zta@blank$' || zfs snapshot zta@blank";
        options.ashift = "12";
        options.autotrim = "on";
        datasets = {
          # DETAILS REMOVED
          nixos = {
            type = "zfs_fs";
            options = {
              copies = "1";
              mountpoint = "none";
              canmount = "off";
            };
          };
          "nixos/local" = {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
              canmount = "off";
            };
          };
          "nixos/safe" = {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
              canmount = "off";
            };
          };
          "nixos/local/ephemeral" = {
            type = "zfs_fs";
            mountpoint = "/";
            options = {
              mountpoint = "legacy";
              canmount = "noauto";
              # https://wiki.archlinux.org/title/ZFS - see /tmp
              sync = "disabled";
            };
            postCreateHook = ''
              zfs snapshot zta/nixos/local/ephemeral@blank
            '';
          };
          "nixos/local/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options = {
              atime = "off";
              canmount = "noauto";
              mountpoint = "legacy";
            };
          };
          "nixos/local/varcache" = {
            type = "zfs_fs";
            mountpoint = "/var/cache";
            options = {
              mountpoint = "legacy";
              canmount = "noauto";
            };
          };
          "nixos/local/varlog" = {
            type = "zfs_fs";
            mountpoint = "/var/log";
            options = {
              mountpoint = "legacy";
              canmount = "noauto";
              "com.sun:auto-snapshot" = "true";
            };
          };
          "nixos/safe/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            options = {
              mountpoint = "legacy";
              canmount = "noauto";
              "com.sun:auto-snapshot" = "true";
            };
          };
          "nixos/safe/persistent" = {
            type = "zfs_fs";
            mountpoint = "/persistent";
            options = {
              mountpoint = "legacy";
              canmount = "noauto";
              "com.sun:auto-snapshot" = "true";
            };
          };
          "nixos/safe/encrypted" = {
            type = "zfs_fs";
            options = {
              mountpoint = "/home";
              canmount = "off";
              "com.sun:auto-snapshot" = "true";
            };
          };
          "nixos/safe/encrypted/user" = {
            type = "zfs_fs";
            options = {
              encryption = "aes-256-gcm";
              keyformat = "passphrase";
              canmount = "on";
            };
          };
          # DETAILS REMOVED
        };
      };
    };
  };
}
