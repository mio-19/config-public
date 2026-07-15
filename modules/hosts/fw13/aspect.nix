{ den, lib, ... }:
{
  den.aspects.fw13 = {
    includes = [
      den.aspects.common
      den.batteries.hostname
      den.aspects.persistent
      den.aspects.bios
      #(den.aspects.desktop-specialisation-cosmic)
      den.aspects.hidpi
      #(den.aspects.desktop-specialisation-pantheon) # broken: lightdm didn't show up
      den.aspects.keep
      den.aspects.music
      den.aspects.privacy
      den.aspects.careless
      den.aspects.boot
      #(den.aspects.xrdp)
      #(den.aspects.v3opt) # needs too many time to compile
      #(den.aspects.wheel-nopasswd)
      #(den.aspects.safe)
      den.aspects.zfs
      den.aspects.cachy_kernel
      den.aspects.rocm
      den.aspects.desktop-baremetal-kde
      den.aspects.zswap
      den.aspects.games
      den.aspects.games-extra
      den.aspects.extra
      den.aspects.desktopextra
      den.aspects.desktop-offline
      #(den.aspects.genai) # too much time to compile
      den.aspects.devcommand
      den.aspects.scx
      den.aspects.emulated-arm
      den.aspects.harmonia_lan_only_not_public_ip
      #(den.aspects.rc)
    ];

    provides.to-users =
      { user, ... }:
      {
        homeManager._module.args.enable-fcitx = true;
        homeManager.home.stateVersion = lib.mkDefault "25.11";
        homeManager.programs.plasma = {
          enable = true;
          powerdevil.AC = {
            powerButtonAction = lib.mkForce "sleep";
            autoSuspend.action = lib.mkForce "sleep";
            whenLaptopLidClosed = lib.mkForce "sleep";
          };
        };
        # DETAILS REMOVED
      };
  };
}
