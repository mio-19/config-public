# Shared baseline: HM defaults, nix registry, cachix substituters (den.aspects.basic).
{ den, ... }:
let
  shared =
    {
      config,
      inputs,
      lib,
      ...
    }:
    {
      home-manager.extraSpecialArgs = {
        inherit inputs;
      };
      home-manager.sharedModules = [
        inputs.nix-index-database.homeModules.nix-index
      ];
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = lib.mkDefault "hm-backup";

      nix = {
        # https://github.com/KornelJahn/nixos-disko-zfs-test/blob/673ed629a7ef80efd99ad3b1676d9e4c62829c21/hosts/testhost.nix#L37
        # Credits: Misterio77
        # https://raw.githubusercontent.com/Misterio77/nix-config/e227d8ac2234792138753a0153f3e00aec154c39/hosts/common/global/nix.nix
        # Add each flake input as a registry
        registry = lib.mapAttrs (_: v: { flake = v; }) (lib.removeAttrs inputs [ "nixpkgs" ]);
        # Map registries to channels (useful when using legacy commands)
        nixPath = lib.mapAttrsToList (n: v: "${n}=${v.to.path}") config.nix.registry;
        settings = {
          substituters = [
            "https://mio.cachix.org/"
            "https://mio-cache.cachix.org/"
            #"https://staging.cachix.org/"
            # https://garnix.io/docs/caching - https://t.me/nixos_zhcn/728695 # garnix sometimes often 504 Gateway Time-out. to avoid waiting on this garnix, supply `--offline` to nix commands.
            #"https://cache.garnix.io"
            #"https://nix-community.cachix.org"
            "https://cache.numtide.com" # https://github.com/numtide/llm-agents.nix
          ];
          trusted-public-keys = [
            "mio.cachix.org-1:FlupyyLPURqwdRqtPT/LBWKsXY7JKsDkzZQo2K6LeMM="
            "mio-cache.cachix.org-1:ouuIJZ59HIflYjpLW6DRyMc1c+6r3kC/LHuqGUsWigg="
            #"staging.cachix.org-1:WX63nyFdVdWGn6n59pIYwkcH/AtjJGjvMQFKlI2z00w="
            #"cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
            #"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
          ];
        };
      };
    };
in
{
  den.aspects.basic = {
    description = "Shared baseline: HM defaults, nix registry, and cachix substituters";
    nixos =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        system,
        ...
      }:
      {
        imports = [ (shared args) ];

        # https://search.nixos.org/packages
        environment.systemPackages =
          with pkgs;
          lib.optionals (pkgs ? nixtamal) [
            nixtamal
          ];
      };
    darwin =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        ...
      }:
      {
        imports = [ (shared args) ];

        nix = {
          #daemonIOLowPriority = true;
          #daemonProcessType = "Background";
          gc = {
            automatic = true;
            # https://nixos.wiki/wiki/Storage_optimization
            interval = {
              Weekday = 0;
              Hour = 0;
              Minute = 0;
            };
            options = "--delete-older-than 30d";
          };
          optimise = {
            automatic = true;
          };
          extraOptions = ''
            trusted-users = @admin root
          '';
        };
      };
  };
}
