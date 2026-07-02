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
  programs.java.package = hardenedPkg progs.jdk;
  # https://search.nixos.org/packages
  environment.systemPackages =
    with pkgs;
    (map hardenedPkg (
      import ../extra-common.nix { inherit pkgs; }
      ++ [
        wgcf
        fdroidcl
        (sbt.override { jre = progs.jre; })
        mill
        (pkgs.scala_3.override { jre = progs.jre; })
        (maven.override { jdk_headless = progs.jdk_headless; })
        (ammonite.override { jre = progs.jre; })
        progs.jdk
        agda
        lean4
        yarn-berry
        update-nix-fetchgit
        jujutsu
        nvfetcher
        #git-repo
        pmbootstrap
        #clang
        gnumake
        texliveFull
        poppler-utils
        markdownlint-cli
        cargo
        rustc
        qpdf # decrypt pdf
        #julia # https://github.com/NixOS/nixpkgs/issues/475534
        baidupcs-go
        nix-init
        nixd
        mediainfo
        img2pdf
        vulnix
        jq
        s-tui
        eza
        #bat
        rustscan
        ffmpeg-full
        #onefetch
        #fresh-editor
        nixpkgs-reviewFull
        nix-update
        gh
        #code2prompt
        yazi
        nix-tree
        matugen
        polarity
        diffnav
        haskell-language-server
        ghc
        progs.antlr
        nur.repos.mio.pdf2pptx
        easyeda2kicad
        interactive-html-bom
        diffoscope
        inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.forester
        inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.sem-cli
      ]
    ))
    ++ (map cleanPkg [
      opencode
      codex
      cursor-cli
      #pkgs'.openclaw
      #claude-code
      distrobox
      gcc
      gef
      gdb
    ])
    ++ (with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
      antigravity-cli
    ]);
  virtualisation.podman.enable = true;

  # https://discourse.nixosstag.fcio.net/t/how-to-fix-cursor-size/2938/8
  # trying to fix steam session small cursor
  #services.xserver.upscaleDefaultCursor = true;
  #services.xserver.dpi = lib.mkDefault 162; # required by services.xserver.upscaleDefaultCursor
  #environment.variables.XCURSOR_SIZE = "64";

  #virtualisation.docker.enable = true;
  #virtualisation.docker.enableOnBoot = false;
}
