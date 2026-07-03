{ den, ... }: {
  den.aspects.desktop-office = {
    description = "Office-related fonts (OnlyOffice rendering)";
    nixos = { pkgs, ... }: {
      fonts.packages = with pkgs; [
        # gemini - Crucial for OnlyOffice to look right and render text correctly:
        corefonts # Installs Arial, Times New Roman, Calibri, etc.
        vista-fonts
      ];
    };
  };
}
