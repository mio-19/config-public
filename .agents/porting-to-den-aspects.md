# Porting `nixos/*.nix` (and `mac/*.nix`) to Den single-file aspects

This documents the workflow used to migrate standalone NixOS/nix-darwin modules into `modules/<name>.nix` files that declare `den.aspects.<name>`.

See also [AGENTS.md](./AGENTS.md) for public/private sync rules and Den home-manager routing quirks.

## Goal

Replace raw imports like:

```nix
../../../../nixos/foo.nix
```

with:

```nix
(import ../../../../aspect.nix "foo")
```

The old file is deleted after its body lives in a single aspect file under `modules/`. `import-tree` picks up new `modules/*.nix` files automatically and registers `den.aspects.*`.

## Aspect file template

```nix
{ den, ... }:
{
  den.aspects.<name> = {
    description = "Short human-readable summary";
    nixos =
      args@{ config, inputs, lib, pkgs, ... }:
      let
        _include = args._include or (import ../nixos/include.nix args);
      in
      with _include;
      {
        # former nixos/foo.nix body (config options only)
      };
  };
}
```

Use `../nixos/include.nix` when the old module used `_include` / `with _include` for `hardenedPkg`, `novirt`, `boot-to-steam`, etc.

## Pick the right Den class branch

| Old module content | Den branch | Notes |
|---|---|---|
| NixOS-only system config | `nixos` | Most `nixos/*.nix` files |
| nix-darwin-only config | `darwin` | e.g. former `mac/*.nix` service modules |
| Both NixOS + nix-darwin (same keys) | `os` | e.g. `nix.settings`, `environment.sessionVariables` in `common` |
| Per-user Home Manager config | `homeManager` | See below — **do not** keep `config.home-manager.sharedModules` inside `nixos` |

Examples in-tree:

- `modules/music.nix` — `nixos` only
- `modules/harmonia_lan_only_not_public_ip.nix` — `nixos` + `darwin` (different paths/settings per OS)
- `modules/token.nix`, `modules/auto-allocate-uids.nix` — `os` (+ platform-specific extras when needed)
- `modules/alwayson.nix`, `modules/zfs.nix`, `modules/wsl-base.nix` — `nixos` + `homeManager`
- `modules/harmonia.nix` — `darwin` only (launchd service module via `darwin.imports`)
- `modules/hardened.nix` — wired through `den.aspects.common` `includes`, not per-host imports

## Home Manager: use `homeManager`, not `nixos` + `sharedModules`

If the old module had:

```nix
config.home-manager.sharedModules = [ ... ];
```

split it into an aspect `homeManager` branch. `aspect.nix` resolves that branch and merges it into `home-manager.sharedModules` for every HM user on the host:

```nix
homeManager = {
  imports = [
    ({ lib, osConfig, ... }: { /* per-user options */ })
  ];
};
```

Or, when the branch body needs `lib` at the top level (e.g. `lib.mkAliasOptionModule`):

```nix
homeManager =
  { lib, ... }:
  {
    imports = [
      (lib.mkAliasOptionModule [ "programs" "ssh" "settings" ] [ "programs" "ssh" "matchBlocks" ])
      ({ ... }: { /* ... */ })
    ];
  };
```

Reference: `modules/alwayson.nix`, `modules/zfs.nix`, `modules/wsl-base.nix`.

Verify per-user application on a host with multiple HM users (eval `home-manager.users.<name>.*`).

## Modules that declare `options`

If the old file mixed top-level `options` with `config.foo = ...`, keep that shape in the `nixos` branch — use the `config.` prefix on config keys:

```nix
nixos = args@{ config, lib, pkgs, ... }: {
  options.myOption = lib.mkOption { ... };
  config.services.foo.enable = true;  # not bare `services.foo`
};
```

See `modules/zfs.nix` (`options.zfs_arc_max_mib` + `config.*`).

## Path fixes when moving `nixos/` → `modules/`

| Old path (from `nixos/foo.nix`) | New path (from `modules/foo.nix`) |
|---|---|
| `./profile` | `../nixos/profile` |
| `../nixos-base-den.nix` | `../nixos-base-den.nix` (unchanged) |
| `./include.nix` | `../nixos/include.nix` |

Keep all existing comments, links, and commented-out blocks unless the user asks to remove them.

## Updating consumers

1. **Host `_nixos/default.nix`**

   ```nix
   (import ../../../../aspect.nix "foo")
   ```

2. **Another aspect's `nixos.imports`**

   ```nix
   imports = [
     (import ../aspect.nix "games")
   ];
   ```

3. **`den.aspects.common` `includes`** (shared baseline, both OSes)

   ```nix
   includes = [
     ...
     den.aspects.hardened
     den.aspects.token
   ];
   ```

   Remove the old raw import from `common.nix` `nixos`/`darwin` `imports` when moving here.

