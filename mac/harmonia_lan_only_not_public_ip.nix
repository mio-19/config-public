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
  # $ sudo mkdir -p /var/lib/secrets && sudo nix-store --generate-binary-cache-key <hostname> /var/lib/secrets/harmonia.secret /var/lib/secrets/harmonia.pub
  services.harmonia.cache.signKeyPaths = [ "/var/lib/secrets/harmonia.secret" ];
  services.harmonia.cache.settings = {
    bind = "0.0.0.0:5111";
  };
}
