{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
{

  # THEY ARE CAUSING mas to STUCK EVERY TIME; so only check for newinstall then. WHY DO THEY GET REINSTALLED EVERYTIME DURING ACTIVATION
  homebrew.masApps = {
    Saber = 1671523739;
    "Ice Cubes" = 6444915884;
    "Windows App" = 1295203466;
    Infuse = 1136220934;
    "Microsoft Outlook" = 985367838;
    Xcode = 497799835;
    # only mac app store version supports browser integration
    Bitwarden = 1352778147;
    Amphetamine = 937984704;
    Meshtastic = 1586432531;
  };
}
