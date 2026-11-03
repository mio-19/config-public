# THIS IS A STUB
{
  den.aspects.user = {
    homeManager =
      { ... }:
      {
        imports = [
          ./users/_/cli.nix
          ./users/_/common.nix
        ];
      };
  };
}
