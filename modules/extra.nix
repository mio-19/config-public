{ den, ... }:
let
  # Common CLI tools, split by packaging intent:
  # - nixos: hardenedPkg vs cleanPkg
  # - darwin: no wrapping needed, so just concatenate
  commonCliHardened =
    {
      pkgs,
      progs,
      inputs,
      ...
    }:
    with pkgs;
    [
      lynx
      nh
      nur.repos.mio.nurl_patched
      jadx
      cachix
      wrangler
      btop
      markdownlint-cli
      gh
      cargo
      rustc
      diffnav
      gef
      gdb
      progs.antlr
      openscad
    ]
    ++ lib.optional (
      inputs.mio.packages.${pkgs.stdenv.hostPlatform.system} ? forester
    ) inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.forester;
  commonCliClean =
    { pkgs, ... }:
    with pkgs;
    [
      codex
      opencode
      github-copilot-cli
    ];

  commonCliDarwin = args: commonCliHardened args ++ commonCliClean args;

in
{
  den.aspects.extra = {
    nixos =
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
            commonCliHardened {
              inherit
                pkgs
                progs
                inputs
                ;
            }
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
              nvfetcher
              gnumake
              texliveFull
              poppler-utils
              qpdf # decrypt pdf
              nixd
              jq
              ffmpeg-full
              nixpkgs-reviewFull
              nix-update
              nix-tree
              haskell-language-server
              ghc
              diffoscope
            ]
          ))
          ++ (map cleanPkg (
            commonCliClean { inherit pkgs; }
            ++ [
              cursor-cli
              #claude-code
              distrobox
              gcc
            ]
          ))
          ++ [
            antigravity-cli
          ];
        virtualisation.podman.enable = true;

        # https://discourse.nixosstag.fcio.net/t/how-to-fix-cursor-size/2938/8
        # trying to fix steam session small cursor
        #services.xserver.upscaleDefaultCursor = true;
        #services.xserver.dpi = lib.mkDefault 162; # required by services.xserver.upscaleDefaultCursor
        #environment.variables.XCURSOR_SIZE = "64";

        #virtualisation.docker.enable = true;
        #virtualisation.docker.enableOnBoot = false;
      };
    darwin =
      {
        pkgs,
        inputs,
        lib,
        config,
        _include,
        ...
      }@args:
      with _include;
      {
        imports = [
          (import ../aspect.nix "desktopextra") # cross-platform desktop apps shared with NixOS desktopextra
          (import ../aspect.nix "games")
        ];

        # disable emacs to work around https://github.com/hraban/mac-app-util/issues/43
        #home-manager.sharedModules = [
        #  ../extradeusers.nix
        #];

        homebrew.brews = [
          "ollama"
        ];

        # List packages installed in system profile. To search by name, run:
        # $ nix-env -qaP | grep wget
        environment.systemPackages =
          with pkgs;
          commonCliDarwin {
            inherit
              pkgs
              progs
              inputs
              ;
          }
          ++ [
            mdbook
            nur.repos.mio.mdbook-generate-summary
            uv
            claude-code
            #ollama # no MLX
            #onefetch
            unixtools.watch
            opam
            # unfree:
            p7zip-rar

            (ammonite.override { jre = progs.jre; })
            (sbt.override { jre = progs.jre; })
            mill
            progs.nodejs
            progs.jdk
            progs.pnpm
            progs.yarn-berry
            progs.emacs
            agda
            lean4
            #isabelle # cli only; use brew cask then
            nixpkgs-review
            nix-update
            llvmPackages.bintools # provides readelf that gef needs
            yt-dlp
            #easyeda2kicad
            #interactive-html-bom
            inputs.exo.packages.${pkgs.stdenv.hostPlatform.system}.exo # inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.exo
            # unfree:
            cursor-cli
          ]
          ++ lib.optionals config.mio_aria2 [
            nur.repos.mio.aria2
            nur.repos.mio.aria2-wrapped
          ]
          ++ lib.optionals (!config.mio_aria2) [
            aria2
          ]
          ++ lib.optionals pkgs.stdenv.hostPlatform.isAarch64 [
            # unsupported on x86_64 macOS:
            tuxguitar
          ]
          ++ lib.optional (
            pkgs.stdenv.hostPlatform.isAarch64
            && inputs.mio.packages.${pkgs.stdenv.hostPlatform.system} ? ryubing
          ) inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.ryubing
          ++ (with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
            oh-my-opencode
            #oh-my-codex # no binary cache
          ])
          ++ [
            (lib.hiPrio antigravity-cli) # higher prio than gui app for cli command "antigravity"
          ];

      };
  };
}
