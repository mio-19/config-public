{ den, ... }:
{
  den.aspects.zfs = {
    description = "ZFS ARC, impermanence-on-shutdown, trim, and atuin daemon";
    nixos =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        ...
      }:
      let
        # https://github.com/KornelJahn/nixos-disko-zfs-test/blob/673ed629a7ef80efd99ad3b1676d9e4c62829c21/hosts/testhost.nix#L6
        rootDiffScript = pkgs.writeShellScriptBin "my-root-diff" ''
          ${pkgs.zfs}/bin/zfs diff ${config.chaotic.zfs-impermanence-on-shutdown.volume}@${config.chaotic.zfs-impermanence-on-shutdown.snapshot}
        '';
      in
      # required: config.chaotic.zfs-impermanence-on-shutdown.volume
      {
        options.zfs_arc_max_mib = lib.mkOption {
          type = lib.types.ints.positive;
          default = 512;
          description = ''
            Maximum ARC size for ZFS in bytes.
            This value must be a positive integer.
          '';
        };

        #security.pam.zfs.enable = true;
        #security.pam.zfs.homes = "${pool}/nixos/safe/encrypted";
        config.security.pam.zfs.noUnmount = false;
        # https://www.reddit.com/r/NixOS/comments/tzksw4/mount_an_encrypted_zfs_datastore_on_login/
        config.boot.zfs.requestEncryptionCredentials = false;

        config.boot.kernelParams = [
          "zfs_force=1"
          "zfs.zfs_arc_max=${toString (config.zfs_arc_max_mib * 1048576)}"
        ];
        config.chaotic.zfs-impermanence-on-shutdown = {
          enable = true;
          snapshot = lib.mkDefault "blank";
          #volume = "${pool}/nixos/local/ephemeral";
        };
        /*
          # for dedup and share
          config.systemd.services."zfs-mount-a" = {
            description = "ZFS mount -a at boot";
            wantedBy = [ "multi-user.target" ];
            after = [ "local-fs.target" ];

            # Run once and stay 'active' after exit
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${pkgs.zfs}/bin/zfs mount -a";
              RemainAfterExit = true;
            };
          };
        */
        config.services.zfs = {
          trim.enable = true;
        };
        # Explicitly disable ZFS mount service since we rely on legacy mounts
        config.systemd.services.zfs-mount.enable = false;

        config.environment.systemPackages = [
          rootDiffScript
        ];
      };
    homeManager = {
      imports = [
        (
          { ... }:
          {
            # https://forum.atuin.sh/t/getting-the-daemon-working-on-nixos/334/10
            programs.atuin = {
              daemon = {
                enable = true;
              };
            };
          }
        )
      ];
    };
  };
}
