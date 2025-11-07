#!/bin/bash

set -xeuo pipefail

cp -avf "/ctx/system_files"/. /

install -d /usr/share/kitkat/

#nuke kde, sddm and xwaylandvideobridge
systemctl disable sddm.service
dnf remove -y kde-settings kde-settings-pulseaudio kde-settings-minimal || true
dnf remove -y plasma-workspace plasma-desktop sddm plasma-systemsettings || true
dnf remove -y kwin kwin-wayland kwin-x11 || true
dnf remove -y kde-cli-tools kde-gtk-config || true
dnf remove -y kde-settings* plasma* kwin* kde-cli* kde-gtk* || true
dnf remove -y xwaylandvideobridge || true

#install niri
dnf -y copr enable yalter/niri
dnf -y copr disable yalter/niri
echo "priority=1" | tee -a /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:yalter:niri.repo
dnf -y --enablerepo copr:copr.fedorainfracloud.org:yalter:niri install niri

#install dank linux
dnf -y copr enable avengemedia/danklinux
dnf -y copr disable avengemedia/danklinux
dnf -y --enablerepo copr:copr.fedorainfracloud.org:avengemedia:danklinux install quickshell

#install dms
dnf -y copr enable avengemedia/dms
dnf -y copr disable avengemedia/dms
dnf -y \
    --enablerepo copr:copr.fedorainfracloud.org:avengemedia:dms \
    --enablerepo copr:copr.fedorainfracloud.org:avengemedia:danklinux \
    install --setopt=install_weak_deps=False \
    dms \
    dms-cli \
    dms-greeter \
    dgop

#install matugen/cliphist
dnf -y copr enable zirconium/packages
dnf -y copr disable zirconium/packages
dnf -y --enablerepo copr:copr.fedorainfracloud.org:zirconium:packages install \
    matugen \
    cliphist

#install greetd
dnf -y install \
    greetd \
    greetd-selinux \

sed -i '/gnome_keyring.so/ s/-auth/auth/ ; /gnome_keyring.so/ s/-session/session/' /etc/pam.d/greetd
cat /etc/pam.d/greetd

systemctl enable greetd
systemctl enable dms-greeter-folder-create.service

#install packages. we run and remove any on this list if its preinstalled.
dnf -y install \
    brightnessctl \
    cava \
    chezmoi \
    ddcutil \
    fastfetch \
    flatpak \
    fpaste \
    fzf \
    git-core \
    glycin-thumbnailer \
    gnome-keyring \
    greetd \
    greetd-selinux \
    input-remapper \
    just \
    dolphin \
    orca \
    pipewire \
    steam-devices \
    tuigreet \
    udiskie \
    webp-pixbuf-loader \
    wireplumber \
    wl-clipboard \
    wlsunset \
    xdg-desktop-portal-gnome \
    xdg-desktop-portal-kde \
    xdg-user-dirs \
    xwayland-satellite

dnf install -y --setopt=install_weak_deps=False \
    kf6-kirigami \
    qt6ct \
    polkit-kde \
    plasma-breeze \
    kf6-qqc2-desktop-style

#session target thing
sed -i "s/After=.*/After=graphical-session.target/" /usr/lib/systemd/user/plasma-polkit-agent.service

#kde dialogs
tee /usr/share/xdg-desktop-portal/niri-portals.conf <<'EOF'
[preferred]
default=kde;gnome;
org.freedesktop.impl.portal.ScreenCast=gnome;
org.freedesktop.impl.portal.Access=kde;
org.freedesktop.impl.portal.Notification=kde;
org.freedesktop.impl.portal.Secret=gnome-keyring;
EOF

#add systemd stuff
add_wants_niri() {
    sed -i "s/\[Unit\]/\[Unit\]\nWants=$1/" "/usr/lib/systemd/user/niri.service"
}
add_wants_niri cliphist.service
add_wants_niri plasma-polkit-agent.service
add_wants_niri udiskie.service
add_wants_niri xwayland-satellite.service
cat /usr/lib/systemd/user/niri.service

cp -avf "/ctx/files"/. /

systemctl enable --global chezmoi-init.service
systemctl enable --global chezmoi-update.timer
systemctl enable --global dms.service
systemctl enable --global cliphist.service
systemctl enable --global gnome-keyring-daemon.socket
systemctl enable --global gnome-keyring-daemon.service
systemctl enable --global plasma-polkit-agent.service
systemctl enable --global udiskie.service
systemctl enable --global xwayland-satellite.service
systemctl preset --global chezmoi-init
systemctl preset --global chezmoi-update
systemctl preset --global cliphist
systemctl preset --global plasma-polkit-agent
systemctl preset --global udiskie
systemctl preset --global xwayland-satellite

#fonts
dnf install -y \
    default-fonts-core-emoji \
    google-noto-color-emoji-fonts \
    google-noto-emoji-fonts \
    glibc-all-langpacks \
    default-fonts

mkdir -p "/usr/share/fonts/Maple Mono"

MAPLE_TMPDIR="$(mktemp -d)"
trap 'rm -rf "${MAPLE_TMPDIR}"' EXIT

LATEST_RELEASE_FONT="$(curl "https://api.github.com/repos/subframe7536/maple-font/releases/latest" | jq '.assets[] | select(.name == "MapleMono-Variable.zip") | .browser_download_url' -rc)"
curl -fSsLo "${MAPLE_TMPDIR}/maple.zip" "${LATEST_RELEASE_FONT}"
unzip "${MAPLE_TMPDIR}/maple.zip" -d "/usr/share/fonts/Maple Mono"

#borrowing a rice for now
git clone "https://github.com/zirconium-dev/zdots.git" /usr/share/kitkat/zdots
install -d /etc/niri/
cp -f /usr/share/kitkat/zdots/dot_config/niri/config.kdl /etc/niri/config.kdl
file /etc/niri/config.kdl | grep -F -e "empty" -v
stat /etc/niri/config.kdl

#will add stuff as I learn

#clean that dnf up
dnf5 clean all
rm -rf /var/cache/dnf/*
