#!/bin/bash

set -xeuo pipefail

cp -avf "/ctx/system_files"/. /

#nuke kde and sddm
systemctl disable sddm.service
dnf remove -y kde-settings kde-settings-pulseaudio kde-settings-minimal || true
dnf remove -y plasma-workspace plasma-desktop sddm plasma-systemsettings || true
dnf remove -y kwin kwin-wayland kwin-x11 || true
dnf remove -y kde-cli-tools kde-gtk-config || true
dnf remove -y kde-settings* plasma* kwin* kde-cli* kde-gtk* || true

#install niri
dnf -y copr enable yalter/niri-git
dnf -y copr disable yalter/niri-git
echo "priority=1" | tee -a /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:yalter:niri-git.repo
dnf -y --enablerepo copr:copr.fedorainfracloud.org:yalter:niri-git install niri

#install dank linux
dnf -y copr enable avengemedia/danklinux
dnf -y copr disable avengemedia/danklinux
dnf -y --enablerepo copr:copr.fedorainfracloud.org:avengemedia:danklinux install quickshell-git

#install dms
dnf -y copr enable avengemedia/dms-git
dnf -y copr disable avengemedia/dms-git
dnf -y \
    --enablerepo copr:copr.fedorainfracloud.org:avengemedia:dms-git \
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

#will add stuff as I learn

#clean that dnf up
dnf5 clean all
rm -rf /var/cache/dnf/*
