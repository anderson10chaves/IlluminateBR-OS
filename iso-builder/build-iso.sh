#!/usr/bin/env bash
set -e

echo "==================================================================="
echo "🏗️ [IlluminateBR-OS] Compilador da ISO Bootável (Base Ubuntu 24.04 LTS)"
echo "==================================================================="

WORK_DIR="$(pwd)/build_dir"
CHROOT_DIR="$WORK_DIR/chroot"
IMAGE_DIR="$WORK_DIR/image"

echo "🧹 Limpando compilações anteriores..."
sudo rm -rf "$WORK_DIR" IlluminateBR-OS-*.iso || true
mkdir -p "$CHROOT_DIR" "$IMAGE_DIR/live" "$IMAGE_DIR/boot/grub" "$IMAGE_DIR/EFI/BOOT"

echo "🛠️ Instalando ferramentas no Host..."
sudo apt-get update -y
sudo apt-get install -y debootstrap mtools xorriso grub-pc-bin grub-efi-amd64-bin squashfs-tools

echo "📦 1. Criando sistema base (Debootstrap Ubuntu 24.04 Noble)..."
sudo debootstrap --arch=amd64 noble "$CHROOT_DIR" http://archive.ubuntu.com/ubuntu/

echo "⚙️ 2. Configurando o Chroot e instalando pacotes do sistema..."
sudo mount --bind /dev "$CHROOT_DIR/dev"
sudo mount --bind /proc "$CHROOT_DIR/proc"
sudo mount --bind /sys "$CHROOT_DIR/sys"

# Copia o Instalador Flutter se ele existir
if [ -d "installer-bin" ]; then
    echo "🚚 Injetando o Instalador Flutter no Chroot..."
    sudo mkdir -p "$CHROOT_DIR/usr/bin/installer"
    sudo cp -r installer-bin/* "$CHROOT_DIR/usr/bin/installer/"
    sudo chmod +x "$CHROOT_DIR/usr/bin/installer/illuminatebr_os" 2>/dev/null || true
fi

cat << 'EOF' | sudo chroot "$CHROOT_DIR" /bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

# Repositórios Ubuntu
cat << 'REPOS' > /etc/apt/sources.list
deb http://archive.ubuntu.com/ubuntu/ noble main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-updates main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu noble-security main restricted universe multiverse
REPOS

apt-get update -y
apt-get install -y --no-install-recommends \
    linux-image-generic \
    live-boot \
    systemd-sysv \
    network-manager \
    cinnamon-core \
    lightdm \
    lightdm-gtk-greeter \
    alacritty \
    nemo \
    calamares \
    sudo \
    wget \
    curl \
    git \
    zsh \
    gparted \
    dosfstools \
    e2fsprogs

# Configuração do Usuário Live com Auto-Login sem Senha
groupadd -r nopasswdlogin || true
useradd -m -s /bin/bash user || true
echo "user:live" | chpasswd
passwd -d user || true
usermod -aG sudo,video,audio,cdrom,nopasswdlogin user

# Auto-login no LightDM
mkdir -p /etc/lightdm/lightdm.conf.d/
cat << 'LIGHTDM' > /etc/lightdm/lightdm.conf.d/80-live-autologin.conf
[Seat:*]
autologin-guest=false
autologin-user=user
autologin-user-timeout=0
autologin-nopasswd=true
LIGHTDM

apt-get clean
rm -rf /tmp/* /var/lib/apt/lists/*
EOF

echo "🚚 Copiando Kernel e Initrd para a estrutura da ISO..."
sudo cp "$CHROOT_DIR"/boot/vmlinuz-* "$IMAGE_DIR/live/vmlinuz"
sudo cp "$CHROOT_DIR"/boot/initrd.img-* "$IMAGE_DIR/live/initrd"

echo "🧹 Desmontando sistemas de arquivos do Chroot..."
sudo umount -l "$CHROOT_DIR/dev" || true
sudo umount -l "$CHROOT_DIR/proc" || true
sudo umount -l "$CHROOT_DIR/sys" || true

echo "📦 3. Criando o sistema de arquivos comprimido (SquashFS)..."
sudo mksquashfs "$CHROOT_DIR" "$IMAGE_DIR/live/filesystem.squashfs" -e boot

echo "⚙️ 4. Configurando Bootloader GRUB com TODOS os modos de Boot..."
cat << 'EOF' | sudo tee "$IMAGE_DIR/boot/grub/grub.cfg"
set default=0
set timeout=10

insmod all_video
insmod gfxterm
set gfxmode=auto
terminal_output gfxterm

menuentry "🚀 IlluminateBR-OS Live (Cinnamon Desktop)" {
    linux /live/vmlinuz boot=live quiet splash ---
    initrd /live/initrd
}

menuentry "🛡️ IlluminateBR-OS Live (Safe Graphics / Modo de Segurança)" {
    linux /live/vmlinuz boot=live nomodeset quiet splash ---
    initrd /live/initrd
}

menuentry "💻 IlluminateBR-OS (Iniciar Direto no Instalador)" {
    linux /live/vmlinuz boot=live quiet splash systemd.unit=multi-user.target ---
    initrd /live/initrd
}

menuentry "🖥️ IlluminateBR-OS (Modo Terminal / CLI Only)" {
    linux /live/vmlinuz boot=live systemd.unit=multi-user.target ---
    initrd /live/initrd
}

menuentry "🔄 Reiniciar Sistema" {
    reboot
}

menuentry "⚡ Desligar Computador" {
    halt
}
EOF

echo "💿 5. Gerando a imagem ISO final com xorriso (Boot Dual Híbrido)..."
sudo grub-mkrescue -o IlluminateBR-OS-v1.0.0-x86_64.iso "$IMAGE_DIR" -- -volid "ILLUMINATE_OS"

echo "==================================================================="
echo "🎉 ISO GERADA COM SUCESSO! MODOS LIVE, SAFE, INSTALLER E CLI DISPONÍVEIS!"
echo "==================================================================="
