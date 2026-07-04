# Firejail profile for gemini-desktop
# Persistent local customizations
include gemini-desktop.local
# Persistent global definitions
include globals.local

noblacklist ${HOME}/.cache/gemini-desktop
noblacklist ${HOME}/.config/gemini-desktop
noblacklist ${HOME}/.config/Gemini Desktop
noblacklist ${HOME}/.local/share/gemini-desktop

mkdir ${HOME}/.cache/gemini-desktop
mkdir ${HOME}/.config/gemini-desktop
mkdir ${HOME}/.config/Gemini Desktop
mkdir ${HOME}/.local/share/gemini-desktop
whitelist ${HOME}/.cache/gemini-desktop
whitelist ${HOME}/.config/gemini-desktop
whitelist ${HOME}/.config/Gemini Desktop
whitelist ${HOME}/.local/share/gemini-desktop

# Redirect
include electron-common.profile

# Allow D-Bus notifications/portal
ignore dbus-user none
dbus-user filter
dbus-user.talk org.freedesktop.Notifications
dbus-user.talk org.freedesktop.portal.Desktop
dbus-user.talk org.freedesktop.portal.OpenURI
dbus-system none
