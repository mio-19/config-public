{
  inputs,
  config,
  pkgs,
  lib,
  with-zen-browser ? false,
  osConfig,
  ...
}@args:
let
  commonExtensions =
    with pkgs;
    [
      # also available from nixpkgs vscode-extensions. :
      #neveruse#nix-vscode-extensions.vscode-marketplace.scalameta.metals
      nix-vscode-extensions.vscode-marketplace.scala-lang.scala
      nix-vscode-extensions.vscode-marketplace.haskell.haskell
      nix-vscode-extensions.vscode-marketplace.justusadam.language-haskell # haskell.haskell really depends on this??
      nix-vscode-extensions.vscode-marketplace.tomoki1207.pdf
      #nix-vscode-extensions.vscode-marketplace.bbenoist.nix
      nix-vscode-extensions.vscode-marketplace.jnoortheen.nix-ide
      nix-vscode-extensions.vscode-marketplace.myriad-dreamin.tinymist
      nix-vscode-extensions.vscode-marketplace.chenglou92.rescript-vscode
      nix-vscode-extensions.vscode-marketplace.banacorn.agda-mode
      nix-vscode-extensions.vscode-marketplace.davidanson.vscode-markdownlint
      nix-vscode-extensions.vscode-marketplace.ms-vscode.hexeditor
      nix-vscode-extensions.vscode-marketplace.rooveterinaryinc.roo-cline
      # nix-vscode-extensions.vscode-marketplace. only:
      nix-vscode-extensions.vscode-marketplace.openai.chatgpt

      (
        if pkgs.stdenv.isAarch64 && pkgs.stdenv.isDarwin then
          vscode-extensions.eamodio.gitlens # https://github.com/NixOS/nixpkgs/issues/462082
        else
          nix-vscode-extensions.vscode-marketplace.eamodio.gitlens
      )
    ]
    ++ lib.optionals (!(pkgs.stdenv.isDarwin)) [
      # pkgs.stdenv.isx86_64 &&
      # not supported on x86_64-darwin and aarch64-darwin?
      vscode-extensions.platformio.platformio-vscode-ide
      nix-vscode-extensions.vscode-marketplace.ms-vscode.cpptools # depended by platformio-vscode-ide # not available from nix-vscode-extensions on darwin
    ];
  inherit (import ./include.nix args) hasAntigravity hasCursor;
