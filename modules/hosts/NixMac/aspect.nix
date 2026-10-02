{ den, ... }: {
  den.aspects.NixMac = {
    includes = [
      den.aspects.rusty
      den.aspects.common
      den.aspects.nixbuild
      den.aspects.nixbuild-always
      den.aspects.mac-fix
    ];
  };
}
