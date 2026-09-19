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
      let
        # /run/pulse/native is used when Pulse (or PipeWire's pulse compat) is system-wide.
        # Per-user mode uses /run/user/$UID/pulse/native instead — Waydroid must not
        # be forced to /run/pulse in that case.
        pulseSystemWide =
          (
            config.services.pipewire.enable
            && config.services.pipewire.pulse.enable
            && config.services.pipewire.systemWide
          )
          || (config.services.pulseaudio.enable && config.services.pulseaudio.systemWide);
      in
      {
        # NEED: sudo tailscale set  --accept-dns=false
        # https://github.com/NixOS/nixpkgs/issues/459520 -> https://github.com/waydroid/waydroid/issues/117
        services.resolved.enable = false;
        # https://github.com/waydroid/waydroid/issues/117#issuecomment-1380760713
        #networking.resolvconf.enable = false;
        #environment.etc."resolv.conf".text = ''
        #  nameserver 1.1.1.1
        #  nameserver 8.8.8.8'';
        virtualisation.waydroid.enable = true;
        # https://github.com/NixOS/nixpkgs/pull/466473/files
        virtualisation.waydroid.package = pkgs.waydroid-nftables;
        networking.nftables.enable = true;

        assertions = [
          {
            assertion =
              !config.services.pulseaudio.systemWide
              || config.services.pulseaudio.enable
              || (config.services.pipewire.enable && config.services.pipewire.systemWide);
            message = ''
              services.pulseaudio.systemWide = true but neither services.pulseaudio.enable
              nor services.pipewire.systemWide is on — pulse is not actually system-wide.
              Waydroid only sets PULSE_RUNTIME_PATH=/run/pulse when pulse really is system-wide
              (pipewire.systemWide + pipewire.pulse, or pulseaudio.enable + pulseaudio.systemWide).
            '';
          }
        ];

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

        # Waydroid bind-mounts $PULSE_RUNTIME_PATH/native; system-wide socket is /run/pulse/native.
        environment.sessionVariables = lib.mkIf pulseSystemWide {
          PULSE_RUNTIME_PATH = "/run/pulse";
        };

        # System pipewire-pulse.socket ships SocketMode=0660 pipewire:pipewire.
        # Per-user sockets default to 0666. Waydroid only mounts the socket into LXC;
        # Android audio UIDs are not in the pipewire group, so connect(2) fails and
        # the session is silent even though the container starts.
        systemd.sockets.pipewire-pulse = lib.mkIf (
          config.services.pipewire.enable
          && config.services.pipewire.pulse.enable
          && config.services.pipewire.systemWide
        ) { socketConfig.SocketMode = "0666"; };

        environment.systemPackages =
          with pkgs;
          (map hardenedPkg [
            wl-clipboard # https://nixos.wiki/wiki/WayDroid - clipboard sharing
          ])
          ++ [
            (lib.hiPrio (
              pkgs.writeShellScriptBin "waydroid" ''
                ${lib.optionalString pulseSystemWide ''
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
