{
  config,
  inputs,
  lib,
  pkgs,
  osConfig,
  ...
}@args:
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
