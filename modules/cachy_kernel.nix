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

        # chaotic's per-kernel `zfs_cachyos` is built with `--with-config=all`,
        # so it builds zfs' userspace half as well as the kernel module.
        # nixpkgs exports the kernel's kbuild flags (`commonMakeFlags`) as
        # `kernelModuleMakeFlags`, and zfs forwards them to its *whole* build as
        # `makeFlags`, not only to the kernel-module sub-make. Those flags start
        # with `CC=${stdenv.cc.cc}`, i.e. the *unwrapped* compiler (the kernel
        # build cannot use the cc-wrapper because of `-target`), and that
        # compiler does not know the wrapper's include paths. The userspace
        # compile then fails with `fatal error: 'stdio.h' file not found` on
        # clang/LTO kernels, or with `blkid/blkid.h`, `uuid/uuid.h`,
        # `curl/curl.h` not found on the gcc kernels.
        # The module itself is compiled by kbuild with KERNEL_CC, which zfs
        # passes to `module/Makefile` at configure time, so the leaked CC is not
        # needed there either. Drop it from `makeFlags`; make then uses the
        # compiler configure recorded (the cc-wrapper).
        # nixpkgs' own per-kernel zfs is `--with-config=kernel` (no userspace
        # half), so it is unaffected and this is used for chaotic only.
        zfsWithWrappedCC =
          zfs:
          zfs.overrideAttrs (old: {
            makeFlags = lib.filter (flag: !(lib.hasPrefix "CC=" flag)) (old.makeFlags or [ ]);
          });
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
          # `boot.zfs.modulePackage` defaults to the zfs package from the kernel
          # set (`boot.kernelPackages.<zfs.package.kernelModuleAttribute>`).
          # chaotic's one is `--with-config=all`, i.e. the derivation affected
          # by the leaked CC above, so point the option at the fixed package.
          boot.zfs.modulePackage = lib.mkIf (!nixpkgs_kernel) (
            zfsWithWrappedCC config.boot.kernelPackages.zfs_cachyos
          );

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
