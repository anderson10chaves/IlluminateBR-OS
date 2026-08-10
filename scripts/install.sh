#!/usr/bin/env bash

set -e

# Detecta usuário real caso esteja rodando via sudo
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo "~$REAL_USER")

# Recebe o parâmetro ('dev', 'devops' ou 'full'). Padrão: devops
PROFILE="${1:-devops}"

echo "==================================================================="
echo "🚀 [IlluminateBR-OS] Iniciando Instalação no Perfil: $PROFILE"
echo "👤 Usuário de Instalação: $REAL_USER"
echo "==================================================================="

# Helper para executar comandos como o usuário comum
run_as_user() {
    sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u "$REAL_USER")/bus "$@"
}

# -----------------------------------------------------------------------------
# 0. Atualização de Chaves e Repositórios
# -----------------------------------------------------------------------------
echo "🔑 Inicializando e atualizando chaves do Arch Linux..."
pacman-key --init || true
pacman-key --populate archlinux || true
pacman -Sy --noconfirm archlinux-keyring || true

# -----------------------------------------------------------------------------
# 1. Atualizar o sistema e repositórios
# -----------------------------------------------------------------------------
echo "📦 Atualizando sistema e habilitando Flathub..."
pacman -Syu --noconfirm --overwrite '*'

pacman -S --needed --noconfirm flatpak
run_as_user flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true

# -----------------------------------------------------------------------------
# 2. Ergonomia Visual (Filtro de Luz Azul / Night Light)
# -----------------------------------------------------------------------------
echo "👁️ Configurando iluminação ergonômica..."
run_as_user gsettings set org.cinnamon.settings-daemon.plugins.color night-light-enabled true 2>/dev/null || true
run_as_user gsettings set org.cinnamon.settings-daemon.plugins.color night-light-temperature 3500 2>/dev/null || true

# -----------------------------------------------------------------------------
# 3. Desempenho e Memória (auto-cpufreq + zRAM)
# -----------------------------------------------------------------------------
echo "⚡ Otimizando desempenho do processador e memória RAM (zRAM)..."
pacman -S --needed --noconfirm auto-cpufreq zram-generator || true
systemctl enable --now auto-cpufreq || true

bash -c 'cat <<ZRAM > /etc/systemd/zram-generator.conf
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
ZRAM' || true

# -----------------------------------------------------------------------------
# 4. Virtualização e KVM
# -----------------------------------------------------------------------------
echo "⚡ Configurando aceleração KVM e suporte a máquinas virtuais..."
pacman -S --needed --noconfirm qemu-full virt-manager virt-viewer dnsmasq vde2 bridge-utils iptables-nft libguestfs || true
systemctl enable --now libvirtd || true
usermod -aG kvm "$REAL_USER" || true
usermod -aG libvirt "$REAL_USER" || true

# -----------------------------------------------------------------------------
# 5. Ferramentas Base, Compiladores e Utilitários CLI
# -----------------------------------------------------------------------------
echo "🛠️ Instalando utilitários essenciais de terminal e compiladores..."
pacman -S --needed --noconfirm \
    base-devel git curl wget gcc make cmake ninja clang pkg-config \
    fastfetch htop btop tmux neovim zsh util-linux cabextract fontconfig \
    bat ripgrep fd zoxide eza flameshot copyq \
    unzip zip tar xz fuse2 fuse3 || true

# -----------------------------------------------------------------------------
# 6. Runtimes Base: Java (LTS) & Web/Front-end (Node, Bun, Angular, Tailwind)
# -----------------------------------------------------------------------------
echo "☕ Instalando OpenJDK 21 LTS..."
pacman -S --needed --noconfirm jdk21-openjdk openjdk21-doc openjdk21-src || true

echo "🌐 Instalando ecossistema Web & Front-end..."
pacman -S --needed --noconfirm nodejs npm yarn bun-bin html5-xml-support sass-c || true

echo "🅰️ Instalando CLIs globais (Angular, Typescript, Tailwind)..."
npm install -g @angular/cli typescript tailwindcss live-server lighthouse || true

# -----------------------------------------------------------------------------
# 7. Configuração do Flutter SDK
# -----------------------------------------------------------------------------
echo "💙 Configurando Flutter SDK..."
pacman -S --needed --noconfirm gtk3 || true

FLUTTER_DIR="$REAL_HOME/development"
run_as_user mkdir -p "$FLUTTER_DIR"

