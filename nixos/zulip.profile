# Firejail profile for zulip (NixOS-friendly; upstream + netfilter/dbus fixes)
# Persistent local customizations
include zulip.local
# Persistent global definitions
include globals.local

ignore noexec /tmp
ignore netfilter

noblacklist ${HOME}/.config/Zulip

include disable-common.inc
include disable-devel.inc
include disable-exec.inc
include disable-interpreters.inc
include disable-programs.inc
include disable-shell.inc
include disable-xdg.inc

mkdir ${HOME}/.config/Zulip
whitelist ${HOME}/.config/Zulip
whitelist ${DOWNLOADS}
include whitelist-common.inc
include whitelist-var-common.inc

apparmor
caps.drop all
no3d
nodvd
nogroups
noinput
nonewprivs
noroot
notv
nou2f
novideo
protocol unix,inet,inet6
seccomp

disable-mnt
private-bin locale,zulip
private-cache
private-dev
private-etc @tls-ca
private-tmp

restrict-namespaces

dbus-user filter
dbus-user.talk org.freedesktop.portal.Desktop
dbus-user.talk org.freedesktop.portal.Documents
dbus-user.talk org.freedesktop.portal.Settings
dbus-user.talk org.freedesktop.DBus
dbus-user.talk ca.desrt.dconf
dbus-user.talk org.freedesktop.Notifications
dbus-system none
