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
- **Always verify the public tree compiles:** Before committing and pushing to `config-public`, you MUST successfully run `nix eval --show-trace ".#nixosConfigurations.<host>.config.system.build.toplevel"` (or equivalent) in `config-public` to catch broken import paths or missing redactions.
- Before push: `git diff` host files — should be import-path (or similarly tiny) changes only; no new user blocks, `sshkeys`, disk paths, or `facter.json` paths.
- Private-only (do not sync): `modules/hosts/lenovo/`, `modules/hosts.nix`, `modules/lenovo.nix`, `nixos/apc/`, `nixos/wsl.nix`, etc.

**If private details were pushed to config-public**

- Reset to last safe commit, re-apply sanitized changes only, `git push --force` to rewrite history.

**Pulling from config-public to private config**

The private `config` repository acts as a downstream fork of `config-public`.
When pulling changes from `config-public` into `config`, you will often encounter merge conflicts in files that contain `# DETAILS REMOVED` in the public repository but hold real secrets in the private repository.
**Always resolve these conflicts by keeping the private (`HEAD`) version (`git checkout --ours <file>`) to ensure secrets are preserved!**

## Den & import-tree behavior

- **Auto-import behavior**: The `import-tree.provides.host` battery in Den automatically scans host directories (`modules/hosts/<hostname>`) for folders starting with `_` and maps them to a class. For example, `_nixos` maps to `host.nixos.imports` and `_homeManager` maps to `host.homeManager.imports`.
- **`_nixos` semantics**: Because `host.nixos` applies directly to the NixOS system configuration, anything placed in `_nixos/` automatically becomes a host-wide NixOS module.
- **`_homeManager` semantics**: By design, `_homeManager` under a host is intended for **host-wide** Home-Manager configuration. However, due to a breaking change in Den, host-level `homeManager` scopes are **inert** and will not propagate to individual users. Therefore, placing user configurations (like `user.nix` or `zdmin.nix`) in `hosts/<hostname>/_homeManager` is incorrect—it evaluates them at the host scope silently (or causes evaluation errors with missing arguments like `enable-fcitx`), but fails to actually apply the configuration to the user.
- **Directories without `_`**: If you rename a directory to not start with `_` (e.g. `.hm_users` or `users`), it escapes the `import-tree.provides.host` battery. However, the main `import-tree` scanning `modules/` ONLY ignores paths containing `/_`. Therefore, `.hm_users` will NOT be exempted and will be mistakenly parsed as `den.aspects...".hm_users"`. To truly avoid unwanted magic, either inline configurations directly, move them entirely outside `modules/`, or leave them in `_homeManager` knowing the host-level scope is inert.
- **Home-manager configs for users**: When routing user-specific Home Manager configurations for a host (e.g. in `lenovo.nix` or `fw13.nix`), do **not** use `provides.<username>.homeManager.imports` (especially `provides.user` which silently fails due to shadowing the `user` context variable). Instead, always route through the `provides.to-users` block. You can inline the config directly, or use `lib.optional (user.name == "name") [ ... ]` to selectively apply imports.
