{ den, lib, ... }:
{
  den.aspects.miodroid = {
    description = "Miodroid Android container (rootless)";
    nixos =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        system,
        ...
      }:
      let
        _include = args._include or (import ../nixos/include.nix args);
      in
      with _include;
      {
        imports = [
          inputs.mio.legacyPackages."${system}".modules.miodroid
        ];

        virtualisation.miodroid-rootless = {
          enable = true;
          package = pkgs.miodroid;
        };

        # Primary user configuration for rootless container execution
        users.users.user = {
          extraGroups = [
            "miodroid"
            "lxc-user"
            "fuse"
          ];
          autoSubUidGidRange = true;
        };

        # Limits to allow real-time and high-priority Android services
        security.pam.loginLimits = [
          {
            domain = "*";
            item = "nice";
            type = "-";
            value = "-20";
          }
          {
            domain = "*";
            item = "rtprio";
            type = "-";
            value = "40";
          }
        ];
        systemd.settings.Manager.DefaultLimitNICE = "-20";
        systemd.user.settings.Manager.DefaultLimitNICE = "-20";
        systemd.settings.Manager.DefaultLimitRTPRIO = "40";
        systemd.user.settings.Manager.DefaultLimitRTPRIO = "40";

        # Forward the Home Manager module
        home-manager.sharedModules = [
          inputs.mio.legacyPackages."${system}".modules.miodroid-rootless
        ];

        home-manager.users.user = {
          programs.miodroid-rootless = {
            enable = true;
            package = pkgs.miodroid;
          };
        };
      };

    provides.to-users =
      { user, ... }:
      lib.optionalAttrs (user.name == "user") {
        homeManager.programs.miodroid-rootless.enable = true;
      };
  };
}
