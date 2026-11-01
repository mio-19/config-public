# NixMac: bare-metal Asahi Linux

`nixmac-asahi` replaces the UTM/QEMU `macvirt` configuration. The macOS
`NixMac` configuration is separate. The shared bare-metal KDE, common,
selector4nix and persistent aspects follow the other Linux hosts. The existing
user, password-file convention and state version (25.11) are retained.

## Prepare the Mac

Follow the [upstream installation guide](https://github.com/nix-community/nixos-apple-silicon/blob/main/docs/uefi-standalone.md)
to check model support, create the Asahi UEFI boot environment and boot its NixOS
installer. Keep the Asahi ESP, its `vendorfw/firmware.cpio`, macOS stub and Apple
recovery partitions. Do not run whole-disk Disko or create a new GPT table.

Create a Linux partition in the free space as described upstream. Identify it
and the Asahi ESP explicitly with `lsblk -o NAME,SIZE,FSTYPE,LABEL,PARTUUID`.
The commands below format ONLY the selected Linux partition. Replace the example
paths; partition numbers vary between Macs. Run from a root installer shell.

```sh
set -eu
linux_partition=/dev/disk/by-partuuid/REPLACE_WITH_LINUX_PARTUUID
asahi_esp=/dev/disk/by-partuuid/REPLACE_WITH_ASAHI_ESP_PARTUUID
# Check both selections before continuing.
lsblk -o NAME,SIZE,FSTYPE,LABEL,PARTUUID "$linux_partition" "$asahi_esp"
cryptsetup luksFormat --type luks2 --label NIXMAC_CRYPT "$linux_partition"
cryptsetup open "$linux_partition" cryptroot
mkfs.btrfs -L NIXMAC_ROOT /dev/mapper/cryptroot
mount -o subvolid=5 /dev/mapper/cryptroot /mnt
for subvolume in root persistent varlog home nix swap; do
  btrfs subvolume create "/mnt/$subvolume"
done
btrfs filesystem mkswapfile --size 8G /mnt/swap/swapfile
umount /mnt

# Label the EXISTING Asahi ESP; do not format it.
fatlabel "$asahi_esp" NIXMAC_EFI
mount -o subvol=/root,compress-force=zstd,noatime /dev/mapper/cryptroot /mnt
for entry in home:home nix:nix persistent:persistent varlog:var/log swap:.swapvol; do
  subvolume=${entry%%:*}
  destination=${entry#*:}
  mkdir -p "/mnt/$destination"
  mount -o "subvol=/$subvolume,compress-force=zstd,noatime" /dev/mapper/cryptroot "/mnt/$destination"
done
mkdir -p /mnt/boot
mount "$asahi_esp" /mnt/boot
test -f /mnt/boot/vendorfw/firmware.cpio
```

## Install

From this repository's root, create the retained user's password hash before
installing. Both root and `user` use this password file, as in the former VM.

```sh
set -eu
install -d -m 700 /mnt/persistent/etc
umask 077
nix shell nixpkgs#mkpasswd --command mkpasswd -m yescrypt > /mnt/persistent/etc/pass-user-user
chmod 600 /mnt/persistent/etc/pass-user-user
nixos-install --flake ./nixos#nixmac-asahi --no-root-password \
  --option extra-substituters https://nixos-apple-silicon.cachix.org \
  --option extra-trusted-public-keys "nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20="
```

After boot, rebuild from the repository root:

```sh
sudo nixos-rebuild boot --flake ./nixos#nixmac-asahi
```

The initrd prompts for the LUKS passphrase, extracts vendor firmware from the
unencrypted Asahi ESP at boot, then resets the ephemeral root before mounting
it. Home, Nix, logs, swap and `/persistent` survive resets. Previous root
subvolumes are retained for 30 days. Hibernation remains disabled because root
rollback is incompatible with it. No firmware needs to be committed or copied
into the public repository. Back up the LUKS header separately after setup.

The old VM's `facter.json`, if present in a private checkout, is historical and
unused; generate a fresh hardware report on the Mac before enabling facter.

## Former VM references

Rosetta/SPICE and QEMU guest services were removed for bare metal. Historical
references from the VM configuration:

- <https://xyno.space/posts/nixos-utm-rosetta/>
- <https://github.com/NixOS/nixpkgs/issues/209242>
- <https://github.com/zhaofengli/rosetta-spice>
- <https://github.com/Yeshey/nixos-box64-binfmt>
- <https://discourse.nixos.org/t/box86-box64-as-part-of-binfmt/52498>
