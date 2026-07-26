{ den, ... }:
{
  den.aspects.grub-pointer = {
    description = "GRUB mouse and touchscreen support (REQUIRES a1ive PATCHSET)";
    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        boot.loader.grub = {
          # WARNING: This configuration DOES NOT WORK with standard GNU GRUB.
          # It explicitly requires a GRUB build compiled with the `a1ive` patchset
          # (often found in projects like agFM or grub2-androidx86).
          # If your GRUB package (e.g. `mio.grub2_patched`) does not include the
          # a1ive patches, attempting to load `efi_mouse` will crash the bootloader.

          # The system must boot in UEFI mode so GRUB can use EFI pointer protocols.
          # A graphical theme utilizing gfxmenu is required.
          # Make sure to set gfxmodeEfi to your native resolution for proper touch mapping.

          extraConfig = ''
            insmod gfxterm
            insmod gfxmenu
            insmod usb
            insmod usbms
            insmod efi_mouse

            terminal_input --append mouse
            terminal_output gfxterm
          '';
        };
      };
  };
}
