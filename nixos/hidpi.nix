{
  config,
  inputs,
  lib,
  pkgs,
  _include,
  ...
}@args:
{
  nixpkgs.overlays = [
    (final: prev: {
      ghidra = final.nur.repos.mio.ghidra;
    })
  ];
  # https://github.com/AvaloniaUI/Avalonia/issues/9390#issuecomment-2382126451
  # ryubing/ryujinx: 00:00:00.229 |W| Application GetActualScaleFactor: Couldn't determine monitor DPI: Wayland not yet supported
  environment.sessionVariables.AVALONIA_GLOBAL_SCALE_FACTOR = "2.00";

}
