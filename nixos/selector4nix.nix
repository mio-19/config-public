{
  inputs,
  ...
}:
{
  imports = [
    inputs.selector4nix.nixosModules.selector4nix
    ../selector4nix.nix
  ];
}
