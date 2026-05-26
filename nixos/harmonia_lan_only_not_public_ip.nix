{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:
# https://github.com/nix-community/harmonia/tree/main
{
  services.harmonia.cache.enable = true;
  # FIXME: generate a public/private key pair like this:
  # $ sudo mkdir -p /persistent/secrets && sudo nix-store --generate-binary-cache-key <hostname> /persistent/secrets/harmonia.secret /persistent/secrets/harmonia.pub
  services.harmonia.cache.signKeyPaths = [ "/persistent/secrets/harmonia.secret" ];
  networking.firewall.allowedTCPPorts = [ 5000 ];
}
