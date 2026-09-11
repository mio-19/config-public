{ den, ... }:
let
  mkOptions =
    isDarwin:
    args@{
      lib,
      pkgs,
      config,
      ...
    }:
    let
      inherit (pkgs) stdenv;
      nixosInclude = if isDarwin then null else (args._include or (import ../nixos/include.nix args));
      inc =
        if isDarwin then
          null
        else
          let
            microarchDefault = if stdenv.hostPlatform.isAarch64 then "v4" else "v3";
            microarchValue = config.microarch or microarchDefault;
          in
          nixosInclude.scopeFor (config // { microarch = microarchValue; });
    in
    {
      options = {
        hdr_very_bright = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "if default brightness will result in very bright so dark background must be used in login/bootloader";
        };
        use_betterbird = lib.mkOption {
          type = lib.types.bool;
          default = if isDarwin then true else pkgs.stdenv.hostPlatform.isx86_64;
          description = "use betterbird instead of thunderbird.";
        };
        gemini_zh = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "gemini-desktop zh";
        };
        system_background = lib.mkOption {
          type = lib.types.either lib.types.package lib.types.path;
          description = "path to system background image";
        };
        use_librewolf_bin = lib.mkOption {
          type = lib.types.bool;
          default = !pkgs.stdenv.hostPlatform.isDarwin && !pkgs.stdenv.hostPlatform.isx86_64;
          description = "Use librewolf-bin instead of building from source (Linux only).";
        };
        librewolf_firejail = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "wrap librewolf with firejail.";
        };
        librewolf_declarative_extensions = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Install a fixed set of LibreWolf extensions via wrapFirefox nixExtensions.
            Shared between NixOS and nix-darwin. Blocks manual extension installs while enabled.
          '';
        };
        mio_openssh_hpn = lib.mkOption {
          type = lib.types.bool;
          default = if (isDarwin || !stdenv.hostPlatform.isx86_64) then true else inc.atleastV3;
          description = "use mio v3 patched openssh";
        };
        mio_aria2 = lib.mkOption {
          type = lib.types.bool;
          default = if (isDarwin || !stdenv.hostPlatform.isx86_64) then true else inc.atleastV3;
          description = "use mio v3 patched aria2";
        };
        compile_gram = lib.mkOption {
          type = lib.types.bool;
          default =
            if stdenv.hostPlatform.isDarwin then true else stdenv.hostPlatform.isx86_64 && inc.atleastV3;
          description = "compile our custom materialgram&telegram";
        };
        use_this_ix = lib.mkOption {
          type = lib.types.enum [
            "nix"
            "nix_git"
            "nix_latest"
            "lix"
          ];
          default = "nix_latest";
          description = "use ?";
        };
        ridiculous_fonts = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "enable ridiculous fonts (too big to download and need many disk space)";
        };
        hidpi = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "use hidpi";
        };
        systemPackages_hardened = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = "Packages to be installed and wrapped with hardenedPkg (on NixOS) or just installed (on Darwin).";
        };
        systemPackages_clean = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = "Packages to be installed and wrapped with cleanPkg (on NixOS) or just installed (on Darwin).";
        };
      }
      // lib.optionalAttrs (!isDarwin) {
        # Linux
        linux_tz = lib.mkOption {
          type = lib.types.enum [
            null
            "Pacific/Auckland"
            "Australia/Canberra"
          ];
          default = null;
          description = "Linux timezone";
        };
        fprintd-plasma_workaround = lib.mkOption {
          type = lib.types.enum [
            false
            # Modes vs fprint_fix (libfprint USB serial retry overlay):
            # - delay_restart: greeter recycle after D-Bus name; better WITH fprint_fix
            #   (helps Goodix/Synaptics after unclean fprintd stop). Not required.
            # - delay_restart_v2: greeter recycle after GetDefaultDevice; better than
            #   delay_restart; better WITH fprint_fix. Not required.
            # - fingerprint_rearm: kscreenlocker patch rearms fingerprint PAM (no greeter
            #   kill) + stop/restart fprintd on sleep. Best long-term workaround.
            #   REQUIRES fprint_fix (asserted): unclean fprintd restart is inherent;
            #   without the libfprint retry, GetDefaultDevice/rearm can still fail on
            #   Goodix/Synaptics after resume.
            # - powerdown_cmd: only stop fprintd on sleep; weakest. fprint_fix optional;
            #   not particularly recommended with this mode alone.
            # - false: no Plasma sleep workaround; fprint_fix is independent (ok either way).
            "delay_restart"
            "delay_restart_v2"
            "fingerprint_rearm"
            "powerdown_cmd"
          ];
          default = false;
        };
        # Gated separately from services.fprintd.enable so nixpkgs.overlays does not
        # recurse through pkgs ↔ config (classic NixOS overlay infinite-recursion trap).
        fprint_fix = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Apply the libfprint USB serial retry / device_id fallback overlay
            (nixos/fprint-fix.patch) for flaky Goodix/Synaptics readers after
            unclean fprintd restarts (nixpkgs#432276).
          '';
        };
        gnome_paperwm = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "use paperwm";
        };
        windose20_automate_kickoff = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            On the windose20 boot specialisation, replace Plasma panels so the
            application launcher uses the Windose20 logo and the label "Start".

            Disabled by default because plasma-manager overwrites the existing
            panel layout when this is enabled.
          '';
        };
        fonts_noto = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "use noto";
        };
        fonts_evil_c = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "fonts for evil c";
        };
        config_impure = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "allow impure config";
        };
        enable_big-parallel = lib.mkOption {
          type = lib.types.bool;
          default = nixosInclude.novirt;
          description = "enable big-parallel";
        };
        microarch = lib.mkOption {
          type = lib.types.enum [
            "v2"
            "v3"
            "v4"
            "zen4"
          ];
          default = if stdenv.hostPlatform.isAarch64 then "v4" else "v3";
          description = "x86-64 microarchitecture level (v2: legacy e.g. i5-2410M)";
        };
        wine64_package = lib.mkPackageOption pkgs [ "wineWow64Packages" "full" ] {
          extraDescription = "The wine 32/64 package to use.";
        };
        adhocNetworks = lib.mkOption {
          type = lib.types.bool;
          default = nixosInclude.boot-to-steam;
          description = "enable adhoc network connections. but might make network unusable";
        };
        plasma-login-manager_instead = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "plasma login manager instead of sddm";
        };
        skip_lockscreen_click = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "[WIP] skip click/key press to go to passwordenter/fingerprint screen";
        };
        vicinaeHm.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Include vicinae in home-manager.sharedModules (off for home-manager-7074 / WSL).";
        };
        middle_click_scroll = lib.mkOption {
          type = lib.types.enum [
            "off"
            "plasma"
            "browsers"
          ];
          default = "plasma";
          description = ''
            Middle-click scrolling mode:
            - "plasma": all apps via Plasma/libinput ("Hold down middle button and move mouse to scroll")
            - "browsers": Chromium MiddleClickAutoscroll + LibreWolf/Firefox general.autoScroll
            - "off": disabled
            Plasma and browsers modes conflict on the middle button; pick one.
          '';
        };
        plasma_focused_brightness = lib.mkOption {
          type = lib.types.submodule {
            options = {
              enable = lib.mkEnableOption "focused-display monitor brightness hotkeys on KDE Plasma";
            };
          };
          default = {
            enable = true;
          };
          description = ''
            On KDE Plasma 6, hardware brightness keys normally adjust every connected
            monitor. When enabled, PowerDevil's default shortcuts are disabled and
            Monitor Brightness Up/Down target only the focused display (5% steps).
            Hold-to-repeat is handled in the helper via evdev; the session user is
            added to the `input` group (re-login required after first enable).
          '';
        };
      };

      config = {
        environment.systemPackages =
          if isDarwin then
            config.systemPackages_hardened ++ config.systemPackages_clean
          else
            (map nixosInclude.hardenedPkg config.systemPackages_hardened)
            ++ (map nixosInclude.cleanPkg config.systemPackages_clean);
      }
      // lib.optionalAttrs (!isDarwin) {
        assertions = [
          {
            assertion = (config.mio_aria2 && pkgs.stdenv.hostPlatform.isx86_64) -> inc.atleastV3;
            message = "on x86_64, no mio aria2 for v2";
          }
          {
            assertion = (config.mio_openssh_hpn && pkgs.stdenv.hostPlatform.isx86_64) -> inc.atleastV3;
            message = "on x86_64, no mio hpn openssh for v2";
          }
          {
            assertion = (config.compile_gram && pkgs.stdenv.hostPlatform.isx86_64) -> inc.atleastV3;
            message = "on x86_64, no gram compile for v2";
          }
          {
            # fingerprint_rearm always unclean-stops/restarts fprintd; libfprint retry is required
            # so GetDefaultDevice + PAM rearm can succeed on flaky Goodix/Synaptics readers.
            assertion = config.fprintd-plasma_workaround != "fingerprint_rearm" || config.fprint_fix;
            message = ''fprintd-plasma_workaround = "fingerprint_rearm" requires fprint_fix = true'';
          }
        ];
        nix.settings.system-features =
          lib.optionals config.enable_big-parallel [
            "big-parallel"
          ]
          ++ lib.optionals stdenv.hostPlatform.isx86_64 (
            lib.optionals inc.atleastV3 [
              "gccarch-x86-64-v3"
            ]
            ++ lib.optionals inc.atleastV4 [
              "gccarch-x86-64-v4"
            ]
          );
      };
    };
in
{
  den.aspects.options = {
    nixos = mkOptions false;
    darwin = mkOptions true;
  };
}