in
{
  imports = [ ./home-cli.nix ];
  programs.zed-editor = {
    enable = true;
    package = lib.mkDefault null;
    ## This populates the userSettings "auto_install_extensions"
    extensions = [
      "nix"
      "toml"
      "elixir"
      "make"
      "typst"
      "java"
    ];

    userSettings = {
      # Zed settings
      #
      # For information on how to configure Zed, see the Zed
      # documentation: https://zed.dev/docs/configuring-zed
      #
      # To see all of Zed's default settings without changing your
      # custom settings, run `zed: open default settings` from the
      # command palette (cmd-shift-p / ctrl-shift-p)
      features = {
        "edit_prediction_provider" = "copilot";
      };
      "ui_font_size" = 16;
      "buffer_font_size" = 15;
      base_keymap = "VSCode";
      theme = {
        mode = "system";
        light = "One Light";
        dark = "One Dark";
      };
      # https://potatofi.github.io/posts/word-wrap-in-zed/
      soft_wrap = "editor_width";
      autosave.after_delay.milliseconds = 100;
    };
  };

  home.packages =
    with pkgs;
    lib.mkIf config.programs.vscode.enable [
      # Too big. write in per machine configure file if needed.
      /*
          haskell-language-server
          ghc
      */
      nixd
    ];
  programs.vscode = {
    enable = lib.mkDefault true;
    #package = pkgs.vscode;
    profiles.default = {
      enableUpdateCheck = false;
      extensions =
        with pkgs;
        commonExtensions
        ++ [
          # sync better if we use from vscode-extensions. instead of nix-vscode-extensions.vscode-marketplace. : they require hardcoded vscode verion cannot new or old by even 1
          vscode-extensions.github.copilot-chat
          vscode-extensions.ms-vscode-remote.vscode-remote-extensionpack
          vscode-extensions.ms-vscode-remote.remote-wsl
          vscode-extensions.ms-vscode-remote.remote-ssh
          vscode-extensions.ms-vscode-remote.remote-ssh-edit
          vscode-extensions.ms-vscode-remote.remote-containers
          vscode-extensions.ms-vscode.remote-explorer
        ];
      userSettings = {
        "git.enableSmartCommit" = true;
        "git.confirmSync" = false;
        "git.autofetch" = true;
        "files.autoSave" = "afterDelay";
        "window.autoDetectColorScheme" = true;
        "github.copilot.nextEditSuggestions.enabled" = true;
        "git.openRepositoryInParentFolders" = "always";
        # https://code.visualstudio.com/docs/nodejs/nodejs-debugging
        "debug.javascript.autoAttachFilter" = "always";
        # https://code.visualstudio.com/docs/terminal/profiles
        "terminal.integrated.automationProfile.osx" = {
          path = lib.getExe pkgs.dash;
        };
        "terminal.integrated.automationProfile.linux" = {
          path = lib.getExe pkgs.dash;
        };
        "extensions.ignoreRecommendations" = true;
        "remote.SSH.localServerDownload" = "off";
        "haskell.manageHLS" = "PATH";
        "editor.wordWrap" = "on";
        #"remote.SSH.useExecServer" = false; # will this fix macos remote?
        "gitlens.ai.model" = "vscode"; # default settings added by gitlens
        # added by scala plugin:
        "files.watcherExclude" = {
          "**/.bloop" = true;
          "**/.metals" = true;
        };
        "chat.tools.terminal.autoApprove" = {
          "sbt" = true;
        };
        "chat.tools.urls.autoApprove" = {
          "*" = true;
        };
        "chat.agent.maxRequests" = 100;
        "terminal.integrated.suggest.enabled" = false;
        "nix.enableLanguageServer" = true;
        #"nix.serverPath" = "${lib.getExe pkgs.nixd}"; # nix store path doesn't work for windows; note that we are using wsl to manage some windows configurations. ; also doesn't work for remote development.
        "nix.serverPath" = "nixd";
        "roo-cline.debug" = false;
        "roo-cline.allowedCommands" = [
          "*"
        ];
        "roo-cline.deniedCommands" = [ ];
        "github.copilot.enable" = {
          "*" = true;
          "plaintext" = true;
          "markdown" = true;
          "scminput" = true;
        };
      };
    };
  };
  programs.antigravity = {
    enable = hasAntigravity;
    package = null;

    profiles.default = {
      enableExtensionUpdateCheck = false;
      extensions = with pkgs; commonExtensions;
      userSettings = config.programs.vscode.profiles.default.userSettings;
    };
  };
  programs.cursor = {
    enable = hasCursor;
    package = null;

    profiles.default = {
      enableUpdateCheck = false;
      extensions = with pkgs; commonExtensions;
      userSettings = config.programs.vscode.profiles.default.userSettings;
    };
  };

  #programs.librewolf = {
  #  enable = true;
  #  package = null;
  #};

  /*
    programs.zen-browser = {
      enable = lib.mkDefault false;
      # https://github.com/0xc000022070/zen-browser-flake
      # Add any other native connectors here
      nativeMessagingHosts = if pkgs.stdenv.isDarwin then [ ] else [ pkgs.firefoxpwa ];
      policies = {
        AutofillAddressEnabled = false;
        AutofillCreditCardEnabled = false;
        DisableAppUpdate = true;
        DisableFeedbackCommands = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableTelemetry = true;
        DontCheckDefaultBrowser = true;
        NoDefaultBookmarks = true;
        OfferToSaveLogins = false;
        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
        };
      };
    };
  */

  # https://blog.jetbrains.com/platform/2024/07/wayland-support-preview-in-2024-2/
  home.file.".config/JetBrains/IntelliJIdea2025.1/idea64.vmoptions" = lib.mkIf pkgs.stdenv.isLinux {
    text = ''
      -Dawt.toolkit.name=WLToolkit
    '';
  };
  home.file.".config/JetBrains/IdeaIC2025.1/idea64.vmoptions" = lib.mkIf pkgs.stdenv.isLinux {
    text = ''
      -Dawt.toolkit.name=WLToolkit
    '';
  };
  home.file.".config/JetBrains/JetBrainsGateway2025.2/gateway64.vmoptions" =
    lib.mkIf pkgs.stdenv.isLinux
      {
        text = ''
          -Dawt.toolkit.name=WLToolkit
        '';
      };

  #programs.helix = {
  #  enable = true;
  #};
}
