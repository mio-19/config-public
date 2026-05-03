{
  config,
  inputs,
  lib,
  pkgs,
  _include,
  ...
}@args:
with _include;
{
  boot.loader.grub.keepBootedSystemEntry = true;
}
