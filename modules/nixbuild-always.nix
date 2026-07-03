{ den, ... }:
let
  nixbuild-always =
    { ... }:
    {
      nix = {
        distributedBuilds = true;
        buildMachines = [
          {
            hostName = "eu.nixbuild.net";
            system = "x86_64-linux";
            maxJobs = 100;
            supportedFeatures = [
              "benchmark"
              "big-parallel"
            ];
          }
          {
            hostName = "eu.nixbuild.net";
            system = "armv7l-linux";
            maxJobs = 100;
            supportedFeatures = [
              "benchmark"
              "big-parallel"
              "gccarch-armv7-a"
            ];
          }
        ];
      };
    };
in
{
  den.aspects.nixbuild-always = {
    description = "Always route builds to nixbuild.net (distributed buildMachines)";
    nixos = nixbuild-always;
    darwin = nixbuild-always;
  };
}
