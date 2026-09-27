{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hardware.framework.trackpad-resume-workaround;
in
{
  options.hardware.framework.trackpad-resume-workaround = {
    enable = lib.mkEnableOption "workaround for trackpad not working after suspend on Framework laptops";
  };

  config = lib.mkIf cfg.enable {
    # Workaround for trackpad sometimes not working after resume
    # https://community.frame.work/t/trackpad-not-working-after-sleep/42226/
    powerManagement.resumeCommands = ''
      ${pkgs.kmod}/bin/modprobe -r i2c_hid_acpi || true
      ${pkgs.kmod}/bin/modprobe i2c_hid_acpi
    '';
  };
}
