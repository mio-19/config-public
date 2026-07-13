# Extra desktop packages and apps (den.aspects.desktopextra).
{ den, ... }:
let
  # cross-platform apps shared between the NixOS desktopextra body and the darwin
  # `extra` aspect (modules/extra.nix darwinExtra). Defined once so both stay in
  # sync: NixOS applies hardenedPkg, darwin installs them plain.
  sharedApps =
    { pkgs, inputs }:
    with pkgs;
    [
      downkyicore # nur.repos.mio.downkyicore
      ghidra
      blender
      jetbrains.gateway
    ];
in
{
  den.aspects.desktopextra = {
    description = "Extra desktop packages, firejail wrappers, and wireshark";
    includes = [
      den.aspects.gemini-desktop
      den.aspects.games
    ];
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

        home-manager.sharedModules = [
          ../extradeusers.nix
        ];

        # https://search.nixos.org/packages
        environment.systemPackages =
          with pkgs;
          (map hardenedPkg [
            rclone

            nur.repos.mio.bifrost
            # may need `xhost si:localuser:root` - https://www.reddit.com/r/linux4noobs/comments/lu1plx/hi_i_get_this_authorization_required_but_no/
            #inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.wireguird
            progs.inkscape
            #gg-jj
            kdiskmark
            #gsmartcontrol
            qdiskinfo
            obs-studio
            freecad
            #openscad
            #nemo
            #qcm
            teams-for-linux
            nur.repos.mio.waveterm
            pianotrans
            # binaryNativeCode:
            spotube
            nur.repos.mio.musescore-alex
            pkgs-pin2.musescore-evolution
            inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
            # unfree:
            (lib.hiPrio pkgs.aseprite) # lib.hiPrio: a file colliding with libresprite
            #davinci-resolve
            lmstudio
            google-chrome # does antigravity only work with google-chrome?
            code-cursor
          ])
          ++ (map cleanPkg [
            # unfree:
            android-studio
            antigravity-fhs
            # DETAILS REMOVED
          ])
          # https://github.com/dune3d/dune3d/issues/87#issuecomment-2095816938
          ++ lib.optionals config.hardware.nvidia.enabled [
            (lib.hiPrio (
              pkgs.writeShellScriptBin "dune3d" ''
                export GDK_DEBUG="gl-prefer-gl"
                exec "${lib.getExe (hardenedPkg pkgs.dune3d)}" "$@"
              ''
            ))
          ]
          ++ (map hardenedPkg (sharedApps {
            inherit pkgs inputs;
          }));

        #programs.throne.enable = true;
        #programs.throne.tunMode.enable = true;

        programs.zoom-us.enable = true;

        programs.firejail.wrappedBinaries = with pkgs; {
          mscore = {
            executable = "${hardenedPkg nur.repos.mio.musescore-alex}/bin/mscore";
            profile = "${pkgs.firejail}/etc/firejail/musescore.profile";
          };
          mscore-evo = {
            executable = "${hardenedPkg pkgs-pin2.musescore-evolution}/bin/mscore-evo";
            profile = "${pkgs.firejail}/etc/firejail/musescore.profile";
          };
          xournalpp = {
            executable = "${hardenedPkg xournalpp}/bin/xournalpp";
            profile = "${pkgs.firejail}/etc/firejail/xournalpp.profile";
          };
          scribus = {
            executable = "${hardenedPkg scribus}/bin/scribus";
            profile = "${pkgs.firejail}/etc/firejail/scribus.profile";
          };
          blender = {
            executable = "${hardenedPkg blender}/bin/blender";
            profile = "${pkgs.firejail}/etc/firejail/blender.profile";
          };
          inkscape = {
            executable = "${hardenedPkg progs.inkscape}/bin/inkscape";
            profile = "${pkgs.firejail}/etc/firejail/inkscape.profile";
          };
        };

        # cloudflare-warp could cause problems when mobile devices want to access public wifi login page.
        /*
          # see common commands: https://gist.github.com/arafays/619c2fd24db34592b1626c51544d719f
          services.cloudflare-warp.enable = true;
          services.cloudflare-warp.openFirewall = true;
        */

        programs.wireshark.enable = true;
      };
    # darwin reuses only the cross-platform apps shared with the NixOS desktopextra
    # (sharedApps above). The firejail/wireshark and other Linux-only bits stay in
    # the nixos branch.
    darwin =
      { inputs, pkgs, ... }@args:
      let
        _include = args._include or import ../mac/include.nix args;
      in
      with _include;
      {
        environment.systemPackages = sharedApps { inherit pkgs inputs; } ++ [
          pkgs-pin3.nur.repos.mio.musescore-alex
          pkgs-pin3.musescore-evolution
        ];
      };
  };
}
