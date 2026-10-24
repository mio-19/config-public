{ den, ... }: {
  den.aspects.NixMac = {
    includes = [
      den.aspects.rusty
      den.aspects.common
      den.aspects.desktopextra2
      den.aspects.nixbuild
      den.aspects.nixbuild-always
      den.aspects.mac-fix
    ];
  };
}
