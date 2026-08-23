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
        nixpkgs_kernel = (
          config.microarch == "zen4" && config.workaround_i_dont_know_kernel_nvidia_refer_problem == "nixpkgs"
        );
        zen4 = config.microarch == "zen4";
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
              "pin.no-zen4"
              "nixpkgs"
            ];
            default = false;
            description = "I don't know why it does not or does work";
          };
        };
        config = {
          kernel_rust = nixpkgs_kernel; # https://t.me/chaotic_nyx_sac/32603
          boot.kernelPackages =
            if config.workaround_i_dont_know_kernel_nvidia_refer_problem == "no-zen4" then
              pkgs-chaotic.linuxPackages_cachyos
            else if config.workaround_i_dont_know_kernel_nvidia_refer_problem == "'" then
              assert zen4;
              pkgs-chaotic'.linuxPackages_cachyos-lto-znver4
            else if config.workaround_i_dont_know_kernel_nvidia_refer_problem == "pin" then
              assert zen4;
              pkgs-chaotic_pin.linuxPackages_cachyos-lto-znver4
            else if config.workaround_i_dont_know_kernel_nvidia_refer_problem == "pin.no-zen4" then
              pkgs-chaotic_pin.linuxPackages_cachyos
            else if config.workaround_i_dont_know_kernel_nvidia_refer_problem == "pkgs.zen4" then
              assert zen4;
              pkgs.linuxPackages_cachyos-lto-znver4
            else if config.workaround_i_dont_know_kernel_nvidia_refer_problem == "pkgs.no-zen4" then
              pkgs.linuxPackages_cachyos
            else if nixpkgs_kernel then
              pkgs.linuxPackages_6_18
            else if
              config.virtualisation.vmware.host.enable
              || builtins.hasAttr "bcachefs" config.boot.supportedFilesystems
            then
              pkgs-chaotic.linuxPackages_cachyos-gcc
            else if config.microarch == "zen4" then
              assert config.workaround_i_dont_know_kernel_nvidia_refer_problem == false;
              pkgs-chaotic.linuxPackages_cachyos-lto-znver4
            else
              pkgs-chaotic.linuxPackages_cachyos;
          boot.zfs.package = if nixpkgs_kernel then pkgs.zfs else pkgs.zfs_cachyos;
        };
      };
  };
}
