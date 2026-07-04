{ den, ... }: {
  den.aspects.NixMac = {
    includes = [
      den.aspects.common
      den.aspects.nixbuild
      den.aspects.nixbuild-always
    ];
    provides.to-users = { ... }: {
      homeManager._module.args.enable-fcitx = false;
    };
  };
}
