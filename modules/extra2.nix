{ den, ... }:
{
  den.aspects.extra2 = {
    description = "Extra CLI/desktop tools and llm-agents packages";
    nixos =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        ...
      }:
      let
        _include = args._include or (import ../nixos/include.nix args);
      in
      with _include;
      {
        # https://search.nixos.org/packages
        environment.systemPackages =
          with pkgs;
          (map hardenedPkg [
            yt-dlp
            nur.repos.mio.rocksmith2tab
            nur.repos.mio.mdbook-generate-summary
            inputs.mio.packages."${pkgs.stdenv.hostPlatform.system}".payload-dumper-go
          ])
          ++ (map cleanPkg [
            github-copilot-cli
          ])
          ++ (with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
            #oh-my-codex
            oh-my-opencode
          ]);
      };
  };
}
