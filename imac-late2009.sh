#!/bin/sh

USER_NAME_LOGIN="keinos"
USER_NAME_FULL="KEINOS"
USER_SSH_KEY_URL="https://github.com/KEINOS.keys"

# ---------------------------------------------------------------
#  Set repository mirror to the closest
# ---------------------------------------------------------------
# Detect and add fastest mirror and enable the community repo
setup-apkrepos -f -c
repo_testing="$(cat /etc/apk/repositories | grep edge/community | sed -e "s/community/testing/")"
echo $repo_testing >> /etc/apk/repositories

# ---------------------------------------------------------------
#   update/upgrade apk
# ---------------------------------------------------------------
apk update
apk upgrade

# ---------------------------------------------------------------
#  Basic Admin tools
# ---------------------------------------------------------------
apk add neofetch vim doas ripgrep

# ---------------------------------------------------------------
#  Hardware config
# ---------------------------------------------------------------
# Install PCI bus configuration space accessing tool library and
# message bus system tool
apk add pciutils dbus

rc-update add dbus default
service dbus start

rc-update add hwdrivers sysinit
service hwdrivers start

rc-update add mdev sysinit
service mdev start

# ---------------------------------------------------------------
#  Set Locale and Lang
# ---------------------------------------------------------------
apk add tzdata musl-locales
# Install tzdata and simlink to /etc/localtime
setup-timezone -i Asia/Tokyo
echo "Asia/Tokyo" >  /etc/timezone

echo 'export TZ="Asia/Tokyo"' >> /etc/profile
echo 'export LANG="ja_JP.UTF-8"' >> /etc/profile
echo 'export LANGUAGE="ja_JP.UTF-8"' >> /etc/profile
echo 'export LC_ALL="ja_JP.UTF-8"' >> /etc/profile

# ---------------------------------------------------------------
#  Set Keyboard Layout
# ---------------------------------------------------------------
apk add setxkbmap
setxkbmap jp

# ---------------------------------------------------------------
#  Install Input Method (ibus + anthy)
# ---------------------------------------------------------------
#  We use anthy due to using iBus rather than Qt. (Mozc des not
#  support iBus)
apk add \
    ibus ibus-lang \
    ibus-anthy ibus-anthy-lang \
    ibus-emoji

echo 'export GTK_IM_MODULE=ibus' >> /etc/profile
echo 'export XMODIFIERS=@im=ibus' >> /etc/profile
echo 'export QT_IM_MODUEL=ibus' >> /etc/profile

#echo 'ibus-daemon --config=/usr/lib/ibus/ibus-dconf -r -d -x &' >> /etc/profile
mkdir -p /etc/xdg/autostart
cat << 'HEREDOC' > /etc/xdg/autostart/iBus.desktop
[Desktop Entry]
Encoding=UTF-8
Version=0.9.4
Type=Application
Name=iBus
Comment=Start iBus daemon for Japanese input method (anthy)
Comment[ja]=IME/FEPの自動起動(ibus+anthy)
Exec=ibus-daemon --config=/usr/lib/ibus/ibus-dconf -r -d -x &
OnlyShowIn=XFCE;
RunHook=0
StartupNotify=false
Terminal=false
Hidden=false
HEREDOC

# ---------------------------------------------------------------
#  Install CJK Fonts
# ---------------------------------------------------------------
# Install No-TOFU(noto) fonts for Japanese environments.
# icu-data-full is need for ICU with non-English locales and legacy
# charset support.
apk add \
    fontconfig \
    icu-data-full \
    font-noto font-noto-extra \
    font-noto-cjk font-noto-cjk-extra \
    font-noto-emoji

# Update and check font detection
fc-cache -fv

# ---------------------------------------------------------------
#  Install Chromium and Firefox for GUI dependencies
# ---------------------------------------------------------------
apk add chromium firefox

# ---------------------------------------------------------------
#  Setup Default User (no root privilege)
# ---------------------------------------------------------------
# Create user
setup-user -u -f "$USER_NAME_LOGIN" -k "$USER_SSH_KEY_URL" "$USER_NAME_LOGIN"

# Copy iBus daemon
mkdir -p "/home/${USER_NAME_LOGIN}/.config/autostart"
chown ${USER_NAME_LOGIN}:${USER_NAME_LOGIN} "/home/${USER_NAME_LOGIN}/.config"
chown ${USER_NAME_LOGIN}:${USER_NAME_LOGIN} "/home/${USER_NAME_LOGIN}/.config/autostart"

cp "/etc/xdg/autostart/iBus.desktop" "/home/${USER_NAME_LOGIN}/.config/autostart/iBus.desktop"
chown ${USER_NAME_LOGIN}:${USER_NAME_LOGIN} "/home/${USER_NAME_LOGIN}/.config/autostart/iBus.desktop"

# ---------------------------------------------------------------
#  Setup Desktop (xfce4)
# ---------------------------------------------------------------
# The setup script installs the below by default
#   libxfce4panel
#   libxfce4ui
#   libxfce4util
#   xfce4
#   xfce4-appfinder
#   xfce4-panel
#   xfce4-power-manager
#   xfce4-session
#   xfce4-settings
#   xfce4-terminal
#   lightdm
#   lightdm-gtk-greeter
#   lightdm-openrc
#   thunar
#   thunar-volman
setup-desktop xfce

# Install language packs for the above packages
apk add \
    libxfce4ui-lang \
    libxfce4util-lang \
    xfce4-appfinder-lang \
    xfce4-panel-lang \
    xfce4-power-manager-lang \
    xfce4-session-lang \
    xfce4-settings-lang \
    xfce4-terminal-lang \
    lightdm-lang \
    lightdm-gtk-greeter-lang \
    thunar-lang \
    thunar-volman-lang

# Additional xfce4 packages
apk add \
    xfce4-screensaver xfce4-screensaver-lang \
    xfce4-pulseaudio-plugin xfce4-pulseaudio-plugin-lang \
    xfce4-xkb-plugin xfce4-xkb-plugin-lang \
    lightdm-settings lightdm-settings-lang

# ---------------------------------------------------------------
#  Reboot
# ---------------------------------------------------------------
reboot