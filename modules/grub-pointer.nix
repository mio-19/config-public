{ den, ... }:
{
  den.aspects.grub-pointer = {
    description = "GRUB mouse and touchscreen support (via a1ive patched grub)";
    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        boot.loader.grub = {
          # Note: The system must boot in UEFI mode so GRUB can use EFI pointer protocols.
          # A graphical theme utilizing gfxmenu is required.
          # Make sure to set gfxmodeEfi to your native resolution to ensure proper touch coordinate mapping.
          # WARNING: This requires the a1ive GRUB2 patches (`mio.grub2_patched`) to work, 
          # as standard GRUB does not support `efi_mouse` or `terminal_input mouse`.

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
