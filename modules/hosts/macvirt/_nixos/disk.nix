{ lib, ... }:
let
  mountOptions = [
    "compress-force=zstd"
    "noatime"
  ];
in
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/vda";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              name = "ESP";
              size = "1024M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ]; # Override existing partition
                inherit mountOptions;
                subvolumes = {
                  "/root" = {
                    mountpoint = "/";
                    inherit mountOptions;
                  };
                  "/persistent" = {
                    mountpoint = "/persistent";
                    inherit mountOptions;
                  };
                  "/varlog" = {
                    mountpoint = "/var/log";
                    inherit mountOptions;
                  };
                  "/home" = {
                    mountpoint = "/home";
                    inherit mountOptions;
                  };
                  "/nix" = {
                    mountpoint = "/nix";
                    inherit mountOptions;
                  };
                  "/swap" = {
                    mountpoint = "/.swapvol";
                    inherit mountOptions;
                    swap = {
                      swapfile.size = "8192M";
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
