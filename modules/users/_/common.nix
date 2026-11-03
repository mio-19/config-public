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
      vscode-extensions.justusadam.language-haskell # haskell.haskell really depends on this??
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
        if pkgs.stdenv.hostPlatform.isAarch64 && pkgs.stdenv.hostPlatform.isDarwin then
          vscode-extensions.eamodio.gitlens # https://github.com/NixOS/nixpkgs/issues/462082
        else
          nix-vscode-extensions.vscode-marketplace.eamodio.gitlens
      )
    ]
    ++ lib.optionals (!(pkgs.stdenv.hostPlatform.isDarwin)) [
      # pkgs.stdenv.hostPlatform.isx86_64 &&
      # not supported on x86_64-darwin and aarch64-darwin?
      vscode-extensions.platformio.platformio-vscode-ide
      nix-vscode-extensions.vscode-marketplace.ms-vscode.cpptools # depended by platformio-vscode-ide # not available from nix-vscode-extensions on darwin
    ];

  # Extensions/settings shared by both editor profiles.
  baseEditorExtensions =
    with pkgs;
    commonExtensions
    ++ [
      # sync better if we use from vscode-extensions. instead of nix-vscode-extensions.vscode-marketplace. : they require hardcoded vscode verion cannot new or old by even 1
      # Copilot: The standalone `github.copilot` extension was deprecated and merged into
      # `github.copilot-chat`, which now provides completions, next-edit suggestions, and chat.
      # Installed from nixpkgs, so no Microsoft Marketplace access is needed.
      vscode-extensions.github.copilot-chat
    ];

  # These only work with Microsoft's VS Code build, not VSCodium.
  vscodeOnlyExtensions = with pkgs; [
    vscode-extensions.ms-vscode-remote.vscode-remote-extensionpack
    vscode-extensions.ms-vscode-remote.remote-wsl
    vscode-extensions.ms-vscode-remote.remote-ssh
    vscode-extensions.ms-vscode-remote.remote-ssh-edit
    vscode-extensions.ms-vscode-remote.remote-containers
    vscode-extensions.ms-vscode.remote-explorer
  ];

  editorSettings = {
    "update.showReleaseNotes" = false;
    "git.enableSmartCommit" = true;
    "git.confirmSync" = false;
    "git.autofetch" = true;
    "files.autoSave" = "afterDelay";
    "window.autoDetectColorScheme" = true;
    "workbench.preferredLightColorTheme" = "Light 2026";
    "github.copilot.nextEditSuggestions.enabled" = true;
    "git.openRepositoryInParentFolders" = "always";
    # VSCodium disables Copilot/AI features unless this is false.
    "chat.disableAIFeatures" = false;
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

  # VSCodium disables Copilot in its bundled product.json. Copilot only needs
  # the GitHub auth trust entry and the default chat agent metadata; VSCodium
  # already ships the required extensionEnabledApiProposals allow-list.
  # VSCodium deep-merges this user-level product.json over the bundled one.
  # https://github.com/VSCodium/vscodium/blob/master/docs/ext-github-copilot.md
  # https://github.com/microsoft/vscode-copilot-chat/blob/main/CONTRIBUTING.md#running-with-code-oss
  vscodiumProductJson = {
    trustedExtensionAuthAccess = {
      github = [
        "GitHub.copilot"
        "GitHub.copilot-chat"
        "github.copilot-chat"
      ];
      github-enterprise = [
        "GitHub.copilot"
        "GitHub.copilot-chat"
        "github.copilot-chat"
      ];
      microsoft = [
        "vscode.github-authentication"
      ];
    };
    defaultChatAgent = {
      extensionId = "GitHub.copilot";
      chatExtensionId = "GitHub.copilot-chat";
      chatExtensionOutputId = "GitHub.copilot-chat.GitHub Copilot Chat.log";
      chatExtensionOutputExtensionStateCommand = "github.copilot.debug.extensionState";
      documentationUrl = "https://aka.ms/github-copilot-overview";
      termsStatementUrl = "https://aka.ms/github-copilot-terms-statement";
      privacyStatementUrl = "https://aka.ms/github-copilot-privacy-statement";
      skusDocumentationUrl = "https://aka.ms/github-copilot-plans";
      optimizeUsageDocumentationUrl = "https://aka.ms/token-usage-tips";
      publicCodeMatchesUrl = "https://aka.ms/github-copilot-match-public-code";
      manageSettingsUrl = "https://aka.ms/github-copilot-settings";
      managePlanUrl = "https://aka.ms/github-copilot-manage-plan";
      manageOverageUrl = "https://aka.ms/github-copilot-manage-overage";
      upgradePlanUrl = "https://aka.ms/github-copilot-upgrade-plan";
      signUpUrl = "https://aka.ms/github-sign-up";
      provider = {
        default = {
          id = "github";
          name = "GitHub";
        };
        enterprise = {
          id = "github-enterprise";
          name = "GHE";
        };
        google = {
          id = "google";
          name = "Google";
        };
        apple = {
          id = "apple";
          name = "Apple";
        };
        microsoft = {
          id = "microsoft";
          name = "Microsoft";
        };
      };
      providerExtensionId = "vscode.github-authentication";
      providerUriSetting = "github-enterprise.uri";
      providerScopes = [
        [
          "read:user"
          "user:email"
          "repo"
          "workflow"
        ]
        [ "user:email" ]
        [ "read:user" ]
      ];
      entitlementUrl = "https://api.github.com/copilot_internal/user";
      entitlementSignupLimitedUrl = "https://api.github.com/copilot_internal/subscribe_limited_user";
      chatQuotaExceededContext = "github.copilot.chat.quotaExceeded";
      completionsQuotaExceededContext = "github.copilot.completions.quotaExceeded";
      walkthroughCommand = "github.copilot.open.walkthrough";
      completionsMenuCommand = "github.copilot.toggleStatusMenu";
      chatRefreshTokenCommand = "github.copilot.refreshToken";
      generateCommitMessageCommand = "github.copilot.git.generateCommitMessage";
      resolveMergeConflictsCommand = "github.copilot.git.resolveMergeConflicts";
      completionsAdvancedSetting = "github.copilot.advanced";
      completionsEnablementSetting = "github.copilot.enable";
      nextEditSuggestionsSetting = "github.copilot.nextEditSuggestions.enabled";
      tokenEntitlementUrl = "https://api.github.com/copilot_internal/v2/token";
      mcpRegistryDataUrl = "https://api.github.com/copilot/mcp_registry";
      mcpConnectorsUrl = "https://api.github.com/copilot-connectors/api/v1";
      managedSettingsUrl = "https://api.github.com/copilot_internal/managed_settings";
    };
    # Prevent VSCodium's built-in chat setup flow from trying to auto-install
    # GitHub.copilot-chat from the gallery (Open VSX doesn't carry it).
    # The extension is already installed via Nix; this stops the "cannot be
    # installed because it was not found" error after GitHub sign-in.
    # https://github.com/VSCodium/vscodium/blob/master/docs/ext-github-copilot.md
    builtInExtensionsEnabledWithAutoUpdates = [ ];
  };
in
{
  _module.args.commonExtensions = commonExtensions;

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
    lib.mkIf (config.programs.vscode.enable || config.programs.vscodium.enable) [
      # Too big. write in per machine configure file if needed.
      /*
          haskell-language-server
          ghc
      */
      nixd
    ];

  # VSCodium is the default editor. VSCode stays fully configured as a fallback
  # for hosts that set `programs.vscode.enable = lib.mkForce true;`.
  programs.vscode = {
    enable = lib.mkDefault false;
    profiles.default = {
      enableUpdateCheck = false;
      extensions = baseEditorExtensions ++ vscodeOnlyExtensions;
      userSettings = editorSettings;
    };
  };

  programs.vscodium = {
    enable = lib.mkDefault true;
    #package = pkgs.vscodium;
    profiles.default = {
      enableUpdateCheck = false;
      # The Microsoft remote-development extensions only work in VS Code.
      extensions = baseEditorExtensions;
      userSettings = editorSettings;
    };
  };

  # VSCodium reads this file from its user data directory and deep-merges it
  # over the bundled product.json. This is the documented Copilot workaround.
  xdg.configFile = lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) {
    "VSCodium/product.json".text = builtins.toJSON vscodiumProductJson;
  };
  home.file = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    "Library/Application Support/VSCodium/product.json".text = builtins.toJSON vscodiumProductJson;
  };

  /*
    programs.zen-browser = {
      enable = lib.mkDefault false;
      # https://github.com/0xc000022070/zen-browser-flake
      # Add any other native connectors here
      nativeMessagingHosts = if pkgs.stdenv.hostPlatform.isDarwin then [ ] else [ pkgs.firefoxpwa ];
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

  /*
    # https://blog.jetbrains.com/platform/2024/07/wayland-support-preview-in-2024-2/
    home.file.".config/JetBrains/IntelliJIdea2025.1/idea64.vmoptions" = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      text = ''
        -Dawt.toolkit.name=WLToolkit
      '';
    };
    home.file.".config/JetBrains/IdeaIC2025.1/idea64.vmoptions" = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      text = ''
        -Dawt.toolkit.name=WLToolkit
      '';
    };
    home.file.".config/JetBrains/JetBrainsGateway2025.2/gateway64.vmoptions" =
      lib.mkIf pkgs.stdenv.hostPlatform.isLinux
        {
          text = ''
            -Dawt.toolkit.name=WLToolkit
          '';
        };
  */

  #programs.helix = {
  #  enable = true;
  #};
}
