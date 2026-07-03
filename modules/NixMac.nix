{ den, ... }: {
  den.aspects.NixMac = {
    includes = [
      den.aspects.common
    ];
  };
}
