{ den, ... }:
{
  den.aspects.user = {
    homeManager =
      { ... }:
      {
        imports = [ ../../nixos/home-user.nix ];
      };
  };
}
