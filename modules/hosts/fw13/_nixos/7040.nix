{
  config,
  inputs,
  lib,
  pkgs,
  system,
  _include,
  ...
}@args:
with _include;
let
  fan_workaround = false;
in
{
  microarch = "zen4";
  # https://wiki.nixos.org/wiki/Hardware/Framework/Laptop_13#AMD_AI_300_Series
  imports = [
    inputs.nixos-hardware.nixosModules.framework-13-7040-amd
  ];

  # https://github.com/Svenum/holynix/blob/2a3d096b74bbbcf0a166ee58507846fb2f5ba8c3/systems/x86_64-linux/Yon/hardware.nix#L76
  # https://github.com/TamtamHero/fw-fanctrl/blob/0cf784fcd0ec908fdb447f0710dd45eba90a5ca0/src/fw_fanctrl/_resources/config.json#L6
  hardware.fw-fanctrl = {
    enable = true;
    #enable = false; # fan sometimes zero with false???
    keepDefaultStrategies = false;
    settings = {

      defaultStrategy = if fan_workaround then "charging-workaround" else "charging-smooth";
      strategyOnDischarging = if fan_workaround then "discharging-workaround" else "discharging-smooth";

      strategies = {
        "discharging-smooth" = {
          fanSpeedUpdateFrequency = 10;
          movingAverageInterval = 30;
          speedCurve = [
            {
              temp = 30;
              speed = 0;
            }
            {
              temp = 40;
              speed = 10;
            }
            {
              temp = 48;
              speed = 25;
            }
            {
              temp = 70;
              speed = 40;
            }
            {
              temp = 80;
              speed = 50;
            }
            {
              temp = 90;
              speed = 100;
            }
          ];
        };
        "charging-smooth" = {
          fanSpeedUpdateFrequency = 10;
          movingAverageInterval = 30;
          speedCurve = [
            {
              temp = 30;
              speed = 0;
            }
            {
              temp = 40;
              speed = 10;
            }
            {
              temp = 47;
              speed = 25;
            }
            {
              temp = 70;
              speed = 40;
            }
            {
              temp = 80;
              speed = 50;
            }
            {
              temp = 90;
              speed = 100;
            }
          ];
        };
        # https://community.frame.work/t/amd-7840u-fan-issues/69704/2
        # https://community.frame.work/t/fan-hysterersis-issue/4469/4
        # workaround: avoid clicking sound : jump from 0 to speed = 10; directly to speed = 39;
        "silent-workaround" = {
          fanSpeedUpdateFrequency = 7;
          movingAverageInterval = 30;
          speedCurve = [
            {
              temp = 0;
              speed = 0;
            }
            {
              temp = 39.99;
              speed = 0;
            }
            {
              temp = 40;
              speed = 10;
            }
            {
              temp = 57.99;
              speed = 10;
            }
            {
              temp = 58;
              speed = 39;
            }
            {
              temp = 70;
              speed = 39;
            }
            {
              temp = 80;
              speed = 50;
            }
            {
              temp = 90;
              speed = 100;
            }
          ];
        };
        "discharging-workaround" = {
          fanSpeedUpdateFrequency = 7;
          movingAverageInterval = 30;
          speedCurve = [
            {
              temp = 0;
              speed = 0;
            }
            {
              temp = 39.99;
              speed = 0;
            }
            {
              temp = 40;
              speed = 10;
            }
            {
              temp = 47.99;
              speed = 10;
            }
            {
              temp = 48;
              speed = 39;
            }
            {
              temp = 70;
              speed = 39;
            }
            {
              temp = 80;
              speed = 50;
            }
            {
              temp = 90;
              speed = 100;
            }
          ];
        };
        "charging-workaround" = {
          fanSpeedUpdateFrequency = 7;
          movingAverageInterval = 30;
          speedCurve = [
            {
              temp = 0;
              speed = 0;
            }
            {
              temp = 39.99;
              speed = 0;
            }
            {
              temp = 40;
              speed = 10;
            }
            {
              temp = 46.99;
              speed = 10;
            }
            {
              temp = 47;
              speed = 39;
            }
            {
              temp = 70;
              speed = 39;
            }
            {
              temp = 80;
              speed = 50;
            }
            {
              temp = 90;
              speed = 100;
            }
          ];
        };
      };
    };
  };

  # https://github.com/ilya-zlobintsev/LACT/wiki/Overclocking-(AMD)
  hardware.amdgpu.overdrive.enable = true;
  services.lact.enable = true;
  # https://wiki.archlinux.org/title/AMDGPU -> Overclocking
  hardware.amdgpu.overdrive.ppfeaturemask = "0xfff7ffff";

  systemPackages_hardened = with pkgs; [
    amdgpu_top
    ryzenadj
  ];

  boot.kernelParams = [

    # https://github.com/search?q=mem_sleep_default%3Ds2idle+language%3ANix&type=code&l=Nix
    "mem_sleep_default=s2idle"
    # https://www.reddit.com/r/framework/comments/1hxoola/trackpad_delays/
    "amdgpu.dcdebugmask=0x10"
  ];

  programs.ryzen-monitor-ng.enable = true;
  hardware.cpu.amd.ryzen-smu.enable = true;

}
