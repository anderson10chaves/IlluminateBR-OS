#!/usr/bin/env bash
set -e

echo "==================================================================="
echo "🏗️ [IlluminateBR-OS] Compilador de ISO (Base Debian Live)"
echo "==================================================================="

echo "🧹 Limpando compilações anteriores..."
lb clean --purge || true
rm -rf config/

echo "🛠️ Criando wrapper do wget para interceptar Contents-amd64.gz..."
BIN_DIR="$(pwd)/bin"
mkdir -p "$BIN_DIR"

cat << 'EOF' > "$BIN_DIR/wget"
#!/usr/bin/env bash
is_contents=false
for arg in "$@"; do
    if [[ "$arg" == *"Contents-amd64.gz"* ]]; then
        is_contents=true
        break
    fi
done

if [ "$is_contents" = true ]; then
    echo "[MOCK WGET] Interceptado download do Contents-amd64.gz." >&2
    for arg in "$@"; do
        if [[ "$arg" == "-O" || "$arg" == "-O-" ]]; then
            printf "" | gzip -c
            exit 0
        fi
    done
    printf "" | gzip -c > Contents-amd64.gz
    exit 0
fi

exec /usr/bin/wget "$@"
EOF

chmod +x "$BIN_DIR/wget"
export PATH="$BIN_DIR:$PATH"

echo "⚙️ Configurando o live-build com GRUB (substitui o syslinux incompativel)..."
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
    --bootloader grub-pc \
    --win32-loader false

mkdir -p config/package-lists/
cat << 'EOF' > config/package-lists/illuminate.list.chroot
linux-image-amd64
live-boot
systemd-sysv
firmware-linux
firmware-linux-nonfree
grub-pc
grub-efi-amd64
grub-common
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

# Repositório de segurança do Bookworm
mkdir -p config/archives/
cat << 'EOF' > config/archives/security.list.chroot
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
EOF

cat << 'EOF' > config/archives/security.list.binary
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
EOF

# Auto-Login no LightDM
mkdir -p config/includes.chroot/etc/lightdm/lightdm.conf.d/
cat << 'EOF' > config/includes.chroot/etc/lightdm/lightdm.conf.d/80-live-autologin.conf
[Seat:*]
autologin-guest=false
autologin-user=user
autologin-user-timeout=0
EOF

echo "📦 Iniciando compilação da ISO..."
lb build

echo "==================================================================="
echo "🎉 ISO GERADA COM SUCESSO!"
echo "==================================================================="
