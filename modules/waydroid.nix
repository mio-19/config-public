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
        systemd.services."waydroid-container".wantedBy = lib.mkForce [ ]; # don't start waydroid-container at boot
        systemd.tmpfiles.rules = [
          # type  target                    link-to-path                mode uid  gid  age  argument
          "L+ /var/lib/waydroid - - - - /home/user/.var_lib_waydroid"
        ];
        services.avahi.enable = false; # does this interfere by any chance?

        environment.systemPackages =
          with pkgs;
          with pkgs;
          (map hardenedPkg [
            wl-clipboard # https://nixos.wiki/wiki/WayDroid - clipboard sharing
          ])
          ++ [
            nur.repos.ataraxiasjel.waydroid-script

            waydroid-helper
          ];
      };
  };
}
