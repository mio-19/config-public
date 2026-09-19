{ den, ... }:
{
  den.aspects.waydroid = {
    description = "waydroid";
    nixos =
      {
        lib,
        pkgs,
        config,
        _include,
        ...
      }@args:
      with _include;
      {
        # NEED: sudo tailscale set  --accept-dns=false
        # https://github.com/NixOS/nixpkgs/issues/459520 -> https://github.com/waydroid/waydroid/issues/117
        services.resolved.enable = false;
        # https://github.com/waydroid/waydroid/issues/117#issuecomment-1380760713
        networking.resolvconf.enable = false;
        environment.etc."resolv.conf".text = ''
          nameserver 1.1.1.1
          nameserver 8.8.8.8'';
        virtualisation.waydroid.enable = true;
        # https://github.com/NixOS/nixpkgs/pull/466473/files
        virtualisation.waydroid.package = pkgs.waydroid-nftables;
        networking.nftables.enable = true;

        # Don't start at boot — encrypted /home/user may still be locked
        systemd.services."waydroid-container".wantedBy = lib.mkForce [ ];

        # Data lives under encrypted home; dangling until user unlocks home is fine
        systemd.tmpfiles.rules = [
          # type  target              link-to-path
          "L+ /var/lib/waydroid - - - - /home/user/.var_lib_waydroid"
        ];
        # LXC/AppArmor follow the real path; alias keeps profiles matching /var/lib/waydroid/
        security.apparmor.includes."tunables/alias" = ''
          alias /var/lib/waydroid/ -> /home/user/.var_lib_waydroid/,
        '';

        # System-wide PipeWire pulse socket is /run/pulse/native, not /run/user/$UID/pulse/native.
        # Waydroid bind-mounts $PULSE_RUNTIME_PATH/native and fails if that path is missing.
        environment.sessionVariables = lib.mkIf config.services.pipewire.systemWide {
          PULSE_RUNTIME_PATH = "/run/pulse";
        };

        environment.systemPackages =
          with pkgs;
          (map hardenedPkg [
            wl-clipboard # https://nixos.wiki/wiki/WayDroid - clipboard sharing
          ])
          ++ [
            (lib.hiPrio (
              pkgs.writeShellScriptBin "waydroid" ''
                ${lib.optionalString config.services.pipewire.systemWide ''
                  export PULSE_RUNTIME_PATH=/run/pulse
                ''}
                exec ${config.virtualisation.waydroid.package}/bin/waydroid "$@"
              ''
            ))
            nur.repos.ataraxiasjel.waydroid-script
            waydroid-helper
          ];
      };
  };
}
