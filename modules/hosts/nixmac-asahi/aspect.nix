{ den, lib, ... }:
{
  den.aspects.nixmac-asahi = {
    includes = [
      den.aspects.common
      den.aspects.selector4nix
      den.aspects.alwayson
      den.batteries.hostname
      den.aspects.desktop-baremetal-kde
      den.aspects.persistent
    ];

    provides.to-users =
      { user, ... }:
      {
        homeManager._module.args.enable-fcitx = false;
        homeManager.home.stateVersion = lib.mkDefault "25.11";
      };
  };
}
