# Custom Rules

- When adding patches from GitHub PRs to Nix configurations, the `name` attribute should be the PR title.
- Use the `nurl` command to get the hash for fetchers (like `fetchpatch`).
- When editing or moving files, keep existing comments in place. Do not drop explanatory comments, links, or commented-out config unless the user asks. If a path changes, update the comment path — do not delete the comment.
