# Bare-metal Gnome desktop via GDM (den.aspects.desktop-baremetal-gdm).
{ den, ... }: {
  den.aspects.desktop-baremetal-gdm = {
    description = "Bare-metal desktop with GDM and full desktop packages";
    includes = [
      den.aspects.baremetal
    ];
    nixos =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        system,
        ...
      }:
      import ./_desktop-baremetal-gdm/default.nix args;
  };
}
