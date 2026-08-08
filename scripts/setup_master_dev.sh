#!/usr/bin/env bash

set -e

echo "🚀 [IlluminateBR-OS] Iniciando Configuração Master de Desenvolvimento..."

# -----------------------------------------------------------------------------
# 1. Atualizar Sistema e Habilitar Flathub
# -----------------------------------------------------------------------------
echo "📦 [1/11] Atualizando base do sistema e habilitando Flathub..."
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true

# -----------------------------------------------------------------------------
# 2. Virtualização KVM para Emulador Android
# -----------------------------------------------------------------------------
echo "⚡ [2/11] Configurando virtualização KVM..."
sudo pacman -S --needed --noconfirm qemu-full virt-manager virt-viewer dnsmasq vde2 bridge-utils iptables-nft libguestfs || true
sudo systemctl enable --now libvirtd || true
sudo usermod -aG kvm $USER || true
sudo usermod -aG libvirt $USER || true

# -----------------------------------------------------------------------------
# 3. Pacotes Base, Compiladores e Utilitários CLI
# -----------------------------------------------------------------------------
echo "🛠️ [3/11] Instalando pacotes base, Zsh e utilitários modernos de terminal..."
sudo pacman -S --needed --noconfirm \
    base-devel git curl wget gcc make \
    fastfetch htop btop tmux neovim \
    zsh util-linux cabextract fontconfig \
    bat ripgrep fd zoxide eza flameshot copyq \
    unzip zip tar xz fuse2 fuse3 distrobox || true

# -----------------------------------------------------------------------------
# 4. Java 21 (OpenJDK)
# -----------------------------------------------------------------------------
echo "☕ [4/11] Configurando OpenJDK 21 LTS..."
sudo pacman -S --needed --noconfirm jdk21-openjdk || true

# -----------------------------------------------------------------------------
# 5. Node.js, NPM, Angular CLI 17 & YaRN/Pnpm
# -----------------------------------------------------------------------------
echo "🅰️ [5/11] Instalando Node.js, NPM e Angular CLI 17..."
sudo pacman -S --needed --noconfirm nodejs npm yarn || true
sudo npm install -g @angular/cli@17 pnpm || true

# -----------------------------------------------------------------------------
# 6. Flutter SDK & Dependências do Linux
# -----------------------------------------------------------------------------
echo "💙 [6/11] Configurando Flutter SDK..."
sudo pacman -S --needed --noconfirm clang cmake ninja pkgconf gtk3 || true

FLUTTER_DIR="$HOME/development"
mkdir -p "$FLUTTER_DIR"

if [ ! -d "$FLUTTER_DIR/flutter" ]; then
    echo "⬇️ Baixando repositório estável do Flutter..."
    git clone https://github.com/flutter/flutter.git -b stable "$FLUTTER_DIR/flutter" || true
fi

