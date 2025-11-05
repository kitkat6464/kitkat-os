FROM scratch AS ctx

COPY cleanup /cleanup
COPY ghcurl /ghcurl
COPY dnf5-setopt /dnf5-setopt
COPY dnf5-search /dnf5-search

COPY build.sh /build.sh
COPY system_files /system_files

FROM ghcr.io/zirconium-dev/zirconium:latest@sha256:33baa6fc3068f155d49571b2ce4e35fa3ef640e9bf73b84352228ffdf1e8e4d2

# Setup Copr repos
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    mkdir -p /var/roothome && \
    dnf5 -y install dnf5-plugins && \
    for copr in \
        bazzite-org/bazzite \
        bazzite-org/bazzite-multilib \
        ublue-os/staging \
        ublue-os/packages \
        bazzite-org/obs-vkcapture \
        ycollet/audinux \
        bazzite-org/rom-properties \
        bazzite-org/webapp-manager \
        hhd-dev/hhd \
        lizardbyte/beta \
        che/nerd-fonts; \
    do \
        echo "Enabling copr: $copr"; \
        dnf5 -y copr enable $copr; \
        dnf5 -y config-manager setopt copr:copr.fedorainfracloud.org:${copr////:}.priority=98 ;\
    done && unset -v copr && \
    dnf5 -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release{,-extras} && \
    dnf5 -y config-manager addrepo --overwrite --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo && \
    dnf5 -y install \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm && \
    dnf5 -y config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-steam.repo && \
    dnf5 -y config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-rar.repo && \
    dnf5 -y config-manager addrepo --overwrite --from-repofile=https://negativo17.org/repos/fedora-multimedia.repo && \
    sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/negativo17-fedora-multimedia.repo && \
    dnf5 -y config-manager setopt "*bazzite*".priority=1 && \
    dnf5 -y config-manager setopt "*terra*".priority=3 "*terra*".exclude="nerd-fonts topgrade scx-scheds steam python3-protobuf" && \
    dnf5 -y config-manager setopt "terra-mesa".enabled=true && \
    dnf5 -y config-manager setopt "terra-nvidia".enabled=false && \
    eval "$(/ctx/dnf5-setopt setopt '*negativo17*' priority=4 exclude='mesa-* *xone*')" && \
    dnf5 -y config-manager setopt "*rpmfusion*".priority=5 "*rpmfusion*".exclude="mesa-*" && \
    dnf5 -y config-manager setopt "*fedora*".exclude="mesa-* kernel-core-* kernel-modules-* kernel-uki-virt-*" && \
    dnf5 -y config-manager setopt "*staging*".exclude="scx-scheds kf6-* mesa* mutter*" && \
    /ctx/cleanup

# Install patched fwupd
# Install Valve's patched Mesa, Pipewire, Bluez, and Xwayland
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    declare -A toswap=( \
        ["copr:copr.fedorainfracloud.org:bazzite-org:bazzite"]="wireplumber" \
        ["copr:copr.fedorainfracloud.org:bazzite-org:bazzite-multilib"]="pipewire bluez xorg-x11-server-Xwayland" \
        ["terra-mesa"]="mesa-filesystem" \
        ["copr:copr.fedorainfracloud.org:ublue-os:staging"]="fwupd" \
    ) && \
    for repo in "${!toswap[@]}"; do \
        for package in ${toswap[$repo]}; do dnf5 -y swap --repo=$repo $package $package; done; \
    done && unset -v toswap repo package && \
    dnf5 versionlock add \
        pipewire \
        pipewire-alsa \
        pipewire-gstreamer \
        pipewire-jack-audio-connection-kit \
        pipewire-jack-audio-connection-kit-libs \
        pipewire-libs \
        pipewire-plugin-libcamera \
        pipewire-pulseaudio \
        pipewire-utils \
        wireplumber \
        wireplumber-libs \
        bluez \
        bluez-cups \
        bluez-libs \
        bluez-obexd \
        xorg-x11-server-Xwayland \
        mesa-dri-drivers \
        mesa-filesystem \
        mesa-libEGL \
        mesa-libGL \
        mesa-libgbm \
        mesa-va-drivers \
        mesa-vulkan-drivers \
        fwupd \
        fwupd-plugin-flashrom \
        fwupd-plugin-modem-manager \
        fwupd-plugin-uefi-capsule-data && \
    dnf5 -y install \
        mesa-va-drivers.i686 \
        libfreeaptx && \
    dnf5 -y install --enable-repo="*rpmfusion*" --disable-repo="*fedora-multimedia*" \
        libaacs \
        libbdplus \
        libbluray \
        libbluray-utils && \
    /ctx/cleanup

# Install new packages
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    --mount=type=secret,id=GITHUB_TOKEN \
    dnf5 -y install \
        $(/ctx/ghcurl https://api.github.com/repos/bazzite-org/cicpoffs/releases/latest | jq -r '.assets[] | select(.name| test(".*rpm$")).browser_download_url') && \
    dnf5 -y install \
        bazaar \
        iwd \
        twitter-twemoji-fonts \
        google-noto-sans-cjk-fonts \
        lato-fonts \
        fira-code-fonts \
        nerd-fonts \
        Sunshine \
        python3-pip \
        libadwaita \
        duperemove \
        cpulimit \
        sqlite \
        xwininfo \
        xrandr \
        compsize \
        ryzenadj \
        ddcutil \
        input-remapper \
        libinput-utils \
        i2c-tools \
        lm_sensors \
        fw-ectool \
        fw-fanctrl \
        udica \
        ladspa-caps-plugins \
        ladspa-noise-suppression-for-voice \
        pipewire-module-filter-chain-sofa \
        python3-icoextract \
        tailscale \
        webapp-manager \
        btop \
        duf \
        fish \
        lshw \
        xdotool \
        wmctrl \
        libcec \
        yad \
        f3 \
        pulseaudio-utils \
        lzip \
        p7zip \
        p7zip-plugins \
        rar \
        libxcrypt-compat \
        vulkan-tools \
        xwiimote-ng \
        fastfetch \
        glow \
        gum \
        vim \
        cockpit-networkmanager \
        cockpit-podman \
        cockpit-selinux \
        cockpit-system \
        cockpit-files \
        cockpit-storaged \
        topgrade \
        ydotool \
        stress-ng \
        snapper \
        btrfs-assistant \
        edk2-ovmf \
        qemu \
        libvirt \
        lsb_release \
        uupd \
        ds-inhibit \
        rocm-hip \
        rocm-opencl \
        rocm-clinfo \
        waydroid \
        cage \
        wlr-randr && \
    systemctl mask iscsi && \
    mkdir -p /usr/lib/extest/ && \
    /ctx/ghcurl "$(/ctx/ghcurl https://api.github.com/repos/bazzite-org/extest/releases/latest | jq -r '.assets[] | select(.name| test(".*so$")).browser_download_url')" -Lo /usr/lib/extest/libextest.so && \
    /ctx/ghcurl "$(/ctx/ghcurl https://api.github.com/repos/FrameworkComputer/framework-system/releases/latest | jq -r '.assets[] | select(.name == "framework_tool").browser_download_url')" -Lo /usr/bin/framework_tool && \
    chmod +x /usr/bin/framework_tool && \
    /ctx/ghcurl "$(/ctx/ghcurl https://api.github.com/repos/HikariKnight/ls-iommu/releases/latest | jq -r '.assets[] | select(.name| test(".*x86_64.tar.gz$")).browser_download_url')" -Lo /tmp/ls-iommu.tar.gz && \
    mkdir -p /tmp/ls-iommu && \
    sed -i 's|uupd|& --disable-module-distrobox|' /usr/lib/systemd/system/uupd.service && \
    setcap 'cap_sys_admin+p' $(readlink -f /usr/bin/sunshine) && \
    dnf5 -y --setopt=install_weak_deps=False install \
        rocm-hip \
        rocm-opencl \
        rocm-clinfo \
        rocm-smi && \
    mkdir -p /etc/xdg/autostart && \
    sed -i~ -E 's/=.\$\(command -v (nft|ip6?tables-legacy).*/=/g' /usr/lib/waydroid/data/scripts/waydroid-net.sh && \
    sed -i 's/ --xdg-runtime=\\"${XDG_RUNTIME_DIR}\\"//g' /usr/bin/btrfs-assistant-launcher && \
    /ctx/ghcurl "https://raw.githubusercontent.com/bazzite-org/steam-proton-mf-wmv/master/installcab.py" -Lo /usr/bin/installcab && \
    chmod +x /usr/bin/installcab && \
    /ctx/ghcurl "https://raw.githubusercontent.com/bazzite-org/steam-proton-mf-wmv/refs/heads/master/install-mf-wmv.sh" -Lo /usr/bin/install-mf-wmv && \
    chmod +x /usr/bin/install-mf-wmv && \
    tar --no-same-owner --no-same-permissions --no-overwrite-dir -xvzf /tmp/ls-iommu.tar.gz -C /tmp/ls-iommu && \
    rm -f /tmp/ls-iommu.tar.gz && \
    cp -r /tmp/ls-iommu/ls-iommu /usr/bin/ && \
    /ctx/ghcurl "https://github.com/HikariKnight/ScopeBuddy/archive/refs/tags/$(/ctx/ghcurl https://api.github.com/repos/HikariKnight/scopebuddy/releases/latest | jq -r '.tag_name').tar.gz" -Lo /tmp/scopebuddy.tar.gz && \
    mkdir -p /tmp/scopebuddy && \
    tar --no-same-owner --no-same-permissions --no-overwrite-dir -xvzf /tmp/scopebuddy.tar.gz -C /tmp/scopebuddy && \
    rm -f /tmp/scopebuddy.tar.gz && \
    cp -r /tmp/scopebuddy/ScopeBuddy-*/bin/* /usr/bin/ && \
    /ctx/cleanup

# Install Steam & Lutris, plus supporting packages
# Downgrade ibus to fix an issue with the Steam keyboard
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    --mount=type=secret,id=GITHUB_TOKEN \
    dnf5 versionlock add \
        ibus && \
    dnf5 -y install \
        gamescope.x86_64 \
        gamescope-libs.x86_64 \
        gamescope-libs.i686 \
        gamescope-shaders \
        jupiter-sd-mounting-btrfs \
        umu-launcher \
        dbus-x11 \
        xdg-user-dirs \
        gobject-introspection \
        libFAudio.x86_64 \
        libFAudio.i686 \
        vkBasalt.x86_64 \
        vkBasalt.i686 \
        mangohud.x86_64 \
        mangohud.i686 \
        libobs_vkcapture.x86_64 \
        libobs_glcapture.x86_64 \
        libobs_vkcapture.i686 \
        libobs_glcapture.i686 \
        VK_hdr_layer && \
    dnf5 -y --setopt=install_weak_deps=False install \
        steam \
        lutris && \
    dnf5 -y remove \
        gamemode && \
    /ctx/ghcurl "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks" -Lo /usr/bin/winetricks && \
    chmod +x /usr/bin/winetricks && \
    /ctx/cleanup

# Install Addtional Apps
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
dnf5 -y install \
    dolphin \
    ptyxis \
    hyfetch \
    xdg-desktop-portal-kde && \
dnf5 -y copr enable atim/starship && \
dnf5 -y install \
    starship && \
    /ctx/cleanup

# Nuke Apps
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
dnf5 -y remove \
    nautilus \
    ghostty && \
    /ctx/cleanup

# Run build.sh for things I need to move over to here
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

RUN ls -lah /usr/lib/modules

RUN bootc container lint
