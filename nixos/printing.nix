{
  config,
  inputs,
  lib,
  pkgs,
  _include,
  ...
}@args:
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
