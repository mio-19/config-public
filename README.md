# config-public

what can be public - nixos and nix-darwin configuration

What is a configuration? A configuration is a collection of workarounds and things that happened to work but I don't know why

this configuration is not organized in the best way. I move my focus to other things in my life as long as my configuration is mostly doing its jobs.

I put time in this configuration when kde plasma or some other software hurts me.

I spend time in this configuration when I am bored and unable to do other things 

this is shared for debugging purposes

you can see `DETAILS REMOVED` with what I feel uncomfortable sharing or unsafe to share.
If a file starts with `# THIS IS A STUB`, it means that the whole file has been recreated for `config-public`.

```zsh
--option extra-substituters https://mio-config.cachix.org --option extra-trusted-public-keys mio-config.cachix.org-1:VM6OZi+PC/ENBDf5ogaArQMgVUvJNvAL5t9ayXZdCIg=
```

```zsh
--option substituters 'https://cache.nixos.org/ https://mio-config.cachix.org' --option extra-trusted-public-keys mio-config.cachix.org-1:VM6OZi+PC/ENBDf5ogaArQMgVUvJNvAL5t9ayXZdCIg=
```

<https://gist.github.com/lxl66566/697db0cccd04b7247dc9a0cfb96d328c> <https://github.com/ccicnce113424/nixos-config/blob/main/lib/apply-patches-cow.nix>

```zsh
wget https://gist.github.com/lxl66566/697db0cccd04b7247dc9a0cfb96d328c/raw/aa9d7fe25bedb3458866ac09bec9718402b5ebea/nixfollows.py
wget https://github.com/ccicnce113424/nixos-config/raw/refs/heads/main/lib/apply-patches-cow.nix
```

## LLM policy

Headache. Use LLM for boring, no-brain tasks. LLM pushed living cost higher? I cannot opt out of the higher living cost by opting out of LLM myself.

## common problem - cannot install grub, uefi

then install systemd-boot first, later change to grub if needed

## to have list

+ pam_ssh_agent_auth
