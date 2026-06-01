# sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount  ~/Documents/config/nixos/ipc2/disk-v3.nix
# NOTE: CONSIDER --root-mountpoint IF THE SYSTEM HAS SOMETHING UNDER /mnt
{ lib, ... }:
{
  disko.devices = {
    disk = {
      ipcv3 = {
        type = "disk";
        device = "/dev/sda-CHANGE-ME-TO-YOUR-DISK";
        content = {
          type = "gpt";
          partitions = {
            # first letter to specify order
            ESP = {
              size = "768M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            aZfs = {
              size = "256G"; # later increased size using parted and `sudo zpool online -e ipcv3 <device>`
              content = {
                type = "zfs";
                pool = "ipcv3";
              };
            };
            # remaining space: for ntfs
          };
        };
      };
    };
    zpool = {
      ipcv3 = {
        type = "zpool";
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
        postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^ipcv3@blank$' || zfs snapshot ipcv3@blank";
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
              zfs snapshot ipcv3/nixos/local/ephemeral@blank
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
