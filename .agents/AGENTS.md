# Custom Rules

- When adding patches from GitHub PRs to Nix configurations, the `name` attribute should be the PR title.
- Use the `nurl` command to get the hash for fetchers (like `fetchpatch`).
- When editing or moving files, keep existing comments in place. Do not drop explanatory comments, links, or commented-out config unless the user asks. If a path changes, update the comment path — do not delete the comment.

## Syncing private `config` and `config-public`

config-public is a **sanitized** public repo. Private details are redacted as `# DETAILS REMOVED` (see `README.md`).

**Never** `cp` whole files from private `config` into `config-public`, especially host `_nixos/default.nix` files — that replaces redactions with real users, keys, disks, hostnames, tailscale, etc.

**Do**

- Sync only paths that belong in public (shared modules, den aspects, import-line updates on public hosts).
- Keep every existing `# DETAILS REMOVED` comment and placeholder in config-public files.
- Apply **minimal diffs**: e.g. change an import to `(import ./aspect.nix "bios")` on the public copy of `modules/hosts/fw13/_nixos/default.nix`, not by copying the private host file wholesale.
- Keep `modules/common.nix` (`den.aspects.common`) structurally in sync between repos: same aspect shape and imports, with `# DETAILS REMOVED` preserved in config-public. Do not copy private-only paths or full private files into config-public.
- **Always verify the public tree compiles:** Before committing and pushing to `config-public`, you MUST successfully run `nix eval --show-trace ".#nixosConfigurations.<host>.config.system.build.toplevel"` (or equivalent) in `config-public` to catch broken import paths or missing redactions.
- **Redaction safety check (mandatory):** Before *any* `config-public` push, review the full `git diff` and ensure every `# DETAILS REMOVED` placeholder in touched files is still present (not replaced with real content), and no new private details were introduced. If a placeholder was overwritten, reset to the last safe commit and re-apply sanitized diffs only.
- Before push: `git diff` host files — should be import-path (or similarly tiny) changes only; no new user blocks, `sshkeys`, disk paths, or `facter.json` paths.
- **Public vs private paths:** do not maintain a hand-written private-only list. Compare `config` to `../config-public`: if a path is absent from config-public, treat it as private and do not sync it; if it exists there, keep it sanitized and in sync.

**If private details were pushed to config-public**

- Reset to last safe commit, re-apply sanitized changes only, `git push --force` to rewrite history.

**Pulling from config-public to private config**

The private `config` repo regularly merges `config-public/main` to stay aligned on shared modules.
When pulling changes from `config-public` into `config`, you will often encounter merge conflicts in files that contain `# DETAILS REMOVED` in the public repository but hold real secrets in the private repository.
**Always resolve these conflicts by keeping the private (`HEAD`) version (`git checkout --ours <file>`) to ensure secrets are preserved!**

**Always merge config-public back into config after config-public changes**

After any commit/push to `config-public`, **always** merge `config-public/main` into private `config` and push `config` too — even when the merge is a no-op on disk (e.g. you synced private → public and the trees already match). The merge commit records the sync point in git history for future pulls, conflict resolution, and audits.

Typical flow:

1. Change `config-public` → eval → commit → push `config-public`.
2. In `config`: `git fetch config-public` → `git merge config-public/main` → resolve conflicts with `--ours` where `# DETAILS REMOVED` vs secrets → commit → push `config`.
3. When you changed private `config` first and then synced sanitized edits to `config-public`, still do step 2 after pushing public — content may be unchanged, but the merge-back is required for history.

**Sometimes faster:** When the change is clearly public-only (shared modules/import-line tweaks with no secrets), you can implement it directly in `config-public` first (eval → commit → push), then merge it into private `config`. This reduces manual porting and lowers the chance of accidentally overwriting `# DETAILS REMOVED` placeholders.

## Den & import-tree behavior

- **Auto-import behavior**: The `import-tree.provides.host` battery in Den automatically scans host directories (`modules/hosts/<hostname>`) for folders starting with `_` and maps them to a class. For example, `_nixos` maps to `host.nixos.imports` and `_homeManager` maps to `host.homeManager.imports`.
- **`_nixos` semantics**: Because `host.nixos` applies directly to the NixOS system configuration, anything placed in `_nixos/` automatically becomes a host-wide NixOS module.
- **`_homeManager` semantics**: By design, `_homeManager` under a host is intended for **host-wide** Home-Manager configuration. However, due to a breaking change in Den, host-level `homeManager` scopes are **inert** and will not propagate to individual users. Therefore, placing user configurations (like `user.nix` or `zdmin.nix`) in `hosts/<hostname>/_homeManager` is incorrect—it evaluates them at the host scope silently (or causes evaluation errors with missing arguments like `enable-fcitx`), but fails to actually apply the configuration to the user.
- **Directories without `_`**: If you rename a directory to not start with `_` (e.g. `.hm_users` or `users`), it escapes the `import-tree.provides.host` battery (which only looks for `_nixos`, `_darwin`, `_homeManager`, … under a host). However, any `.nix` files you place anywhere under `modules/` will still be picked up by the top-level `(inputs.import-tree ./modules)` (except paths containing `/_`). If you want to keep files from being auto-imported during Den eval, either place them outside `modules/`, or put them under a path containing `/_` so `import-tree` ignores them by default.
- **Home-manager configs for users**: When routing user-specific Home Manager configurations for a host (e.g. in `lenovo.nix` or `fw13.nix`), do **not** use `provides.<username>.homeManager.imports` (especially `provides.user` which silently fails due to shadowing the `user` context variable). Instead, always route through the `provides.to-users` block. You can inline the config directly, or use `lib.optional (user.name == "name") [ ... ]` to selectively apply imports.
- **`provides.to-users` Home Manager shape**: In `provides.to-users`, use **flat class-prefixed keys** (`homeManager.programs.vscode.enable`, `homeManager.imports`, …) or `provides.to-users.homeManager = { ... }`. Do **not** nest a `homeManager = { ... }` attrset inside the `provides.to-users` function body — Den will not forward most options from that nested block to Home Manager (e.g. `programs.*.enable` and `mkForce` overrides are dropped). `imports` inside the nested block may still load, which makes this failure mode especially confusing: shared modules like `home-common.nix` apply while host disables do not. Top-level keys merged with `// lib.optionalAttrs` (e.g. `programs.plasma`, `xdg.configFile`) are unaffected and will still apply.
