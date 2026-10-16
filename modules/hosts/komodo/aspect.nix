{ den, lib, ... }:
{
  den.aspects.komodo = {
    includes = [
      den.aspects.common
      den.batteries.hostname
    ];

    provides.to-users =
      { user, ... }:
      {
        homeManager._module.args.enable-fcitx = false;
        homeManager.home.stateVersion = lib.mkDefault "25.11";
      };
  };
}
