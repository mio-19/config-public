# Firejail profile for bitwig-studio
# Description: Bitwig Studio digital audio workstation
# No upstream profile yet: https://github.com/netblue30/firejail/issues/1139
# Community tip for update blocking: firejail --noprofile --net=none bitwig-studio
#   (https://www.kvraudio.com/forum/viewtopic.php?t=547237)
# Persistent local customizations
include bitwig-studio.local
# Persistent global definitions
include globals.local

# Config / project / plugin dirs (disable-programs.inc blacklists ~/.vst ~/.lv2 ~/.wine*)
noblacklist ${HOME}/.BitwigStudio
noblacklist ${HOME}/Bitwig Studio
noblacklist ${HOME}/.vst
noblacklist ${HOME}/.vst3
noblacklist ${HOME}/.clap
noblacklist ${HOME}/.lv2
noblacklist ${HOME}/.wine
noblacklist ${HOME}/.wine64
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
# Keep network for license activation; put `net none` in bitwig-studio.local after activation if desired
netfilter
# UI needs OpenGL; audio/MIDI need devices and input — do not set no3d/nosound/noinput/private-dev
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

dbus-user filter
dbus-user.talk org.freedesktop.Notifications
dbus-user.talk org.freedesktop.portal.Desktop
dbus-user.talk org.freedesktop.portal.OpenURI
dbus-system none
