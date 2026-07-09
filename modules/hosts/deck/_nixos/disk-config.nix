{ lib, ... }:
{
  disko.devices = {
    disk = {
      deckssd = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "deck";
              };
            };
            encryptedSwap = {
              size = "16G";
              content = {
                discardPolicy = "both"; # it is fine for our use cases to expose some information that might reduce security of encrypted swap
                type = "swap";
                randomEncryption = true;
              };
            };
          };
        };
      };
    };
    zpool = {
      deck = {
        type = "zpool";
        # Workaround: cannot import 'deck': I/O error in disko tests
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
        };
        postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^deck@blank$' || zfs snapshot deck@blank";
        options.ashift = "12";
        datasets = {
          nixos = {
            type = "zfs_fs";
            options = {
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
              zfs snapshot deck/nixos/local/ephemeral@blank
            '';
          };
          "nixos/local/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options = {
              canmount = "noauto";
              mountpoint = "legacy";
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
          "nixos/safe/persistent" = {
            type = "zfs_fs";
            mountpoint = "/persistent";
            options = {
              mountpoint = "legacy";
              canmount = "noauto";
              "com.sun:auto-snapshot" = "true";
            };
          };
        };
      };
    };
  };
}
