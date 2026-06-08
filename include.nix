{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:
import ./customize.nix args
// rec {
  allowUnfreeNonSourcePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "binaryninja-free"
      "corefonts"
      "vista-fonts"
      "bitwig-studio6"
      "steam"
      "steam-unwrapped"
      "nvidia-x11"
      "cloudflare-warp"
      "p7zip"
      "bilibili"
      "ventoy-gtk3"
      "obsidian"
      "discord"
      "vscode"
      "code"
      "gateway"
      "lmstudio"
      "android-studio-stable"
      "antigravity"
      "nvidia-settings"
      "vscode-extension-ms-vscode-cpptools"
      "vscode-extension-github-copilot"
      "vscode-extension-ms-vscode-remote-vscode-remote-extensionpack"
      "vscode-extension-ms-vscode-remote-remote-wsl"
      "vscode-extension-ms-vscode-remote-remote-ssh"
      "davinci-resolve-studio"
      "vscode-extension-ms-vscode-remote-remote-ssh-edit"
      "vscode-extension-ms-vscode-remote-remote-containers"
      "vscode-extension-ms-vscode-remote-explorer"
      "steamdeck-hw-theme"
      "steam-jupiter-unwrapped"
      "mathematica-cuda"
      "mathematica"
      "wpsoffice"
      "gitbutler" # fsl11Mit
      "alienarena"
      "bombsquad"
      "zw3d"
      "cider-2"
      "widevine-cdm"
      "celeste64" # assets
      "github-copilot-cli"
      "vmware-workstation"
      "zoom"
      "google-chrome"
      "android-studio"
      "sublimetext4"
      "sublime-merge"
      "chromium" # when with widevine.
      "chromium-unwrapped" # when with widevine.
      "lightworks"
      "nvidia-cg-toolkit"
      "claude-code"
      "rpcs3"
      "cursor"
      "cursor-cli"
      "nvidia-kernel-modules"
      "wechat"
      # darwin only:
      "graalvm-oracle"
      "keka"
      "raycast"
      "jetbrains-toolbox"
      "idea"
      "clion"
      "gateway"
      # cuda:
      "libcublas"
      "libcufft"
      "libcurand"
      "libcusparse"
      "libnvjitlink"
      "cudnn"
      "libnpp"
      "libcusolver"
      "libcufile"
      "libcusparse_lt"
    ]
    || lib.hasPrefix "cuda-" (lib.getName pkg)
    || lib.hasPrefix "cuda_" (lib.getName pkg)
    || (
      (config.nixpkgs.config.cudaSupport or false)
      && builtins.elem (lib.getName pkg) [
        "blender"
      ]
    );
  allowUnfreePredicate =
    pkg:
    allowUnfreeNonSourcePredicate pkg
    # unfree but source code available:
    || builtins.elem (lib.getName pkg) [
      "art-standalone"
      "bionic-translation"
      "aseprite"
    ]
    || lib.hasPrefix "libretro-" (lib.getName pkg);
  allowNonSourcePredicate =
    let
      depsFiles = [
        "${inputs.nixpkgs}/pkgs/by-name/ry/ryubing/deps.json"
        "${
          inputs.nur.legacyPackages."${pkgs.stdenv.hostPlatform.system}".repo-sources.mio
        }/by-name/downkyicore/deps.json"
        "${inputs.nixpkgs}/pkgs/by-name/ms/msbuild/deps.json"
        "${inputs.nixpkgs}/pkgs/by-name/ro/roslyn/deps.json"
        "${inputs.nixpkgs}/pkgs/by-name/ce/celeste64/deps.json"
        "${inputs.nixpkgs}/pkgs/by-name/pi/pinta/deps.json"
      ];
      allowed = [
        "librusty_v8"
        "dotnet-sdk"
        "koreader"
        "flutter-wrapped"
        "flutter"
        "dart"
        "pdfium-binaries"
        "sqlcipher_flutter_libs"
        "libreoffice" # dependencies are binaryBytecode
        "gradle"
        "ant"
        "zotero"
        "maven"
        "wine-wow"
        "wine-wow64"
        "onlyoffice-desktopeditors"
        "closure-compiler"
        "cef-binary"
        "waveterm"
        "sbt"
        "graalvm-ce"
        "isabelle"
        "bun"
        "ghidra" # deps
        "spotube"
        "bifrost-unwrapped" # deps
        "bifrost" # deps
        "fresh" # librusty_v8.a
        "msbuild"
        "jabref" # deps
        "jbang"
        "plezy" # deps
        "rigsofrods-bin"
        "virtualbox"
        "virtualbox-modules"
        "librewolf-bin"
        "librewolf-bin-unwrapped"
        "source" # plezy
        "splayer"
        "tor-browser"
        "librewolf" # librewolf-bin
        "antlr"
        "jadx"
        "kaleido"
        "pyspark"
        "py4j"
        # darwin only:
        "bib2gls"
        "arara" # binaryBytecode
        "swt"
        "zulu-ca-jdk"
        "electron"
        "rectangle"
        "localsend"
        "mousecape"
        "ice-bar"
        "iina"
        "maccy"
        "vlc-bin-arm64"
        "whisky"
        "stats"
        "libreoffice-bin"
        "losslesscut"
        # for bootstrapping only:
        "go"
        "cargo-bootstrap"
        "rustc-bootstrap-wrapper"
        "rustc-bootstrap"
        "ghc-binary"
        "temurin-bin"
      ]
      ++ lib.lists.flatten (
        map (deps: map (x: x.pname) (builtins.fromJSON (builtins.readFile deps))) depsFiles
      )
      ++ lib.optionals (pkgs.stdenv.isx86_64 && pkgs.stdenv.isDarwin) [
        "dotnet-runtime"
        "aspnetcore-runtime"
        "vlc-bin-intel64"
      ];
    in
    pkg:
    allowUnfreeNonSourcePredicate pkg
    || builtins.elem (lib.getName pkg) allowed
    || lib.all (p: p.isSource || p == lib.sourceTypes.binaryBytecode) (
      lib.toList pkg.meta.sourceProvenance
    )
    # https://discourse.nixos.org/t/whats-the-use-case-for-allowunfreepredicate-and-friends/30468/6
    || lib.all (p: p.isSource || p == lib.sourceTypes.binaryFirmware) (
      lib.toList pkg.meta.sourceProvenance
    )
    || lib.hasPrefix "Microsoft." (lib.getName pkg)
    || (lib.hasPrefix "runtime." (lib.getName pkg) && lib.hasInfix "Microsoft." (lib.getName pkg))
    || lib.hasPrefix "VBoxGuestAdditions_" (lib.getName pkg);

  librewolf_prefs = ''
    // Don't remove data on exit
    pref("privacy.sanitize.sanitizeOnShutdown", false);
    pref("privacy.clearOnShutdown.history", false);
    pref("privacy.clearOnShutdown.cookies", false);
    pref("privacy.clearOnShutdown.sessions", false);
    pref("privacy.clearOnShutdown.cache", false);
    pref("privacy.clearOnShutdown.downloads", false);
    pref("privacy.clearOnShutdown.formdata", false);
    pref("privacy.clearOnShutdown.offlineApps", false);
    pref("privacy.clearOnShutdown.siteSettings", false);
  '';
}
