{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:
{

  nix = {
    settings = {
      extra-sandbox-paths = [ "/var/cache/ccache" ];
    };
  };

  # https://docs.robotnix.org/modules/other.html
  system.userActivationScripts.ccache100g.text = ''
    mkdir -p -m0770 /var/cache/ccache
    chmod 0770 /var/cache/ccache
    chown root:nixbld /var/cache/ccache
    echo max_size = 100G > /var/cache/ccache/ccache.conf
    chown root:nixbld /var/cache/ccache/ccache.conf
  '';

  # https://nixos.wiki/wiki/CCache
  programs.ccache.enable = true;
  programs.ccache.cacheDir = "/var/cache/ccache";
  programs.ccache.packageNames = [
    "materialgram-unwrapped"
    "betterbird-unwrapped"
    "telegram-desktop-unwrapped"
  ];

}
