{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:
let
  _include = args._include or import ./include.nix args;
in
with _include;
{
  # https://wiki.nixos.org/wiki/Printing
  config = lib.mkIf novirt {
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    services.printing = {
      enable = true;
    };
  };

}
