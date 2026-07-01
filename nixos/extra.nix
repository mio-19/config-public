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
  programs.java.package = hardenedPkg program.jdk;
  # https://search.nixos.org/packages
  environment.systemPackages =
    with pkgs;
    (map hardenedPkg (
      [
        wgcf
        fdroidcl
        (sbt.override { jre = program.jre; })
        mill
        program.scala_3
        (maven.override { jdk_headless = program.jdk_headless; })
        (ammonite.override { jre = program.jre; })
        program.jdk
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
        #baidupcs-go
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
        btop
        program.antlr
        nur.repos.mio.pdf2pptx
        easyeda2kicad
        interactive-html-bom
        diffoscope
        inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.forester
      ]
      ++ import ../extra-common.nix { inherit pkgs; }
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
