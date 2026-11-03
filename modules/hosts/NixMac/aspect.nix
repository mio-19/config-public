{ den, ... }: {
  den.aspects.NixMac = {
    includes = [
      den.aspects.rusty
      den.aspects.common
      den.aspects.desktopextra2
      den.aspects.nixbuild
      den.aspects.nixbuild-always
      den.aspects.mac-fix
      den.aspects.extra
      den.aspects.harmonia_lan_only_not_public_ip
      den.aspects.selector4nix
    ];
  };
}
