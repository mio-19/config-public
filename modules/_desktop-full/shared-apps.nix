# Apps shared between the NixOS desktop (den.aspects.desktop-full) and the darwin
# system config (modules/common.nix darwin branch). Defined once here so both
# platforms stay in sync: NixOS wraps them with firejail (hardenedPkg/cleanPkg)
# and gates the x86_64-only ones, while darwin installs them plain/unconditional.
{ pkgs, progs }:
{
  hardened = with pkgs; [
    trayscale
    localsend
    pear-desktop
    element-desktop
    qbittorrent-enhanced
  ];
  clean = [
    progs.librewolf' # progs.librewolf'_for_firejail
  ];
  cleanX86 = with pkgs; [
    zotero # segfault with hardenedPkg on NixOS
  ];
}
