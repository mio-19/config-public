{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:
{
  # https://discourse.nixos.org/t/when-is-keep-outputs-keep-derivations-garbage-collected/23498
  # https://github.com/mitchellh/nixos-config/blob/ad77d61cb64f8d2bb554826e127b332e041fc472/machines/macbook-pro-m1.nix#L18
  /*
    nix.extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '';
  */
  nix.settings = {
    keep-outputs = true;
    keep-derivations = true;
  };
}
