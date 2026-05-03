{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:
{
  boot.loader.grub = {
    extraEntries = ''
      if [ "$grub_platform" = "efi" ]; then
        menuentry "BIOS - Firmware Settings" {
          fwsetup
        }
      fi
    '';
  };
}
