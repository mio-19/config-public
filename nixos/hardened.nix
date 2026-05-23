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
    inputs.nix-mineral.nixosModules.nix-mineral
  ];
  nix-mineral.enable = true;
  nix-mineral.preset = "compatibility";
  nix-mineral.extras.system.zram = false;
  nix-mineral.filesystems.enable = false; # conflicts with persistence
  nix-mineral.settings.entropy.jitterentropy = false; # jitterentropy.service: Main process exited, code=killed, status=31/SYS
  nix-mineral.settings.debug.coredump = false;
  /*
    # https://saylesss88.github.io/nix/hardening_NixOS.html
    systemd.coredump.enable = false;
    # ➡️ Sets the kernel's resource limit (ulimit -c 0)
    security.pam.loginLimits = [
      {
        domain = "*"; # Applies to all users/sessions
        type = "-"; # Set both soft and hard limits
        item = "core"; # The soft/hard limit item
        value = "0"; # Core dumps size is limited to 0 (effectively disabled)
      }
    ];
  */

  services.openssh.package = lib.mkDefault (hardenedPkg pkgs.openssh);
  #services.chrony.package = (hardenedPkg pkgs.chrony); # conflicts with https://github.com/NixOS/nixpkgs/commit/5bec6005dad89b021a158a7935d6870fc7330b0e
  #services.chrony.enableMemoryLocking = false; # default to false with grapheneos allocator https://github.com/NixOS/nixpkgs/blob/cad22e7d996aea55ecab064e84834289143e44a0/nixos/modules/services/networking/ntp/chrony.nix#L89
  #nix.package = lib.mkDefault (hardenedPkg pkgs.nix);
  networking.networkmanager.package = lib.mkDefault (hardenedPkg pkgs.networkmanager);
  services.udisks2.package = lib.mkDefault (
    hardenedPkg pkgs.udisks // { inherit (pkgs.udisks) libblockdev; }
  );
  services.pipewire.package = lib.mkDefault (
    hardenedPkg pkgs.pipewire
    // {
      inherit (pkgs.pipewire) jack;
    }
  );
  programs.wireshark.package = lib.mkDefault (hardenedPkg pkgs.wireshark-cli);
  services.dbus.dbusPackage = lib.mkDefault (hardenedPkg pkgs.dbus);
  hardware.bluetooth.package = lib.mkDefault (hardenedPkg pkgs.bluez);
  services.power-profiles-daemon.package = lib.mkDefault (hardenedPkg pkgs.power-profiles-daemon);
  networking.wireless.iwd.package = lib.mkDefault (hardenedPkg pkgs.iwd);
  #security.polkit.package = lib.mkDefault (hardenedPkg pkgs.polkit);
  services.pipewire.wireplumber.package = lib.mkDefault (hardenedPkg pkgs.wireplumber);

  # https://github.com/NixOS/nixpkgs/blob/fa972b1d29bb165bebc538c227a6e57f33631789/nixos/modules/profiles/hardened.nix#L73C1-L102C7
  boot.blacklistedKernelModules = [
    # Obscure network protocols
    "ax25"
    "netrom"
    "rose"

    # Old or rare or insufficiently audited filesystems
    "adfs"
    "affs"
    "bfs"
    "befs"
    "cramfs"
    "efs"
    #"erofs"
    "exofs"
    "freevxfs"
    "f2fs"
    "hfs"
    "hpfs"
    "jfs"
    "minix"
    "nilfs2"
    #"ntfs"
    "omfs"
    "qnx4"
    "qnx6"
    "sysv"
    "ufs"
  ];
  #security.lockKernelModules = true; # does this cause xbox controller not working?

  boot.kernel.sysctl = with lib; {
    # Disable ftrace debugging
    "kernel.ftrace_enabled" = mkDefault false;

    # Enable strict reverse path filtering (that is, do not attempt to route
    # packets that "obviously" do not belong to the iface's network; dropped
    # packets are logged as martians).
    "net.ipv4.conf.all.log_martians" = mkDefault true;
    "net.ipv4.conf.all.rp_filter" = mkDefault "1";
    "net.ipv4.conf.default.log_martians" = mkDefault true;
    "net.ipv4.conf.default.rp_filter" = mkDefault "1";

    # Ignore broadcast ICMP (mitigate SMURF)
    "net.ipv4.icmp_echo_ignore_broadcasts" = mkDefault true;

    # Ignore incoming ICMP redirects (note: default is needed to ensure that the
    # setting is applied to interfaces added after the sysctls are set)
    "net.ipv4.conf.all.accept_redirects" = mkDefault false;
    "net.ipv4.conf.all.secure_redirects" = mkDefault false;
    "net.ipv4.conf.default.accept_redirects" = mkDefault false;
    "net.ipv4.conf.default.secure_redirects" = mkDefault false;
    "net.ipv6.conf.all.accept_redirects" = mkDefault false;
    "net.ipv6.conf.default.accept_redirects" = mkDefault false;
  };
}
