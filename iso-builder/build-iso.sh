#!/usr/bin/env bash

set -e

echo "==================================================================="
echo "🏗️ [IlluminateBR-OS] Compilador de ISO (Base Releng + Chaotic-AUR)"
echo "==================================================================="

BUILD_DIR="$(pwd)"
OUT_DIR="$BUILD_DIR/out"
PROFILE_DIR="$BUILD_DIR/profile"

sudo rm -rf "$PROFILE_DIR"
mkdir -p "$OUT_DIR"

echo "🚀 Rodando compilação em container isolado Arch Linux..."

sudo podman run --rm --privileged \
  --net=host \
  --dns 8.8.8.8 --dns 1.1.1.1 \
  -v "$BUILD_DIR:/build:z" \
  docker.io/library/archlinux:latest \
  /bin/bash -c "
    set -e
    echo 'nameserver 8.8.8.8' > /etc/resolv.conf
    pacman-key --init
    pacman-key --populate archlinux
    pacman -Sy --noconfirm archiso git wget

    # Clonar perfil oficial do Arch Linux (releng)
    cp -r /usr/share/archiso/configs/releng /build/profile

    # Personalizar identificação da ISO
    sed -i 's/iso_name=\"archlinux\"/iso_name=\"IlluminateBR-OS\"/g' /build/profile/profiledef.sh
    sed -i 's/iso_label=\"ARCH_\$(date +%Y%m)\"/iso_label=\"ILLUMINATE_\$(date +%Y%m)\"/g' /build/profile/profiledef.sh

    # 1. Instalar e assinar a chave do Chaotic-AUR no container host
    pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com || true
    pacman-key --lsign-key 3056513887B78AEB || true
    pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' || true
    pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' || true

    # 2. Configurar Chaotic-AUR com URL direta e SigLevel flexível no pacman.conf da ISO
    cat << 'CHAOTIC' >> /build/profile/pacman.conf

[chaotic-aur]
SigLevel = Optional TrustAll
Server = https://cdn-mirror.chaotic.cx/chaotic-aur/\$arch
CHAOTIC

    # Configurar também no pacman.conf do container hospedeiro
    cat << 'CHAOTIC' >> /etc/pacman.conf

[chaotic-aur]
SigLevel = Optional TrustAll
Server = https://cdn-mirror.chaotic.cx/chaotic-aur/\$arch
CHAOTIC

    # 3. Lista de pacotes
    cat << 'PACKAGES' >> /build/profile/packages.x86_64
chaotic-keyring
chaotic-mirrorlist
xorg-server
lightdm
lightdm-slick-greeter
cinnamon
alacritty
nemo
calamares
boost-libs
ckbcomp
hwinfo
qt6-base
qt6-svg
qt6-declarative
kpmcore
PACKAGES

    # Injetar arquivos do Calamares no perfil
    mkdir -p /build/profile/airootfs/usr/share/calamares
    mkdir -p /build/profile/airootfs/etc/calamares
    mkdir -p /build/profile/airootfs/etc/skel/Desktop
    mkdir -p /build/profile/airootfs/etc/skel/IlluminateBR-OS

    [ -d /build/calamares/branding ] && cp -r /build/calamares/branding /build/profile/airootfs/usr/share/calamares/ || true
    [ -d /build/calamares/modules ] && cp -r /build/calamares/modules/* /build/profile/airootfs/etc/calamares/modules/ 2>/dev/null || true
    [ -f /build/calamares/settings.conf ] && cp /build/calamares/settings.conf /build/profile/airootfs/etc/calamares/settings.conf || true

    cp -r /build/../scripts /build/profile/airootfs/etc/skel/IlluminateBR-OS/ 2>/dev/null || true

    cat << 'DESKTOP' > /build/profile/airootfs/etc/skel/Desktop/install-illuminate.desktop
[Desktop Entry]
Type=Application
Version=1.0
Name=Instalar o IlluminateBR-OS
Comment=Inicie o instalador gráfico do sistema
Exec=sudo calamares -d
Icon=system-software-install
Terminal=false
StartupNotify=true
Categories=System;
DESKTOP

    chmod +x /build/profile/airootfs/etc/skel/Desktop/install-illuminate.desktop

    echo '🚀 Compilando a ISO final...'
    mkarchiso -v -w /tmp/archiso-tmp -o /build/out /build/profile
  "

echo "==================================================================="
echo "🎉 ISO GERADA COM SUCESSO EM: $OUT_DIR"
echo "==================================================================="
