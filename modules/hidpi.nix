{ den, ... }:
{
  den.aspects.hidpi = {
    description = "HiDPI scaling (Avalonia scale factor, ghidra overlay)";
    nixos =
      { inputs, ... }:
      {
        hidpi = true;
        nixpkgs.overlays = [
          (final: prev: {
            # Use mio's pinned ghidra for HiDPI; avoid recursion with NUR overrides.
            ghidra = inputs.mio.packages.${final.stdenv.hostPlatform.system}.ghidra_hidpi;
          })
        ];
        # https://github.com/AvaloniaUI/Avalonia/issues/9390#issuecomment-2382126451
        # ryubing/ryujinx: 00:00:00.229 |W| Application GetActualScaleFactor: Couldn't determine monitor DPI: Wayland not yet supported
        environment.sessionVariables.AVALONIA_GLOBAL_SCALE_FACTOR = "2.00";
        # for https://github.com/mio-19/nurpkgs/blob/66bf4502ae06769827811aecc81ba6c8fd64368c/by-name/bi/bifrost/package.nix#L43
        # but breaks ventoy?
        #environment.sessionVariables.GDK_SCALE = "2";
      };
    darwin =
      { inputs, ... }:
      {
        hidpi = true;
      };
  };
}
