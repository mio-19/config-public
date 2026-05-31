{
  inputs,
  config,
  pkgs,
  lib,
  ...
}@args:
let
  _include = (args._include or import ./include.nix args);
in
with _include;
{
  _module.args._include = _include;

  # workaround for homebrew insecure - https://stackoverflow.com/questions/13762280/zsh-compinit-insecure-directories
  # https://github.com/nix-community/home-manager/blob/9e3a33c0bcbc25619e540b9dfea372282f8a9740/modules/programs/zsh/default.nix#L174
  programs.zsh.completionInit = "autoload -Uz compinit && compinit -u";

  programs.emacs.package = pkgs.emacs-31;

  targets.darwin.mac-app-util.enable = mac-app-util-enabled;
  targets.darwin.linkApps.enable = true;
  targets.darwin.copyApps.enable = false;

  # https://discourse.nixos.org/t/icons-missing-in-gnome-applications/49835/7
  #gtk = {
  #  enable = true;
  #  #Icon Theme
  #  iconTheme = {
  #    package = pkgs.adwaita-icon-theme;
  #    name = "Adwaita";
  #    # package = pkgs.kdePackages.breeze-icons;
  #    # name = "Breeze-Dark";
  #  };
  #};
  #fonts.fontconfig.enable = true;

  # TODO: try programs.desktoppr.settings.picture
}
