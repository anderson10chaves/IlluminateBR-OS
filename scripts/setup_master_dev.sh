#!/usr/bin/env bash

set -e

# =============================================================================
# 🚀 ILLUMINATEBR-OS - INSTALADOR UNIFICADO (SO + PACOTES + AMBIENTE)
# =============================================================================

PROFILE="${1:-devops}"
DISC="${2:-/dev/sda}"

echo "==================================================================="
echo "🚀 [IlluminateBR-OS] Iniciando Instalador do Sistema e Ambiente"
echo "📦 Perfil Selecionado: $PROFILE"
echo "💾 Disco Alvo: $DISC"
echo "==================================================================="

# -----------------------------------------------------------------------------
# ETAPA A: SE ESTIVER NO AMBIENTE LIVE (ARCHISO), INSTALAR O SO NO DISCO
# -----------------------------------------------------------------------------
if [ -f /run/archiso/bootmnt ] || [ "$HOSTNAME" = "archiso" ] || [ "$USER" = "root" ] && [ ! -f /etc/illuminate-installed ]; then
    echo "💿 Ambiente Live ISO detectado! Prepara-se para formatar $DISC..."
    
    if [ ! -b "$DISC" ]; then
        echo "❌ Erro: O disco $DISC não foi encontrado! Verifique o caminho no QEMU."
        exit 1
    fi

    # 1. Particionamento GPT
    echo "🧹 Formatando e particionando o disco $DISC..."
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

    # 2. Montar partições
    echo "📂 Montando partições em /mnt..."
    mount "$PART_ROOT" /mnt
    mkdir -p /mnt/boot
    mount "$PART_EFI" /mnt/boot

    # 3. Pacstrap Base
    echo "📦 Instalando base do Arch Linux, kernel e utilitários..."
    pacman-key --init || true
    pacman-key --populate archlinux || true
    pacstrap -K /mnt base linux linux-firmware base-devel git sudo bash networkmanager grub efibootmgr

    # 4. Gerar Fstab
    genfstab -U /mnt >> /mnt/etc/fstab

    # 5. Criar marcador de instalação
    touch /mnt/etc/illuminate-installed

    # 6. Configuração Chroot (Usuário e Bootloader)
    echo "👤 Configurando Usuário 'illuminate', Senhas e GRUB Bootloader..."
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

    # 7. Copiar repositório/scripts para o sistema e executar pós-instalação
    mkdir -p /mnt/home/illuminate/IlluminateBR-OS/scripts
    cp "$0" /mnt/home/illuminate/IlluminateBR-OS/scripts/install.sh
    chown -R illuminate:illuminate /mnt/home/illuminate/IlluminateBR-OS

    echo "🔄 Transição para o pós-instalador dentro do HD virtual..."
    arch-chroot /mnt /bin/bash -c "
        cd /home/illuminate/IlluminateBR-OS/scripts
        su illuminate -c 'bash install.sh $PROFILE system-post'
    "

    echo "==================================================================="
    echo "🎉 ILLUMINATEBR-OS INSTALADO COM SUCESSO NO DISCO!"
    echo "🔑 Usuário: illuminate | Senha: 123456"
    echo "🔑 Root Senha: 123456"
    echo "⚠️ Desligue a VM, remova a ISO do boot e ligue a máquina novamente."
    echo "==================================================================="
    exit 0
fi

# -----------------------------------------------------------------------------
# ETAPA B: PÓS-INSTALAÇÃO DO AMBIENTE (EXECUTADO COMO USUÁRIO DENTRO DO HD)
# -----------------------------------------------------------------------------

REAL_USER="$USER"
REAL_HOME="$HOME"

echo "⚙️ Instalando softwares do perfil '$PROFILE' para o usuário: $REAL_USER"

# 1. Atualizar Chaves e Sistema Base
sudo pacman-key --init || true
sudo pacman-key --populate archlinux || true
sudo pacman -Sy --noconfirm archlinux-keyring || true

sudo pacman -Syu --needed --noconfirm \
    base-devel git curl wget gcc make cmake ninja clang pkg-config \
    fastfetch htop btop tmux neovim zsh util-linux cabextract fontconfig \
    bat ripgrep fd zoxide eza flameshot copyq \
    unzip zip tar xz fuse2 fuse3 flatpak pipewire-jack qt6-multimedia-ffmpeg || true

# 2. Habilitar Flathub
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true

# 3. Ergonomia e Otimizações de CPU e RAM
sudo pacman -S --needed --noconfirm auto-cpufreq zram-generator || true
sudo systemctl enable auto-cpufreq || true

# 4. Virtualização KVM
sudo pacman -S --needed --noconfirm qemu-full virt-manager virt-viewer dnsmasq vde2 bridge-utils iptables-nft libguestfs || true
sudo systemctl enable libvirtd || true

