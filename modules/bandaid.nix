# Kernel CVE mitigations and hardening band-aids (den.aspects.bandaid).
{ den, ... }: {
  den.aspects.bandaid = {
    description = "Kernel CVE mitigations and hardening band-aids";
    nixos =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        system,
        ...
      }:
      import ./_bandaid/default.nix args;
  };
}
