{ den, ... }:
{
  den.aspects.safe = {
    description = "Safe-mode specialisation (powersave, disable undervolt/lact/corectrl)";
    nixos =
      { lib, ... }:
      {
        specialisation.safe = {
          configuration = {
            system.nixos.tags = [ "safe" ];
            services.undervolt.enable = lib.mkForce false;
            services.lact.enable = lib.mkForce false;
            programs.corectrl.enable = lib.mkForce false;
            powerManagement.cpuFreqGovernor = lib.mkForce "powersave";
          };
        };
      };
  };
}
