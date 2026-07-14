{
  den.aspects.user = {
    homeManager =
      { ... }:
      {
        imports = [ ./users/_/cli.nix ];
      };
  };
}
