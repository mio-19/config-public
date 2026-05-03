{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:
{
  # https://unix.stackexchange.com/questions/448268/change-systemd-stop-job-timeout-in-nixos-configuration/460141#460141
  # https://github.com/search?q=DefaultTimeoutStopSec+language%3ANix+&type=code
  systemd.settings.Manager.DefaultTimeoutStopSec = "10s";
  # https://www.freedesktop.org/software/systemd/man/latest/logind.conf.html#UserStopDelaySec=
  systemd.settings.Manager.UserStopDelaySec = 0;

  # https://github.com/systemd/systemd/issues/12262#issuecomment-1887321354
  systemd.services."user@".serviceConfig = {
    TimeoutStopSec = "4s";
  };
}
