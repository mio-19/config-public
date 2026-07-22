{ den, ... }:
{
  den.aspects.printing-sharing = {
    description = "Shared network printing and Avahi publish (LAN/Tailscale only)";
    nixos =
      args@{
        lib,
        pkgs,
        config,
        ...
      }:
      let
        _include = args._include or (import ../nixos/include.nix args);
        # Source ranges for nftables (interface-agnostic: works on eth *or* wifi).
        # RFC1918 = typical LAN; 100.64.0.0/10 = Tailscale CGNAT.
        lanAndTailscaleV4 = [
          "10.0.0.0/8"
          "172.16.0.0/12"
          "192.168.0.0/16"
          "100.64.0.0/10"
        ];
      in
      with _include;
      {
        # https://wiki.nixos.org/wiki/Printing
        # https://www.cups.org/doc/man-cupsd.conf.html  (@LOCAL = non-PTP ifaces: eth/wifi; NOT VPN)
        # https://wiki.nixos.org/wiki/Firewall          (extraInputRules needs nftables)
        config = lib.mkIf novirt {
          # extraInputRules only applies with the nftables backend.
          networking.nftables.enable = true;

          services.avahi = {
            enable = true;
            nssmdns4 = true;
            openFirewall = true; # mDNS multicast for LAN discovery (not useful over Tailscale)
            publish = {
              enable = true;
              userServices = true;
            };
          };

          services.printing = {
            listenAddresses = [ "*:631" ];
            # cupsd.conf(5): @LOCAL uses subnets on non-point-to-point interfaces
            # (Ethernet and Wi-Fi). VPN/TUN (Tailscale) is excluded — allow CGNAT explicitly.
            allowFrom = [
              "localhost"
              "@LOCAL"
              "100.64.0.0/10"
            ];
            browsing = true;
            defaultShared = true;
            # Do not use openFirewall: that opens TCP 631 on all interfaces to the internet.
            openFirewall = false;
          };

          # Allow IPP by source address, not by iface name → same on ethernet or wifi.
          networking.firewall.extraInputRules = ''
            ip saddr { ${lib.concatStringsSep ", " lanAndTailscaleV4} } tcp dport 631 accept
            ip6 saddr { fc00::/7, fe80::/10 } tcp dport 631 accept
          '';
        };
      };
  };
}