if [ ! -d "$FLUTTER_DIR/flutter" ]; then
    echo "⬇️ Clonando repositório do Flutter..."
    run_as_user git clone https://github.com/flutter/flutter.git -b stable "$FLUTTER_DIR/flutter" || true
fi

config_shell_env() {
    local file="$1"
    if [ -f "$file" ] || [ "$file" = "$REAL_HOME/.bashrc" ]; then
        touch "$file"
        chown "$REAL_USER:$REAL_USER" "$file"
        if ! grep -q 'flutter/bin' "$file"; then
            echo '' >> "$file"
            echo '# Flutter & Android SDK Path' >> "$file"
            echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> "$file"
            echo 'export ANDROID_HOME="$HOME/Android/Sdk"' >> "$file"
            echo 'export PATH="$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools"' >> "$file"
        fi
    fi
}

config_shell_env "$REAL_HOME/.bashrc"
config_shell_env "$REAL_HOME/.zshrc"

export PATH="$FLUTTER_DIR/flutter/bin:$PATH"

# -----------------------------------------------------------------------------
# 8. Bancos de Dados Base
# -----------------------------------------------------------------------------
echo "🐘 Configurando serviços de Bancos de Dados..."
pacman -S --needed --noconfirm postgresql mariadb-clients sqlite || true

if [ ! -d "/var/lib/postgres/data/base" ]; then
    sudo -u postgres initdb -D /var/lib/postgres/data || true
fi
systemctl enable --now postgresql || true

# =============================================================================
# PERFIL: DEVOPS & INFRAESTRUTURA (Executado para 'devops' e 'full')
# =============================================================================
if [ "$PROFILE" = "devops" ] || [ "$PROFILE" = "full" ]; then
    echo "☁️ [Módulo DevOps] Instalando Docker, Kubernetes, Terraform, AWS CLI e Redes..."
    pacman -S --needed --noconfirm \
        docker containerd docker-buildx docker-compose podman \
        kubectl helm terraform ansible \
        aws-cli nmap wireshark-qt wireguard-tools || true

    systemctl enable --now docker || true
    groupadd -f docker || true
    usermod -aG docker "$REAL_USER" || true
fi

# =============================================================================
# PERFIL: CRIAÇÃO DE CONTEÚDO & MÍDIA (Executado apenas para 'full')
# =============================================================================
if [ "$PROFILE" = "full" ]; then
    echo "🎥 [Módulo Mídia/Marketing] Instalando OBS, Kdenlive, Blender, GIMP, Inkscape e Audacity..."
    pacman -S --needed --noconfirm \
        obs-studio kdenlive shotcut \
        audacity gimp inkscape krita blender \
        ffmpeg || true
fi

# -----------------------------------------------------------------------------
# 9. Verificação e Instalação do Auxiliar AUR (paru)
# -----------------------------------------------------------------------------
if ! run_as_user command -v paru &> /dev/null; then
    echo "📦 Compilando e instalando helper do AUR (paru)..."
    rm -rf /tmp/paru
    run_as_user git clone https://aur.archlinux.org/paru.git /tmp/paru
    (cd /tmp/paru && run_as_user makepkg -si --noconfirm) || true
    rm -rf /tmp/paru
fi

# -----------------------------------------------------------------------------
# 10. Aplicativos Desktop, IDEs & Produtividade
# -----------------------------------------------------------------------------
echo "📧 Instalando aplicativos de produtividade e navegadores..."
pacman -S --needed --noconfirm thunderbird libreoffice-fresh libreoffice-fresh-pt-br ttf-jetbrains-mono ttf-fira-code || true

run_as_user paru -S --needed --noconfirm ttf-ms-fonts google-chrome visual-studio-code-bin || true

# Cursor IDE (AppImage)
echo "🤖 Instalando Cursor IDE..."
CURSOR_DIR="$REAL_HOME/.local/bin"
run_as_user mkdir -p "$CURSOR_DIR" "$REAL_HOME/.local/share/applications"

run_as_user curl -L "https://downloader.cursor.sh/linux/appImage/x64" -o "$CURSOR_DIR/cursor.AppImage" || true
chmod +x "$CURSOR_DIR/cursor.AppImage" || true

cat <<EOF > "$REAL_HOME/.local/share/applications/cursor.desktop"
[Desktop Entry]
Name=Cursor
Exec=$CURSOR_DIR/cursor.AppImage --no-sandbox %U
Terminal=false
Type=Application
Icon=code
StartupWMClass=Cursor
Comment=AI-first Code Editor
Categories=Development;IDE;
EOF

chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.local"
