{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
let
  # DETAILS REMOVED
  trusted-public-keys = [
    "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
    "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    "staging.cachix.org-1:WX63nyFdVdWGn6n59pIYwkcH/AtjJGjvMQFKlI2z00w="
    "mio-cache.cachix.org-1:ouuIJZ59HIflYjpLW6DRyMc1c+6r3kC/LHuqGUsWigg="
    "mio-config.cachix.org-1:VM6OZi+PC/ENBDf5ogaArQMgVUvJNvAL5t9ayXZdCIg="
    "mio.cachix.org-1:FlupyyLPURqwdRqtPT/LBWKsXY7JKsDkzZQo2K6LeMM="
    "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    # DETAILS REMOVED
  ];
in
{
  services.selector4nix = {
    enable = true;
    configureSubstituter = "overwrite";
    settings = {
      network.nar_info_timeout_secs = 30;
      network.nar_timeout_secs = 30;
      network.tolerance_msecs = 10000;
      network.max_concurrent_requests = 99;
      substituters = [
        {
          # https://www.nyx.chaotic.cx
          url = "https://nyx-cache.chaotic.cx/";
          priority = 40;
        }
        {
          url = "https://nix-gaming.cachix.org";
          priority = 40;
        }
        {
          url = "https://nix-community.cachix.org";
          priority = 40;
        }
        {
          # garnix sometimes often 504 Gateway Time-out
          url = "https://cache.garnix.io/";
          storage_url = "https://garnix-cache.com/";
          priority = 30;
        }
        {
          url = "https://staging.cachix.org/";
          priority = 20;
        }
        {
          url = "https://mio-cache.cachix.org/";
          priority = 20;
        }
        {
          url = "https://mio-config.cachix.org/";
          priority = 20;
        }
        {
          url = "https://mio.cachix.org/";
          priority = 20;
        }
        {
          url = "https://cache.nixos.org/";
          priority = 5;
        }
        {
          url = "https://mirror.sjtu.edu.cn/nix-channels/store";
          priority = 5;
        }
        {
          url = "https://mirrors.ustc.edu.cn/nix-channels/store";
          priority = 5;
        }
        {
          url = "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store";
          priority = 5;
        }
        {
          # https://github.com/numtide/nixos-passthru-cache
          url = "https://hetzner-cache.numtide.com";
          priority = 5;
        }
        {
          # https://github.com/numtide/llm-agents.nix
          url = "https://cache.numtide.com";
          priority = 40;
        }
        # DETAILS REMOVED
      ];
    };
  };
  nix = {
    settings = {
      inherit trusted-public-keys;
    };
  };
}
