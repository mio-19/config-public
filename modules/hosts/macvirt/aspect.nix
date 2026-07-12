{ den, lib, ... }:
{
  den.aspects.macvirt = {
    includes = [
      den.aspects.common
      den.batteries.hostname
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
