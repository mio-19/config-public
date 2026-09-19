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
        systemd.services."waydroid-container" = {
          wantedBy = lib.mkForce [ ]; # don't start waydroid-container at boot
          # Stage-2 units only get a minimal PATH (coreutils/…), not util-linux —
          # same idiom as nixpkgs systemd-fsck@ / zram-setup (path = [ pkgs.util-linux ]).
          path = [ pkgs.util-linux ];
          preStart = ''
            mkdir -p /home/user/.var_lib_waydroid
            mkdir -p /var/lib/waydroid
            if ! ${lib.getExe' pkgs.util-linux "mountpoint"} -q /var/lib/waydroid; then
              ${lib.getExe' pkgs.util-linux "mount"} --bind /home/user/.var_lib_waydroid /var/lib/waydroid
            fi
          '';
          postStop = ''
            if ${lib.getExe' pkgs.util-linux "mountpoint"} -q /var/lib/waydroid; then
              ${lib.getExe' pkgs.util-linux "umount"} /var/lib/waydroid || true
            fi
          '';
        };
        systemd.tmpfiles.rules = [
          # type  target                    link-to-path                mode uid  gid  age  argument
          "d /home/user/.var_lib_waydroid 0755 root root - -"
        ];
        security.apparmor.includes."tunables/alias" = ''
          alias /var/lib/waydroid/ -> /home/user/.var_lib_waydroid/,
        '';
        #services.avahi.enable = false; # does this interfere by any chance?

        environment.systemPackages =
          with pkgs;
          (map hardenedPkg [
            wl-clipboard # https://nixos.wiki/wiki/WayDroid - clipboard sharing
          ])
          ++ [
            (lib.hiPrio (
              pkgs.writeShellScriptBin "waydroid" ''
                # As root (e.g. waydroid init): bind before the daemon runs.
                # As user: waydroid-container.service preStart does the bind — don't warn/race.
                if [ "$EUID" -eq 0 ] && ! ${lib.getExe' pkgs.util-linux "mountpoint"} -q /var/lib/waydroid; then
                  mkdir -p /home/user/.var_lib_waydroid
                  mkdir -p /var/lib/waydroid
                  ${lib.getExe' pkgs.util-linux "mount"} --bind /home/user/.var_lib_waydroid /var/lib/waydroid
                fi
                exec ${config.virtualisation.waydroid.package}/bin/waydroid "$@"
              ''
            ))
            nur.repos.ataraxiasjel.waydroid-script

            waydroid-helper
          ];
      };
  };
}
