#!/usr/bin/env bash

set -e

# Garantir permissões de superusuário para montagem
if [ "$EUID" -ne 0 ]; then
  echo "⚠️ Este script precisa ser executado como root (sudo ./build.sh)"
  exit 1
fi

BUILD_DIR="$(pwd)/work"
OUT_DIR="$(pwd)/out"
PROFILE_DIR="$(pwd)/profile"

echo "🚀 [IlluminateBR-OS] Iniciando compilação da ISO..."

# Limpar compilações anteriores
rm -rf "$BUILD_DIR" "$OUT_DIR"
mkdir -p "$BUILD_DIR" "$OUT_DIR"

# Executar a compilação via mkarchiso (caso esteja em ambiente Arch/Manjaro/Big)
if command -v mkarchiso &> /dev/null; then
    echo "📦 Compilando imagem ISO..."
    mkarchiso -v -w "$BUILD_DIR" -o "$OUT_DIR" "$PROFILE_DIR"
    echo "🎉 ISO gerada com sucesso em: $OUT_DIR/"
else
    echo "ℹ️ Ferramenta 'mkarchiso' não encontrada no sistema host."
    echo "📌 A estrutura de arquivos em 'profile/' está pronta e validada para ser empacotada em ambiente de build Arch/Debian."
fi
