{ den, ... }:
{
  den.aspects.cachy_kernel = {
    description = "CachyOS kernel packages (chaotic) with zen4/vmware variants";
    nixos =
      args@{
        config,
        pkgs,
        lib,
        ...
      }:
      let
        _include = args._include or (import ../nixos/include.nix args);
      in
      with _include;
      {
        options = {
          workaround_i_dont_know_kernel_nvidia_refer_problem = lib.mkOption {
            type = lib.types.enum [
              false
              "'"
              "no-zen4"
              "pkgs.zen4"
              "pkgs.no-zen4"
              "pin"
              "nixpkgs"
            ];
            default = false;
            description = "I don't know why it does not or does work";
          };
        };
        config = {
          boot.kernelPackages =
            if
              config.virtualisation.vmware.host.enable
              || builtins.hasAttr "bcachefs" config.boot.supportedFilesystems
            then
              pkgs-chaotic.linuxPackages_cachyos-gcc
            else if config.microarch == "zen4" then
              (
                if config.workaround_i_dont_know_kernel_nvidia_refer_problem == "no-zen4" then
                  pkgs-chaotic.linuxPackages_cachyos
                else if config.workaround_i_dont_know_kernel_nvidia_refer_problem == "'" then
                  pkgs-chaotic'.linuxPackages_cachyos-lto-znver4
                else if config.workaround_i_dont_know_kernel_nvidia_refer_problem == "pin" then
                  pkgs-chaotic_pin.linuxPackages_cachyos-lto-znver4
                else if config.workaround_i_dont_know_kernel_nvidia_refer_problem == "pkgs.zen4" then
                  pkgs.linuxPackages_cachyos-lto-znver4
                else if config.workaround_i_dont_know_kernel_nvidia_refer_problem == "pkgs.no-zen4" then
                  pkgs.linuxPackages_cachyos
                else if config.workaround_i_dont_know_kernel_nvidia_refer_problem == "nixpkgs" then
                  pkgs.linuxPackages_6_18
                else
                  assert config.workaround_i_dont_know_kernel_nvidia_refer_problem == false;
                  pkgs-chaotic.linuxPackages_cachyos-lto-znver4
              )
            else
              pkgs-chaotic.linuxPackages_cachyos;
          boot.zfs.package =
            if
              (
                config.microarch == "zen4" && config.workaround_i_dont_know_kernel_nvidia_refer_problem == "nixpkgs"
              )
            then
              pkgs.zfs
            else
              pkgs.zfs_cachyos;
        };
      };
  };
}
