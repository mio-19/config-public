# Bare-metal KDE baseline: SDDM or plasma-login-manager (den.aspects.desktop-baremetal-kde-basic).
{ den, ... }: {
  den.aspects.desktop-baremetal-kde-basic = {
    description = "Bare-metal KDE baseline with SDDM or plasma-login-manager";
    nixos =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        system,
        ...
      }:
      import ./_desktop-baremetal-kde-basic/default.nix args;
  };
}
