# Full desktop packages and apps (den.aspects.desktop-full).
{ den, ... }:
{
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
    # darwin reuses only the cross-platform apps shared with the NixOS desktop
    # (see modules/_desktop-full/shared-apps.nix). The firejail/flatpak/chromium
    # and other Linux-only bits stay in the nixos branch.
    darwin =
      args@{
        pkgs,
        ...
      }:
      let
        _include = args._include or import ../mac/include.nix args;
        sharedApps = import ./_desktop-full/shared-apps.nix {
          inherit pkgs;
          inherit (_include) progs;
        };
      in
      {
        environment.systemPackages = sharedApps.hardened ++ sharedApps.clean ++ sharedApps.cleanX86;
      };
  };
}
