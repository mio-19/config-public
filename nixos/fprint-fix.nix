{
  config,
  lib,
  ...
}:

/*
  Rebased on libfprint v1.94.10 from wvhulle/libfprint kill-without-clean:
  - synaptics: retry USB serial reads with exponential backoff
  - fpi-device: USB topology fallback when device_id is missing
  USB reset in synaptics probe is already upstream in 1.94.10.
  https://github.com/NixOS/nixpkgs/issues/432276
  https://codeberg.org/wvhulle/libfprint
*/
lib.mkIf config.services.fprintd.enable {
  nixpkgs.overlays = [
    (final: prev: {
      libfprint = prev.libfprint.overrideAttrs (oldAttrs: {
        patches = (oldAttrs.patches or [ ]) ++ [ ./fprint-fix.patch ];
      });
    })
  ];
}
