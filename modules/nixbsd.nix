{ den, lib, ... }:
{
  den.classes.nixbsd = {
    description = "nixbsd configuration class";
  };

  den.hosts.x86_64-freebsd.fw13 = {
    hostName = "fw13";
    class = "nixbsd";
  };
}
