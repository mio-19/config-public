{ den, ... }:
{
  den.aspects.cachy_kernel = {
    description = "CachyOS kernel packages (chaotic) with zen4/vmware variants";
    nixos =
      args@{
        config,
        pkgs,
        lib,
        ...
      }:
      let
        _include = args._include or (import ../nixos/include.nix args);
        nixpkgs_kernel =
          config.kernel_variant == "nixpkgs"
          || (zen4 && config.workaround_i_dont_know_kernel_nvidia_refer_problem == "nixpkgs");
        zen4 = config.microarch == "zen4";

        # nixpkgs' module aggregator (commit 6bd7526) unconditionally merges the
        # per-module certificates produced by kmodigest (`*.ko.cer`) into
        # `modules.cer`. Kernels and out-of-tree modules built with an older
        # nixpkgs do not produce those files, which makes the aggregation fail
        # with `cp: cannot stat '.../modules.cer'`.
        # The cachyos kernel comes from chaotic, which builds against its own
        # (older) nixpkgs pin, so it has no certificate files at all.
        # Skip the merge when the kernel did not provide modules.cer, and only
        # concatenate the certificates that actually exist.
        # https://github.com/NixOS/nixpkgs/issues/575192
        certMergeOld = lib.concatStringsSep "\n" [
          "    cp --no-preserve=mode,ownership --remove-destination \\"
          "      -- \"$(readlink -f modules.cer)\" modules.cer"
          "    sed \"1,$(wc -l < modules.order)d; s/\\.ko.*/.ko.cer/\" modules.dep \\"
          "        | xargs -d'\\n' cat >> modules.cer"
          ""
        ];
        certMergeNew = lib.concatStringsSep "\n" [
          "    if test -e modules.cer; then"
          "      cp --no-preserve=mode,ownership --remove-destination \\"
          "        -- \"$(readlink -f modules.cer)\" modules.cer"
          "      sed \"1,$(wc -l < modules.order)d; s/\\.ko.*/.ko.cer/\" modules.dep \\"
          "          | xargs -d'\\n' sh -c 'for f do if test -e \"$f\"; then cat \"$f\" || exit 1; fi; done' sh >> modules.cer"
          "    else"
          "      echo \"aggregateModules: kernel did not provide modules.cer; skipping certificate merge\""
          "    fi"
          ""
        ];
      in
      with _include;
      {
        options = {
          kernel_variant = lib.mkOption {
            type = lib.types.enum [
              "nixpkgs"
              "chaotic"
            ];
            default = "chaotic";
            description = "CachyOS kernel variant to use";
          };
          workaround_i_dont_know_kernel_nvidia_refer_problem = lib.mkOption {
            type = lib.types.enum [
              false
              "'"
              "no-zen4"
              "pkgs.zen4"
              "pkgs.no-zen4"
              "pin"
              "pin.no-zen4"
              "nixpkgs"
            ];
            default = false;
            description = "for zen4, I don't know why it does not or does work";
          };
        };
        config = {
          boot.kernelPackages =
            if nixpkgs_kernel then
              pkgs.linuxPackages_6_18
            else if zen4 && config.workaround_i_dont_know_kernel_nvidia_refer_problem == "no-zen4" then
              pkgs-chaotic.linuxPackages_cachyos
            else if zen4 && config.workaround_i_dont_know_kernel_nvidia_refer_problem == "'" then
              pkgs-chaotic'.linuxPackages_cachyos-lto-znver4
            else if zen4 && config.workaround_i_dont_know_kernel_nvidia_refer_problem == "pin" then
              pkgs-chaotic_pin.linuxPackages_cachyos-lto-znver4
            else if zen4 && config.workaround_i_dont_know_kernel_nvidia_refer_problem == "pin.no-zen4" then
              pkgs-chaotic_pin.linuxPackages_cachyos
            else if zen4 && config.workaround_i_dont_know_kernel_nvidia_refer_problem == "pkgs.zen4" then
              pkgs.linuxPackages_cachyos-lto-znver4
            else if zen4 && config.workaround_i_dont_know_kernel_nvidia_refer_problem == "pkgs.no-zen4" then
              pkgs.linuxPackages_cachyos
            else if
              config.virtualisation.vmware.host.enable
              || builtins.hasAttr "bcachefs" config.boot.supportedFilesystems
            then
              pkgs-chaotic.linuxPackages_cachyos-gcc
            else if zen4 then
              assert config.workaround_i_dont_know_kernel_nvidia_refer_problem == false;
              pkgs-chaotic.linuxPackages_cachyos-lto-znver4
            else
              pkgs-chaotic.linuxPackages_cachyos;
          boot.zfs.package = if nixpkgs_kernel then pkgs.zfs else pkgs-chaotic.zfs_cachyos;

          nixpkgs.overlays = [
            (final: prev: {
              aggregateModules =
                modules:
                (prev.aggregateModules modules).overrideAttrs (old: {
                  postBuild = builtins.replaceStrings [ certMergeOld ] [ certMergeNew ] old.postBuild;
                });
            })
          ];
        };
      };
  };
}
