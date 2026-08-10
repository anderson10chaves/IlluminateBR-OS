#!/usr/bin/env bash

set -e

# =============================================================================
# 🚀 ILLUMINATEBR-OS - INSTALADOR UNIFICADO (BASE UBUNTU 24.04 LTS)
# =============================================================================

PROFILE="${1:-standard}"

log_step() {
    local percent="$1"
    local message="$2"
    echo "[PROGRESS:$percent]"
    echo "[STEP:$message]"
    echo "==================================================================="
    echo "🚀 $message"
    echo "==================================================================="
}

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo "~$REAL_USER")

export DEBIAN_FRONTEND=noninteractive

log_step "55" "Atualizando Repositórios e Pacotes Base (APT)..."
apt-get update -y
apt-get upgrade -y

# Ferramentas e Utilitários Globais
apt-get install -y --no-install-recommends \
    build-essential git curl wget gcc make cmake ninja-build clang pkg-config \
    fastfetch htop btop tmux neovim zsh util-linux cabextract fontconfig \
    bat ripgrep fd-find zoxide eza flameshot copyq \
    unzip zip tar xz-utils fuse3 flatpak ca-certificates gnome-software-plugin-flatpak

# Configurar Flathub
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true

log_step "65" "Instalando Softwares Essenciais de Sistema e Usabilidade..."
# Softwares para Usuários Comuns e Uso Diário
apt-get install -y \
    google-chrome-stable || apt-get install -y chromium-browser \
    thunderbird libreoffice libreoffice-l10n-pt-br \
    vlc mpv gparted synaptic ubuntu-restricted-extras \
    fonts-jetbrains-mono fonts-firacode || true

# Apps em Flatpak (Para todos os perfis)
flatpak install -y flathub com.spotify.Client || true
flatpak install -y flathub com.aurora.whatsie || true
flatpak install -y flathub com.github.IsmaelMartinez.teams_for_linux || true

# -----------------------------------------------------------------------------
# PERFIL 1: STANDARD (Usuário Comum / Produtividade Básica)
# -----------------------------------------------------------------------------
if [ "$PROFILE" = "standard" ]; then
    log_step "85" "Configurando Perfil Standard (Uso Geral)..."
    flatpak install -y flathub org.onlyoffice.desktopeditors || true
fi

# -----------------------------------------------------------------------------
# PERFIL 2, 3 e 4: DEV, DEVOPS e FULL (Ecossistema de Desenvolvimento)
# -----------------------------------------------------------------------------
if [ "$PROFILE" = "dev" ] || [ "$PROFILE" = "devops" ] || [ "$PROFILE" = "full" ]; then
    log_step "75" "Instalando Linguagens, Runtimes e SDKs (Java, Node, Flutter)..."
    
    # Java 21, Node.js e BDs
    apt-get install -y openjdk-21-jdk nodejs npm postgresql sqlite3 || true
    npm install -g @angular/cli typescript tailwindcss live-server || true

    # Flutter SDK
    mkdir -p "$REAL_HOME/development"
    if [ ! -d "$REAL_HOME/development/flutter" ]; then
        git clone https://github.com/flutter/flutter.git -b stable "$REAL_HOME/development/flutter" || true
        chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/development"
    fi

    # Configuração de Variáveis de Ambiente
    for rc in "$REAL_HOME/.bashrc" "$REAL_HOME/.zshrc"; do
        if [ -f "$rc" ] && ! grep -q 'flutter/bin' "$rc"; then
            echo '' >> "$rc"
            echo '# Flutter SDK' >> "$rc"
            echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> "$rc"
        fi
    done

    # IDEs e Ferramentas Dev
    snap install code --classic || true
    flatpak install -y flathub com.google.AndroidStudio || true
    flatpak install -y flathub io.dbeaver.DBeaverCommunity || true
    flatpak install -y flathub usebruno.Bruno || true

    # Cursor IDE
    mkdir -p "$REAL_HOME/.local/bin" "$REAL_HOME/.local/share/applications"
    curl -L "https://downloader.cursor.sh/linux/appImage/x64" -o "$REAL_HOME/.local/bin/cursor.AppImage" || true
    chmod +x "$REAL_HOME/.local/bin/cursor.AppImage" || true
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.local"
fi

# -----------------------------------------------------------------------------
# PERFIL 3 e 4: DEVOPS e FULL (Infraestrutura, Containers e Redes)
# -----------------------------------------------------------------------------
if [ "$PROFILE" = "devops" ] || [ "$PROFILE" = "full" ]; then
    log_step "85" "Configurando Ferramentas de DevOps, Docker e Virtualização..."
    
    apt-get install -y docker.io docker-compose-v2 podman qemu-kvm virt-manager \
        kubectl helm terraform ansible awscli nmap wireshark wireguard || true

    systemctl enable docker || true
    usermod -aG docker,kvm,libvirt "$REAL_USER" || true
fi

# -----------------------------------------------------------------------------
# PERFIL 4: FULL (DevOps + Criação de Conteúdo, Mídia e Edição)
# -----------------------------------------------------------------------------
if [ "$PROFILE" = "full" ]; then
    log_step "92" "Instalando Pacote de Mídia, Design e Edição..."
    
    apt-get install -y obs-studio kdenlive blender gimp inkscape audacity || true
fi

log_step "98" "Ajustando Permissões do Usuário e Serviços..."
chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME" || true

log_step "100" "Instalação do Perfil '$PROFILE' Concluída com Sucesso!"
