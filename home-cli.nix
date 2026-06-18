{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
let
  # lib.mkIf pkgs.stdenv.isDarwin {
  shellAliases = {
    ls = "ls --color=auto";
  };
  x86_64-darwin = (pkgs.stdenv.isx86_64 && pkgs.stdenv.isDarwin);
  # doesn't have binary cache on x86_64-darwin
  enable-shell-gpt = (!x86_64-darwin);
  enable-zsh-patina = true;
  enable-zsh-sage = false;
in
{
  imports = [
    ./users.nix
    ./home-cli-extra.nix
  ];

  programs.git = {
    ignores = lib.optionals pkgs.stdenv.isDarwin [
      ".DS_Store"
    ];
    enable = true;
    lfs.enable = true;
    settings = {
      core.editor = "nano";
      pull.rebase = "false"; # merge
      #pull.rebase = "true"; # rebase
      color.ui = "auto";
      core.autocrlf = "false";
      init.defaultBranch = "main";
      #pager.diff = lib.getExe pkgs.diffnav;
      trailer.changeid.key = "Change-Id"; # lineageos https://wiki.lineageos.org/devices/enchilada/build/
      core.longpaths = true; # for windows. alternative: git config --system core.longpaths true
      # https://difftastic.wilfred.me.uk/git.html
      alias.dl = "-c diff.external=${lib.getExe pkgs.difftastic} log -p --ext-diff";
      alias.ds = "-c diff.external=${lib.getExe pkgs.difftastic} show --ext-diff";
      alias.dft = "-c diff.external=${lib.getExe pkgs.difftastic} diff";
      /*
        # https://github.com/nix-community/home-manager/blob/master/modules/programs/difftastic.nix
        diff.tool = lib.mkDefault "difftastic";
        difftool.difftastic.cmd =
          let
            difftCommand = "${lib.getExe pkgs.difftastic} ${lib.cli.toCommandLineShellGNU { } { }}";
          in
          "${difftCommand} $LOCAL $REMOTE";
      */
    };
  };

  #home.file."forge.yaml".text = ''
  #  # yaml-language-server: $schema=https://raw.githubusercontent.com/antinomyhq/forge/refs/heads/main/forge.schema.json
  #  model: anthropic/claude-3.7-sonnet:thinking
  #'';
  programs.starship = {
    enable = true;
    enableInteractive = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
    settings = {
      # https://starship.rs/config/
      add_newline = false;
      username.show_always = true;
      hostname.ssh_only = false;
      hostname.trim_at = "";
      battery.disabled = true;
      container.disabled = true; # it shows [Systemd] for orbstack, which isn't very useful
      scala.disabled = true; # it shows `vdeprecated`
    };
  };

  home.packages = [
    pkgs.zsh-completions
    pkgs.starship
  ]
  ++ lib.optionals enable-shell-gpt [
    pkgs.shell-gpt
  ]
  ++ lib.optionals enable-zsh-sage [
    # _sage_db_init:6: command not found: sqlite3
    pkgs.sqlite
  ];

  home.activation.ensureSgptRc = lib.mkIf enable-shell-gpt (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # DETAILS REMOVED
    ''
  );
  programs.bash = {
    package = null;
    enable = true;
    # https://github.com/TheR1D/shell_gpt/blob/main/sgpt/integration.py
    bashrcExtra = lib.optionalString enable-shell-gpt ''
      # Shell-GPT integration BASH v0.2
      _sgpt_bash() {
      if [[ -n "$READLINE_LINE" ]]; then
          READLINE_LINE=$(sgpt --shell <<< "$READLINE_LINE" --no-interaction)
          READLINE_POINT=''${#READLINE_LINE}
      fi
      }
      bind -x '"\C-l": _sgpt_bash'
      # Shell-GPT integration BASH v0.2
    '';
    shellAliases = shellAliases;
  };
  programs.zsh = {
    enable = true;

    /*
      # With Antidote:
      antidote = {
        # antidote is bad as it is doing git cloning.
        enable = false;
        plugins = [
          ''
            # Completions
            mattmc3/ez-compinit
            zsh-users/zsh-completions kind:fpath path:src
            #aloxaf/fzf-tab  # Remove if you don't use fzf

            # Completion styles
            belak/zsh-utils path:completion/functions kind:autoload post:compstyle_zshzoo_setup

            # Keybindings
            belak/zsh-utils path:editor

            # History
            belak/zsh-utils path:history

            # Prompt
            #romkatv/powerlevel10k

            # Utilities
            #zshzoo/macos # conditional:is-macos
            belak/zsh-utils path:utility
            romkatv/zsh-bench kind:path
            ohmyzsh/ohmyzsh path:plugins/extract

            # Other Fish-like features
            zdharma-continuum/fast-syntax-highlighting  # Syntax highlighting
            zsh-users/zsh-autosuggestions               # Auto-suggestions
            zsh-users/zsh-history-substring-search      # Up/Down to search history
          ''
        ];
      };
    */

    plugins =
      lib.optionals (!enable-zsh-patina) [
        # https://wiki.nixos.org/wiki/Zsh
        # zsh-fast-syntax-highlighting isn't highligthing the command from atuin?
        #{
        #  name = "zsh-fast-syntax-highlighting";
        #  src = pkgs.zsh-fast-syntax-highlighting;
        #  file = "share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh";
        #}
        # https://github.com/zsh-users/zsh-syntax-highlighting/issues/951#issuecomment-2089829937
        {
          name = "zsh-syntax-highlighting";
          src = pkgs.zsh-syntax-highlighting;
          file = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
        }
      ]
      ++ lib.optionals enable-zsh-patina [
        {
          name = "zsh-patina";
          src = pkgs.runCommand "zsh-patina" { } ''
            mkdir -p $out/share/zsh-patina
            echo 'eval "$(${
              # inputs.zsh-patina.packages.${pkgs.stdenv.hostPlatform.system}.default
              inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.zsh-patina
            }/bin/zsh-patina activate)"' > $out/share/zsh-patina/zsh-patina.plugin.zsh
          '';
          file = "share/zsh-patina/zsh-patina.plugin.zsh";
        }
      ]
      ++ lib.optionals (!enable-zsh-sage) [
        # zsh-autocomplete slows zsh init down
        #{
        #  name = "zsh-autocomplete";
        #  src = pkgs.zsh-autocomplete;
        #  file = "share/zsh-autocomplete/zsh-autocomplete.plugin.zsh";
        #}
        {
          name = "zsh-autosuggestions";
          src = pkgs.zsh-autosuggestions;
          file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
        }
      ]
      ++ lib.optionals enable-zsh-sage [
        {
          name = "zsh-sage";
          src = inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.zsh-sage;
          file = "share/zsh-sage/zsh-sage.plugin.zsh";
        }
      ]
      ++ [
        # p10k is VERY VERY SLOW via ssh
        #{
        #  name = "powerlevel10k-config";
        #  src = ./p10k;
        #  file = "p10k.zsh";
        #}
      ];
    #eval "$(atuin init --disable-up-arrow zsh)"
    #eval "$(starship init zsh)"
    initContent = lib.mkOrder 1200 (
      ''
        setopt noEXTENDED_GLOB 
        setopt INTERACTIVE_COMMENTS
        ${lib.optionalString enable-shell-gpt ''
          # https://github.com/TheR1D/shell_gpt/blob/main/sgpt/integration.py
          # Shell-GPT integration ZSH v0.2
          _sgpt_zsh() {
          if [[ -n "$BUFFER" ]]; then
              _sgpt_prev_cmd=$BUFFER
              BUFFER+="⌛"
              zle -I && zle redisplay
              BUFFER=$(sgpt --shell <<< "$_sgpt_prev_cmd" --no-interaction)
              zle end-of-line
          fi
          }
          zle -N _sgpt_zsh
          bindkey ^l _sgpt_zsh
          # Shell-GPT integration ZSH v0.2
        ''}
      ''
      +
        # doesn't seem to fix things; doesn't seem necessary
        lib.optionalString false ''
          # https://github.com/NixOS/nixpkgs/blob/d0fc30899600b9b3466ddb260fd83deb486c32f1/nixos/modules/programs/zsh/zsh.nix#L281C9-L281C53
          # THIS IS NOT ENABLED ON OUR NIXOS SYSTEM LEVEL BECAUSE WE DISABLED programs.zsh.enable AT SYSTEM LEVEL FOR SOME OTHER REASONS
          eval "$(${pkgs.coreutils}/bin/dircolors -b)"
        ''
    );
    inherit shellAliases;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
  };

  programs.fish = {
    enable = true;
    shellAliases = shellAliases;
  };

  /*
    programs.delta = {
      enable = true;
      enableGitIntegration = true;
      enableJujutsuIntegration = true;
    };
  */

  programs.difftastic = {
    enable = true;
    # THIS MESS UP AUTOMATION TOOLS. PLEASE CUSTOMIZE git difftool ONLY, NOT git diff
    /*
      git.enable = true;
      git.diffToolMode = true;
    */
  };

  programs.pay-respects = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };

  programs.tmux = {
    enable = true;
    mouse = true;
    package = lib.mkDefault null;
    #terminal = "screen-256color";
    # https://stackoverflow.com/questions/18600188/home-end-keys-do-not-work-in-tmux/55616731#55616731
    extraConfig = ''
      bind-key -n Home send Escape "OH"
      bind-key -n End send Escape "OF"
    '';
  };
  # https://github.com/nix-community/NUR
  home.file.".config/nixpkgs/config.nix".text = ''
    {
      packageOverrides = pkgs: {
        nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/main.tar.gz") {
          inherit pkgs;
        };
      };
    }
  '';

  home.stateVersion = lib.mkDefault "25.11";
}
