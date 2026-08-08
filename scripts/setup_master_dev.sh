#!/usr/bin/env bash

set -e

echo "==================================================================="
echo "🚀 [IlluminateBR-OS] Configuração Master Dev, DevOps & Mídia"
echo "==================================================================="

# -----------------------------------------------------------------------------
# 1. Atualizar o sistema e habilitar Flathub
# -----------------------------------------------------------------------------
echo "📦 Atualizando sistema e habilitando repositórios..."
sudo pacman -Syu --noconfirm

sudo pacman -S --needed --noconfirm flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true

# -----------------------------------------------------------------------------
# 2. Ergonomia Visual (Redução do Cansaço Ocular / Night Light)
# -----------------------------------------------------------------------------
echo "👁️ Aplicando configurações de ergonomia e filtro de luz azul..."
gsettings set org.cinnamon.settings-daemon.plugins.color night-light-enabled true 2>/dev/null || true
gsettings set org.cinnamon.settings-daemon.plugins.color night-light-temperature 3500 2>/dev/null || true

# -----------------------------------------------------------------------------
# 3. Desempenho de Hardware e Otimização de RAM (auto-cpufreq + zRAM)
# -----------------------------------------------------------------------------
echo "⚡ Configurando utilitários de desempenho de CPU e compressão zRAM..."
sudo pacman -S --needed --noconfirm auto-cpufreq zram-generator || true
sudo systemctl enable --now auto-cpufreq || true

sudo bash -c 'cat <<ZRAM > /etc/systemd/zram-generator.conf
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
ZRAM' || true

# -----------------------------------------------------------------------------
# 4. Ativar Aceleração KVM para Emulador Android e Virtualização
# -----------------------------------------------------------------------------
echo "⚡ Configurando virtualização KVM..."
sudo pacman -S --needed --noconfirm qemu-full virt-manager virt-viewer dnsmasq vde2 bridge-utils iptables-nft libguestfs || true
sudo systemctl enable --now libvirtd || true
sudo usermod -aG kvm $USER || true
sudo usermod -aG libvirt $USER || true

# -----------------------------------------------------------------------------
# 5. Pacotes Base, Compiladores e Utilitários CLI
# -----------------------------------------------------------------------------
echo "🛠️ Instalando utilitários do sistema, base-devel, Git, Zsh e CLI..."
sudo pacman -S --needed --noconfirm \
    base-devel git curl wget gcc make cmake ninja clang pkg-config \
    fastfetch htop btop tmux neovim zsh util-linux cabextract fontconfig \
    bat ripgrep fd zoxide eza flameshot copyq \
    unzip zip tar xz fuse2 fuse3 || true

# -----------------------------------------------------------------------------
# 6. Java (OpenJDK 21 LTS) & Runtimes
# -----------------------------------------------------------------------------
echo "☕ Instalando OpenJDK 21 LTS..."
sudo pacman -S --needed --noconfirm jdk21-openjdk openjdk21-doc openjdk21-src || true

# -----------------------------------------------------------------------------
# 7. Front-end, Web & Marketing Digital (Node, Bun, Angular, Tailwind, Typescript)
# -----------------------------------------------------------------------------
echo "🌐 Instalando ferramentas de Front-end, Web e Marketing Digital..."
sudo pacman -S --needed --noconfirm nodejs npm yarn bun-bin html5-xml-support sass-c || true

echo "🅰️ Instalando CLIs e utilitários globais da Web..."
sudo npm install -g @angular/cli typescript tailwindcss live-server lighthouse || true

# -----------------------------------------------------------------------------
# 8. Flutter SDK & Android SDK Variables
# -----------------------------------------------------------------------------
echo "💙 Instalando dependências e SDK do Flutter..."
sudo pacman -S --needed --noconfirm gtk3 || true

FLUTTER_DIR="$HOME/development"
mkdir -p "$FLUTTER_DIR"

if [ ! -d "$FLUTTER_DIR/flutter" ]; then
    echo "⬇️ Baixando Flutter SDK..."
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
# 9. DevOps, Infraestrutura & Redes (Docker, K8s, Terraform, Ansible)
# -----------------------------------------------------------------------------
echo "☁️ Instalando suíte de DevOps, Kubernetes e Nuvem..."
sudo pacman -S --needed --noconfirm \
    docker docker-buildx docker-compose podman \
    kubectl helm terraform ansible \
    aws-cli nmap wireshark-qt wireguard-tools || true

