{ den, ... }: {
  den.aspects.bios = {
    nixos.boot.loader.grub.extraEntries = ''
      if [ "$grub_platform" = "efi" ]; then
        menuentry "BIOS - Firmware Settings" {
          fwsetup
        }
      fi
    '';
  };
}