4. **Commented imports** — update to aspect form for consistency:

   ```nix
   #(import ../../../../aspect.nix "rc")
   ```

5. **Legacy non-Den entrypoints** (e.g. `nixos/wsl.nix`) — use repo-root `aspect.nix`:

   ```nix
   (import ../aspect.nix "wsl-base")
   ```

6. **Darwin host modules** (e.g. `mac/nixmac.nix`):

   ```nix
   (import ../aspect.nix "harmonia_lan_only_not_public_ip")
   ```

## Cross-platform merge pattern

When `nixos/foo.nix` and `mac/foo.nix` differ only by platform paths/settings, one aspect with two branches:

```nix
den.aspects.foo = {
  nixos = { ... }: { /* linux */ };
  darwin = { ... }: { /* mac */ };
};
```

Delete both old files. Example: `modules/harmonia_lan_only_not_public_ip.nix`.

When a `mac/modules/` tree is really a nix-darwin **service module** (defines `options`), move it into an aspect with `darwin.imports = [ ... ]`. Example: `modules/harmonia.nix` included from `common`.

## Private vs public (`config-public`)

1. Compare trees: paths absent from `config-public` are **private-only** (e.g. WSL hosts, `wifi-extra`, extra users) — aspect can stay private-only; no public push required.
2. Shared aspects: copy or recreate in `config-public`, preserving `# DETAILS REMOVED` where the private file has secrets (e.g. `modules/wifi.nix`, `modules/token.nix`).
3. **Never** bulk-copy private host files or redacted files into public.
4. If repos diverge for reasons **other than** redaction, stop and ask the user which version wins (see AGENTS.md).
5. On merge-back conflicts in redacted/secret files: `git checkout --ours` in private `config`.

## Verification

Before push to `config-public`:

```bash
cd config-public/nixos
nix eval .#nixosConfigurations.fw13.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.ipc.config.system.build.toplevel.drvPath
```

Pick hosts that actually import the aspect. Optionally confirm key options:

```bash
nix eval --impure --expr '
  let f = builtins.getFlake (toString ./..);
  in f.nixosConfigurations.ipc.config.services.scx.enable
'
```

Run `nixfmt` on all touched `.nix` files.

Darwin cross-eval from Linux often fails pre-existing IFD issues — not necessarily a regression from the port.

## Commit / push / merge-back

**Public + private change:**

1. Implement in private `config` (or public first if no secrets).
2. Sync sanitized edits to `config-public` if applicable.
3. `nixfmt` → eval public hosts → commit → push `config-public`.
4. Commit → push private `config`.
5. Merge public into private for history:

   ```bash
   git fetch config-public
   git merge --no-ff config-public/main -m "Merge config-public: ..."
   git push origin main
   ```

   Use `git checkout --ours` on conflicted secret/redacted files (`modules/token.nix`, `modules/wifi.nix`, etc.).

**Important:** Prefer `git push origin main` after merge without `git pull --rebase` when the goal is to **keep the merge commit**. Rebase can drop duplicate commits and erase the merge record.

**Private-only change:** commit and push `config` only (no public merge needed).

## Common pitfalls

1. **Broken auto-wrap scripts** — do not regex-wrap old modules; nested `{ config, ... }@args:` signatures end up inside the aspect body and eval fails with “does not look like a module”.
2. **`include.nix` needs full args** — if the aspect calls `import ../nixos/include.nix args`, the `nixos` function must accept at least `config`, `pkgs`, `lib`, not just `{ lib, ... }`.
3. **`homeManager` dropped on host-scope aspects** — host-level `homeManager` in a parametric aspect does not reach users; use explicit `homeManager` branch + `aspect.nix`, or `provides.to-users` for per-host user routing.
4. **Deleting stale files** — remove old `nixos/*.nix` and orphaned `mac/modules/*` after porting; grep for remaining references.
5. **Aspect name vs file name** — aspect key uses the string passed to `aspect.nix` (e.g. `"printing-sharing"`, `"harmonia_lan_only_not_public_ip"`); file is usually `modules/<same-name>.nix`.

## Checklist (copy per port)

- [ ] Read old module + list all consumers (`rg 'foo\.nix'`)
- [ ] Create `modules/<name>.nix` with correct class branch(es)
- [ ] Fix relative paths; preserve comments
- [ ] Move HM content to `homeManager` branch if present
- [ ] Update consumers to `(import .../aspect.nix "<name>")`
- [ ] Add to `common.includes` if it replaces a common import
- [ ] Delete old `nixos/<name>.nix` (and `mac/` copy if merged)
- [ ] Sync `config-public` if shared; redact secrets
- [ ] `nixfmt` + eval affected hosts
- [ ] Commit/push; merge public → private if public changed
