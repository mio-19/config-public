# Firejail profile for bilibili-linux
# Persistent local customizations
include bilibili.local
# Persistent global definitions
include globals.local

noblacklist ${HOME}/.cache/bilibili
noblacklist ${HOME}/.config/bilibili
noblacklist ${HOME}/.local/share/bilibili

mkdir ${HOME}/.cache/bilibili
mkdir ${HOME}/.config/bilibili
mkdir ${HOME}/.local/share/bilibili
whitelist ${HOME}/.cache/bilibili
whitelist ${HOME}/.config/bilibili
whitelist ${HOME}/.local/share/bilibili

# Redirect
include electron-common.profile

# Allow D-Bus notifications/portal
ignore dbus-user none
dbus-user filter
dbus-user.talk org.freedesktop.Notifications
dbus-user.talk org.freedesktop.portal.Desktop
dbus-system none
