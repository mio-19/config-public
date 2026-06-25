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
{
  # https://wiki.nixos.org/wiki/Hardware/Framework/Laptop_13#AMD_AI_300_Series
  imports = [
    inputs.nixos-hardware.nixosModules.framework-13-7040-amd
    ../rocm.nix
  ];
  services.power-profiles-daemon.enable = true;

  # https://github.com/Svenum/holynix/blob/2a3d096b74bbbcf0a166ee58507846fb2f5ba8c3/systems/x86_64-linux/Yon/hardware.nix#L76
  # https://github.com/TamtamHero/fw-fanctrl/blob/0cf784fcd0ec908fdb447f0710dd45eba90a5ca0/src/fw_fanctrl/_resources/config.json#L6
  hardware.fw-fanctrl = {
    enable = true;
    keepDefaultStrategies = false;
    settings = {
      defaultStrategy = "charging-smooth";
      strategyOnDischarging = "discharging-smooth";
      /*
        defaultStrategy = "charging-workaround";
        strategyOnDischarging = "discharging-workaround";
      */
      strategies = {
        "discharging-smooth" = {
          fanSpeedUpdateFrequency = 7;
          movingAverageInterval = 30;
          speedCurve = [
            {
              temp = 20;
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
          fanSpeedUpdateFrequency = 7;
          movingAverageInterval = 30;
          speedCurve = [
            {
              temp = 20;
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

  environment.systemPackages =
    with pkgs;
    (map hardenedPkg [
      ryzenadj
      kdePackages.kamoso
    ]);

  boot.kernelParams = [
    # https://github.com/search?q=mem_sleep_default%3Ds2idle+language%3ANix&type=code&l=Nix
    "mem_sleep_default=s2idle"
    # https://www.reddit.com/r/framework/comments/1hxoola/trackpad_delays/
    "amdgpu.dcdebugmask=0x10"
  ];

  # https://github.com/troymoder/dotfiles/blob/f09867c7d178331596359cf1229e7e6806e75624/system/framework.nix#L48-L49
  # https://wiki.archlinux.org/title/Framework_Laptop_13_(AMD_Ryzen_7040_Series)
  services.colord.enable = true;
  environment.etc."color/icc/BOE_CQ_NE135FBM_N41_03.icm".source = ./BOE_CQ_______NE135FBM_N41_03.icm;

  programs.ryzen-monitor-ng.enable = true;
  hardware.cpu.amd.ryzen-smu.enable = true;

  # https://www.reddit.com/r/framework/comments/17d6pjy/comment/k5uup6a/
  boot.blacklistedKernelModules = [
    "psmouse"
  ];
}
