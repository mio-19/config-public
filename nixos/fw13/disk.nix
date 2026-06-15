# sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount  ~/Documents/config/nixos/fw13/disk.nix
# NOTE: CONSIDER --root-mountpoint IF THE SYSTEM HAS SOMETHING UNDER /mnt
{ lib, ... }:
{
  disko.devices = {
    disk = {
      razer = {
        type = "disk";
        device = "/dev/somewhere"; # DETAILS REMOVED
        content = {
          type = "gpt";
          partitions = {
            # use the first letter to specify order
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
            # later adjusted size with parted and zpool online -e
            aZfs = {
              size = "768G";
              content = {
                type = "zfs";
                pool = "razer";
              };
            };
            # later moved location with gparted
            bSwap = {
              size = "192G";
              content = {
                type = "swap";
                discardPolicy = "both"; # it is fine for our use cases to expose some information that might reduce security of encrypted swap
                randomEncryption = true;
              };
            };
            # DETAILS REMOVED
          };
        };
      };
    };
    zpool = {
      razer = {
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
        postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^razer@blank$' || zfs snapshot razer@blank";
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
              zfs snapshot razer/nixos/local/ephemeral@blank
            '';
          };
          "nixos/local/gnu" = {
            type = "zfs_fs";
            mountpoint = "/gnu";
            options = {
              atime = "off";
              canmount = "noauto";
              mountpoint = "legacy";
            };
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
