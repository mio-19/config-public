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
  imports = [
    ./games.nix
  ];

  home-manager.sharedModules = [
    ../extradeusers.nix
  ];

  # https://search.nixos.org/packages
  environment.systemPackages =
    with pkgs;
    (map hardenedPkg [
      rclone

      musescore-evolution
      nur.repos.mio.musescore-alex
      jellyfin-desktop
      jetbrains.idea-oss
      nur.repos.mio.bifrost
      # may need `xhost si:localuser:root` - https://www.reddit.com/r/linux4noobs/comments/lu1plx/hi_i_get_this_authorization_required_but_no/
      inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.wireguird
      downkyicore # nur.repos.mio.downkyicore
      progs.inkscape
      #gg-jj
      kdiskmark
      #gsmartcontrol
      qdiskinfo
      #wlvncc
      #gpt4all
      #figma-linux
      #scribus # can edit pdf? - https://www.reddit.com/r/opensource/comments/1bu1gdi/adobe_acrobat_foss_alternative_to_end_all/
      #xournalpp # can draw on pdf? - https://www.reddit.com/r/opensource/comments/1bu1gdi/adobe_acrobat_foss_alternative_to_end_all/
      obs-studio
      freecad
      #openscad
      blender
      okteta
      dune3d
      lingot
      gmetronome
      #piliplus # bluescreen
      millisecond
      audacious
      splayer
      netease-cloud-music-gtk
      notepad-next
      nemo
      #qcm
      teams-for-linux
      # binaryNativeCode:
      spotube
      waveterm
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
      # unfree:
      (lib.hiPrio pkgs.aseprite) # lib.hiPrio: a file colliding with libresprite
      jetbrains.gateway
      #davinci-resolve
      lmstudio
      # DETAILS REMOVED
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
    ];

  #programs.throne.enable = true;
  #programs.throne.tunMode.enable = true;

  programs.zoom-us.enable = true;

  programs.firejail.enable = true;
  programs.firejail.wrappedBinaries = with pkgs; {
    mscore = {
      executable = "${hardenedPkg nur.repos.mio.musescore-alex}/bin/mscore";
      profile = "${pkgs.firejail}/etc/firejail/musescore.profile";
    };
    mscore-evo = {
      executable = "${hardenedPkg musescore-evolution}/bin/mscore-evo";
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
    # no network with bilibili.profile?
    /*
      bilibili = {
        executable = "${hardenedPkg inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.bilibili}/bin/bilibili";
        profile = ./bilibili.profile;
      };
    */
  };

  # cloudflare-warp could cause problems when mobile devices want to access public wifi login page.
  /*
    # see common commands: https://gist.github.com/arafays/619c2fd24db34592b1626c51544d719f
    services.cloudflare-warp.enable = true;
    services.cloudflare-warp.openFirewall = true;
  */

  programs.wireshark.enable = true;
}
