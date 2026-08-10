#!/usr/bin/env bash

set -e

# =============================================================================
# 🚀 ILLUMINATEBR-OS - INSTALADOR UNIFICADO COM LOGS EM TEMPO REAL
# =============================================================================

PROFILE="${1:-devops}"
DISC="${2:-/dev/sda}"

log_step() {
    local percent="$1"
    local message="$2"
    echo "[PROGRESS:$percent]"
    echo "[STEP:$message]"
    echo "==================================================================="
    echo "🚀 $message"
    echo "==================================================================="
}

# -----------------------------------------------------------------------------
# ETAPA A: SE ESTIVER NO AMBIENTE LIVE (ARCHISO), INSTALAR O SO NO DISCO
# -----------------------------------------------------------------------------
if [ -f /run/archiso/bootmnt ] || [ "$HOSTNAME" = "archiso" ] || [ "$USER" = "root" ] && [ ! -f /etc/illuminate-installed ]; then
    log_step "5" "Ambiente Live ISO Detectado! Preparando Disco $DISC..."
    
    if [ ! -b "$DISC" ]; then
        echo "❌ Erro: O disco $DISC não foi encontrado! Verifique o caminho no QEMU."
        exit 1
    fi

    log_step "10" "Formatando e Particionando o Disco $DISC..."
    parted -s "$DISC" mklabel gpt
    parted -s "$DISC" mkpart ESP fat32 1MiB 512MiB
    parted -s "$DISC" set 1 esp on
    parted -s "$DISC" mkpart primary ext4 512MiB 100%

    PART_EFI="${DISC}1"
    PART_ROOT="${DISC}2"
    if [[ "$DISC" == *"nvme"* ]]; then
        PART_EFI="${DISC}p1"
        PART_ROOT="${DISC}p2"
    fi

    mkfs.fat -F32 "$PART_EFI"
    mkfs.ext4 -F "$PART_ROOT"

    log_step "18" "Montando Partiçoes e Preparando Diretorios..."
    mount "$PART_ROOT" /mnt
    mkdir -p /mnt/boot
    mount "$PART_EFI" /mnt/boot

    log_step "25" "Instalando Base do Arch Linux (Pacstrap)..."
    pacman-key --init || true
    pacman-key --populate archlinux || true
    pacstrap -K /mnt base linux linux-firmware base-devel git sudo bash networkmanager grub efibootmgr

    genfstab -U /mnt >> /mnt/etc/fstab
    touch /mnt/etc/illuminate-installed

    log_step "40" "Configurando Usuario 'illuminate' e GRUB Bootloader..."
    arch-chroot /mnt /bin/bash -c "
        echo 'illuminateos' > /etc/hostname
        systemctl enable NetworkManager

        ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
        hwclock --systohc

        useradd -m -G wheel,kvm,libvirt -s /bin/bash illuminate || true
        echo 'illuminate:123456' | chpasswd
        echo 'root:123456' | chpasswd
        echo '%wheel ALL=(ALL:ALL) ALL' >> /etc/sudoers

        grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=IlluminateBR-OS
        grub-mkconfig -o /boot/grub/grub.cfg
    "

    mkdir -p /mnt/home/illuminate/IlluminateBR-OS/scripts
    cp "$0" /mnt/home/illuminate/IlluminateBR-OS/scripts/install.sh
    chown -R illuminate:illuminate /mnt/home/illuminate/IlluminateBR-OS

    log_step "50" "Iniciando Instalacao dos Pacotes do Perfil ($PROFILE)..."
    arch-chroot /mnt /bin/bash -c "
        cd /home/illuminate/IlluminateBR-OS/scripts
        su illuminate -c 'bash install.sh $PROFILE system-post'
    "

    log_step "100" "IlluminateBR-OS Instalado com Sucesso no Disco!"
    exit 0
fi

# -----------------------------------------------------------------------------
# ETAPA B: PÓS-INSTALAÇÃO DO AMBIENTE (EXECUTADO DENTRO DO HD)
# -----------------------------------------------------------------------------

REAL_USER="$USER"
REAL_HOME="$HOME"

log_step "55" "Atualizando Repositorios e Chaves do Sistema..."
sudo pacman-key --init || true
sudo pacman-key --populate archlinux || true
sudo pacman -Sy --noconfirm archlinux-keyring || true

sudo pacman -Syu --needed --noconfirm \
    base-devel git curl wget gcc make cmake ninja clang pkg-config \
    fastfetch htop btop tmux neovim zsh util-linux cabextract fontconfig \
    bat ripgrep fd zoxide eza flameshot copyq \
    unzip zip tar xz fuse2 fuse3 flatpak pipewire-jack qt6-multimedia-ffmpeg || true

flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true

log_step "65" "Configurando Otimizacoes e KVM Virtualizacao..."
sudo pacman -S --needed --noconfirm auto-cpufreq zram-generator qemu-full virt-manager virt-viewer dnsmasq vde2 bridge-utils iptables-nft libguestfs || true
sudo systemctl enable auto-cpufreq || true
sudo systemctl enable libvirtd || true

log_step "72" "Instalando Java 21, Node.js e Flutter SDK..."
sudo pacman -S --needed --noconfirm jdk21-openjdk openjdk21-doc openjdk21-src nodejs npm yarn bun-bin gtk3 postgresql mariadb-clients sqlite || true
sudo npm install -g @angular/cli typescript tailwindcss live-server lighthouse || true

mkdir -p "$REAL_HOME/development"
if [ ! -d "$REAL_HOME/development/flutter" ]; then
    git clone https://github.com/flutter/flutter.git -b stable "$REAL_HOME/development/flutter" || true
fi

log_step "80" "Configurando Ferramentas DevOps e Containers..."
if [ "$PROFILE" = "devops" ] || [ "$PROFILE" = "full" ]; then
    sudo pacman -S --needed --noconfirm \
        docker containerd docker-buildx docker-compose podman \
        kubectl helm terraform ansible aws-cli nmap wireshark-qt wireguard-tools || true

    sudo systemctl enable docker || true
    sudo usermod -aG docker "$REAL_USER" || true
fi

log_step "88" "Compilando Helper AUR (paru) e Instalando Apps..."
if ! command -v paru &> /dev/null; then
    rm -rf /tmp/paru
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    (cd /tmp/paru && makepkg -si --noconfirm) || true
    rm -rf /tmp/paru
fi

sudo pacman -S --needed --noconfirm thunderbird libreoffice-fresh libreoffice-fresh-pt-br ttf-jetbrains-mono ttf-fira-code || true
if command -v paru &> /dev/null; then
    paru -S --needed --noconfirm ttf-ms-fonts google-chrome visual-studio-code-bin || true
fi

log_step "94" "Instalando Cursor IDE e Pacotes Flatpak..."
mkdir -p "$REAL_HOME/.local/bin" "$REAL_HOME/.local/share/applications"
curl -L "https://downloader.cursor.sh/linux/appImage/x64" -o "$REAL_HOME/.local/bin/cursor.AppImage" || true
chmod +x "$REAL_HOME/.local/bin/cursor.AppImage" || true

flatpak install -y flathub com.google.AndroidStudio io.dbeaver.DBeaverCommunity usebruno.Bruno || true

log_step "98" "Configurando Interface Grafica Cinnamon e Display Manager..."
sudo pacman -S --needed --noconfirm cinnamon lightdm-slick-greeter starship || true
sudo systemctl enable lightdm || true

log_step "100" "Ambiente Concluido com Sucesso!"
