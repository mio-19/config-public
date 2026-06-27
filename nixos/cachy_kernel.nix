{
  config,
  pkgs,
  lib,
  _include,
  ...
}:
with _include;
let
  cachyKernel =
    if config.virtualisation.vmware.host.enable then
      pkgs-chaotic.linuxPackages_cachyos-gcc
    else if
      config.microarch == "zen4" && !config.workaround_i_dont_know_kernel_nvidia_refer_problem
    then
      /*
        pkgs-chaotic.linuxPackages_cachyos.cachyOverride {
          cachyVars = pkgs.linuxPackages_cachyos.kernel.cachyConfig.cachyVars // {
            "_processor_opt" = "ZEN4";
          };
        }
      */
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
}
