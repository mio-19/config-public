{ inputs, den, ... }:
{
  imports = [ inputs.den.flakeModule ];

  den.aspects.selector4nix = {
    nixos = {
      imports = [
        inputs.selector4nix.nixosModules.selector4nix
        ../selector4nix.nix
      ];
    };
    darwin = {
      imports = [
        inputs.selector4nix.darwinModules.selector4nix
        ../selector4nix.nix
      ];
    };
  };

  den.default.includes = [ den.aspects.selector4nix ];
}
