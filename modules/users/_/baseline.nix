{
  inputs,
  config,
  pkgs,
  lib,
  osConfig,
  options,
  ...
}:
let
  ifNoOS = default: f: if osConfig == null then default else f;
in
{
  #programs.git.package = null; # use system git, not home-manager's
  programs.ssh = {
    package = null; # use system ssh, not home-manager's
    enable = true;
    enableDefaultConfig = false; # home-manager suggests this to be false
    settings."*" = {
      # https://github.com/d12frosted/environment/blob/472f5df9bb533f21c40950179f438f4f7196a6c2/nix/home.nix#L85
      # https://github.com/Ericson2314/nixos-configuration/blob/8f2aa60bbd1172be828cf70872ed0c34e7a4d19a/user/secrets.nix#L15
      controlMaster = "auto";
    };
  };
  programs.nix-index = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
  };

  manual.manpages.enable = ifNoOS true (
    osConfig.documentation.enable
    && (osConfig.documentation.man.enable or osConfig.documentation.man.cache.enable)
  );
  manual.json.enable = ifNoOS true osConfig.documentation.enable;
  manual.html.enable = ifNoOS true osConfig.documentation.enable;
  programs.man.generateCaches = ifNoOS true (
    osConfig.documentation.enable
    && (osConfig.documentation.man.enable or osConfig.documentation.man.cache.enable)
  );

  # https://discourse.nixos.org/t/how-to-remove-discover-notifier/64343/2
  xdg.configFile."autostart/org.kde.discover.notifier.desktop" =
    lib.mkIf (osConfig.services.desktopManager.plasma6.enable or false)
      {
        text = ''
          [Desktop Entry]
          Hidden=true
        '';
      };

  # disable - reduce attack surface
  /*
    # https://github.com/search?q=.local%2Fbin+language%3ANix+&type=code
    home.sessionPath = [
      "${config.home.homeDirectory}/.cargo/bin"
      "${config.home.homeDirectory}/.local/bin"
    ];
  */

  gtk.gtk4.theme = config.gtk.theme; # was default until 25.11

  xdg.userDirs = lib.optionalAttrs (options.xdg.userDirs ? setSessionVariables) {
    # default for 25.11 is xdg.userDirs.setSessionVariables = true;
    setSessionVariables = false;
  };
}
