{
  config,
  inputs,
  lib,
  pkgs,
  _include,
  ...
}@args:
with _include;
let
  pkgs-norocm = import inputs.nixpkgs {
    config = config.nixpkgs.config // {
      rocmSupport = false;
    };
    system = config.nixpkgs.system;
    overlays = [ ];
  };
in
{
  nixpkgs.overlays = [
    (final: prev: {
      # maybe it depends on some ai library that requires recompiling librewolf when rocmSupport is enabled
      #librewolf = if (config.nixpkgs.config.rocmSupport) then pkgs-norocm.librewolf else prev.librewolf;
      #  https://github.com/NixOS/nixpkgs/issues/497745 cause whisper-cpp (dependened by ffmpeg/kdenlive) failed to compile. last working nixpkgs: 80bdc1e5ce51f56b19791b52b2901187931f5353 first broken: aca4d95fce4914b3892661bcb80b8087293536c6
      kdenlive = if (config.nixpkgs.config.rocmSupport) then pkgs-norocm.kdenlive else prev.kdenlive;
      ffmpeg-full =
        if (config.nixpkgs.config.rocmSupport) then pkgs-norocm.ffmpeg-full else prev.ffmpeg-full;
    })
  ];

  nixpkgs.config.rocmSupport = !(config.nixpkgs.config.cudaSupport or false); # onnxruntime: ROCM does not support build with CUDA!
}
