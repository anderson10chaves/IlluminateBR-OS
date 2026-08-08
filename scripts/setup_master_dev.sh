#!/usr/bin/env bash

set -e

# Recebe o parâmetro do Flutter ('dev', 'devops' ou 'full'). Padrão: devops
PROFILE="${1:-devops}"

echo "==================================================================="
echo "🚀 [IlluminateBR-OS] Iniciando Instalação no Perfil: $PROFILE"
echo "==================================================================="

# -----------------------------------------------------------------------------
# 1. Atualizar o sistema e repositórios
# -----------------------------------------------------------------------------
echo "📦 Atualizando sistema e habilitando Flathub..."
sudo pacman -Syu --noconfirm

sudo pacman -S --needed --noconfirm flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true

# -----------------------------------------------------------------------------
# 2. Ergonomia Visual (Filtro de Luz Azul / Night Light)
# -----------------------------------------------------------------------------
echo "👁️ Configurando iluminação ergonômica..."
gsettings set org.cinnamon.settings-daemon.plugins.color night-light-enabled true 2>/dev/null || true
gsettings set org.cinnamon.settings-daemon.plugins.color night-light-temperature 3500 2>/dev/null || true

# -----------------------------------------------------------------------------
# 3. Desempenho e Memória (auto-cpufreq + zRAM)
# -----------------------------------------------------------------------------
echo "⚡ Otimizando desempenho do processador e memória RAM (zRAM)..."
sudo pacman -S --needed --noconfirm auto-cpufreq zram-generator || true
sudo systemctl enable --now auto-cpufreq || true

sudo bash -c 'cat <<ZRAM > /etc/systemd/zram-generator.conf
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
ZRAM' || true

# -----------------------------------------------------------------------------
# 4. Virtualização e KVM
# -----------------------------------------------------------------------------
echo "⚡ Configurando aceleração KVM e suporte a máquinas virtuais..."
sudo pacman -S --needed --noconfirm qemu-full virt-manager virt-viewer dnsmasq vde2 bridge-utils iptables-nft libguestfs || true
sudo systemctl enable --now libvirtd || true
sudo usermod -aG kvm "$USER" || true
sudo usermod -aG libvirt "$USER" || true

# -----------------------------------------------------------------------------
# 5. Ferramentas Base, Compiladores e Utilitários CLI
# -----------------------------------------------------------------------------
echo "🛠️ Instalando utilitários essenciais de terminal e compiladores..."
sudo pacman -S --needed --noconfirm \
    base-devel git curl wget gcc make cmake ninja clang pkg-config \
    fastfetch htop btop tmux neovim zsh util-linux cabextract fontconfig \
    bat ripgrep fd zoxide eza flameshot copyq \
    unzip zip tar xz fuse2 fuse3 || true

# -----------------------------------------------------------------------------
# 6. Runtimes Base: Java (LTS) & Web/Front-end (Node, Bun, Angular, Tailwind)
# -----------------------------------------------------------------------------
echo "☕ Instalando OpenJDK 21 LTS..."
sudo pacman -S --needed --noconfirm jdk21-openjdk openjdk21-doc openjdk21-src || true

echo "🌐 Instalando ecossistema Web & Front-end..."
sudo pacman -S --needed --noconfirm nodejs npm yarn bun-bin html5-xml-support sass-c || true

echo "🅰️ Instalando CLIs globais (Angular, Typescript, Tailwind)..."
sudo npm install -g @angular/cli typescript tailwindcss live-server lighthouse || true

# -----------------------------------------------------------------------------
# 7. Configuração do Flutter SDK
# -----------------------------------------------------------------------------
echo "💙 Configurando Flutter SDK..."
sudo pacman -S --needed --noconfirm gtk3 || true

FLUTTER_DIR="$HOME/development"
mkdir -p "$FLUTTER_DIR"

if [ ! -d "$FLUTTER_DIR/flutter" ]; then
    echo "⬇️ Clonando repositório do Flutter..."
    git clone https://github.com/flutter/flutter.git -b stable "$FLUTTER_DIR/flutter" || true
fi

config_shell_env() {
    local file="$1"
    if [ -f "$file" ] || [ "$file" = "$HOME/.bashrc" ]; then
        touch "$file"
        if ! grep -q 'flutter/bin' "$file"; then
            echo '' >> "$file"
            echo '# Flutter & Android SDK Path' >> "$file"
            echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> "$file"
            echo 'export ANDROID_HOME="$HOME/Android/Sdk"' >> "$file"
            echo 'export PATH="$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools"' >> "$file"
        fi
    fi
}

config_shell_env "$HOME/.bashrc"
config_shell_env "$HOME/.zshrc"

export PATH="$FLUTTER_DIR/flutter/bin:$PATH"

# -----------------------------------------------------------------------------
# 8. Bancos de Dados Base
# -----------------------------------------------------------------------------
echo "🐘 Configurando serviços de Bancos de Dados..."
sudo pacman -S --needed --noconfirm postgresql mariadb-clients sqlite || true

if [ ! -d "/var/lib/postgres/data/base" ]; then
    sudo -u postgres initdb -D /var/lib/postgres/data || true
fi
sudo systemctl enable --now postgresql || true

