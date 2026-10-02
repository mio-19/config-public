{
  config,
  inputs,
  lib,
  pkgs,
  system,
  ...
}@args:
{
  microarch = "intel-ultra-xe";
  imports = [
    # https://wiki.nixos.org/wiki/Hardware/Framework/Laptop_13#AMD_AI_300_Series
    inputs.nixos-hardware.nixosModules.framework-intel-core-ultra-series3
    ./windows-vm.nix
  ];
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;
  boot.kernelParams = [
    "intel_pstate=active"
    "pcie_aspm=force"
    "snd_hda_intel.power_save=1"
  ];
  powerManagement.powertop.enable = true;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vpl-gpu-rt
    ];
  };
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };

  #services.lact.enable = true;

  # https://github.com/NixOS/nixos-hardware/tree/master/framework
  services.fwupd.enable = true;

}
