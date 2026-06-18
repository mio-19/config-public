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
  fprintWorkaound = false; # seem to make things actually worse
in
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
      defaultStrategy = "chargingstrategy";
      strategyOnDischarging = "dischargingstrategy";
      # https://community.frame.work/t/amd-7840u-fan-issues/69704/2
      # https://community.frame.work/t/fan-hysterersis-issue/4469/4
      # avoid clicking sound : jump from 0 to speed = 10; directly to speed = 37;
      strategies = {
        "silent" = {
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
              speed = 37;
            }
            {
              temp = 70;
              speed = 37;
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
        "dischargingstrategy" = {
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
              speed = 37;
            }
            {
              temp = 70;
              speed = 37;
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
        "chargingstrategy" = {
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
              temp = 44.99;
              speed = 10;
            }
            {
              temp = 45;
              speed = 37;
            }
            {
              temp = 70;
              speed = 37;
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

  # https://github.com/FrameworkComputer/linux-docs/tree/1b1a292be31cf5d0e079a8a95df98b1c52944630/Fingerprint-Wake-Workaround
  # https://community.frame.work/t/fingerprint-sensor-fails-to-resume-after-suspend-on-framework-13-amd-goodix-27c6-609c/79900/5
  systemd.services.fw13-fingerprint-wake-workaround = lib.mkIf fprintWorkaound {
    description = "Restore fingerprint reader after system resume";
    after = [
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
      "suspend-then-hibernate.target"
    ];
    wantedBy = [
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
      "suspend-then-hibernate.target"
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "fw13-fingerprint-wake-workaround" ''
        export PATH=${
          lib.makeBinPath (
            with pkgs;
            [
              usbutils
              gnugrep
              gawk
              coreutils
              config.systemd.package
              util-linux
            ]
          )
        }:$PATH

        FPRINT_DEVICE=$(lsusb | grep -E "Goodix.*Fingerprint|27c6:609c" | head -1)
        if [ -z "$FPRINT_DEVICE" ]; then exit 0; fi

        FPRINT_ID=$(echo "$FPRINT_DEVICE" | grep -oP 'ID \K[0-9a-f]{4}:[0-9a-f]{4}')
        BUS_RAW=$(echo "$FPRINT_DEVICE" | awk '{print $2}')
        BUS=$((10#$BUS_RAW))

        USB_DEVICE_PATH="/sys/bus/usb/devices/usb$BUS"
        USB_PATH=$(readlink -f "$USB_DEVICE_PATH")
        PCI_FUNC=$(echo "$USB_PATH" | grep -oP '[0-9a-f]{4}:[0-9a-f]{2}:[0-9a-f]{2}\.[0-9]' | tail -1)

        PCI_DEVICE_PATH="/sys/bus/pci/devices/$PCI_FUNC"
        DRIVER_LINK="$PCI_DEVICE_PATH/driver"
        DRIVER_NAME=$(basename "$(readlink -f "$DRIVER_LINK")")
        DRIVER_PATH="/sys/bus/pci/drivers/$DRIVER_NAME"

        logger -t fp-rebind "Checking fingerprint reader after wake"
        sleep 2

        if ! lsusb -d "$FPRINT_ID" >/dev/null 2>&1; then
          logger -t fp-rebind "Fingerprint missing, resetting controller $PCI_FUNC"
          echo "$PCI_FUNC" >"$DRIVER_PATH/unbind" 2>/dev/null || true
          sleep 1
          echo "$PCI_FUNC" >"$DRIVER_PATH/bind" 2>/dev/null || true
          sleep 2
          systemctl try-restart fprintd.service
        else
          logger -t fp-rebind "Reader present, no action needed"
        fi
      ''}";
    };
  };
}
