{ den, ... }: {
  den.aspects.devcommand = {
    description = "dev shell helper to unlock ZFS home and restart home-manager";
    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        # DETAILS REMOVED
      in
      {
        environment.systemPackages = [
          # DETAILS REMOVED
        ];
      };
  };
}
