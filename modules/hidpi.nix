{ den, ... }:
{
  den.aspects.hidpi = {
    description = "HiDPI scaling (Avalonia scale factor, ghidra overlay)";
    nixos =
      { inputs, ... }:
      {
        nixpkgs.overlays = [
          (final: prev: {
            # Use mio's pinned ghidra for HiDPI; avoid recursion with NUR overrides.
            ghidra = inputs.mio.packages.${final.stdenv.hostPlatform.system}.ghidra;
          })
        ];
        # https://github.com/AvaloniaUI/Avalonia/issues/9390#issuecomment-2382126451
        # ryubing/ryujinx: 00:00:00.229 |W| Application GetActualScaleFactor: Couldn't determine monitor DPI: Wayland not yet supported
        environment.sessionVariables.AVALONIA_GLOBAL_SCALE_FACTOR = "2.00";
      };
  };
}
