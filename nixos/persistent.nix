{
  config,
  inputs,
  lib,
  pkgs,
  _include,
  ...
}@args:
with _include;
{
  environment.persistence."/persistent" = {
    hideMounts = true;
    directories = [
      #"/etc/ssh/authorized_keys.d"
      "/var/lib/upower"
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/flatpak"
      "/var/lib/tailscale"
      "/root/.ssh" # for use nixremote
      # https://discourse.nixos.org/t/screen-brightness-at-100-on-startup/59157/4
      "/var/lib/systemd/backlight"
      # NO WE DON't WANT TO SAVE default sessions when we might want to specify default session in nixos config
      #"/var/lib/AccountsService" # maybe hold default session selection? https://github.com/Alper-Celik/MyConfig/blob/7295be005fd4db3ff13f9487a6fab32a6812bad6/Configs/impermanence.os.nix#L10C7-L10C33
      {
        directory = "/var/lib/colord";
        user = "colord";
        group = "colord";
        mode = "u=rwx,g=rx,o=";
      }
      "/root/.local/share/fish" # "/root/.local/share/fish/fish_history"
    ]
    ++ lib.optionals config.adhocNetworks [
      # for adhoc network connections. but might make network unusable
      "/etc/NetworkManager/system-connections"
      "/var/lib/NetworkManager"
    ]
    ++ lib.optionals (config.services.howdy.enable or false) [
      "/var/lib/howdy"
    ]
    ++ lib.optionals (config.services.linux-enable-ir-emitter.enable or false) [
      "/var/lib/linux-enable-ir-emitter"
    ]
    ++ lib.optionals config.services.cloudflare-warp.enable [
      "/var/lib/cloudflare-warp"
    ]
    ++ lib.optionals config.services.fprintd.enable [
      "/var/lib/fprint"
    ]
    ++ lib.optionals config.networking.wireless.iwd.enable [
      "/var/lib/iwd" # remember last connected wifi and autoconnect?
    ]
    ++ lib.optionals config.systemd.coredump.enable [
      "/var/lib/systemd/coredump"
    ]
    ++ lib.optionals config.virtualisation.docker.enable [
      "/var/lib/docker"
    ]
    ++ lib.optionals config.services.displayManager.sddm.enable [
      #"/var/lib/sddm/.cache" # maybe faster boot time?
    ]
    ++ lib.optionals config.services.power-profiles-daemon.enable [
      "/var/lib/power-profiles-daemon"
    ]
    ++ lib.optionals config.services.chrony.enable [
      "/var/lib/chrony"
    ]
    ++ lib.optionals config.services.dnscrypt-proxy.enable [
      "/var/cache/dnscrypt-proxy"
    ]
    ++ lib.optionals (config.services.snap.enable or false) [
      "/var/lib/snapd"
      "/snap"
    ]
    ++
      lib.optionals
        (builtins.any (
          p: builtins.match ".*wireguird.*" (lib.getName p) != null
        ) config.environment.systemPackages)
        [
          "/etc/wireguard"
        ]
    ++ lib.optionals (config.services.ollama.enable) [
      config.services.ollama.home
    ];
    files = [
      # also see https://github.com/zincentimeter/nix-conf/blob/7f6b378da1c4e4bfbc6532b65d9344e27c432770/system/persist/system.nix#L139
      "/etc/adjtime"
      #"/etc/machine-id" # let's use systemd.machine_id=firmware instead # https://github.com/nix-community/preservation/issues/6
      #"/etc/zfs/zpool.cache"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
  };

  # https://github.com/systemd/systemd/issues/39438
  # https://www.reddit.com/r/NixOS/comments/1n313lp/change_machine_id_declaratively/
  boot.kernelParams = [ "systemd.machine_id=firmware" ];
}
