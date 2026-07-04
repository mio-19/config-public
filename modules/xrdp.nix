{ den, ... }:
{
  den.aspects.xrdp = {
    description = "XRDP remote desktop with XFCE";
    nixos =
      { ... }:
      {
        services.xrdp.enable = true;
        services.xrdp.defaultWindowManager = "xfce4-session";
        services.xserver.desktopManager.xfce.enable = true;
        services.xrdp.openFirewall = true; # PLEASE LIMIT TO LAN ONLY.
        services.xrdp.audio.enable = true;
        services.pulseaudio.enable = true;
        services.pipewire.enable = false;
      };
  };
}
