{ den, ... }:
{
  den.aspects.wheel-nopasswd = {
    description = "Passwordless wheel sudo and machinectl polkit";
    nixos =
      { ... }:
      {
        security.sudo.wheelNeedsPassword = false;

        #security.pam.services.login.rules.session."zfs_key-skip-systemd".enable = lib.mkForce false; # does this fix only second time ego can run without password issue?
        # ego uses machinectl
        security.polkit.extraConfig = ''
          /* Allow members in 'wheel' to use machinectl without password authentication. */
          polkit.addRule(function(action, subject) {
              if (subject.isInGroup("wheel")) {
                  if (action.id == "org.freedesktop.machine1.shell" ||
                      action.id == "org.freedesktop.machine1.manage-machines" ||
                      action.id == "org.freedesktop.machine1.manage-images" ||
                      action.id == "org.freedesktop.machine1.login" ||
                      action.id == "org.freedesktop.machine1.open-pty" ||
                      action.id == "org.freedesktop.machine1.host-open-pty" ||
                      action.id == "org.freedesktop.machine1.host-shell")
                  {
                      return polkit.Result.YES; // Allow without authentication
                  }
              }
          });
        '';

        /*
          LLM: 3. Why the "Broadcast" and "8-Second" Wait?

           The Broadcast: Your systemctl status shows that while the wall service is dead, the systemd-ask-password-wall.path is active (waiting). This path unit continuously watches for any authentication request and instantly fires the "Broadcast message" to all terminals the moment Polkit doesn't find an immediate YES.

           The Delay: The 7–8 second "hang" is a known behavior of systemd-tty-ask-password-agent. It occurs during "agent arbitration," where the system waits to see if a graphical agent (like a pop-up) or a TTY agent will claim the request. In modern NixOS versions, this delay is often exactly 8 seconds due to internal timeouts related to graphics driver initialization and session classification .
        */
        # workaround doesn't work around 2025-12 2026-01
        #systemd.paths."systemd-ask-password-wall".enable = false; # workaround it asking for password . bug appear areound 25.11 release date. what changed?
      };
  };
}
