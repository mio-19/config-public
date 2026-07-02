{
  lib,
  self,
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    ./common.nix
    ../extra-den.nix
    ../nixos/nixbuild.nix
    ../nixos/nixbuild-always.nix
    ./harmonia_lan_only_not_public_ip.nix
    #./newinstall.nix
    ../selector4nix-den.nix
  ];

  networking.hostName = "NixMac";

  home-manager.users.user = (
    { ... }:
    {
      imports = [ ./home-user.nix ];
      programs.opam.enable = true;
      programs.opam.enableBashIntegration = true;
      programs.opam.enableZshIntegration = true;
      programs.opam.enableFishIntegration = true;
    }
  );
  # DETAILS REMOVED
  users.users.user = {
    name = "user";
    home = "/Users/user";
    uid = 501;
  };
  # DETAILS REMOVED
  users.users.root = {
    home = "/var/root";
    shell = "/bin/zsh";
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  system.primaryUser = "user";

  environment.systemPackages = with pkgs; [
    #fdroidserver
    #sdkmanager # IT IS INSTALLING LINUX BINARY ON THE MAC
    supertuxkart
  ];

  #homebrew.onActivation.cleanup = "uninstall"; # looks like homebrew updated and this broke..
  homebrew.taps = [ "xpipe-io/tap" ];
  homebrew.casks = [
    "background-music"
    "xquartz"
    "switchresx"
    "xpipe-io/tap/xpipe"
    "crossover"
    "cleanmymac-zh"
    "blockblock"
    #"lulu"
    "knockknock"
    # Good Linux GUI packages:
    "kate"
    # NOTE: SOME FONTS ARE INSTALLED FOR PRIMARY USER ONLY
    "font-sf-mono"
    "font-sf-pro"
    "font-sf-compact"
    "font-new-york"
  ];
  homebrew.brews = [
    #"repo"
    # aria2 compiling dependencies
    "autoconf"
    "automake"
    "libtool"
    "pkg-config"
    "cppunit"
    "sphinx-doc"
    "c-ares"
    "libssh2"
    "libxml2"
    "zlib"
    "sqlite3"
  ];
  homebrew.masApps = {
    WeChat = 836500024;
    WhatsApp = 310633997;
    QQ = 451108668;
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  environment.variables.ANDROID_HOME = "/opt/android-sdk";

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
