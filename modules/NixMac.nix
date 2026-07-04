{ den, ... }: {
  den.aspects.NixMac = {
    includes = [
      den.aspects.common
      den.aspects.nixbuild
      den.aspects.nixbuild-always
      den.aspects.mac-fix
    ];
  };
}
