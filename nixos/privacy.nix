{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  # WILL CAUSE PROBLEM IF NEED MAC <-> IP ASSIGNMENT BY ROUTER
  # https://github.com/cynicsketch/nix-mineral/blob/395384ceabc7f1b04dc32fa92654f3cc3294f330/nix-mineral.nix#L781
  networking = {
    networkmanager = {
      ethernet.macAddress = "random";
      wifi = {
        macAddress = "random";
        scanRandMacAddress = true;
      };
      # Enable IPv6 privacy extensions in NetworkManager.
      connectionConfig."ipv6.ip6-privacy" = 2;
    };
  };
}
