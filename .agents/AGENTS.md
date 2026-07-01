# Custom Rules

- When adding patches from GitHub PRs to Nix configurations, the `name` attribute should be the PR title.
- Use the `nurl` command to get the hash for fetchers (like `fetchpatch`).
- When editing or moving files, keep existing comments in place. Do not drop explanatory comments, links, or commented-out config unless the user asks. If a path changes, update the comment path — do not delete the comment.

## Syncing to config-public (`../config-public`)

config-public is a **sanitized** public repo. Private details are redacted as `# DETAILS REMOVED` (see `README.md`).

**Never** `cp` whole files from private `config` into `config-public`, especially host `default.nix` files — that replaces redactions with real users, keys, disks, hostnames, tailscale, etc.

**Do**

- Sync only paths that belong in public (shared modules, den aspects, import-line updates on public hosts).
- Keep every existing `# DETAILS REMOVED` comment and placeholder in config-public files.
- Apply **minimal diffs**: e.g. change `../bios.nix` → `../../bios-den.nix` on the public copy, not by copying private `nixos/fw13/default.nix`.
- Rebuild shared aspect modules (e.g. `modules/nixos-common.nix`) from **config-public’s** `nixos/common.nix`, not from private `config`.
- Before push: `git diff` host files — should be import-path (or similarly tiny) changes only; no new user blocks, `sshkeys`, disk paths, or `facter.json` paths.
- Private-only (do not sync): `modules/hosts/lenovo/`, `modules/hosts.nix`, `modules/lenovo.nix`, `nixos/apc/`, `nixos/wsl.nix`, etc.

**If private details were pushed to config-public**

- Reset to last safe commit, re-apply sanitized changes only, `git push --force` to rewrite history.
