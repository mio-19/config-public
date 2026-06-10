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
        # Setup logging
        exec 1>>/tmp/pam_ssh_bypass.log 2>&1
        echo "--- $(date) ---"
        echo "PAM_USER=$PAM_USER"
        echo "PAM_TTY=$PAM_TTY"
        echo "PPID=$PPID"
        echo "Environment:"
        env
        echo "Process tree for PPID:"
        ${pkgs.psmisc}/bin/pstree -s $PPID || true

        if [ -n "$SSH_TTY" ] || [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_CLIENT" ]; then
          echo "SSH variables found natively. Exiting 0."
          exit 0
        fi

        # Try to find if sshd is in the process tree of the PAM invocation
        if ${pkgs.psmisc}/bin/pstree -s $$ | ${pkgs.gnugrep}/bin/grep -q "sshd"; then
          echo "sshd found in pstree. Exiting 0."
          exit 0
        fi

        # The session is local (e.g., seat0 physical hardware) or multiplexer failed to detect.
        echo "No SSH context detected. Exiting 1."
        # Exit 1 instructs PAM to ignore the rule and evaluate fprintd normally.
        exit 1
      ''}"
    ];
  };
}
