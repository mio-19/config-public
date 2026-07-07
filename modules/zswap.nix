{ den, ... }:
{
  den.aspects.zswap = {
    description = "zswap kernel params (zstd compressor)";
    nixos =
      { ... }:
      {
        zramSwap.enable = false;

        boot.kernelParams = [
          "zswap.enabled=1" # enables zswap
          "zswap.compressor=zstd" # compression algorithm
          "zswap.max_pool_percent=50" # maximum percentage of RAM that zswap is allowed to use
          "zswap.shrinker_enabled=1" # whether to shrink the pool proactively on high memory pressure
        ];
      };
  };
  den.aspects.zram = {
    description = "zram kernel params";
    nixos =
      { config, ... }:
      {
        zramSwap.enable = true;

        assertions = [
          {
            assertion = !(builtins.elem "zswap.enabled=1" config.boot.kernelParams);
            message = "zramSwap is enabled, but zswap is enabled in boot.kernelParams. Using both simultaneously causes redundant compression.";
          }
        ];
      };
  };
}
