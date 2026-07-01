{ den, lib, ... }: {
  den.hosts.x86_64-linux.fw13 = {
    hostName = "fw13";
    users.user.classes = [ "homeManager" ];
    # DETAILS REMOVED
  };

  den.aspects.fw13 = {
    includes = [ den.batteries.hostname ];

    provides.to-users = { user, ... }: {
      homeManager = {
        _module.args.enable-fcitx = true;
        home.stateVersion = lib.mkDefault "25.11";
        imports =
          lib.optional (user.name == "user") ../nixos/home-user.nix;
          # DETAILS REMOVED
      };
    };
  };
}
