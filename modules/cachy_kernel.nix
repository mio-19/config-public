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
      let
        cachyKernel =
          if config.virtualisation.vmware.host.enable then
            pkgs-chaotic.linuxPackages_cachyos-gcc
          else if config.microarch == "zen4" then
            (
              if config.workaround_i_dont_know_kernel_nvidia_refer_problem then
                pkgs-chaotic.linuxPackages_cachyos
              else if workaround_i_dont_know_nvidia_refer_problem_workaround_b then
                pkgs.linuxPackages_cachyos-lto-znver4
              else
                pkgs-chaotic.linuxPackages_cachyos-lto-znver4
            )
              pkgs-chaotic.linuxPackages_cachyos-lto-znver4
          else
            pkgs-chaotic.linuxPackages_cachyos;
      in
      {
        options = {
          workaround_i_dont_know_kernel_nvidia_refer_problem = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "I don't know why it does not or does work";
          };
        };
        config = {
          boot.kernelPackages = cachyKernel;
          boot.zfs.package = pkgs.zfs_cachyos;
        };
      };
  };
}
