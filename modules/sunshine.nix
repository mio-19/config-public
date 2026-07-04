{ den, ... }:
{
  den.aspects.sunshine = {
    description = "Sunshine game streaming host";
    nixos =
      { ... }:
      {
        services.sunshine = {
          enable = true;
          capSysAdmin = true;
          autoStart = true;
          openFirewall = true;
        };
      };
  };
}
