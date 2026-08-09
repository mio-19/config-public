{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (pkgs) stdenv;
  x86_64-linux = stdenv.isLinux && stdenv.isx86_64;
  hostName = config.networking.hostName;
  trusted-public-keys = [
    "exo.cachix.org-1:okq7hl624TBeAR3kV+g39dUFSiaZgLRkLsFBCuJ2NZI="
    "selector4nix.cachix.org-1:wovVlT07In5JCVz2tFgxPQTLpnN8hZT6P/RwfFcz3KE="
    "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
    "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
    "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "staging.cachix.org-1:WX63nyFdVdWGn6n59pIYwkcH/AtjJGjvMQFKlI2z00w="
    "mio-cache.cachix.org-1:ouuIJZ59HIflYjpLW6DRyMc1c+6r3kC/LHuqGUsWigg="
    "mio-config.cachix.org-1:VM6OZi+PC/ENBDf5ogaArQMgVUvJNvAL5t9ayXZdCIg="
    "mio.cachix.org-1:FlupyyLPURqwdRqtPT/LBWKsXY7JKsDkzZQo2K6LeMM="
    # DETAILS REMOVED
  ];
  # DETAILS REMOVED
in
{
  services.selector4nix = {
    enable = true;
    configureSubstituter = "overwrite";
    settings = {
      proxy.rewrite_nar_url = false; # is this better? idk
      network.nar_info_timeout_secs = 30;
      network.nar_timeout_secs = 30;
      network.tolerance_msecs = 10000;
      network.max_concurrent_requests = 16;
      network.ignore_nar_info_error = true;
      network.chunked_streaming = false; # seems to have problems still
      substituters = [
        {
          url = "https://exo.cachix.org";
          priority = 40;
        }
        {
          url = "https://selector4nix.cachix.org";
          priority = 40;
        }
        {
          url = "https://cache.nixos-cuda.org";
          priority = 40;
        }
        {
          # https://www.nyx.chaotic.cx
          url = "https://nyx-cache.chaotic.cx/";
          priority = 40;
        }
        {
          # https://github.com/numtide/llm-agents.nix
          url = "https://cache.numtide.com";
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
          priority = 6;
        }
        {
          url = "https://mirrors.ustc.edu.cn/nix-channels/store";
          priority = 6;
        }
        {
          url = "https://mirrors.cqupt.edu.cn/nix-channels/store";
          priority = 6;
        }
        {
          url = "https://mirror.sjtu.edu.cn/nix-channels/store";
          priority = 6;
        }
        {
          url = "https://mirror.nju.edu.cn/nix-channels/store";
          priority = 6;
        }
        {
          url = "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store";
          priority = 6;
        }
        {
          # https://github.com/numtide/nixos-passthru-cache
          url = "https://hetzner-cache.numtide.com";
          priority = 6;
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