# 5. Java & Node / Web CLI
echo "☕ Instalando Java 21 e ecossistema Web..."
sudo pacman -S --needed --noconfirm jdk21-openjdk openjdk21-doc openjdk21-src nodejs npm yarn bun-bin || true
sudo npm install -g @angular/cli typescript tailwindcss live-server lighthouse || true

# 6. Flutter SDK
echo "💙 Configurando Flutter SDK..."
sudo pacman -S --needed --noconfirm gtk3 || true
mkdir -p "$REAL_HOME/development"

if [ ! -d "$REAL_HOME/development/flutter" ]; then
    git clone https://github.com/flutter/flutter.git -b stable "$REAL_HOME/development/flutter" || true
fi

for rc in "$REAL_HOME/.bashrc" "$REAL_HOME/.zshrc"; do
    touch "$rc"
    if ! grep -q 'flutter/bin' "$rc"; then
        echo '' >> "$rc"
        echo '# Flutter & Android SDK Path' >> "$rc"
        echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> "$rc"
        echo 'export ANDROID_HOME="$HOME/Android/Sdk"' >> "$rc"
        echo 'export PATH="$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools"' >> "$rc"
    fi
done

# 7. Bancos de Dados
sudo pacman -S --needed --noconfirm postgresql mariadb-clients sqlite || true
if [ ! -d "/var/lib/postgres/data/base" ]; then
    sudo -u postgres initdb -D /var/lib/postgres/data || true
fi
sudo systemctl enable postgresql || true

# 8. Módulo DevOps
if [ "$PROFILE" = "devops" ] || [ "$PROFILE" = "full" ]; then
    echo "☁️ Configurando Módulo DevOps & Docker..."
    sudo pacman -S --needed --noconfirm \
        docker containerd docker-buildx docker-compose podman \
        kubectl helm terraform ansible aws-cli nmap wireshark-qt wireguard-tools || true

    sudo systemctl enable docker || true
    sudo usermod -aG docker "$REAL_USER" || true
fi

# 9. Auxiliar AUR (paru) - Executado corretamente sem privilégios de root direto
if ! command -v paru &> /dev/null; then
    echo "📦 Compilando helper AUR (paru)..."
    rm -rf /tmp/paru
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    (cd /tmp/paru && makepkg -si --noconfirm) || true
    rm -rf /tmp/paru
fi

# 10. Apps AUR & Desktop
sudo pacman -S --needed --noconfirm thunderbird libreoffice-fresh libreoffice-fresh-pt-br ttf-jetbrains-mono ttf-fira-code || true

if command -v paru &> /dev/null; then
    paru -S --needed --noconfirm ttf-ms-fonts google-chrome visual-studio-code-bin || true
fi

# Cursor IDE
echo "🤖 Instalando Cursor IDE..."
mkdir -p "$REAL_HOME/.local/bin" "$REAL_HOME/.local/share/applications"
curl -L "https://downloader.cursor.sh/linux/appImage/x64" -o "$REAL_HOME/.local/bin/cursor.AppImage" || true
chmod +x "$REAL_HOME/.local/bin/cursor.AppImage" || true

cat << 'CURSOR_ENTRY' > "$REAL_HOME/.local/share/applications/cursor.desktop"
[Desktop Entry]
Name=Cursor
Exec=/home/illuminate/.local/bin/cursor.AppImage --no-sandbox %U
Terminal=false
Type=Application
Icon=code
StartupWMClass=Cursor
Comment=AI-first Code Editor
Categories=Development;IDE;
CURSOR_ENTRY

# Apps Flatpak
echo "📱 Instalando Aplicativos Flatpak..."
flatpak install -y flathub com.google.AndroidStudio || true
flatpak install -y flathub org.eclipse.Java || true
flatpak install -y flathub com.aurora.whatsie || true
flatpak install -y flathub com.github.IsmaelMartinez.teams_for_linux || true
flatpak install -y flathub com.github.Mailspring || true
flatpak install -y flathub org.onlyoffice.desktopeditors || true
flatpak install -y flathub com.spotify.Client || true
flatpak install -y flathub com.slack.Slack || true
flatpak install -y flathub io.dbeaver.DBeaverCommunity || true
flatpak install -y flathub usebruno.Bruno || true

# 11. Cinnamon Desktop & Interface
echo "🎨 Configurando Cinnamon Desktop e Display Manager..."
sudo pacman -S --needed --noconfirm cinnamon lightdm-slick-greeter starship || true
sudo systemctl enable lightdm || true

echo "==================================================================="
echo "✅ Configuração concluída para $REAL_USER!"
echo "==================================================================="
