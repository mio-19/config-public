# Apps shared between the NixOS desktopextra aspect and the darwin `extra` aspect
# (modules/extra.nix darwinExtra). Defined once here so both platforms stay in
# sync: NixOS wraps them with firejail (hardenedPkg), darwin installs them plain.
{ pkgs, inputs }:
{
  hardened = with pkgs; [
    inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.gemini-desktop
    downkyicore # nur.repos.mio.downkyicore
    musescore-evolution
    nur.repos.mio.musescore-alex
    ghidra
    blender
    jetbrains.gateway
  ];
}
