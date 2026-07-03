{ den, lib, ... }:
{
  den.aspects.ipc = {
    includes = [
      den.aspects.common
      den.batteries.hostname
      den.aspects.persistent
    ];

    provides.to-users =
      { user, ... }:
      {
        homeManager._module.args.enable-fcitx = true;
        homeManager.home.stateVersion = lib.mkDefault "25.11";
        homeManager.imports = lib.optional (user.name == "user") ../nixos/home-user.nix;
        # DETAILS REMOVED
      };
  };
}
