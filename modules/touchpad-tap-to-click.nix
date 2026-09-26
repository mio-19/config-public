{ den, ... }:
{
  den.aspects.touchpad-tap-to-click = {
    provides.to-users = { ... }: {
      homeManager.programs.plasma = {
        input.touchpads = [
          {
            enable = true;
            name = "PIXA3854:00 093A:0274 Touchpad";
            vendorId = "093a";
            productId = "0274";
            tapToClick = true;
          }
        ];
      };
    };
  };
}
