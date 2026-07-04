{ den, ... }:
{
  den.aspects.scx = {
    description = "SCX scheduler (scx_lavd) with optional Jovian wantedBy";
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
        services.scx.enable = true;
        services.scx.package = lib.mkDefault pkgs.scx.rustscheds;
        # https://www.phoronix.com/news/Meta-SCX-LAVD-Steam-Deck-Server
        # https://github.com/search?q=scx_lavd+language%3ANix&type=code&l=Nix
        services.scx.scheduler = "scx_lavd";
        # https://github.com/Jovian-Experiments/Jovian-NixOS/blob/d15853dadb69837bc1e86c5be52c1e6b4bda3da4/modules/steam/steam.nix#L64C7-L64C36
        # https://github.com/NixOS/nixpkgs/blob/9dfcba812aa0f4dc374acfe0600d591885f4e274/lib/modules.nix#L653C13-L653C23
        # see matrix group:
        /*
          k0kada (he/him): Any reason why Jovian removes the `wantedBy` from scx service? CC K900 (༼ つ ◕_◕ ༽つ give zen6):

          K900 (༼ つ ◕_◕ ༽つ give zen6): > <@k0kada:matrix.org> Any reason why Jovian removes the `wantedBy` from scx service? CC K900 (༼ つ ◕_◕ ༽つ give zen6):

          Yes, steamos-manager manages it

          K900 (༼ つ ◕_◕ ༽つ give zen6): So we don't want it to start by default

          k0kada (he/him): > <@k900:0upti.me> Yes, steamos-manager manages it

          Does it start only in gaming mode or also in desktop mode?

          K900 (༼ つ ◕_◕ ༽つ give zen6): Currently AFAIUI it does not start it at all

          K900 (༼ つ ◕_◕ ༽つ give zen6): But we want to follow the vendor behavior here
        */
        systemd.services.scx.wantedBy = lib.mkIf is-jovian (lib.mkOverride 49 [ "multi-user.target" ]);
      };
  };
}
