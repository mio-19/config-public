# Firejail profile for gemini-desktop
# Persistent local customizations
include gemini-desktop.local
# Persistent global definitions
include globals.local

# Must come before include electron-common.profile (sets dbus-user none / netfilter).
ignore noinput
ignore dbus-user none
ignore dbus-system none
ignore netfilter

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

private-etc @tls-ca
private-bin bash,cut,echo,egrep,electron,electron[0-9],electron[0-9][0-9],gemini-desktop,grep,head,sed,sh,tr,xdg-mime,xdg-open,zsh

include electron-common.profile

dbus-user filter
dbus-user.talk org.freedesktop.Notifications
dbus-user.talk org.freedesktop.portal.Desktop
dbus-user.talk org.freedesktop.portal.OpenURI
dbus-system none