config_shell_env() {
    local file="$1"
    if [ -f "$file" ] || [ "$file" = "$HOME/.bashrc" ]; then
        touch "$file"
        if ! grep -q 'flutter/bin' "$file"; then
            echo '' >> "$file"
            echo '# IlluminateBR-OS: Flutter & Android SDK Path' >> "$file"
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
# 7. Bancos de Dados: PostgreSQL e MySQL/MariaDB
# -----------------------------------------------------------------------------
echo "🐘 [7/11] Configurando PostgreSQL e MariaDB/MySQL..."
sudo pacman -S --needed --noconfirm postgresql mariadb mariadb-clients || true

if [ ! -d "/var/lib/postgres/data/base" ]; then
    sudo -u postgres initdb -D /var/lib/postgres/data || true
fi
if [ ! -d "/var/lib/mysql/mysql" ]; then
    sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql || true
fi

sudo systemctl enable --now postgresql || true
sudo systemctl enable --now mariadb || true

# -----------------------------------------------------------------------------
# 8. WhatsApp, Clientes de E-mail e Comunicação
# -----------------------------------------------------------------------------
echo "💬 [8/11] Instalando WhatsApp, Thunderbird e Apps de Comunicação..."
sudo pacman -S --needed --noconfirm thunderbird || true

# WhatsApp (Prioriza Whatsie -> ZapZap -> WhatsDesk)
echo "🟢 Instalando WhatsApp Web Client..."
flatpak install -y flathub com.aurora.whatsie || flatpak install -y flathub io.github.mickaelmendes50.ZapZap || flatpak install -y flathub io.github.khe2002.whatsdesk || true

# Outros comunicadores e e-mail
flatpak install -y flathub com.github.Mailspring || true
flatpak install -y flathub com.slack.Slack || true
flatpak install -y flathub com.github.IsmaelMartinez.teams_for_linux || true

# -----------------------------------------------------------------------------
# 9. IDEs, Navegadores, Cursor IDE & Suíte de Escritório
# -----------------------------------------------------------------------------
echo "🌐 [9/11] Instalando Chrome, VS Code, Cursor IDE, DBeaver e Suíte de Escritório..."
sudo pacman -S --needed --noconfirm libreoffice-fresh libreoffice-fresh-pt-br || true

# Fontes Microsoft e Google Chrome
if command -v paru &> /dev/null; then
    paru -S --needed --noconfirm ttf-ms-fonts google-chrome visual-studio-code-bin || true
elif command -v yay &> /dev/null; then
    yay -S --needed --noconfirm ttf-ms-fonts google-chrome visual-studio-code-bin || true
fi

# Cursor IDE (AppImage Nativo)
CURSOR_DIR="$HOME/.local/bin"
mkdir -p "$CURSOR_DIR" "$HOME/.local/share/applications"
if [ ! -f "$CURSOR_DIR/cursor.AppImage" ]; then
    curl -L "https://downloader.cursor.sh/linux/appImage/x64" -o "$CURSOR_DIR/cursor.AppImage" || true
    chmod +x "$CURSOR_DIR/cursor.AppImage" || true
fi

cat <<EOF > "$HOME/.local/share/applications/cursor.desktop"
[Desktop Entry]
Name=Cursor AI
Exec=$CURSOR_DIR/cursor.AppImage --no-sandbox %U
Terminal=false
Type=Application
Icon=code
StartupWMClass=Cursor
Comment=AI-first Code Editor
Categories=Development;IDE;
EOF

# Demais IDEs e Ferramentas Dev via Flatpak
flatpak install -y flathub com.google.AndroidStudio || true
flatpak install -y flathub io.dbeaver.DBeaverCommunity || true
flatpak install -y flathub usebruno.Bruno || true
flatpak install -y flathub org.onlyoffice.desktopeditors || true
flatpak install -y flathub com.spotify.Client || true

# Fontes para Programação
sudo pacman -S --needed --noconfirm ttf-jetbrains-mono ttf-fira-code || true

# -----------------------------------------------------------------------------
# 10. Docker & Containers
# -----------------------------------------------------------------------------
echo "🐳 [10/11] Configurando ambiente Docker Engine & Compose..."
sudo pacman -S --needed --noconfirm docker docker-buildx docker-compose || true
sudo systemctl enable --now docker || true
sudo usermod -aG docker $USER || true

# -----------------------------------------------------------------------------
# 11. Cinnamon Desktop, Tema macOS WhiteSur + Ubuntu Dark & Shell
# -----------------------------------------------------------------------------
echo "🎨 [11/11] Aplicando Interface Cinnamon com Estilo WhiteSur Dark..."
sudo pacman -S --needed --noconfirm cinnamon lightdm-slick-greeter starship || true
sudo systemctl enable lightdm || true

# Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true
fi

# Configurar Starship no Terminal
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

# Instalação do Tema Visual WhiteSur
mkdir -p "$HOME/.themes" "$HOME/.icons"
rm -rf /tmp/WhiteSur-gtk /tmp/WhiteSur-icon
git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git /tmp/WhiteSur-gtk --depth 1 || true
git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git /tmp/WhiteSur-icon --depth 1 || true

if [ -d "/tmp/WhiteSur-gtk" ]; then
    /tmp/WhiteSur-gtk/install.sh -c Dark -m -N ubuntu || true
fi

if [ -d "/tmp/WhiteSur-icon" ]; then
    /tmp/WhiteSur-icon/install.sh || true
fi

rm -rf /tmp/WhiteSur-gtk /tmp/WhiteSur-icon

echo "-------------------------------------------------------------------"
echo "✅ [IlluminateBR-OS] Script Master concluído com sucesso!"
echo "-------------------------------------------------------------------"
