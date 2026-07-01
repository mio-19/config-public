# Den hosts

Host directories under `modules/hosts/<name>/` use Den's import-tree layout (`_nixos/`, `_homeManager/`).

This repo is the public tree: hosts listed here are public. The private `config` repo may contain additional hosts under `modules/hosts/` — infer private-only paths by diffing against this tree; do not maintain a separate list in either repo.

Per-host Den aspects live in `modules/<hostname>.nix` when needed (e.g. `modules/fw13.nix`, `modules/ipc.nix`).
