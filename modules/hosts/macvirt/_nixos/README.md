# macvirt - qemu on utm

enable GPU for UTM.

```zsh
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount ~/Documents/config/modules/hosts/macvirt/_nixos/disk.nix


sudo nixos-install --no-root-passwd --flake ~/Documents/config/nixos#macvirt --impure --option 'extra-substituters' 'https://chaotic-nyx.cachix.org/' --option extra-trusted-public-keys "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8=" --option extra-substituters https://niri.cachix.org --option extra-trusted-public-keys niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964= --option extra-substituters https://install.determinate.systems --option extra-trusted-public-keys cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM=
# REMEMBER TO SET UP pass-user-* to /mnt/persistent/etc/
cd /mnt/persistent/etc/
~/Documents/config/nixos/my-mkpass pass-user-user
```

## box64/rosetta

+ <https://xyno.space/posts/nixos-utm-rosetta/>
+ <https://github.com/NixOS/nixpkgs/issues/209242> -> <https://github.com/zhaofengli/rosetta-spice>
+ <https://github.com/Yeshey/nixos-box64-binfmt>
+ <https://discourse.nixos.org/t/box86-box64-as-part-of-binfmt/52498>
