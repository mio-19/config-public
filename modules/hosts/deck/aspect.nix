{ den, lib, ... }:
{
  # Named deck-host (not deck) so user account `deck` on other hosts does not
  # resolve den.aspects.deck via lookupAspect.
  den.aspects.deck-host = {
    includes = [
      den.aspects.common
      den.batteries.hostname
      den.aspects.persistent
      den.aspects.privacy
      den.aspects.careless
      den.aspects.boot
      #(den.aspects.v3opt)
      den.aspects.wheel-nopasswd
      den.aspects.zfs
      den.aspects.baremetal
      den.aspects.games
      #(den.aspects.desktop-specialisation) # never use
      den.aspects.zswap
      den.aspects.rocm
      den.aspects.scx
    ];

    provides.to-users =
      { user, ... }:
      {
        homeManager._module.args.enable-fcitx = false;
        homeManager.home.stateVersion = lib.mkDefault "25.11";
      };
  };

  den.hosts.x86_64-linux.deck = {
    hostName = "deck";
    aspect = den.aspects.deck-host;
    users.user.classes = [ "homeManager" ];
    users.user.nixosZshUser.enable = true;
    users.deck.classes = [ "homeManager" ];
    users.deck.nixosZshUser.enable = true;
    users.zdmin = {
      classes = [ "homeManager" ];
      aspect = den.aspects.zdmin;
    };
  };
}
