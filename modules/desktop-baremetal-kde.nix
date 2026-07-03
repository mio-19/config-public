# Bare-metal KDE full desktop stack (den.aspects.desktop-baremetal-kde).
{ den, ... }: {
  den.aspects.desktop-baremetal-kde = {
    description = "Bare-metal KDE desktop with full desktop packages";
    nixos =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        system,
        ...
      }:
      import ./_desktop-baremetal-kde/default.nix args;
  };
}
