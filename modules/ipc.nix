{ den, lib, ... }:
{
  den.aspects.ipc = {
    includes = [
      den.aspects.common
      den.batteries.hostname
      den.aspects.persistent
      den.aspects.bios
      den.aspects.hidpi
      den.aspects.keep
      den.aspects.music
      den.aspects.privacy
      den.aspects.careless
      den.aspects.boot
      #(den.aspects.v3opt) # needs too many time to compile
      den.aspects.wheel-nopasswd
      #(den.aspects.safe)
      den.aspects.zfs
      den.aspects.cachy_kernel
      den.aspects.desktop-baremetal-kde
      #(den.aspects.desktop-specialisation)
      den.aspects.zswap
      den.aspects.alwayson
      den.aspects.extra
      den.aspects.extra2
      den.aspects.desktopextra
      #(den.aspects.desktop-offline)
      #(den.aspects.sunshine)
      #(den.aspects.genai) # too much time to compile
      den.aspects.devcommand
      den.aspects.cuda
      den.aspects.games
      #(den.aspects.games-extra)
      den.aspects.persistentkde
      den.aspects.scx
      den.aspects.printing-sharing
      den.aspects.harmonia_lan_only_not_public_ip
    ];

    provides.to-users =
      { user, ... }:
      {
        homeManager._module.args.enable-fcitx = true;
        homeManager.home.stateVersion = lib.mkDefault "25.11";
        # DETAILS REMOVED
      };
  };
}
