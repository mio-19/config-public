{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  # https://wiki.linuxaudio.org/wiki/system_configuration#do_i_really_need_a_real-time_kernel
  boot.kernelParams = [
    "threadirqs"
  ];

  # https://wiki.linuxaudio.org/wiki/system_configuration#simultaneous_multithreading
  security.allowSimultaneousMultithreading = lib.mkDefault false;

  # https://github.com/HexGuard-Security/GridNix/blob/c860d07d507c8a375c6214ba67c017447b20a73d/nixos/modules/hardware-tools.nix#L120-L131
  # nixpkgs#millisecond - User user is currently not member of a group that has sufficient rtprio (95) and memlock (4294967296) set. Add yourself to a group with sufficent limits set, i.e. audio or realtime, with 'sudo usermod -a -G <group_name> user. See also https://wiki.linuxaudio.org/wiki/system_configuration#audio_group
  security.pam.loginLimits = [
    {
      domain = "@realtime";
      type = "-";
      item = "rtprio";
      value = "99";
    }
    {
      domain = "@realtime";
      type = "-";
      item = "memlock";
      value = "unlimited";
    }
  ];
  users.groups = {
    realtime = { };
  };

  # https://discourse.nixos.org/t/creating-a-custom-udev-rule/14569
  # https://wiki.linuxaudio.org/wiki/system_configuration#quality_of_service_interface
  # https://github.com/Ardour/ardour/blob/master/tools/udev/99-cpu-dma-latency.rules
  services.udev.extraRules = ''
    DEVPATH=="/devices/virtual/misc/cpu_dma_latency", OWNER="root", GROUP="audio", MODE="0660"
  '';
}