sudo systemctl enable --now docker || true
sudo usermod -aG docker $USER || true

# -----------------------------------------------------------------------------
# 10. Bancos de Dados (PostgreSQL, MariaDB, SQLite)
# -----------------------------------------------------------------------------
echo "🐘 Instalando e configurando Bancos de Dados..."
sudo pacman -S --needed --noconfirm postgresql mariadb-clients sqlite || true

if [ ! -d "/var/lib/postgres/data/base" ]; then
    sudo -u postgres initdb -D /var/lib/postgres/data || true
fi
sudo systemctl enable --now postgresql || true

# -----------------------------------------------------------------------------
# 11. Gravação de Tela, Edição de Vídeo, Áudio & Design (Marketing & Criadores)
# -----------------------------------------------------------------------------
echo "🎥 Instalando suíte audiovisual e design..."
sudo pacman -S --needed --noconfirm \
    obs-studio kdenlive shotcut \
    audacity gimp inkscape krita blender \
    ffmpeg || true

# -----------------------------------------------------------------------------
# 12. E-mail, Comunicação & Escritório
# -----------------------------------------------------------------------------
echo "📧 Instalando clientes de e-mail e produtividade..."
sudo pacman -S --needed --noconfirm thunderbird libreoffice-fresh libreoffice-fresh-pt-br || true
flatpak install -y flathub com.github.Mailspring || true

# Fontes da Microsoft e Google Chrome/VS Code via paru
paru -S --needed --noconfirm ttf-ms-fonts google-chrome visual-studio-code-bin || true

# Cursor IDE (AppImage)
echo "🤖 Instalando Cursor IDE..."
CURSOR_DIR="$HOME/.local/bin"
mkdir -p "$CURSOR_DIR"
mkdir -p "$HOME/.local/share/applications"

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

# -----------------------------------------------------------------------------
# 13. Apps de Comunicação & Dev via Flatpak
# -----------------------------------------------------------------------------
echo "📱 Instalando IDEs e utilitários via Flatpak..."
flatpak install -y flathub com.google.AndroidStudio || true
flatpak install -y flathub org.eclipse.Java || true
flatpak install -y flathub com.aurora.whatsie || flatpak install -y flathub io.github.mickaelmendes50.ZapZap || flatpak install -y flathub io.github.khe2002.whatsdesk || true
flatpak install -y flathub com.github.IsmaelMartinez.teams_for_linux || true
flatpak install -y flathub org.onlyoffice.desktopeditors || true
flatpak install -y flathub com.spotify.Client || true
flatpak install -y flathub com.slack.Slack || true
flatpak install -y flathub io.dbeaver.DBeaverCommunity || true
flatpak install -y flathub usebruno.Bruno || true

# Fontes de Programação
sudo pacman -S --needed --noconfirm ttf-jetbrains-mono ttf-fira-code || true

# -----------------------------------------------------------------------------
# 14. Cinnamon Desktop, Tema macOS (WhiteSur) & Starship Prompt
# -----------------------------------------------------------------------------
echo "🎨 Instalando Cinnamon Desktop, Starship Prompt e Tema macOS..."

sudo pacman -S --needed --noconfirm cinnamon lightdm-slick-greeter || true
sudo systemctl enable lightdm || true

# Efeito Genie (Minimizar estilo Mac)
gsettings set org.cinnamon.desktop.effect.instances minimize "'traditional'" 2>/dev/null || true

# Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "🐚 Instalando Oh My Zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true
fi

# Starship Prompt
sudo pacman -S --needed --noconfirm starship || true

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

# Tema WhiteSur
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
echo "✅ Instalação concluída com sucesso no IlluminateBR-OS / CachyOS!"
echo "👁️ Filtro de luz azul e ergonomia ativados."
echo "⚡ Gerenciador de desempenho (auto-cpufreq) e zRAM ativos."
echo "🌐 Front-end (Angular, Node, Bun, Tailwind) configurados."
echo "☁️ DevOps (Docker, K8s, Terraform, AWS CLI) instalados."
echo "🎥 OBS Studio, Kdenlive, Blender e GIMP prontos."
echo "💙 Flutter configurado em $HOME/development/flutter."
echo "==================================================================="
echo "⚠️ REINICIE o computador para aplicar todas as permissões e sessões."
echo "==================================================================="
