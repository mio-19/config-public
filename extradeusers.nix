{
  inputs,
  config,
  pkgs,
  lib,
  osConfig,
  ...
}@args:
{
  programs.emacs = {
    enable = true;
    extraPackages = epkgs: [
      epkgs.nix-mode
      epkgs.magit
      epkgs.agda2-mode
    ];
  };

}
