{ den, ... }: {
  den.aspects.nixos-common = {
    nixos =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        system,
        ...
      }:
      let
        _include = (args._include or import ../nixos/include.nix args);
      in
      with _include;
      {
        _module.args._include = _include;

        imports = [
          ../nixos/nix-ld.nix # for fork of vscode remote dev
          ../options-den.nix
          ../nixos/nixpkgs-workaround.nix
          ../nixos/customize.nix
          ../nixos/sudo-fprint-ssh-bypass.nix
          ../nixos/fprint-fix.nix
          ../nixos/bandaid
          ../nixos/ccache.nix
          ../nixos/basic.nix
          ../nixos/skip-lockscreen-click
          #./lix.nix
          #inputs.determinate.nixosModules.default
          "${inputs.nix-flatpak}/modules/nixos.nix"
          #inputs.musnix.nixosModules.musnix
          inputs.nix-index-database.nixosModules.nix-index
          #inputs.copyparty.nixosModules.default
          #inputs.chaotic.nixosModules.default
          inputs.impermanence.nixosModules.impermanence
          inputs.nixpkgs.nixosModules.notDetected
          #inputs.stylix.nixosModules.stylix
          inputs.chaotic.nixosModules.zfs-impermanence-on-shutdown # inputs.nur.legacyPackages."${system}".repos.mio.modules.zfs-impermanence-on-shutdown
          inputs.mio.legacyPackages."${system}".modules.darling
          inputs.mio.legacyPackages."${system}".modules.wireguird
          ../nixos/nixbuild.nix
          ../token.nix
          ../nixos/hardened.nix # does this break sddm?
        ];

        # Set your time zone.
        #time.timeZone = lib.mkForce "Pacific/Auckland";
        services.automatic-timezoned.enable = true;

        home-manager.sharedModules = [
          inputs.plasma-manager.homeModules.plasma-manager
          inputs.vscode-server.homeModules.default
          inputs.zen-browser.homeModules.default
          #inputs.android-nixpkgs.hmModule
          ../users.nix
          inputs.vicinae.homeManagerModules.default
          (
            {
              inputs,
              config,
              pkgs,
              lib,
              osConfig,
              ...
            }@args:
            let
              _include = (args._include or import ../nixos/include.nix args);
            in
            {
              _module.args._include = _include;
            }
          )
          (
            { ... }:
            {
              programs.vscode.package = progs.vscode;
            }
          )
        ];
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension =
          "hm-backup-"
          + (
            if config.system.configurationRevision != null then
              config.system.configurationRevision
            else
              "unknown"
          );

        # https://discourse.nixos.org/t/gdm-background-image-and-theme/12632/10
        nixpkgs.overlays = [
          inputs.nur.overlays.default
          #inputs.copyparty.overlays.default
          #inputs.android-nixpkgs.overlays.default
          inputs.nix-vscode-extensions.overlays.default
          #inputs.emacs-overlay.overlays.package
          (
            final: prev:
            let
              mio = inputs.mio.packages."${system}";
            in
            {
              #nur = pkgs'.nur; # this is more pure than applying inputs.nur.overlays.default on nixpkgs directly
              #grub2 = final.nur.repos.mio.grub2;
              #nix-output-monitor = inputs.mio.packages."${system}".nix-output-monitor; # final.nur.repos.mio.nix-output-monitor;
              inherit (mio) wireguird darling grub2;
              sniffnet = mio.sniffnet-patched;
              xfce4-terminal = mio.xfce4-terminal-patched;
              inherit (pkgs-openclaw) openclaw openclawPackages;
              inherit (pkgs-pin) rpcs3;
              inherit (pkgs-pin4)
                diffoscope
                ;
              inherit (pkgs') freecad pianotrans; # no binary cache with cuda and no binary cache with rocm
            }
          )
          inputs.chaotic.overlays.default
          inputs.mac-style-plymouth.overlays.default
          inputs.nix-bwrapper.overlays.default
          inputs.nix-webapps.overlays.lib
        ];

        boot.zfs.forceImportRoot = true; # It is highly recommended to set it to `false`, the new default from 26.11 on, to reduce the risk of data loss. Alternatively, you can silence this warning by explicitly setting it to `true`.

        security.rtkit.enable = config.services.pipewire.enable || config.services.pulseaudio.enable;
        services.pulseaudio.support32Bit = config.services.pulseaudio.enable && pkgs.stdenv.isx86_64;
        services.pipewire.alsa.support32Bit = config.services.pipewire.alsa.enable && pkgs.stdenv.isx86_64;
        services.jack.alsa.support32Bit = config.services.jack.alsa.enable && pkgs.stdenv.isx86_64;
        services.pipewire.pulse.enable = config.services.pipewire.enable;
        services.pipewire.alsa.enable = config.services.pipewire.enable;

        hardware.enableRedistributableFirmware = true;

        system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
        # https://github.com/oxalica/nixos-config/blob/03e0de362290bbfae8615192cdfc03f903f5f583/flake.nix#L78-L85
        # https://github.com/dramforever/config/blob/63be844019b7ca675ea587da3b3ff0248158d9fc/flake.nix#L24-L28
        system.nixos.label =
          with builtins;
          with inputs;
          lib.concatStringsSep "-" (
            (lib.sort (x: y: x < y) config.system.nixos.tags)
            ++ [
              (
                if self.sourceInfo ? lastModifiedDate then
                  "${substring 0 8 self.sourceInfo.lastModifiedDate}.${
                    self.sourceInfo.shortRev or self.dirtyShortRev or "dirty"
                  }"
                else
                  self.sourceInfo.shortRev or self.dirtyShortRev or "dirty"
              )
            ]
          );

        programs.ssh.package =
          if config.mio_openssh_hpn then pkgs.nur.repos.mio.openssh_hpn else pkgs.openssh_hpn;

        services.gnome.gnome-remote-desktop.enable = !config.services.pulseaudio.enable; # doesn't work with pulseaudio

        # https://wiki.nixos.org/wiki/GNOME - GDM does not show user
        environment.shells = with pkgs; [ zsh ];

        # https://github.com/nix-community/home-manager/issues/108#issuecomment-340397178
        programs.zsh.enable = lib.mkDefault false;

        #stylix = {
        #  enable = true;
        #  image = config.system_background;
        #};

        networking = {
          # Generate host ID from hostname
          hostId = builtins.substring 0 8 (builtins.hashString "sha256" config.networking.hostName);
        };

        nix = {
          nrBuildUsers = 128;
          #gc = {
          #  automatic = true;
          #  dates = "weekly";
          #};
          settings = {
            # https://github.com/NixOS/nixpkgs/blob/b103220c1aabc21529a02a8b52106d451d10cef6/nixos/modules/profiles/hardened.nix#L38C1-L40C1
            allowed-users = [ "@users" ];
            #lazy-trees = true;
            auto-optimise-store = true;
            experimental-features = [
              "nix-command"
              "flakes"
            ];
            trusted-users = [
              # "root" # root is already trusted by default
              "@wheel"
            ];
          };
          # https://determinate.systems/blog/changelog-determinate-nix-3111/
          # lazy-tree: Lazy trees are currently stable in Determinate Nix and enabled by default for all users. https://docs.determinate.systems/determinate-nix/#determinate-nix-configuration
          #extraOptions = ''
          #  eval-cores = 0 # Evaluate across all cores
          #'';
        };

        nixpkgs.config.allowUnfree = false;
        nixpkgs.config.allowUnfreePredicate = allowUnfreePredicate;
        nixpkgs.config.allowNonSource = false;
        nixpkgs.config.allowNonSourcePredicate = allowNonSourcePredicate;
        #nixpkgs.config.allowAliases = false;
        nixpkgs.config.allowDeprecatedx86_64Darwin = true; # hide deprecation warning. we aleady know.

        nixpkgs.config.permittedInsecurePackages =
          with pkgs;
          map (pkg: pkg.name) [
            librewolf
            librewolf-unwrapped
            librewolf-bin
            librewolf-bin-unwrapped
            openclaw
            electron_39
            openssl_1_1
            pnpm_9
            pnpm_10_29_2
            #  Ventoy uses binary blobs which can't be trusted to be free of malware or compliant to their licenses.
            ventoy
            ventoy-full-gtk
            ventoy-full-qt
          ];

        i18n.defaultLocale = lib.mkDefault "en_NZ.UTF-8";

        i18n.extraLocaleSettings = {
          LC_ADDRESS = lib.mkDefault "en_NZ.UTF-8";
          LC_IDENTIFICATION = lib.mkDefault "en_NZ.UTF-8";
          LC_MEASUREMENT = lib.mkDefault "en_NZ.UTF-8";
          LC_MONETARY = lib.mkDefault "en_NZ.UTF-8";
          LC_NAME = lib.mkDefault "en_NZ.UTF-8";
          LC_NUMERIC = lib.mkDefault "en_NZ.UTF-8";
          LC_PAPER = lib.mkDefault "en_NZ.UTF-8";
          LC_TELEPHONE = lib.mkDefault "en_NZ.UTF-8";
          LC_TIME = lib.mkDefault "en_NZ.UTF-8";
        };

        networking.firewall.allowedTCPPorts = [ 8080 ]; # temp file share with $ caddy file-server --browse --debug --listen :8080

        # https://search.nixos.org/packages
        environment.systemPackages =
          with pkgs;
          (map hardenedPkg [
            progs.git
            progs.openssh
            #nix-output-monitor

            curl
            wget
            proto
            smartmontools
            mdbook
            dust
            iotop
            nmap
            nixfmt
            nixfmt-tree
            #caddy # caddy file-server --browse
            #copyparty
            typst
            #dmidecode
            pciutils
            usbutils
            unzip
            zip
            #nvd # https://discourse.nixos.org/t/nvd-simple-nix-nixos-version-diff-tool/12397/21
            uv
            python3
            fd
            fzf
            file
            (lib.hiPrio btrfs-progs) # higher prio than builtin btrfs-progs when btrfs is enabled
            inputs.nm2nix.packages.${pkgs.stdenv.hostPlatform.system}.default
            #inputs.pinix.packages.${pkgs.stdenv.hostPlatform.system}.default
            dos2unix
            openssl
            nur.repos.mio.cb
            catimg
            psmisc
            lz4
            android-tools
            difftastic
            nix-output-monitor
            lsof
            imagemagick
            waypipe
            ripgrep
            # unfree:
            p7zip-rar
          ])
          ++ [
            script.upgrade
            script.switch
            script.boot
            script.upboot
          ]
          ++ lib.optionals config.mio_aria2 (
            map hardenedPkg [
              nur.repos.mio.aria2
              nur.repos.mio.aria2-wrapped
            ]
          )
          ++ lib.optionals (!config.mio_aria2) (map hardenedPkg [ aria2 ])
          ++ (map cleanPkg [
            ego
            #  they might execute some binary that doesn't like the grapheneos malloc
            progs.nodejs
            progs.pnpm
          ])
          ++ lib.optionals config.services.desktopManager.plasma6.enable (
            with pkgs.kdePackages;
            map (pkg: hardenedPkg (lib.hiPrio pkg)) [
              # Note: some packages are broken with hardenedPkg. Only list those known to work here.
              # https://github.com/NixOS/nixpkgs/blob/74a6c30612152d8b186f55f9c8b998f978afd6eb/nixos/modules/services/desktop-managers/plasma6.nix#L70-L218
              kwalletmanager
              kwin
              plasma-systemmonitor
              systemsettings
              # optionalPackages
              ark
              elisa
              gwenview
              okular
              dolphin
              spectacle
            ]
          );

        programs.nano.package = lib.mkDefault (cleanPkg pkgs.nano);
        programs.nano.enable = true;

        programs.fuse.enable = true;
        programs.fuse.userAllowOther = true;

        # Workaround for captive-browser unsupported flags
        # https://github.com/NixOS/nixpkgs/issues/533452#issuecomment-4762493257
        programs.captive-browser.browser =
          let
            newBrowserArgs =
              chromium:
              lib.concatStringsSep " " [
                ''env XDG_CONFIG_HOME="$PREV_CONFIG_HOME"''
                "${chromium}/bin/chromium"
                "--user-data-dir=\${XDG_DATA_HOME:-$HOME/.local/share}/chromium-captive"
                ''--proxy-server="socks5://$PROXY"''
                "--no-first-run"
                "--new-window"
                "--incognito"
                "-no-default-browser-check"
                "http://cache.nixos.org/"
              ];
          in
          newBrowserArgs pkgs.chromium;

        # https://zhuanlan.zhihu.com/p/671801498
        fonts = {
          packages = with pkgs; [
            #nerd-fonts.ubuntu-mono
            #nerd-fonts.jetbrains-mono
            #noto-fonts
            #nerd-fonts.noto
            noto-fonts-cjk-sans
            noto-fonts-cjk-serif
            noto-fonts-color-emoji
            nerd-fonts.fira-code
            #nerd-fonts.sauce-code-pro
            #source-code-pro
            # flatpak com.baidu.NetDisk https://tieba.baidu.com/p/8889052162 https://github.com/qier222/YesPlayMusic/issues/2121
            source-han-sans
            #source-han-mono
            source-han-serif
            wqy_zenhei
            wqy_microhei
          ];
          fontconfig = {
            antialias = true;
            hinting.enable = true;
            defaultFonts = {
              emoji = [ "Noto Color Emoji" ];
              monospace = [ "FiraCode Nerd Font" ];
              sansSerif = [ "Noto Sans CJK SC" ];
              serif = [ "Noto Serif CJK SC" ];
            };
          };
        };

        programs.tmux.package = lib.mkDefault (cleanPkg pkgs.tmux);
        programs.tmux.enable = true;
        programs.tmux.extraConfig = ''
          set -g mouse on
        '';

        # https://github.com/nix-community/home-manager/blob/9e3a33c0bcbc25619e540b9dfea372282f8a9740/modules/programs/zsh/default.nix#L166
        #environment.pathsToLink = [ "/share/zsh" ];

        programs.fish.enable = true;
        programs.fish.useBabelfish = true;

        # documentation.enable = lib.mkDefault false;
        # https://discourse.nixos.org/t/solve-slow-man-cache-the-content-addressed-way-but-not-ca-derivation/58463/2
        # documentation.man.cache.enable = lib.mkDefault false;

        hardware.nvidia = {
          package = config.boot.kernelPackages.nvidiaPackages.latest;
        };

        # https://github.com/EmergentMind/nix-config/blob/9a9fefd9ab5ebbaf9530dafdb6d45b734606f645/hosts/common/core/nixos.nix#L25
        security.sudo.extraConfig = "Defaults timestamp_timeout=120";

        # https://discourse.nixos.org/t/logrotate-config-fails-due-to-missing-group-30000/28501/9
        #security.unprivilegedUsernsClone = true;

        # /nix/store/9m6xh63j8mvragnhra8k7rchwxldcrry-systemd-258.2/share/polkit-1/rules.d/10-systemd-logind-root-ignore-inhibitors.rules.example
        security.polkit.extraConfig = ''
          // SPDX-License-Identifier: MIT-0
          //
          // This config file is installed as part of systemd.
          // It may be freely copied and edited (following the MIT No Attribution license).
          //
          // This example can be enabled by symlinking this file to
          // /etc/polkit-1/rules.d/10-systemd-logind-root-ignore-inhibitors.rules

          // Allow the root user to ignore inhibitors when calling reboot etc.
          polkit.addRule(function(action, subject) {
              if ((action.id == "org.freedesktop.login1.power-off-ignore-inhibit" ||
                   action.id == "org.freedesktop.login1.reboot-ignore-inhibit" ||
                   action.id == "org.freedesktop.login1.halt-ignore-inhibit" ||
                   action.id == "org.freedesktop.login1.suspend-ignore-inhibit" ||
                   action.id == "org.freedesktop.login1.hibernate-ignore-inhibit") &&
                  subject.user == "root") {

                  return polkit.Result.YES;
              }
          });
        '';

        security.sudo.execWheelOnly = lib.mkDefault true;

        systemd.tmpfiles.rules = [
          "f /tmp/vscode-skip-server-requirements-check 0644 root root -"
        ];

        #services.flatpak.update.onActivation = true; # maybe need this if we always don't use nixos-rebuild switch - https://github.com/gmodena/nix-flatpak/issues/191
        services.flatpak.uninstallUnmanaged = true;

        services.flatpak.overrides = {
          global = {
            # Force Wayland by default
            Context.sockets = lib.mkIf (!config.services.xserver.enable) [
              "wayland"
              "!x11"
              "!fallback-x11"
            ];
          };
        };

        boot.loader.systemd-boot.includeDistroName = false;
        boot.loader.systemd-boot.entryNamePrefix = "#";
        boot.loader.systemd-boot.ambiguousDateFormat = true;
        boot.loader.systemd-boot.bootCounting.enable = true;

        # https://github.com/fpletz/flake/blob/b8aadc8b398c00a43ca85f28cf420073b030adad/nixos/modules/hardware/thinkpad-x230.nix#L25-L28
        boot.blacklistedKernelModules = [
          "mei_me"
          "mei"
        ];

        # this fix work for sudo but not ego on razer
        /*
          # https://github.com/NixOS/nixpkgs/issues/483867
          systemd.services."polkit-agent-helper@".serviceConfig = {
            PrivateDevices = "no";
            DeviceAllow = [
              "char-mem"
              "char-hidraw"
              "char-video4linux"
            ];
            ProtectHome = "read-only";
          };
        */

        hardware.wirelessRegulatoryDatabase = lib.mkIf (
          config.networking.wireless.enable || config.networking.wireless.iwd.enable
        ) true;
        # https://github.com/NixOS/nixpkgs/issues/25378#issuecomment-1097034289
        # https://github.com/maxhbr/myconfig/blob/766a19abd348fb507d5f2a40bf20d34f937ca58d/hardware/RZ717.nix#L11-L19
        networking.wireless.extraConfig =
          lib.mkIf (config.networking.wireless.enable || config.networking.wireless.iwd.enable)
            ''
              country=${countryCode}
            '';
        boot.extraModprobeConfig =
          lib.mkIf (config.networking.wireless.enable || config.networking.wireless.iwd.enable)
            ''
              options cfg80211 ieee80211_regdom="${countryCode}"
            '';
        hardware.wireless.regulatoryDomain = lib.mkIf (
          config.networking.wireless.enable || config.networking.wireless.iwd.enable
        ) countryCode;

        # https://github.com/NixOS/nixpkgs/issues/432276
        powerManagement.powerDownCommands = lib.mkIf (config.services.fprintd.enable && kdeDMEnabled) ''
          ${config.systemd.package}/bin/systemctl stop fprintd.service 2>/dev/null || true
        '';
        /*
          powerManagement.resumeCommands = lib.mkIf (config.services.fprintd.enable && kdeDMEnabled) ''
            ${config.systemd.package}/bin/systemctl start fprintd.service 2>/dev/null || true
          '';
        */
      };
  };

  den.default.includes = [ den.aspects.nixos-common ];
}
