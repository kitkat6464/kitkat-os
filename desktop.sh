#!/bin/bash

set -xeuo pipefail

##########################################
# Step 1 - Package Installs and Removals #
##########################################

#nuke kde, sddm, and xwaylandvideobridge
systemctl disable sddm.service
dnf5 remove -y @kde-desktop
dnf5 remove -y sddm
dnf5 remove -y xwaylandvideobridge
dnf5 -y autoremove

#install niri
dnf5 -y copr enable yalter/niri
dnf5 -y copr disable yalter/niri
echo "priority=1" | tee -a /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:yalter:niri.repo
dnf5 -y --enablerepo copr:copr.fedorainfracloud.org:yalter:niri install niri

#install quickshell
dnf5 -y copr enable errornointernet/quickshell
dnf5 -y copr disable errornointernet/quickshell
dnf5 -y --enablerepo copr:copr.fedorainfracloud.org:errornointernet:quickshell install quickshell

#install dank linux toolkit
dnf5 -y copr enable avengemedia/danklinux
dnf5 -y copr disable avengemedia/danklinux
dnf5 -y --enablerepo copr:copr.fedorainfracloud.org:avengemedia:danklinux install \
    breakpad \
    cliphist \
    danksearch \
    dgop \
    dms-greeter \
    hyprpicker \
    material-symbols-fonts \
    matugen

#install dms
dnf5 -y copr enable avengemedia/dms
dnf5 -y copr disable avengemedia/dms
dnf5 -y --enablerepo copr:copr.fedorainfracloud.org:avengemedia:dms install \
    dms \
    dms-cli \
    dms-greeter

#install greetd
dnf5 -y install \
    greetd \
    tuigreet \
    greetd-selinux \

#install basic utils
dnf5 -y install \
    polkit-kde \
    brightnessctl \
    cava \
    wl-clipboard \
    gammastep \
    sassc \
    libappstream-glib \
    gnome-keyring \
    xwayland-satellite

#install theming stuff
dnf5 -y install \
    adw-gtk3-theme \
    nwg-look \
    qt6-qtmultimedia \
    qt6ct \
    qt5ct

#portals, more xdgs, and dolphin
dnf5 -y install \
    xdg-desktop-portal-gnome \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal-kde \
    xdg-user-dirs \
    dolphin

#########################
# Step 2 - Configure DM #
#########################

#add greetd config
cat > /etc/greetd/config.toml << 'SYNC_EOF'
[general]
service = "greetd-spawn"

[terminal]
vt = 1

[default_session]
command = "dms-greeter --command niri"
user = "greeter"
SYNC_EOF

#add greetd xdg session config
cat > /etc/greetd/greetd-spawn.pam_env.conf << 'SYNC_EOF'
XDG_SESSION_TYPE DEFAULT=wayland OVERRIDE=wayland
SYNC_EOF

#add greetd pam.d config
cat > /etc/pam.d/greetd-spawn << 'SYNC_EOF'
auth       include      greetd
auth       required     pam_env.so conffile=/etc/greetd/greetd-spawn.pam_env.conf
account    include      greetd
session    include      greetd
SYNC_EOF

#use gnome keyring for greetd
sed -i '/gnome_keyring.so/ s/-auth/auth/ ; /gnome_keyring.so/ s/-session/session/' /etc/pam.d/greetd
cat /etc/pam.d/greetd

#fix dms greeter folders
cat > /usr/lib/systemd/system/dms-greeter-folder-create.service << 'SYNC_EOF'
[Unit]
Description=Create necessary folders for dms-greeter
ConditionPathExists=/usr/bin/dms-greeter
ConditionPathExists=!/var/lib/greeter
ConditionPathExists=!/var/cache/dms-greeter
After=local-fs.target

[Service]
Type=oneshot
# Create folders
ExecStart=/usr/bin/install -dm750 /var/cache/dms-greeter
ExecStart=/usr/bin/install -dm755 /var/lib/greeter
# Set proper SELinux contexts
ExecStart=/usr/bin/semanage fcontext -a -t cache_home_t '/var/cache/dms-greeter(/.*)?'
ExecStart=/usr/bin/restorecon -R /var/cache/dms-greeter
ExecStart=/usr/bin/semanage fcontext -a -t user_home_dir_t '/var/lib/greeter(/.*)?'
ExecStart=/usr/bin/restorecon -R /var/lib/greeter
# Set proper ownership
ExecStart=/usr/bin/chown -R greeter:greeter /var/cache/dms-greeter
ExecStart=/usr/bin/chown -R greeter:greeter /var/lib/greeter
# Disable this service now that it's done
ExecStart=/usr/bin/systemctl disable dms-greeter-folder-create.service

[Install]
WantedBy=multi-user.target
SYNC_EOF

#enable greetd systemd stuff
systemctl enable greetd
systemctl enable dms-greeter-folder-create.service

#########################
# Step 3 - Configure TM #
#########################

#configure polkit agent
sed -i "s/After=.*/After=graphical-session.target/" /usr/lib/systemd/user/plasma-polkit-agent.service

#configure portal
tee /usr/share/xdg-desktop-portal/niri-portals.conf <<'EOF'
[preferred]
default=kde;gnome;
org.freedesktop.impl.portal.ScreenCast=gnome;
org.freedesktop.impl.portal.Access=kde;
org.freedesktop.impl.portal.Notification=kde;
org.freedesktop.impl.portal.Secret=gnome-keyring;
EOF

####################################
# Step 4 - Configure SystemD Stuff #
####################################

#configure kos presets
cat > /usr/lib/systemd/user-preset/01-kos.preset << 'SYNC_EOF'
enable dms.service
enable cliphist.service
enable xwayland-satellite.service
enable plasma-polkit-agent.service
SYNC_EOF

#configure dms service
cat > /usr/lib/systemd/user/dms.service << 'SYNC_EOF'
[Unit]
Description=Shell Service
PartOf=graphical-session.target
After=graphical-session.target

[Service]
ExecStart=dms run
Restart=on-failure
RestartSec=1

[Install]
WantedBy=graphical-session.target
SYNC_EOF

#configure cliphist service
cat > /usr/lib/systemd/user/cliphist.service << 'SYNC_EOF'
[Unit]
Description=Clipboard History service
PartOf=graphical-session.target
After=graphical-session.target

[Service]
ExecStart=wl-paste --watch cliphist store
Restart=on-failure
RestartSec=1

[Install]
WantedBy=graphical-session.target
SYNC_EOF

#configure xwayland-satellite service
cat > /usr/lib/systemd/user/xwayland-satellite.service << 'SYNC_EOF'
[Unit]
Description=Xwayland satellite
PartOf=graphical-session.target
After=graphical-session.target

[Service]
ExecStart=xwayland-satellite
Restart=on-failure
RestartSec=1

[Install]
WantedBy=graphical-session.target
SYNC_EOF

#configure niri service
add_wants_niri() {
    sed -i "s/\[Unit\]/\[Unit\]\nWants=$1/" "/usr/lib/systemd/user/niri.service"
}
add_wants_niri cliphist.service
add_wants_niri plasma-polkit-agent.service
add_wants_niri xwayland-satellite.service
cat /usr/lib/systemd/user/niri.service

#enable systemd services
systemctl enable --global dms.service
systemctl enable --global cliphist.service
systemctl enable --global gnome-keyring-daemon.socket
systemctl enable --global gnome-keyring-daemon.service
systemctl enable --global plasma-polkit-agent.service
systemctl enable --global xwayland-satellite.service
