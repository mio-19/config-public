{ den, ... }:
{
  den.aspects.laptop = {
    description = "Mobile and laptop specific workarounds";
    nixos =
      { ... }:
      {
        # Disable MagicDNS overriding /etc/resolv.conf.
        # Public Wi-Fi networks often block external upstream DNS (like 8.8.8.8) that MagicDNS tries to use.
        # This prevents ERR_NAME_NOT_RESOLVED issues when bypassing captive portals.
        services.tailscale.extraUpFlags = [ "--accept-dns=false" ];
      };
  };
}
