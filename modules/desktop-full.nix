# Full desktop packages and apps (den.aspects.desktop-full).
{ den, ... }: {
  den.aspects.desktop-full = {
    description = "Full desktop packages, firejail, flatpak, and chromium";
    nixos =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        system,
        ...
      }:
      import ./_desktop-full/default.nix args;
  };
}