# =============================================================================
# PERFIL: DEVOPS & INFRAESTRUTURA (Executado para 'devops' e 'full')
# =============================================================================
if [ "$PROFILE" = "devops" ] || [ "$PROFILE" = "full" ]; then
    echo "☁️ [Módulo DevOps] Instalando Docker, Kubernetes, Terraform, AWS CLI e Redes..."
    sudo pacman -S --needed --noconfirm \
        docker docker-buildx docker-compose podman \
        kubectl helm terraform ansible \
        aws-cli nmap wireshark-qt wireguard-tools || true

    sudo systemctl enable --now docker || true
    sudo usermod -aG docker "$USER" || true
fi

# =============================================================================
# PERFIL: CRIAÇÃO DE CONTEÚDO & MÍDIA (Executado apenas para 'full')
# =============================================================================
if [ "$PROFILE" = "full" ]; then
    echo "🎥 [Módulo Mídia/Marketing] Instalando OBS, Kdenlive, Blender, GIMP e Editores..."
    sudo pacman -S --needed --noconfirm \
        obs-studio kdenlive shotcut \
        audacity gimp inkscape krita blender \
        ffmpeg || true
fi

# -----------------------------------------------------------------------------
# 9. Verificação do Auxiliar AUR (paru)
# -----------------------------------------------------------------------------
if ! command -v paru &> /dev/null; then
    echo "📦 Compilando e instalando helper do AUR (paru)..."
    rm -rf /tmp/paru
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    (cd /tmp/paru && makepkg -si --noconfirm) || true
    rm -rf /tmp/paru
fi

# -----------------------------------------------------------------------------
# 10. Aplicativos Desktop, IDEs & Produtividade
# -----------------------------------------------------------------------------
echo "📧 Instalando aplicativos de produtividade e navegadores..."
sudo pacman -S --needed --noconfirm thunderbird libreoffice-fresh libreoffice-fresh-pt-br ttf-jetbrains-mono ttf-fira-code || true

# Fontes MS, Chrome e VS Code via AUR
paru -S --needed --noconfirm ttf-ms-fonts google-chrome visual-studio-code-bin || true

# Cursor IDE (AppImage)
echo "🤖 Instalando Cursor IDE..."
CURSOR_DIR="$HOME/.local/bin"
mkdir -p "$CURSOR_DIR" "$HOME/.local/share/applications"

curl -L "https://downloader.cursor.sh/linux/appImage/x64" -o "$CURSOR_DIR/cursor.AppImage" || true
chmod +x "$CURSOR_DIR/cursor.AppImage" || true

cat <<EOF > "$HOME/.local/share/applications/cursor.desktop"
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

# Aplicativos Flatpak
echo "📱 Instalando suíte Flatpak..."
flatpak install -y flathub com.google.AndroidStudio || true
flatpak install -y flathub org.eclipse.Java || true
flatpak install -y flathub com.aurora.whatsie || flatpak install -y flathub io.github.mickaelmendes50.ZapZap || flatpak install -y flathub io.github.khe2002.whatsdesk || true
flatpak install -y flathub com.github.IsmaelMartinez.teams_for_linux || true
flatpak install -y flathub com.github.Mailspring || true
flatpak install -y flathub org.onlyoffice.desktopeditors || true
flatpak install -y flathub com.spotify.Client || true
flatpak install -y flathub com.slack.Slack || true
flatpak install -y flathub io.dbeaver.DBeaverCommunity || true
flatpak install -y flathub usebruno.Bruno || true

# -----------------------------------------------------------------------------
# 11. Interface Cinnamon Desktop, Tema macOS (WhiteSur) & Shell
# -----------------------------------------------------------------------------
echo "🎨 Configurando ambiente Cinnamon, Tema WhiteSur e Prompt..."

sudo pacman -S --needed --noconfirm cinnamon lightdm-slick-greeter starship || true
sudo systemctl enable lightdm || true

# Efeito Genie no Cinnamon
gsettings set org.cinnamon.desktop.effect.instances minimize "'traditional'" 2>/dev/null || true

# Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true
fi

# Starship Prompt
for rcfile in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rcfile" ]; then
        if ! grep -q 'starship init' "$rcfile"; then
            if [[ "$rcfile" == *".zshrc"* ]]; then
                echo 'eval "$(starship init zsh)"' >> "$rcfile"
            else
                echo 'eval "$(starship init bash)"' >> "$rcfile"
            fi
        fi
    fi
done

# Tema macOS WhiteSur
mkdir -p "$HOME/.themes" "$HOME/.icons"
rm -rf /tmp/WhiteSur-gtk /tmp/WhiteSur-icon
git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git /tmp/WhiteSur-gtk --depth 1 || true
git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git /tmp/WhiteSur-icon --depth 1 || true

if [ -d "/tmp/WhiteSur-gtk" ]; then
    /tmp/WhiteSur-gtk/install.sh -c Dark -m -N glass || true
fi

if [ -d "/tmp/WhiteSur-icon" ]; then
    /tmp/WhiteSur-icon/install.sh || true
fi

rm -rf /tmp/WhiteSur-gtk /tmp/WhiteSur-icon

echo "==================================================================="
echo "✅ Instalação do Perfil '$PROFILE' Concluída com Sucesso!"
echo "==================================================================="
echo "⚠️ Por favor, REINICIE o sistema para validar as permissões de grupo e inicializar a sessão Cinnamon."
echo "==================================================================="
