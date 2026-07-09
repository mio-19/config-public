{ den, ... }:
{
  den.aspects.games-extra = {
    description = "Extra game packages, flatpaks, and firejail wrappers";
    nixos =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        ...
      }:
      let
        _include = args._include or (import ../nixos/include.nix args);
      in
      with _include;
      {
        # https://search.nixos.org/packages
        environment.systemPackages =
          with pkgs;
          (map cleanPkg [
            (offloadPkg rpcs3)
            (offloadPkg eden)
            #(offloadPkg citron-emu) # citron-emu was discontinued in february 2026
            retroarch-full
            #alienarena # hash mismatch
            #(offloadPkg torcs) # needs to compile too much
            (offloadPkg speed-dreams)
            progs.mcpelauncher-ui-qt # login page maybe broken with offloadPkg wrapper
            ppsspp
            #inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.ccleste # did this break flatpak?
            (offloadPkg rigsofrods-bin)
            (offloadPkg flightgear)
            (offloadPkg xemu)
            openloco
            (offloadPkg stuntrally)
            #(offloadPkg warzone2100)
          ])
          ++ lib.optionals pkgs.stdenv.isx86_64 (
            map cleanPkg [
              #wineWow64Packages.waylandFull
              #wineWow64Packages.staging
              #wineWow64Packages.stagingFull
              #winetricks
              (offloadPkg shadps4)
            ]
          );

        services.flatpak = {
          enable = true;
          packages = [
            "io.itch.itch"
            #"io.mrarm.mcpelauncher" # doesn't work
            #"io.github.searchandrescue2.sar2" # button too small under kde plasma
            # built from source by flathub:
            #"com.exok.Celeste64"
            #"org.speed_dreams.SpeedDreams" # FATAL: ssgInit called without a valid OpenGL context.
          ];
        };

        programs.firejail.enable = true;
        programs.firejail.wrappedBinaries = with pkgs; {
          # https://github.com/RigsOfRods/rigs-of-rods/issues/3134
          RoR = lib.mkIf (!boot-to-steam) {
            executable = "${cleanPkg (offloadPkg rigsofrods-bin)}/bin/RoR";
            profile = ../nixos/rigsofrods.profile;
          };
          RunRoR = lib.mkIf (!boot-to-steam) {
            executable = "${cleanPkg (offloadPkg rigsofrods-bin)}/bin/RunRoR";
            profile = ../nixos/rigsofrods.profile;
          };
        };
      };
  };
}
