# https://github.com/janik-haag/nm2nix
# sudo su -c "cd /etc/NetworkManager/system-connections && nix --extra-experimental-features 'nix-command flakes' run github:Janik-Haag/nm2nix | nix --extra-experimental-features 'nix-command flakes' run nixpkgs#nixfmt-rfc-style"
# sudo su -c "cd /etc/NetworkManager/system-connections && nm2nix | nixfmt"
# sudo su -c "rm -f /etc/NetworkManager/system-connections/*"
{ den, ... }:
{
  den.aspects.wifi = {
    description = "NetworkManager WiFi profiles (nm2nix)";
    nixos =
      { ... }:
      {
        /*
          TODO: KDE Plasma glitch sometimes on first connect
          does `psk-flags = "0";` help? does `autoconnect = true;` help?
          related forum post:?
          https://forum.manjaro.org/t/plasma-nm-package-doesnt-connect-at-first-attempt/57300/9
        */
        networking.networkmanager.ensureProfiles.profiles = {
          # DETAILS REMOVED
        };
      };
  };
}
