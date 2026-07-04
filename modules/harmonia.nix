{ den, ... }:
let
  # nix-darwin Harmonia service module (options + launchd daemons). Formerly mac/modules/harmonia.nix.
  harmoniaDarwinModule =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.services.harmonia;
      cacheCfg = cfg.cache;
      daemonCfg = cfg.daemon;

      format = pkgs.formats.toml { };

      cacheConfigFile = format.generate "harmonia.toml" cacheCfg.settings;

      daemonConfigFile = format.generate "harmonia-daemon.toml" {
        socket_path = daemonCfg.socketPath;
        store_dir = daemonCfg.storeDir;
        db_path = daemonCfg.dbPath;
        log_level = daemonCfg.logLevel;
      };
    in
    {
      options.services.harmonia = {
        package = lib.mkPackageOption pkgs "harmonia" { };

        cache = {
          enable = lib.mkEnableOption "Harmonia: Nix binary cache written in Rust";

          signKeyPaths = lib.mkOption {
            type = lib.types.listOf lib.types.path;
            default = [ ];
            description = "Paths to signing keys used for signing the binary cache.";
          };

          settings = lib.mkOption {
            inherit (format) type;
            default = { };
            description = "Harmonia cache TOML settings.";
          };
        };

        daemon = {
          enable = lib.mkEnableOption "Harmonia daemon: Nix daemon protocol implementation";

          socketPath = lib.mkOption {
            type = lib.types.str;
            default = "/var/run/harmonia-daemon/socket";
          };

          storeDir = lib.mkOption {
            type = lib.types.str;
            default = "/nix/store";
          };

          dbPath = lib.mkOption {
            type = lib.types.str;
            default = "/nix/var/nix/db/db.sqlite";
          };

          logLevel = lib.mkOption {
            type = lib.types.str;
            default = "info";
          };
        };
      };

      config = lib.mkMerge [
        (lib.mkIf cacheCfg.enable {
          services.harmonia.cache.settings = builtins.mapAttrs (_: lib.mkDefault) {
            bind = "[::]:5000";
            workers = 4;
            max_connection_rate = 256;
            priority = 50;
          };

          launchd.daemons.harmonia = {
            environment = {
              CONFIG_FILE = "${cacheConfigFile}";
              SIGN_KEY_PATHS = lib.concatStringsSep " " cacheCfg.signKeyPaths;
              HOME = "/tmp";
              RUST_LOG = "info";
            };

            serviceConfig = {
              Label = "org.nixos.harmonia";
              ProgramArguments = [ (lib.getExe cfg.package) ];

              KeepAlive = true;
              RunAtLoad = true;

              StandardOutPath = "/tmp/harmonia.out.log";
              StandardErrorPath = "/tmp/harmonia.err.log";

              WorkingDirectory = "/tmp";
              Umask = 54; # 0066 decimal
            };
          };
        })

        (lib.mkIf daemonCfg.enable {
          launchd.daemons.harmonia-daemon = {
            environment = {
              RUST_LOG = daemonCfg.logLevel;
              RUST_BACKTRACE = "1";
              HARMONIA_DAEMON_CONFIG = "${daemonConfigFile}";
              HOME = "/tmp";
            };

            serviceConfig = {
              Label = "org.nixos.harmonia-daemon";
              ProgramArguments = [
                (lib.getExe' cfg.package "harmonia-daemon")
              ];

              KeepAlive = true;
              RunAtLoad = true;

              StandardOutPath = "/tmp/harmonia-daemon.out.log";
              StandardErrorPath = "/tmp/harmonia-daemon.err.log";

              WorkingDirectory = "/tmp";
              Umask = 63; # 0077 decimal
            };
          };
        })
      ];
    };
in
{
  den.aspects.harmonia = {
    description = "Harmonia binary cache nix-darwin service module (options + launchd)";
    darwin = {
      imports = [ harmoniaDarwinModule ];
    };
  };
}
