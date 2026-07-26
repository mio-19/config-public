{ den, ... }:
{
  den.aspects.grub-touch = {
    description = "GRUB mouse and touchscreen support";
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
          # A graphical theme utilizing gfxmenu is required for click/touch detection.
          # Make sure to set gfxmodeEfi to your native resolution to ensure proper touch coordinate mapping.
          # gfxmodeEfi = "1920x1080";

          extraConfig = ''
            insmod gfxterm
            insmod gfxmenu
            insmod usb
            insmod usbms

            terminal_input --append console
            terminal_output gfxterm
          '';
        };
      };
  };
}
