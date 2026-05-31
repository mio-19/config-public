{ inputs, ... }:
{
  imports = [
    inputs.selector4nix.darwinModules.selector4nix
    ../selector4nix.nix
  ];
}
