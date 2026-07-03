{ ... }: {
  imports = [ ./shared.nix ];

  nix = {
    #daemonIOLowPriority = true;
    #daemonProcessType = "Background";
    gc = {
      automatic = true;
      # https://nixos.wiki/wiki/Storage_optimization
      interval = {
        Weekday = 0;
        Hour = 0;
        Minute = 0;
      };
      options = "--delete-older-than 30d";
    };
    optimise = {
      automatic = true;
    };
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    extraOptions = ''
      trusted-users = @admin root
    '';
  };
}
