# Shared authorized SSH keys for every Den-managed OS user (NixOS + nix-darwin).
# Per-user keys use a unique aspect identity (fleet-demo ssh-keys pattern).
{ ... }:
let
  keys = import ../sshkeys.nix;
in
{
  den.aspects.sshkeys = {
    description = "Provision shared authorized SSH keys from sshkeys.nix";
    os.users.users.root.openssh.authorizedKeys.keys = keys;
    includes = [
      (
        { host, user }:
        {
          name = "sshkeys/${user.userName}@${host.name}";
          nixos.users.users.${user.userName}.openssh.authorizedKeys.keys = keys;
          darwin.users.users.${user.userName}.openssh.authorizedKeys.keys = keys;
        }
      )
    ];
  };
}
