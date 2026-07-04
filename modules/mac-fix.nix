{ den, ... }: {
  den.aspects.mac-fix = {
    description = "Shared base configuration for nix-darwin";
    provides.to-users = { ... }: {
      homeManager._module.args.enable-fcitx = false;
    };
  };
}
