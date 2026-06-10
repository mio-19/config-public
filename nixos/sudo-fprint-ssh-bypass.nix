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
      "seteuid"
      "${pkgs.writeShellScript "pam-sudo-ssh-bypass" ''
        set -euo pipefail

        export PATH=${
          lib.makeBinPath [
            pkgs.psmisc
            pkgs.tmux
            pkgs.systemd
            pkgs.coreutils
            pkgs.gnugrep
            pkgs.gawk
          ]
        }:$PATH

        # Define target user and PTY terminal from the PAM context
        TARGET_USER="''${PAM_USER:-}"
        TARGET_TTY="''${PAM_TTY:-}"

        # If executed outside of PAM context (debugging), attempt local resolution
        if [[ -z "$TARGET_USER" || -z "$TARGET_TTY" ]]; then
            TARGET_USER=$(id -un)
            TARGET_TTY=$(tty)
        fi

        # Clean TTY path (remove /dev/ prefix if present)
        CLEAN_TTY="''${TARGET_TTY#/dev/}"

        # 1. DIRECT PROCESS ANCESTRY CHECK
        # Traverse the parent process tree of the calling script to check for a direct sshd ancestor.
        # This handles raw, non-multiplexed SSH connections.
        if pstree -s $$ | grep -q "sshd"; then
            exit 0
        fi

        # 2. CROSS-BOUNDARY MULTIPLEXER CHECK
        # Resolve the user's numeric UID to locate the tmux socket
        USER_UID=$(id -u "$TARGET_USER")
        TMUX_SOCKET="/tmp/tmux-''${USER_UID}/default"

        # If the tmux socket does not exist, the user is not running a multiplexer session
        if [[ ! -S "$TMUX_SOCKET" ]]; then
            exit 1
        fi

        # Query the tmux server to find the session name associated with our target PTY
        # This maps the PTY of the active sudo execution to the internal tmux pane
        TMUX_SESSION=$(tmux -S "$TMUX_SOCKET" list-panes -a -F '#{pane_tty} #{session_name}' 2>/dev/null \
            | grep -E "^/dev/''${CLEAN_TTY} " \
            | awk '{print $2}' \
            | head -n 1) || true

        # If the terminal path is not mapped to an active session, exit and fall back to local auth
        if [[ -z "$TMUX_SESSION" ]]; then
            exit 1
        fi

        # Retrieve the PIDs of all clients currently attached to the resolved session
        CLIENT_PIDS=$(tmux -S "$TMUX_SOCKET" list-clients -t "$TMUX_SESSION" -F '#{client_pid}' 2>/dev/null) || true

        if [[ -z "$CLIENT_PIDS" ]]; then
            exit 1
        fi

        # Interrogate the connection origin of each attached client process
        for CLIENT_PID in $CLIENT_PIDS; do
            # Check A: Inspect the parent process tree of the client process
            if pstree -s "$CLIENT_PID" | grep -q "sshd"; then
                exit 0
            fi

            # Check B: Query systemd-logind using the client's session identifier
            if [[ -f "/proc/''${CLIENT_PID}/sessionid" ]]; then
                CLIENT_SESSION_ID=$(cat "/proc/''${CLIENT_PID}/sessionid")
                # Ensure it is a valid session ID (4294967295 represents unsigned -1, indicating no session)
                if [[ "$CLIENT_SESSION_ID" != "4294967295" ]]; then
                    # Query loginctl for the session's remote status
                    IS_REMOTE=$(loginctl show-session "$CLIENT_SESSION_ID" -p Remote --value 2>/dev/null || true)
                    if [[ "$IS_REMOTE" == "yes" ]]; then
                        exit 0
                    fi
                fi
            fi
        done

        # If no active client processes originate from an SSH session, enforce local auth
        exit 1
      ''}"
    ];
  };
}
