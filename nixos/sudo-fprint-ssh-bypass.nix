{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Determine if fprintd authentication is actively enabled for the sudo PAM stack.
  isSudoFprintEnabled = config.security.pam.services.sudo.fprintAuth or false;
in
{
  # Only evaluate and inject this PAM rule if fprintd is configured for sudo.
  security.pam.services.sudo.rules.auth.skip_fprintd_for_ssh = lib.mkIf isSudoFprintEnabled {
    enable = true;

    # Dynamically order this rule to execute immediately before the fprintd rule.
    # This guarantees that the [success=1] control flag skips exactly the fprintd module.
    order = config.security.pam.services.sudo.rules.auth.fprintd.order - 1;

    # If the script succeeds (exit 0), skip the next 1 module (pam_fprintd.so).
    # If the script fails (exit 1), ignore the failure and evaluate the biometric module normally.
    control = "[success=1 default=ignore]";

    modulePath = "${pkgs.pam}/lib/security/pam_exec.so";

    # Pass the shell script as an argument to pam_exec.so
    args = [
      "quiet"
      "${pkgs.writeShellScript "pam-sudo-ssh-bypass" ''
        is_remote() {
          local id=$1
          # Check if the session ID is valid and not the 'no session' value.
          [ -n "$id" ] && [ "$id" != "4294967295" ] || return 1
          # Query systemd-logind for the session's Remote property.
          [ "$(${pkgs.systemd}/bin/loginctl show-session "$id" -p Remote --value 2>/dev/null)" = "yes" ]
        }

        # 1. Try to get the session ID from the current process cgroup.
        # This is the most reliable for direct login sessions.
        CGROUP_SESSION=$(${pkgs.systemd}/bin/loginctl session-status 2>/dev/null | head -n1 | awk '{print $1}')
        if is_remote "$CGROUP_SESSION"; then
          exit 0
        fi

        # 2. Check XDG_SESSION_ID from the environment of the parent process (the shell).
        # Multiplexers like tmux might not update the cgroup but often preserve this variable.
        ENV_SESSION_ID=$(grep -z "^XDG_SESSION_ID=" "/proc/$PPID/environ" 2>/dev/null | cut -d= -f2-)
        if is_remote "$ENV_SESSION_ID"; then
          exit 0
        fi

        # 3. Check for explicit SSH indicators in the parent process environment.
        # This is the fallback for tmux/screen sessions where the session ID might be local
        # or missing, but the user is interacting via an SSH-forwarded environment.
        if grep -zqE "^(SSH_CLIENT|SSH_CONNECTION|SSH_TTY)=" "/proc/$PPID/environ" 2>/dev/null; then
          exit 0
        fi

        # No remote indicator found for this specific process context.
        exit 1
      ''}"
    ];
  };
}
