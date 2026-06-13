{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:
{
  specialisation.rc = {
    configuration = {
      system.nixos.tags = [ "rc" ];
      boot.kernelPackages = lib.mkForce pkgs.linuxPackages_cachyos-rc;
      boot.zfs.package = lib.mkForce pkgs.zfs_cachyos;
      virtualisation.virtualbox.host.enable = lib.mkForce false;
      /*
        #hardware.nvidia.open = lib.mkForce false; # nvidia-open compilation failed.
        #hardware.nvidia.package = lib.mkForce config.boot.kernelPackages.nvidiaPackages.beta;
        # nvidia doesn't compile
        services.xserver.videoDrivers = lib.mkForce [
          "modesetting"
          "fbdev"
        ];
        hardware.xone.enable = lib.mkForce false; # compile error with 6.18-rc1
      */
    };
  };
}
