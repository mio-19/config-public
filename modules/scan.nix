{ den, ... }:
{
  den.aspects.scan = {
    description = "Scan";
    nixos =
      args@{
        lib,
        pkgs,
        config,
        ...
      }:
      let
        _include = args._include or (import ../nixos/include.nix args);
      in
      with _include;
      {
        # https://nixos.wiki/wiki/Scanners
        hardware.sane.enable = true; # enables support for SANE scanners
        hardware.sane.extraBackends = [ pkgs.sane-airscan ];
        services.udev.packages = [ pkgs.sane-airscan ];
        hardware.sane.disabledDefaultBackends = [ "escl" ];
        services.ipp-usb.enable = true;
        services.avahi.enable = true;
        services.avahi.nssmdns4 = true;
        # nixpkgs' ipp-usb module still sets the obsolete
        # `services.avahi.publish.{enable,userServices}` options, which makes
        # every evaluation print deprecation warnings. Override them away and
        # set the replacement settings they imply instead.
        services.avahi.publish.enable = lib.mkForce null;
        services.avahi.publish.userServices = lib.mkForce null;
        services.avahi.settings.publish = {
          disable-publishing = false;
          disable-user-service-publishing = false;
          publish-addresses = true;
        };
      };
  };
}
