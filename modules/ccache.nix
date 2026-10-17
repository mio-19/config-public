{ den, ... }:
{
  den.aspects.ccache = {
    description = "100G /var/cache/ccache for selected unwrapped packages";
    nixos =
      { ... }:
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
        # The target executable /nix/store/709y7bnw6dsmp7cy0bhpvgy243vd7dbg-nix-ccache.pl is not an ELF! This is a security risk.
        # Script wrappers (e.g. bash or python) are commonly susceptible to dangerous env var injections.
        #programs.ccache.enable = true;
        programs.ccache.cacheDir = "/var/cache/ccache";
        programs.ccache.packageNames = [
          "materialgram-unwrapped"
          "betterbird-unwrapped"
          "telegram-desktop-unwrapped"
        ];

      };
  };
}
