{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (pkgs) stdenv;
  trusted-public-keys = [
    "staging.cachix.org-1:WX63nyFdVdWGn6n59pIYwkcH/AtjJGjvMQFKlI2z00w="
    "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
    # DETAILS REMOVED
  ];
in
{
  imports = [ inputs.selector4nix.nixosModules.selector4nix ];

  services.selector4nix = {
    enable = true;
    configureSubstituter = "overwrite";
    settings = {
      network.nar_info_timeout_secs = 30;
      network.nar_timeout_secs = 30;
      network.tolerance_msecs = 10000;
      substituters = [
        { url = "https://nix-gaming.cachix.org"; }
        {
          url = "https://cache.nixos.org/";
          priority = 1;
        }
        {
          url = "https://mirrors.ustc.edu.cn/nix-channels/store/";
          priority = 10;
        }
        {
          url = "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store";
          priority = 10;
        }
        {
          url = "https://mio.cachix.org/";
          priority = 20;
        }
        {
          url = "https://mio-cache.cachix.org/";
          priority = 20;
        }
        {
          # https://github.com/numtide/llm-agents.nix
          url = "https://cache.numtide.com";
        }
        {
          url = "https://staging.cachix.org/";
          priority = 20;
        }
        {
          # garnix sometimes often 504 Gateway Time-out
          url = "https://cache.garnix.io/";
          storage_url = "https://garnix-cache.com/";
          priority = 30;
        }
        { url = "https://nix-community.cachix.org"; }
      ]
      # DETAILS REMOVED
      ;
    };
  };
  nix = {
    settings = {
      inherit trusted-public-keys;
    };
  };
}
