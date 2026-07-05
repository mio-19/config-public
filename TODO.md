# TODO

- [ ] `nixos/flake.nix`: Implement automatic patched `nixpkgs` replacement for inputs using `builtins.mapAttrs` (replicating the logic successfully implemented in `mac/flake.nix`).
- [ ] Clean up NixOS host modules: Move top-level host aspect files (e.g. `modules/<hostname>.nix`) into their respective subdirectories (`modules/hosts/<hostname>/aspect.nix`) to keep the `modules/` directory organized and clean, mirroring the changes made for macOS hosts.
