{
  config,
  pkgs,
  _include,
  ...
}:
with _include;
let
  cachyKernel =
    if config.microarch == "zen4" then
      pkgs-unstable.linuxPackages_cachyos.cachyOverride {
        cachyVars = pkgs.linuxPackages_cachyos.kernel.cachyConfig.cachyVars // {
          "_processor_opt" = "ZEN4";
        };
      }
    else
      pkgs-unstable.linuxPackages_cachyos;
in
{
  boot.kernelPackages = cachyKernel;
  boot.zfs.package = pkgs.zfs_cachyos;
}
