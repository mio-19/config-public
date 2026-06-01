{
  config,
  inputs,
  lib,
  pkgs,
  _include,
  ...
}@args:
let
  pool = "ipcv3";
in
with _include;
{
  imports = [
    ../bios.nix
    ../hidpi.nix
    #../betterbird.nix # tired of compiling
    ../keep.nix
    ../music.nix
    ../privacy.nix
    ../careless.nix
    ../boot.nix
    ../v3.nix
    #../v3opt.nix # needs too many time to compile
    ../wheel-nopasswd.nix
    #../safe.nix
    ../zfs.nix
    inputs.nixos-hardware.nixosModules.common-cpu-intel-cpu-only
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    #inputs.nixos-hardware.nixosModules.common-gpu-nvidia-sync # prime is only for igpu+dgpu, right?
    # DETAILS REMOVED
    ./disk-v3.nix
    ../persistent.nix
    ../desktop-baremetal-kde.nix
    #../desktop-specialisation.nix
    ../zswap.nix
    ../alwaysonsys.nix
    ../extra.nix
    ../extra2.nix
    ../desktopextra.nix
    #../desktop-offline.nix
    #../sunshine.nix
    #../genai.nix # too much time to compile
    ../devcommand.nix
    ../cuda.nix
    ../games.nix
    #../games-extra.nix
    ../persistentkde.nix
    #../niri
    #../localai.nix
    ../scx.nix
    ../keepBootedSystemEntry.nix
    ../printing-sharing.nix
    ../harmonia_lan_only_not_public_ip.nix
  ];
  compile_gram = true;
  hdr_very_bright = true;
  #hardware.facter.reportPath = ./facter.json; # DETAILS REMOVED

  nixpkgs.overlays = [
    # DETAILS REMOVED
  ];

  zfs_arc_max_mib = 70000;
  security.pam.zfs.enable = true;
  security.pam.zfs.homes = "${pool}/nixos/safe/encrypted";
  chaotic.zfs-impermanence-on-shutdown.volume = "${pool}/nixos/local/ephemeral";

  virtualisation.vmware.host.enable = true;
  virtualisation.virtualbox.host.enable = true;

  #boot.kernelPackages = pkgs.linuxPackages_6_12;
  boot.kernelPackages = pkgs.linuxPackages_cachyos-gcc.cachyOverride { mArch = "GENERIC_V3"; };
  #boot.kernelPackages = pkgs.linuxPackages_cachyos-lto.cachyOverride { mArch = "GENERIC_V3"; };
  boot.zfs.package = pkgs.zfs_cachyos;
  #boot.kernelPackages = pkgs.nur.repos.mio.lib.zfs-latestCompatibleLinuxPackages;

  security.allowSimultaneousMultithreading = false; # maybe this avoid Machine Check error https://www.reddit.com/r/techsupport/comments/1am75eu/machine_check_errors_on_14700kf_faulty_cpu/?rdt=32949

  home-manager.users.user = ../user.nix;
  # DETAILS REMOVED
  home-manager.extraSpecialArgs = {
    enable-fcitx = true;
  };

  boot.kernel.sysctl = {
    "vm.swappiness" = lib.mkForce 1;
  };

  users.mutableUsers = false;
  users.users.root = {
    shell = pkgs.fish;
    hashedPasswordFile = "/persistent/etc/pass-user-user";
    openssh.authorizedKeys.keys = (import ../../sshkeys.nix);
  };
  # DETAILS REMOVED
  users.users.user = {
    hashedPasswordFile = "/persistent/etc/pass-user-user";
    uid = 1001;
    isNormalUser = true;
    shell = pkgs.zsh;
    ignoreShellProgramCheck = true; # https://github.com/nix-community/home-manager/issues/108#issuecomment-2569823607
    openssh.authorizedKeys.keys = import ../../sshkeys.nix;
    extraGroups = extraAdminGroups;
  };
  # DETAILS REMOVED

  boot.kernelParams = [
    "nohibernate" # no hibernate swap configured
  ];
  # ++ lib.optionals config.services.xserver.enable [
  #  # https://bbs.archlinux.org/viewtopic.php?id=299995
  #  "nvidia_drm.modeset=0"
  #];

  boot.loader = {
    timeout = 8;
    grub.memtest86.enable = true;
    grub.enable = true;
    # https://nixos.wiki/wiki/Dual_Booting_NixOS_and_Windows
    grub.useOSProber = true;
    # https://discourse.nixos.org/t/question-about-grub-and-nodev/37867
    grub.device = "nodev";
    # https://www.reddit.com/r/NixOS/comments/klahwf/comment/kt10tt8
    #grub.default = "saved";
    grub.default = "'Windows Boot Manager'";
    grub.efiSupport = true;
    efi.canTouchEfiVariables = true;
    # https://discourse.nixos.org/t/change-grub-resolution/18273/5
    # https://askubuntu.com/questions/1227735/grub-is-extremely-slow-1-second-per-key-input/1278780#1278780
    grub.gfxmodeEfi = lib.mkForce "1280x720,auto";
    grub2-theme = {
      enable = true;
      # DETAILS REMOVED
      splashImage = ../black.png;
      theme = "stylish";
      #theme = "whitesur";
      #icon = "whitesur";
      footer = true;
      #screen = "4k";
    };
  };

  # neededForBoot flag is not settable from disko
  fileSystems = {
    "/nix".neededForBoot = true;
    "/home".neededForBoot = true;
    "/var/log".neededForBoot = true;
    "/var/cache".neededForBoot = true;
    "/persistent".neededForBoot = true;
  };
  networking.hostName = "ipc";

  networking.firewall.allowedTCPPorts = [ 8080 ]; # temp file share with $ caddy file-server --browse --debug --listen :8080

  # https://nixos.wiki/wiki/OpenSnitch
  #services.opensnitch.enable = true; # no: tired of approving every connection

  # https://search.nixos.org/packages
  environment.systemPackages = with pkgs; [
    lynx
    config.services.lact.package
    ollama-cuda # OLLAMA_CONTEXT_LENGTH=131072 ollama serve
    #config.programs.corectrl.package
    # unfree
    #nur.repos.mio.zw3d
  ];

  #virtualisation.docker.rootless.enable = true;
  #virtualisation.docker.rootless.setSocketVariable = true;
  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = false;
  virtualisation.docker.autoPrune.enable = true; # docker prune -f

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true; # Show battery charge of Bluetooth devices
      };
    };
  };

  services.printing.stateless = true;

  services.lact = {
    enable = true;
  };
  #programs.corectrl.enable = true;
  powerManagement.cpuFreqGovernor = "performance";
  /*
    services.undervolt = {
      enable = true;
      #turbo = 0;
      # https://github.com/sioodmy/dotfiles/blob/9cd5535bbe7417dd7b9f81aeb0628c3057e1ab66/modules/laptop/default.nix#L23
      # https://github.com/jakeisnt/nixcfg/blob/e9230d4f90a855a290882a6e7862c593a114cf5e/hosts/xps/hardware-configuration.nix#L141
      #coreOffset = -40;
      gpuOffset = -80;
      #uncoreOffset = -40;
    };
  */

  # https://nixos.wiki/wiki/Nvidia
  # Load nvidia driver for Xorg and Wayland
  # For offloading, `modesetting` is needed additionally,
  # otherwise the X-server will be running permanently on nvidia,
  # thus keeping the GPU always on (see `nvidia-smi`).
  services.xserver.videoDrivers = [
    # IF WE DON"T OFFLOAD, DISABLE "modesettings". Otherwise lightdm crashes with (EE) failed to create pixmap
    #"modesetting"
    "nvidia"
  ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;
    prime = {
      # disable prime
      sync.enable = false;
      offload.enable = false;
      reverseSync.enable = false;
      # nix-shell -p lshw
      # get id from sudo lshw -c display
      # Make sure to use the correct Bus ID values for your system!
      nvidiaBusId = "PCI:1:0:0";
    };
  };
  # https://bbs.archlinux.org/viewtopic.php?id=299995
  #environment.etc."X11/xorg.conf.d/10-nvidia.conf".text = ''
  #  Section "Device"
  #      Identifier     "Device0"
  #      Driver         "nvidia"
  #      VendorName     "NVIDIA Corporation"
  #      BusID          "PCI:1:0:0"
  #  EndSection
  #'';

  hardware.cpu.intel.updateMicrocode = true;

  # https://github.com/musnix/musnix
  #musnix.enable = true; # has conflicts with our limit settings for wine esync!
  # https://wiki.nixos.org/wiki/PipeWire
  services.pipewire = {
    systemWide = true;
    # If you want to use JACK applications, uncomment the following
    jack.enable = false; # it conflicts with gentoo prefix bootstrap because of LD_LIBRARY_PATH
    wireplumber.extraConfig = {
      # 90-wh1000xm4-no-hw-volume doesn't really work, disable for now
      /*
        "90-wh1000xm4-no-hw-volume" = {
          "monitor.bluez.rules" = [
            {
              matches = [
                { "device.name" = "bluez_card.94_DB_56_73_6A_73"; }
              ];
              actions = {
                update-props = {
                  "bluez5.enable-hw-volume" = false;
                };
              };
            }
          ];
        };
      */
      # no: now we are not using hdmi audio.
      /*
            "51-hdmi-default" = {
              "monitor.alsa.rules" = [
                # Prefer HDMI
                {
                  matches = [
                    { "node.name" = "alsa_output.pci-0000_01_00.1.hdmi-stereo"; }
                  ];
                  actions = {
                    update-props = {
                      "priority.session" = 2000;
                      "priority.driver" = 2000;
                    };
                  };
                }

                # De-prioritize built-in digital audio
                {
                  matches = [
                    { "node.name" = "alsa_output.pci-0000_00_1f.3.iec958-stereo"; }
                  ];
                  actions = {
                    update-props = {
                      "priority.session" = 100;
                      "priority.driver" = 100;
                    };
                  };
                }
              ];
            };
      */
      "51-hdmi-default" = {
        "monitor.alsa.rules" = [
          # De-prioritize HDMI
          {
            matches = [
              { "node.name" = "alsa_output.pci-0000_01_00.1.hdmi-stereo"; }
            ];
            actions = {
              update-props = {
                "priority.session" = 100;
                "priority.driver" = 100;
              };
            };
          }

          #Prefer built-in digital audio
          {
            matches = [
              { "node.name" = "alsa_output.pci-0000_00_1f.3.iec958-stereo"; }
            ];
            actions = {
              update-props = {
                "priority.session" = 2000;
                "priority.driver" = 2000;
              };
            };
          }
        ];
      };
    };
  };
  services.pipewire.enable = true;

  services.power-profiles-daemon.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.openssh.enable = true;
  services.openssh.openFirewall = true;
  services.openssh.settings.PasswordAuthentication = false;
  services.openssh.settings.X11Forwarding = true;

  networking.nftables.enable = true;

  services.tailscale.enable = true;
  services.tailscale.useRoutingFeatures = "both";

  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "25.11";

  # see common commands: https://gist.github.com/arafays/619c2fd24db34592b1626c51544d719f
  # can cause problems with fdroidbuild in distrobox
  #services.cloudflare-warp.enable = true;
  services.cloudflare-warp.openFirewall = true;

  # documentation.man.cache.enable = true;
  # documentation.enable = true;
}
