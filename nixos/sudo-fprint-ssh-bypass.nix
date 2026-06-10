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
        export PATH=${
          lib.makeBinPath [
            pkgs.coreutils
            pkgs.gawk
            pkgs.gnugrep
            pkgs.tmux
          ]
        }:$PATH

        # Get the PID of sudo ($PPID) and then the PID of the shell that called sudo
        SUDO_PID=$PPID
        SHELL_PID=$(awk '{print $4}' /proc/$SUDO_PID/stat)

        # Extract environment variables directly from the calling shell
        # This completely bypasses sudo's aggressive environment stripping
        SHELL_ENV=$(cat /proc/$SHELL_PID/environ | tr '\0' '\n')

        SSH_CONN=$(echo "$SHELL_ENV" | grep -E '^SSH_CONNECTION=' | cut -d= -f2-)
        TMUX_VAR=$(echo "$SHELL_ENV" | grep -E '^TMUX=' | cut -d= -f2-)

        if [ -n "$SSH_CONN" ]; then
          # Direct SSH connection detected in the calling shell
          exit 0
        fi

        if [ -n "$TMUX_VAR" ]; then
          # We are inside tmux. Extract the socket path from the TMUX variable.
          # TMUX variable format: /tmp/tmux-1000/default,5534,0
          TMUX_SOCKET=$(echo "$TMUX_VAR" | cut -d, -f1)
          if [ -S "$TMUX_SOCKET" ]; then
            # Query the tmux server to see if the session environment has SSH_CONNECTION
            if tmux -S "$TMUX_SOCKET" show-environment SSH_CONNECTION >/dev/null 2>&1; then
              exit 0
            fi
          fi
        fi

        # The session is local (e.g., seat0 physical hardware).
        # Exit 1 instructs PAM to ignore the rule and evaluate fprintd normally.
        exit 1
      ''}"
    ];
  };
}
