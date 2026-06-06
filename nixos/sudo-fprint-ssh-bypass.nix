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
        SESSION_ID=$(${pkgs.systemd}/bin/loginctl session-status | head -n1 | awk '{print $1}')

        if [ -z "$SESSION_ID" ]; then
          exit 1
        fi

        # Securely query systemd-logind for the session's Remote property.
        # The --value flag ensures it only outputs "yes" or "no".
        REMOTE_STATUS=$(${pkgs.systemd}/bin/loginctl show-session "$SESSION_ID" -p Remote --value 2>/dev/null || true)

        # Evaluate the Remote property output by loginctl.
        if [ "$REMOTE_STATUS" = "yes" ]; then
          # The session is definitively established via a remote network protocol.
          # Exit 0 instructs PAM to trigger success=1, thereby bypassing fprintd.
          exit 0
        else
          # The session is local (e.g., seat0 physical hardware).
          # Exit 1 instructs PAM to ignore the rule and evaluate fprintd normally.
          exit 1
        fi
      ''}"
    ];
  };
}
