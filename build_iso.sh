#!/bin/bash
set -e

echo "======================================================"
echo " 💿 IlluminateBR-OS: Compilando o Aplicativo Instalador"
echo "======================================================"

# 1. Compilar o App Flutter
cd installer
flutter pub get
flutter build linux --release
cd ..

# 2. Copiar os binários do Flutter para a estrutura do sistema
mkdir -p iso_root/usr/local/bin
mkdir -p iso_root/usr/local/share/illuminate-installer

cp -r installer/build/linux/x64/release/bundle/* iso_root/usr/local/share/illuminate-installer/
cp scripts/setup_master_dev.sh iso_root/usr/local/bin/setup_master_dev.sh
chmod +x iso_root/usr/local/bin/setup_master_dev.sh

# Criar atalho executável para o instalador
cat <<'LAUNCHER' > iso_root/usr/local/bin/illuminate-installer
#!/bin/bash
/usr/local/share/illuminate-installer/illuminatebr_installer
LAUNCHER

chmod +x iso_root/usr/local/bin/illuminate-installer

echo "✔ Binários e scripts integrados à árvore da ISO com sucesso!"
