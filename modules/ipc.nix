{ den, lib, ... }: {
  den.hosts.x86_64-linux.ipc = {
    hostName = "ipc";
    users.user.classes = [ "homeManager" ];
    # DETAILS REMOVED
  };

  den.aspects.ipc = {
    includes = [ den.batteries.hostname ];

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
