{ den, ... }:
{
  den.aspects.harmonia_lan_only_not_public_ip = {
    description = "Harmonia binary cache (LAN-only, no public IP)";
    nixos =
      { ... }:
      # https://github.com/nix-community/harmonia/tree/main
      {
        services.harmonia.cache.enable = true;
        # FIXME: generate a public/private key pair like this:
        # $ sudo mkdir -p /persistent/secrets && sudo nix-store --generate-binary-cache-key <hostname> /persistent/secrets/harmonia.secret /persistent/secrets/harmonia.pub
        services.harmonia.cache.signKeyPaths = [ "/persistent/secrets/harmonia.secret" ];
        networking.firewall.allowedTCPPorts = [ 5000 ];
      };
    darwin =
      { ... }:
      # https://github.com/nix-community/harmonia/tree/main
      {
        services.harmonia.cache.enable = true;
        # FIXME: generate a public/private key pair like this:
        # $ sudo mkdir -p /var/lib/secrets && sudo nix-store --generate-binary-cache-key <hostname> /var/lib/secrets/harmonia.secret /var/lib/secrets/harmonia.pub
        services.harmonia.cache.signKeyPaths = [ "/var/lib/secrets/harmonia.secret" ];
        services.harmonia.cache.settings = {
          bind = "0.0.0.0:5111";
        };
      };
  };
}
