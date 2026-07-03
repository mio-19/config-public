{ den, ... }:
{
  den.aspects.boot = {
    description = "plymouth mac-style boot splash + silent/quiet boot";
    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        boot.plymouth = {
          enable = true;
          theme = "mac-style";
          themePackages = [ pkgs.mac-style-plymouth ];
        };
        # https://wiki.nixos.org/wiki/Plymouth
        boot.initrd.verbose = false;
        boot.consoleLogLevel = 3;

        # https://wiki.archlinux.org/title/Silent_boot
        boot.kernelParams = lib.optionals config.boot.initrd.systemd.enable [
          "quiet"
        ];

        # no: may cause problem with nixos-rebuild switch
        /*
          # https://discourse.nixos.org/t/smooth-transition-with-plymouth-sddm-kde/4646/2
          systemd.services."display-manager" = lib.mkIf config.services.displayManager.sddm.enable {
            conflicts = [ "plymouth-quit.service" ];
            preStart = "${config.boot.plymouth.package}/bin/plymouth deactivate";
            #script = "/run/current-system/sw/bin/sddm";
            postStart = "/bin/sh -c 'sleep 3 && ${config.boot.plymouth.package}/bin/plymouth quit --retain-splash'";
            enable = true;
            startLimitBurst = lib.mkForce 10;
          };
        */
      };
  };
}
