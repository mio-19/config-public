{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.skip_lockscreen_click {
    # 1. Enable and configure the system-wide biometric daemon
    services.fprintd.enable = lib.mkDefault true;

    # Enforce concurrent PAM evaluation for kscreenlocker
    security.pam.services.kde-fingerprint = {
      fprintAuth = true;
      unixAuth = true; # Retains standard UNIX password verification as a parallel fallback
    };

    # 2. Prevent Stale D-Bus Pipes (Nixpkgs Bug #432276)
    # Terminate fprintd before suspend so kscreenlocker establishes a fresh connection on wake
    powerManagement.powerDownCommands = ''
      ${pkgs.systemd}/bin/systemctl stop fprintd.service 2>/dev/null || true
    '';

    # 3. Dismiss the Screen Shield via Virtual Input Injection
    # Enable ydotool, a Wayland-compatible virtual input injection utility
    programs.ydotool.enable = true;

    # Define a post-resume target service to simulate user presence
    systemd.services.wake-screen-shield-on-resume = {
      description = "Simulate a Left Shift keypress to transition kscreenlocker to State B on resume";
      after = [ "post-resume.target" ];
      wantedBy = [ "post-resume.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "wake-screen-shield" ''
          # Allow the kernel display interfaces and USB controllers to initialize
          sleep 1.2

          # Inject Left Shift (Keycode 42) press (1) and release (0) using ydotool
          # Left Shift is a safe modifier that will not append characters to the password field
          YDOTOOL_SOCKET=/run/ydotoold/socket ${pkgs.ydotool}/bin/ydotool key 42:1 42:0
        '';
      };
    };
  };
}
