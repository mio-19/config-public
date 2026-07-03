# NixOS login shell zsh with home-manager zsh; disables system programs.zsh on affected hosts.
# Opt in per user via users.<name>.nixosZshUser.enable = true (NixOS hosts only).
{ den, lib, ... }:
{
  den.aspects.nixos-zsh-user = {
    description = "NixOS login shell zsh with home-manager zsh";
    includes = [
      (
        { user, host }:
        {
          name = "nixos-zsh-user/${user.userName}@${host.name}";
          homeManager.programs.zsh.enable = true;
          nixos =
            { pkgs, ... }:
            {
              users.users.${user.userName} = {
                shell = pkgs.zsh;
                ignoreShellProgramCheck = true; # https://github.com/nix-community/home-manager/issues/108#issuecomment-2569823607
              };
              programs.zsh.enable = lib.mkForce false;
            };
        }
      )
    ];
  };

  den.schema.user = {
    imports = [
      (
        { lib, ... }:
        {
          options.nixosZshUser.enable = lib.mkEnableOption ''
            Use zsh as the NixOS login shell with home-manager zsh
            (sets ignoreShellProgramCheck and disables system programs.zsh on the host).
          '';
        }
      )
    ];

    includes = [
      (
        { user, host, ... }:
        lib.optional (
          (user.nixosZshUser.enable or false) && host.class == "nixos"
        ) den.aspects.nixos-zsh-user
      )
    ];
  };
}
