# collect packages that mostly never use. maybe useful if there is a possible situation of offline
{
  config,
  inputs,
  lib,
  pkgs,
  _include,
  ...
}@args:
with _include;
{
  imports = [
    ./desktopextra2.nix
  ];

  boot.supportedFilesystems = [
    "apfs"
  ]
  ++ lib.optionals (!(builtins.any (tag: tag == "rc") config.system.nixos.tags)) [
    "bcachefs"
  ];

  # https://search.nixos.org/packages
  environment.systemPackages =
    with pkgs;
    (map hardenedPkg [
      motrix-next
      xfce4-terminal
      alacritty
      #kdePackages.tokodon
      ardour
      #whalebird
      sioyek
      thonny
      friture
      wayland-bongocat
      kdePackages.kdenlive
      shotcut
      flowblade
      imhex
      mousam # always buggy
      wxhexeditor
      jabref
      penpot-desktop
      reco
      kdePackages.glaxnimate
      #qmplay2
      smplayer
      easyeffects
      pixelorama
      plezy
      inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.github-store
      inputs.nix-software-center.packages.${pkgs.stdenv.hostPlatform.system}.nix-software-center
      #quickemu
      #whatsapp-chat-exporter
      super-productivity
      # unfree:
      lightworks # maybe doesn't support wayland well # maybe consider https://github.com/kekkoudesu/lightworks-flatpak
      binaryninja-free
    ])
    ++ [
      # breaks with wrapper
      nur.repos.mio.android-translation-layer
    ]
    ++ lib.optionals pkgs.stdenv.isx86_64 (
      map hardenedPkg [
        # unfree:
        (inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.line.override {
          wine = config.wine64_package;
        })
      ]
    );

  services.flatpak = {
    enable = true;
    packages = [
      "cn.lceda.LCEDAPro"
      "app.organicmaps.desktop"
      "io.github.rinigus.PureMaps" # difficult to use
      # followings are built from source by flathub:
      "com.giadamusic.Giada" # Home folder read/write access!
    ];
  };

}
