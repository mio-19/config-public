{ den, ... }:
let
  nixbuild =
    {
      config,
      ...
    }:
    {
      home-manager.users.root = (
        { config, ... }@args:
        {
          home.stateVersion = "25.11";
          # DETAILS REMOVED
        }
      );

      # https://nixbuild.net/get-started
      # https://docs.nixbuild.net/getting-started/#ssh-configuration
      programs.ssh.knownHosts = {
        nixbuild = {
          hostNames = [ "eu.nixbuild.net" ];
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM";
        };
      };

      nix = {
        # https://docs.nixbuild.net/getting-started/#ssh-configuration You probably want to activate the builders-use-substitutes Nix option. This option allows nixbuild.net to download dependencies directly from cache.nixos.org.
        extraOptions = ''
          builders-use-substitutes = true
        '';
      };
    };
in
{
  den.aspects.nixbuild = {
    description = "nixbuild.net remote builder ssh setup (NixOS + nix-darwin)";
    nixos = nixbuild;
    darwin = nixbuild;
  };
}
