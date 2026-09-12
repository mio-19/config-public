# Firejail profile for bitwig-studio
# Description: Bitwig Studio digital audio workstation
# No upstream profile yet: https://github.com/netblue30/firejail/issues/1139
# Paths/permissions cross-checked against Flathub finish-args:
#   https://github.com/flathub/com.bitwig.BitwigStudio/blob/master/com.bitwig.BitwigStudio.yaml
#   (--device=all, pipewire/pulse, network for auth+content, persist .java/.BitwigStudio/Bitwig Studio)
# Offline activation works without net; content packs/updates need network:
#   https://www.bitwig.com/support/shop_license_activation/how-does-the-offline-activation-process-work-25/
# Optional update blocking: firejail --noprofile --net=none bitwig-studio
#   (https://www.kvraudio.com/forum/viewtopic.php?t=547237)
# yabridge/Wine often breaks under DAW sandboxes; keep paths open and expect to loosen further
# Persistent local customizations
include bitwig-studio.local
# Persistent global definitions
include globals.local

# Config / library / project dirs (Flatpak: persist .BitwigStudio and "Bitwig Studio")
noblacklist ${HOME}/.BitwigStudio
noblacklist ${HOME}/Bitwig Studio
# Bundled Java prefs (Flatpak: persist .java; disable-programs.inc blacklists it)
noblacklist ${HOME}/.java
# Native plugin dirs (disable-programs.inc blacklists ~/.vst ~/.lv2; ~/.vst3 ~/.clap used by Bitwig)
noblacklist ${HOME}/.vst
noblacklist ${HOME}/.vst3
noblacklist ${HOME}/.clap
noblacklist ${HOME}/.lv2
# Windows plugins via yabridge (disable-programs.inc blacklists ~/.wine*)
noblacklist ${HOME}/.wine
noblacklist ${HOME}/.wine64
noblacklist ${HOME}/.local/share/yabridge
noblacklist ${DOCUMENTS}
noblacklist ${DOWNLOADS}
noblacklist ${MUSIC}

include disable-common.inc
include disable-devel.inc
include disable-exec.inc
include disable-interpreters.inc
include disable-programs.inc
include disable-xdg.inc

include whitelist-var-common.inc

apparmor
caps.drop all
# Flatpak uses --share=network for auth, content downloads, and notifications
netfilter
# Flatpak: --device=all + DRI + pulse/pipewire — do not set no3d/nosound/noinput/private-dev
nodvd
nogroups
nonewprivs
noroot
notv
novideo
noprinters
protocol unix,inet,inet6
# Bundled JRE / plugin hosts may use chroot-like sandboxing
seccomp !chroot

private-tmp

# Flatpak: --talk-name=org.freedesktop.Notifications
dbus-user filter
dbus-user.talk org.freedesktop.Notifications
dbus-user.talk org.freedesktop.portal.Desktop
dbus-user.talk org.freedesktop.portal.OpenURI
dbus-system none
