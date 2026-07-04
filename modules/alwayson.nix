{ den, ... }:
{
  den.aspects.alwayson = {
    description = "Never sleep/suspend: systemd targets off + per-user KDE/GNOME power settings";
    nixos =
      { ... }:
      {
        # https://discourse.nixos.org/t/stop-pc-from-sleep/5757/2
        # Disable the GNOME3/GDM auto-suspend feature that cannot be disabled in GUI!
        # If no user is logged in, the machine will power down after 20 minutes.
        systemd.targets.sleep.enable = false;
        systemd.targets.suspend.enable = false;
        systemd.targets.hibernate.enable = false;
        systemd.targets.hybrid-sleep.enable = false;
      };
    homeManager = {
      imports = [
        (
          {
            lib,
            osConfig,
            ...
          }:
          {
            programs.plasma = {
              enable = osConfig.services.desktopManager.plasma6.enable;
              powerdevil = {
                AC = {
                  turnOffDisplay = {
                    idleTimeout = "never";
                  };
                  autoSuspend = {
                    action = lib.mkForce "nothing";
                  };
                  dimDisplay.enable = false;
                };
              };
              kscreenlocker = {
                autoLock = lib.mkForce false;
              };
            };
            dconf = lib.mkIf osConfig.services.desktopManager.gnome.enable {
              enable = true;
              settings = {
                # https://discourse.nixos.org/t/stop-pc-from-sleep/5757/9
                # https://github.com/Aylur/dotfiles/blob/29ee73dabd1b661b128c6ba71c87fdadf3991b0e/home/dconf.nix#L84C1-L90C7
                "org/gnome/settings-daemon/plugins/power" = {
                  idle-dim = false;
                  #power-button-action = "interactive";
                  sleep-inactive-ac-type = "nothing";
                  sleep-inactive-battery-type = "nothing";
                };
              };
            };
          }
        )
      ];
    };
  };
}
