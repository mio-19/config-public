# Bare-metal KDE full desktop stack (den.aspects.desktop-baremetal-kde).
{ den, ... }: {
  den.aspects.desktop-baremetal-kde = {
    description = "Bare-metal KDE desktop with full desktop packages";
    includes = [
      den.aspects."desktop-baremetal-kde-basic"
      den.aspects."desktop-full"
    ];
  };
}
