{
  config,
  inputs,
  lib,
  pkgs,
  osConfig ? config,
  ...
}@args:
let
  upper = (import ../include.nix args);
in
with upper;
upper
// rec {
  countryCode = "NZ";
  inherit (pkgs) fetchpatch;
  mkNixPak = inputs.nixpak.lib.nixpak {
    inherit (pkgs) lib;
    inherit pkgs;
  };
  mioPak =
    config:
    if boot-to-steam then
      (config { sloth = lib.throw "no sloth"; }).app.package
    else
      (mkNixPak {
        config =
          args1@{ sloth, ... }:
          let
            prev = config args1;
            _bubblewrap = prev.bubblewrap or { };
            _bind = _bubblewrap.bind or { };
            _dev = _bind.dev or [ ];
          in
          prev
          // {
            bubblewrap = _bubblewrap // {
              bind = _bind // {
                dev = _dev ++ [
                  "/dev/dri"
                  "/dev/nvidia0"
                  "/dev/nvidiactl"
                  "/dev/nvidia-modeset"
                  "/dev/nvidia-uvm"
                  "/dev/nvidia-uvm-tools"
                ];
              };
            };
          };
      }).config.env;
  novirt = (!osConfig.services.qemuGuest.enable);
  progs = with pkgs; rec {
    telegram =
      if config.compile_gram then
        pkgs-pin4.nur.repos.mio.telegram-desktop
      else
        pkgs-pin4.telegram-desktop;
    materialgram = if config.compile_gram then pkgs.nur.repos.mio.materialgram else pkgs.materialgram;
    mcpelauncher-ui-qt = pkgs.mcpelauncher-ui-qt;
    # cannot get bwrapper to work with mcpe login page
    mcpelauncher-ui-qt_failedAttempt1 = mkBwrapper {
      mounts = {
        read = [ "/etc/fonts" ];
        readWrite = [
        ];
      };
      app = {
        package = pkgs.mcpelauncher-ui-qt;
        runScript = "mcpelauncher-ui-qt";
      };
      flatpak.manifestFile = pkgs.fetchurl {
        url = "https://github.com/flathub/io.mrarm.mcpelauncher/raw/refs/heads/master/io.mrarm.mcpelauncher.json";
        hash = "sha256-GvR9+DafntPD6eV+gq3ElXQ4gnETF4aUGkWTVlOJ2H8=";
      };
    };
    # login doesn't save, but otherwise works fine
    mcpelauncher-ui-qt_slightlyfailed = mioPak (
      { sloth, ... }:
      {
        app.package = pkgs.mcpelauncher-ui-qt;
        dbus.enable = true;
        dbus.policies = {
          "org.freedesktop.portal.Desktop" = "talk";
          "org.freedesktop.portal.Documents" = "talk";
          "org.freedesktop.portal.Settings" = "talk";
          "org.freedesktop.DBus" = "talk";
          "ca.desrt.dconf" = "talk";
          "org.gnome.Mutter.IdleMonitor" = "talk"; # harmless if absent
        };
        flatpak.appId = "io.mrarm.mcpelauncher";
        bubblewrap = {
          network = true;

          bind.ro = [
            "/etc"
            "/sys"
          ];
          bind.rw = [
            (sloth.concat' sloth.homeDir "/.local/share/mcpelauncher")
            (sloth.concat' sloth.homeDir "/.cache/mcpelauncher-webview")
            (sloth.env "XDG_RUNTIME_DIR")
            "/run"
          ];
        };
      }
    );
    # mostly working but scenery broken!
    flightgear_failedAttempt1 = mkBwrapper {
      app = {
        package = pkgs.flightgear;
        runScript = "fgfs";
      };
      flatpak.manifestFile =
        let
          yaml = pkgs.fetchurl {
            url = "https://github.com/flathub/org.flightgear.FlightGear/raw/refs/heads/master/org.flightgear.FlightGear.yaml";
            hash = "sha256-xsbjEftN0Kf7igK7ddfLCJPgT2IChbLA4Qdk9z9M4cE=";
          };
        in
        # https://discourse.nixos.org/t/how-to-convert-yaml-nix-object/23755/2
        # https://github.com/cdepillabout/stacklock2nix/blob/65a34bec929e7b0e50fdf4606d933b13b47e2f17/nix/build-support/stacklock2nix/read-yaml.nix
        runCommand "from-yaml" {
          nativeBuildInputs = [ remarshal ];
        } "remarshal -if yaml -i \"${yaml}\" -of json -o \"$out\"";
    };
    zulip = mioPak (
      { sloth, ... }:
      {
        app.package = hardenedPkg pkgs.zulip;
        dbus.enable = true;
        dbus.policies = {
          "org.freedesktop.portal.Desktop" = "talk";
          "org.freedesktop.portal.Documents" = "talk";
          "org.freedesktop.portal.Settings" = "talk";
          "org.freedesktop.DBus" = "talk";
          "ca.desrt.dconf" = "talk";
          #"org.freedesktop.Notifications" = "talk"; # TODO: tray icon still not fixed
        };
        flatpak.appId = "org.zulip.Zulip";
        bubblewrap = {
          network = true;

          bind.ro = [
            "/etc"
            "/sys"
          ];
          bind.rw = [
            (sloth.concat' sloth.homeDir "/.config/Zulip")
            (sloth.env "XDG_RUNTIME_DIR")
            "/run"
          ];
        };
      }
    );
    librewolf_for_firejail =
      if config.use_librewolf_bin then librewolf_for_firejail_bin else librewolf_for_firejail_src;
    librewolf_for_firejail_bin = cleanPkg (
      wrapFirefox librewolf-bin-unwrapped {
        # from nixpkgs
        pname = "librewolf-bin";
        extraPrefsFiles = [
          "${librewolf-bin-unwrapped}/lib/librewolf-bin-${librewolf-bin-unwrapped.version}/librewolf.cfg"
        ];
        extraPoliciesFiles = [
          "${librewolf-bin-unwrapped}/lib/librewolf-bin-${librewolf-bin-unwrapped.version}/distribution/extra-policies.json"
        ];
        # for firejail:
        # https://forum.manjaro.org/t/browsers-like-firefox-require-xdg-desktop-portal-package-to-use-os-default-file-manager/106933
        # keep file picker in firejail - more obvious what file cannot be picked - bug that picker with portal can still only pick files in firejail.
        # lockPref("widget.use-xdg-desktop-portal.file-picker", 1);
        extraPrefs = ''
          lockPref("widget.use-xdg-desktop-portal.file-picker", 2);
          lockPref("widget.use-xdg-desktop-portal.location", 1);
          lockPref("widget.use-xdg-desktop-portal.mime-handler", 1);
          lockPref("widget.use-xdg-desktop-portal.open-uri", 1);
          lockPref("widget.use-xdg-desktop-portal.settings", 1);
        '';
      }
    );
    librewolf_for_firejail_src = cleanPkg (
      wrapFirefox librewolf-unwrapped {
        # from nixpkgs
        inherit (librewolf-unwrapped) extraPrefsFiles extraPoliciesFiles;
        libName = "librewolf";
        # for firejail:
        # https://forum.manjaro.org/t/browsers-like-firefox-require-xdg-desktop-portal-package-to-use-os-default-file-manager/106933
        # keep file picker in firejail - more obvious what file cannot be picked - bug that picker with portal can still only pick files in firejail.
        # lockPref("widget.use-xdg-desktop-portal.file-picker", 1);
        extraPrefs = ''
          lockPref("widget.use-xdg-desktop-portal.file-picker", 2);
          lockPref("widget.use-xdg-desktop-portal.location", 1);
          lockPref("widget.use-xdg-desktop-portal.mime-handler", 1);
          lockPref("widget.use-xdg-desktop-portal.open-uri", 1);
          lockPref("widget.use-xdg-desktop-portal.settings", 1);
        '';
      }
    );
    librewolf'_for_firejail =
      if config.use_librewolf_bin then librewolf'_for_firejail_bin else librewolf'_for_firejail_src;
    librewolf'_for_firejail_bin = cleanPkg (
      wrapFirefox librewolf-bin-unwrapped {
        # from nixpkgs
        pname = "librewolf-bin";
        extraPrefsFiles = [
          "${librewolf-bin-unwrapped}/lib/librewolf-bin-${librewolf-bin-unwrapped.version}/librewolf.cfg"
        ];
        extraPoliciesFiles = [
          "${librewolf-bin-unwrapped}/lib/librewolf-bin-${librewolf-bin-unwrapped.version}/distribution/extra-policies.json"
        ];
        # for firejail:
        # https://forum.manjaro.org/t/browsers-like-firefox-require-xdg-desktop-portal-package-to-use-os-default-file-manager/106933
        # keep file picker in firejail - more obvious what file cannot be picked - bug that picker with portal can still only pick files in firejail.
        # lockPref("widget.use-xdg-desktop-portal.file-picker", 1);
        extraPrefs = librewolf_customize_prefs + ''
          lockPref("widget.use-xdg-desktop-portal.file-picker", 2);
          lockPref("widget.use-xdg-desktop-portal.location", 1);
          lockPref("widget.use-xdg-desktop-portal.mime-handler", 1);
          lockPref("widget.use-xdg-desktop-portal.open-uri", 1);
          lockPref("widget.use-xdg-desktop-portal.settings", 1);
        '';
      }
    );
    librewolf'_for_firejail_src = cleanPkg (
      wrapFirefox librewolf-unwrapped {
        # from nixpkgs
        inherit (librewolf-unwrapped) extraPrefsFiles extraPoliciesFiles;
        libName = "librewolf";
        # for firejail:
        # https://forum.manjaro.org/t/browsers-like-firefox-require-xdg-desktop-portal-package-to-use-os-default-file-manager/106933
        # keep file picker in firejail - more obvious what file cannot be picked - bug that picker with portal can still only pick files in firejail.
        # lockPref("widget.use-xdg-desktop-portal.file-picker", 1);
        extraPrefs = librewolf_customize_prefs + ''
          lockPref("widget.use-xdg-desktop-portal.file-picker", 2);
          lockPref("widget.use-xdg-desktop-portal.location", 1);
          lockPref("widget.use-xdg-desktop-portal.mime-handler", 1);
          lockPref("widget.use-xdg-desktop-portal.open-uri", 1);
          lockPref("widget.use-xdg-desktop-portal.settings", 1);
        '';
      }
    );
    vscode = pkgs.vscode; # vscode-fhs;
    discord = pkgs.discord.override {
      withVencord = true;
      withOpenASAR = true;
    };
    inkscape =
      # https://github.com/Chaddai/nixpkgs/blob/f73d4f0ad010966973bc81f51705cef63683c2f2/doc/packages/inkscape.section.md?plain=1#L18
      (
        inkscape-with-extensions.override {
          inkscapeExtensions = with pkgs.inkscape-extensions; [ inkstitch ];
        }
      );
  };
  program = rec {
    openssh =
      if config.mio_openssh_hpn then
        lib.hiPrio (pkgs.nur.repos.mio.openssh_hpn)
      else
        lib.hiPrio pkgs.openssh_hpn;
    git = (pkgs.git.override { openssh = program.openssh; });
    jdk = pkgs.jdk25; # pkgs.graalvmPackages.graalvm-ce; # pkgs.graalvmPackages.graalvm-oracle;  # graalvm-ce is binaryNativeCode
    jre = jdk;
    jdk_headless = jdk;
    scala_3 = pkgs.scala_3.override { jre = jre; };
    nodejs = pkgs.nodejs_latest;
    nodejs-slim = pkgs.nodejs-slim_latest;
    pnpm = pkgs.pnpm.override { inherit nodejs-slim; };
    antlr = pkgs.antlr.override { jre = program.jre; };
    librewolf' =
      (if config.use_librewolf_bin then pkgs'.librewolf-bin else pkgs'.librewolf).override
        (old: {
          extraPrefs = (old.extraPrefs or "") + librewolf_customize_prefs;
        });
    betterbird = inputs.mio-betterbird.packages.${pkgs.stdenv.hostPlatform.system}.betterbird;
  };

  pkgs' = import inputs.nixpkgs {
    config = osConfig.nixpkgs.config // {
      cudaSupport = false;
      rocmSupport = false;
    };
    system = pkgs.stdenv.hostPlatform.system;
    overlays = [ inputs.nur.overlays.default ];
  };

  script =
    let
      # env NIX_REMOTE=daemon -> workaround for https://github.com/NixOS/nixpkgs/issues/220990
      cmd = action: ''
        sudo ${config.systemd.package}/bin/systemd-inhibit env NIX_REMOTE=daemon ${lib.getExe pkgs.nixos-rebuild-ng} ${action} --flake . --log-format internal-json -v "$@" |& ${pkgs.nix-output-monitor}/bin/nom --json
      '';
    in
    {
      upgrade = lib.mkIf (config.system.nixos.tags == [ ] && !config.system.etc.overlay.enable) (
        pkgs.writeShellScriptBin "upgrade" ''
          set -e
          cd ~/Documents/config/nixos
          git config pull.rebase false
          sudo true # sudo with pipe can cause issues when sudo wants a password. this pre-authenticates
          git pull --no-edit
          if [ -d  ~/Documents/config-public ]; then
            cd ~/Documents/config-public/nixos
            git config pull.rebase false
            git pull --no-edit
            nix flake update
            git add flake.lock
            git commit -m "nixos: lockup" || true
            git push
            cd ~/Documents/config/nixos
            git pull --no-edit https://github.com/mio-19/config-public.git
          else
            git pull --no-edit https://github.com/mio-19/config-public.git
            nix flake update
            git add flake.lock
            git commit -m "nixos: lockup" || true
          fi
          git push &
          ${cmd "switch"}
        ''
      );
      upboot = pkgs.writeShellScriptBin "upboot" ''
        set -e
        cd ~/Documents/config/nixos
        git config pull.rebase false
        sudo true # sudo with pipe can cause issues when sudo wants a password. this pre-authenticates
        git pull --no-edit
        if [ -d  ~/Documents/config-public ]; then
          cd ~/Documents/config-public/nixos
          git config pull.rebase false
          git pull --no-edit
          nix flake update
          git add flake.lock
          git commit -m "nixos: lockup" || true
          git push
          cd ~/Documents/config/nixos
          git pull --no-edit https://github.com/mio-19/config-public.git
        else
          git pull --no-edit https://github.com/mio-19/config-public.git
          nix flake update
          git add flake.lock
          git commit -m "nixos: lockup" || true
        fi
        git push &
        ${cmd "boot"}
      '';
      switch = lib.mkIf (config.system.nixos.tags == [ ] && !config.system.etc.overlay.enable) (
        pkgs.writeShellScriptBin "swit" ''
          set -e
          cd ~/Documents/config/nixos
          git config pull.rebase false
          sudo true # sudo with pipe can cause issues when sudo wants a password. this pre-authenticates
          (git -c http.lowSpeedLimit=10000 -c http.lowSpeedTime=10 -c core.sshCommand="ssh -o ConnectTimeout=15" pull --no-edit && git -c http.lowSpeedLimit=10000 -c http.lowSpeedTime=10 -c core.sshCommand="ssh -o ConnectTimeout=15" pull --no-edit https://github.com/mio-19/config-public.git) || true
          git push &
          ${cmd "switch"}
        ''
      );
      boot = pkgs.writeShellScriptBin "boot" ''
        set -e
        cd ~/Documents/config/nixos
        git config pull.rebase false
        sudo true # sudo with pipe can cause issues when sudo wants a password. this pre-authenticates
        (git -c http.lowSpeedLimit=10000 -c http.lowSpeedTime=10 -c core.sshCommand="ssh -o ConnectTimeout=15" pull --no-edit && git -c http.lowSpeedLimit=10000 -c http.lowSpeedTime=10 -c core.sshCommand="ssh -o ConnectTimeout=15" pull --no-edit https://github.com/mio-19/config-public.git) || true
        git push &
        ${cmd "boot"}
      '';
    };

  hardened-slow =
    osConfig.services.displayManager.defaultSession != "steam"
    && !(osConfig.jovian.steam.enable or false);
  # DETAILS REMOVED
  filterExistingGroups =
    groups: builtins.filter (group: builtins.hasAttr group osConfig.users.groups) groups;
  commonGroups = [
    "users"
  ]
  ++ filterExistingGroups [
    "networkmanager"
    "audio"
    "jackaudio"
    "adbusers"
    "openrazer"
    "pipewire"
    "pulse-access"
    "realtime"
    "dialout" # for serial ports
    "input" # for bongocat
    "vboxusers"
  ];
  commonAdminGroups = commonGroups ++ [
    "wheel"
  ];
  extraAdminGroups =
    commonAdminGroups
    ++ filterExistingGroups [
      "kvm"
      "docker"
      "corectrl"
      "wireshark"
    ];
  /*
    evalValue =
      expr:
      (lib.evalModules {
        modules = [
          (
            { lib, ... }:
            {
              options._value = lib.mkOption {
                type = lib.types.anything;
                default = null;
              };
              osConfig._value = expr;
            }
          )
        ];
      }).osConfig._value;
  */
  wrapPkg =
    suffix: args: pkg:
    pkgs.symlinkJoin (
      lib.filterAttrs (_: v: v != null) {
        pname = pkg.pname or null;
        version = pkg.version or null;
        meta = lib.filterAttrs (_: v: v != null) {
          priority = pkg.meta.priority or null;
          mainProgram = pkg.meta.mainProgram or null;
        };
        name = "${pkg.name}-${suffix}";
        paths = [ pkg ];
        nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
        postBuild = ''
          for program in "${pkg}/bin/"*; do
            if [[ -f "$program" && -x "$program" ]]; then
              rm "$out/bin/$(basename "$program")"
              makeWrapper "$program" "$out/bin/$(basename "$program")" ${
                builtins.replaceStrings [ "\n" ] [ " " ] args
              }
            fi
          done
          if [ -d "$out/share/dbus-1/services" ] && [ -n "$(ls "$out/share/dbus-1/services")" ]; then
            rm -fr "$out/share/dbus-1/services"/*
            cp --force --dereference --recursive "${pkg}/share/dbus-1/services/"* "$out/share/dbus-1/services/"
            substituteInPlace $out/share/dbus-1/services/*.service \
              --replace ${pkg}/bin $out/bin
          fi
        '';
      }
    );
  # https://github.com/surfaceflinger/notflake/blob/c71bd18a369b652b2a2224225da938c7af235636/packages/timedoctor-desktop/default.nix#L36
  # https://github.com/nixos/nixpkgs/blob/d7547a7ed4d0bedcd73c64b2b854426ab55da543/nixos/modules/osConfig/malloc.nix#L10
  hardenedPkg = wrapPkg "hardened" ''--inherit-argv0 --set LD_PRELOAD "${pkgs.graphene-hardened-malloc}/lib/libhardened_malloc.so"'';
  cleanPkg = wrapPkg "clean" "--inherit-argv0 --unset LD_PRELOAD";
  offloadPkg =
    pkg:
    if (!(osConfig.hardware.nvidia.enabled && osConfig.hardware.nvidia.prime.offload.enable)) then
      pkg
    else
      wrapPkg "offloaded" ''
        --inherit-argv0 
        --set __NV_PRIME_RENDER_OFFLOAD 1 
        --set __NV_PRIME_RENDER_OFFLOAD_PROVIDER NVIDIA-G0 
        --set __GLX_VENDOR_LIBRARY_NAME nvidia 
        --set __VK_LAYER_NV_optimus NVIDIA_only'' pkg;
  # https://github.com/tauri-apps/tauri/issues/10702
  fixTauriPkg =
    pkg:
    if (!osConfig.hardware.nvidia.enabled) then
      pkg
    else
      wrapPkg "tauri-patched" "--inherit-argv0 --set __NV_DISABLE_EXPLICIT_SYNC 1" pkg;
  wrapPrio = lib.setPrio 0; # higher than gnome module, lower than firejail

  cudaSupport = osConfig.nixpkgs.config.cudaSupport or false;

  nixpkgsPatch =
    nixpkgs0:
    let
      nixpkgs-drv = pkgs.applyPatches {
        name = "nixpkgs-patched";
        src = nixpkgs0;
        patches = with pkgs; [
        ];
      };
      nixpkgs =
        (import "${nixpkgs-drv}/flake.nix").outputs {
          self = nixpkgs;
        }
        // {
          outPath = toString nixpkgs-drv;
          # for https://github.com/hercules-ci/flake-parts/blob/f7c1a2d347e4c52d5fb8d10cb4d94b5884e546fb/modules/perSystem.nix#L113
          _type = "flake";
        };
    in
    nixpkgs;

  pkgs-pin = import inputs.nixpkgs-pin {
    config = osConfig.nixpkgs.config;
    system = pkgs.stdenv.hostPlatform.system;
    overlays = [
      inputs.nur.overlays.default
      inputs.chaotic.overlays.default
    ];
  };
  pkgs-pin2 = import inputs.nixpkgs-pin2 {
    config = osConfig.nixpkgs.config;
    system = pkgs.stdenv.hostPlatform.system;
    overlays = [
      inputs.nur.overlays.default
      inputs.chaotic.overlays.default
    ];
  };
  pkgs-pin3 = import inputs.nixpkgs-pin3 {
    config = osConfig.nixpkgs.config;
    system = pkgs.stdenv.hostPlatform.system;
    overlays = [
      inputs.nur.overlays.default
      inputs.chaotic.overlays.default
    ];
  };
  pkgs-pin3' = import inputs.nixpkgs-pin3 {
    config = osConfig.nixpkgs.config // {
      cudaSupport = false;
      rocmSupport = false;
    };
    system = pkgs.stdenv.hostPlatform.system;
    overlays = [
      inputs.nur.overlays.default
      inputs.chaotic.overlays.default
    ];
  };
  pkgs-pin4 = import inputs.nixpkgs-pin4 {
    config = osConfig.nixpkgs.config;
    system = pkgs.stdenv.hostPlatform.system;
    overlays = [
      inputs.nur.overlays.default
      inputs.chaotic.overlays.default
    ];
  };
  pkgs-new = import inputs.nixpkgs-new {
    config = osConfig.nixpkgs.config;
    system = pkgs.stdenv.hostPlatform.system;
    overlays = [
      inputs.nur.overlays.default
      inputs.chaotic.overlays.default
    ];
  };
  pkgs-nocuda =
    # avoid infinite recursion, cannot use this if optimization. because pkgs-nocuda is used in cuda.nix
    /*
      if (!(osConfig.nixpkgs.config.cudaSupport or false)) then
        pkgs
      else
    */
    import inputs.nixpkgs {
      config = osConfig.nixpkgs.config // {
        cudaSupport = false;
      };
      system = osConfig.nixpkgs.system;
      overlays = [
        inputs.nur.overlays.default
      ];
    };
  pkgs-pin-nocuda =
    if (!(osConfig.nixpkgs.config.cudaSupport or false)) then
      pkgs-pin
    else
      import inputs.nixpkgs-pin {
        config = osConfig.nixpkgs.config // {
          cudaSupport = false;
        };
        system = osConfig.nixpkgs.system;
        overlays = [
          inputs.nur.overlays.default
        ];
      };
  pkgs-new-nocuda =
    if (!(osConfig.nixpkgs.config.cudaSupport or false)) then
      pkgs-new
    else
      import inputs.nixpkgs-new {
        config = osConfig.nixpkgs.config // {
          cudaSupport = false;
        };
        system = osConfig.nixpkgs.system;
        overlays = [
          inputs.nur.overlays.default
        ];
      };
  pkgs-small = import inputs.nixpkgs-small {
    config = osConfig.nixpkgs.config;
    system = pkgs.stdenv.hostPlatform.system;
    overlays = [
      inputs.nur.overlays.default
    ];
  };
  pkgs-unstable = import inputs.nixpkgs-unstable {
    config = osConfig.nixpkgs.config;
    system = pkgs.stdenv.hostPlatform.system;
    overlays = [
      inputs.chaotic.overlays.default
    ];
  };
  pkgs-chaotic = import inputs.chaotic.inputs.nixpkgs {
    config = osConfig.nixpkgs.config;
    system = pkgs.stdenv.hostPlatform.system;
    overlays = [
      inputs.chaotic.overlays.default
    ];
  };
  pkgs-489506 = import inputs.nixpkgs-489506 {
    config = osConfig.nixpkgs.config;
    system = pkgs.stdenv.hostPlatform.system;
    overlays = [
      inputs.nur.overlays.default
    ];
  };
  pkgs-openclaw = import inputs.nixpkgs {
    config = osConfig.nixpkgs.config;
    system = pkgs.stdenv.hostPlatform.system;
    overlays = [
      inputs.nix-openclaw.overlays.default
    ];
  };
  pkgs-2505 = import inputs.nixpkgs-2505 {
    config = osConfig.nixpkgs.config;
    system = pkgs.stdenv.hostPlatform.system;
    overlays = [
    ];
  };
  # needs qtwebengine-5.15.19, don't compile from source code.
  pkgs-qtwebengine5 = import inputs.nixpkgs {
    config = osConfig.nixpkgs.config;
    system = pkgs.stdenv.hostPlatform.system;
    overlays = [
      (final: prev: {
        libsForQt5 = pkgs-2505.libsForQt5;
      })
    ];
  };

  # https://www.reddit.com/r/NixOS/comments/1htxgly/comment/m5ioyg0
  # this is a custom package, add this in `environment.systemPackages`
  breeze-cursor-default-theme = pkgs.runCommandLocal "breeze-cursor-default-theme" { } ''
    mkdir -p $out/share/icons

    ln -s ${pkgs.kdePackages.breeze}/share/icons/breeze_cursors $out/share/icons/default
  '';

  has-steam = osConfig.programs.steam.enable || (osConfig.jovian.steam.enable or false);

  boot-to-steam =
    (osConfig.jovian.steam.autoStart or false)
    || (
      osConfig.services.displayManager.defaultSession == "steam"
      && osConfig.services.displayManager.autoLogin.enable
    );
  is-jovian = osConfig.jovian.steam.enable or false;

  kdeDMEnabled =
    osConfig.services.displayManager.sddm.enable
    || osConfig.services.displayManager.plasma-login-manager.enable;

  qtIsPreferred = kdeDMEnabled;

  usualDMEnabled =
    osConfig.services.displayManager.sddm.enable
    || osConfig.services.displayManager.plasma-login-manager.enable
    || osConfig.services.displayManager.gdm.enable
    || osConfig.services.xserver.displayManager.lightdm.enable
    || osConfig.services.xserver.enable;

  atleastV3 = lib.elem osConfig.microarch [
    "v3"
    "v4"
    "zen4"
  ];
  atleastV4 = lib.elem osConfig.microarch [
    "v4"
    "zen4"
  ];
}
