#!/usr/bin/env bash
set -e

echo "==================================================================="
echo "🏗️ [IlluminateBR-OS] Compilador de ISO (Base Debian Live)"
echo "==================================================================="

echo "🧹 Limpando compilações anteriores..."
lb clean --purge || true

# Remove arquivos de repositório manuais antigos para evitar avisos de duplicidade
rm -rf config/archives/*

echo "⚙️ Configurando o live-build para Debian..."
# A flag --contents false desativa a tentativa de baixar Contents-amd64.gz
lb config \
    --debian-installer false \
    --mode debian \
    --architectures amd64 \
    --distribution bookworm \
    --archive-areas "main contrib non-free non-free-firmware" \
    --mirror-bootstrap "http://deb.debian.org/debian/" \
    --mirror-chroot "http://deb.debian.org/debian/" \
    --mirror-binary "http://deb.debian.org/debian/" \
    --security false \
    --contents false \
    --bootloader syslinux \
    --win32-loader false

# Adiciona repositório de segurança correto do Bookworm sem duplicar o principal
mkdir -p config/archives/
cat << 'EOF' > config/archives/security.list.chroot
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
EOF

cat << 'EOF' > config/archives/security.list.binary
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
EOF

mkdir -p config/package-lists/
cat << 'EOF' > config/package-lists/illuminate.list.chroot
linux-image-amd64
live-boot
systemd-sysv
firmware-linux
firmware-linux-nonfree
cinnamon-core
lightdm
lightdm-gtk-greeter
alacritty
nemo
calamares
calamares-settings-debian
sudo
network-manager
network-manager-gnome
gparted
dosfstools
e2fsprogs
mtools
squashfs-tools
wget
curl
git
zsh
EOF

# Configuração de Auto-Login no LightDM
mkdir -p config/includes.chroot/etc/lightdm/lightdm.conf.d/
cat << 'EOF' > config/includes.chroot/etc/lightdm/lightdm.conf.d/80-live-autologin.conf
[Seat:*]
autologin-guest=false
autologin-user=user
autologin-user-timeout=0
EOF

# Override da variável interna do live-build para garantir que ele ignore a busca de Contents
export LB_CONTENTS="false"

echo "📦 Iniciando compilação da ISO..."
lb build

echo "==================================================================="
echo "🎉 ISO GERADA COM SUCESSO!"
echo "==================================================================="
