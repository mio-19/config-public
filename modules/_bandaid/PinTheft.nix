{
  config,
  inputs,
  lib,
  pkgs,
  system,
  ...
}@args:
{
  # https://www.openwall.com/lists/oss-security/2026/05/19/6
  # https://github.com/v12-security/pocs/tree/main/pintheft
  # https://git.kernel.org/torvalds/c/e17492979319
  boot.blacklistedKernelModules = [
    "rds"
    "rds_tcp"
    "rds_rdma"
  ];
  boot.extraModprobeConfig = ''
    install rds /run/current-system/sw/bin/false
    install rds_tcp /run/current-system/sw/bin/false
    install rds_rdma /run/current-system/sw/bin/false
  '';
}
