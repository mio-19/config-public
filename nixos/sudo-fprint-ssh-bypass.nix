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
  # BUG: Not Bypassed in tmux in ssh
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
        if [ -n "$SSH_TTY" ] || [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_CLIENT" ]; then
          # The presence of SSH-related environment variables strongly indicates an SSH session.
          # Exit 0 instructs PAM to trigger success=1, thereby bypassing fprintd.
          exit 0
        fi

        # The session is local (e.g., seat0 physical hardware).
        # Exit 1 instructs PAM to ignore the rule and evaluate fprintd normally.
        exit 1
      ''}"
    ];
  };
}
