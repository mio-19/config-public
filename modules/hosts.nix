# Host and user declarations for Den-managed machines.
# Migrate hosts one at a time; other hosts stay on plain nixosConfigurations.
{
  den.hosts.x86_64-linux.fw13 = {
    hostName = "fw13";
    users.user.classes = [ "homeManager" ];
    # DETAILS REMOVED
  };

  den.hosts.x86_64-linux.ipc = {
    hostName = "ipc";
    users.user.classes = [ "homeManager" ];
    # DETAILS REMOVED
  };

  den.hosts.aarch64-darwin.NixMac = {
    hostName = "NixMac";
    users.user.classes = [ "homeManager" ];
    # DETAILS REMOVED
  };
}
