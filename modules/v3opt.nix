{ den, ... }:
{
  den.aspects.v3opt = {
    description = "x86_64-v3 package overrides for core system services";
    nixos =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        ...
      }:
      let
        _include = args._include or (import ../nixos/include.nix args);
      in
      with _include;
      {
        imports = [ ];
        nix.package = lib.mkDefault pkgs.pkgsx86_64_v3.nix;
        systemd.package = lib.mkDefault pkgs.pkgsx86_64_v3.systemd;
        services.dbus.dbusPackage = pkgs.pkgsx86_64_v3.dbus;
        programs.tmux.package = (cleanPkg pkgs.pkgsx86_64_v3.tmux);
        programs.nano.package = (cleanPkg pkgs.pkgsx86_64_v3.nano);
        # ffmpeg failed to build, so no pipewire.
        /*
          services.pipewire.package = (
            hardenedPkg pkgs.pkgsx86_64_v3.pipewire
            // {
              inherit (pkgs.pkgsx86_64_v3.pipewire) jack;
            }
          );
          services.pipewire.wireplumber.package = (hardenedPkg pkgs.pkgsx86_64_v3.wireplumber);
        */
        boot.plymouth.package = pkgs.pkgsx86_64_v3.plymouth;
        services.openssh.package = (hardenedPkg pkgs.pkgsx86_64_v3.openssh);
        networking.wireless.iwd.package = (hardenedPkg pkgs.pkgsx86_64_v3.iwd);
        hardware.bluetooth.package = (hardenedPkg pkgs.pkgsx86_64_v3.bluez);
        services.power-profiles-daemon.package = (hardenedPkg pkgs.pkgsx86_64_v3.power-profiles-daemon);
        networking.networkmanager.package = (hardenedPkg pkgs.pkgsx86_64_v3.networkmanager);
        #security.polkit.package = (pkgs.pkgsx86_64_v3.polkit);
        # no qt allowed
        /*
          programs.kdeconnect.package = lib.mkIf (!config.services.displayManager.gdm.enable) (
            lib.mkForce (hardenedPkg pkgs.pkgsx86_64_v3.kdePackages.kdeconnect-kde)
          );

          home-manager.sharedModules = [
            (
              { pkgs, ... }:
              {
                programs.kdeconnect.package = (
                  lib.mkForce (hardenedPkg pkgs.pkgsx86_64_v3.kdePackages.kdeconnect-kde)
                );
              }
            )
          ];
        */
      };
  };
}
