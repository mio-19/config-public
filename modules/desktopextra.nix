# Extra desktop packages and apps (den.aspects.desktopextra).
{ den, ... }:
{
  den.aspects.desktopextra = {
    description = "Extra desktop packages, firejail wrappers, and wireshark";
    nixos =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        system,
        ...
      }:
      import ./_desktopextra/default.nix args;
    # darwin reuses only the cross-platform apps shared with the NixOS desktopextra
    # (see modules/_desktopextra/shared-apps.nix). The firejail/wireshark and other
    # Linux-only bits stay in the nixos branch.
    darwin =
      args@{
        inputs,
        pkgs,
        ...
      }:
      let
        sharedApps = import ./_desktopextra/shared-apps.nix { inherit pkgs inputs; };
      in
      {
        environment.systemPackages = sharedApps.hardened;
      };
  };
}
