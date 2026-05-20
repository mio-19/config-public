{
  config,
  inputs,
  lib,
  pkgs,
  system,
  ...
}@args:
{
  imports = [ ./PinTheft.nix ];
  # https://git.kernel.org/torvalds/c/31e62c2ebbfd
  boot.kernel.sysctl."kernel.yama.ptrace_scope" =
    assert builtins.elem "yama" config.security.lsm;
    2;

  # Dirty Frag and https://github.com/v12-security/pocs/tree/main/fragnesia https://lists.openwall.net/netdev/2026/05/13/79
  boot.blacklistedKernelModules = [
    "esp4"
    "esp6"
    "rxrpc"
  ];
  boot.extraModprobeConfig = ''
    install esp4 /run/current-system/sw/bin/false
    install esp6 /run/current-system/sw/bin/false
    install rxrpc /run/current-system/sw/bin/false
  '';
}
