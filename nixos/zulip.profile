# Firejail profile for zulip (NixOS-friendly; Electron-based)
# Persistent local customizations
include zulip.local
# Persistent global definitions
include globals.local

# Must come before include electron-common.profile (sets dbus-user none / netfilter).
ignore noinput
ignore dbus-user none
ignore dbus-system none
ignore netfilter
ignore noexec /tmp
ignore apparmor

noblacklist ${HOME}/.config/Zulip

mkdir ${HOME}/.config/Zulip
whitelist ${HOME}/.config/Zulip

private-etc @tls-ca
private-bin bash,cut,echo,egrep,electron,electron[0-9],electron[0-9][0-9],grep,head,locale,sed,sh,tr,xdg-mime,xdg-open,zulip,zsh

include electron-common.profile

dbus-user filter
dbus-user.talk org.freedesktop.portal.Desktop
dbus-user.talk org.freedesktop.portal.Documents
dbus-user.talk org.freedesktop.portal.Settings
dbus-user.talk org.freedesktop.DBus
dbus-user.talk ca.desrt.dconf
dbus-user.talk org.freedesktop.Notifications
dbus-system none
