{ ... }: {

  # CVE-2026-46331
  # Linux Kernel net/sched act_pedit LPE
  # https://git.kernel.org/linus/899ee91156e57784090c5565e4f31bd7dbffbc5a
  # https://github.com/sgkdev/packet_edit_meme
  boot.blacklistedKernelModules = [ "act_pedit" ];
  boot.extraModprobeConfig = ''
    install act_pedit /run/current-system/sw/bin/false
  '';
}
