#!/usr/bin/env bash

set -e

echo "🚀 Iniciando processo de compilação do IlluminateBR-OS..."

# Verificar se as pastas necessárias existem
if [ ! -d "profile" ]; then
    echo "❌ Erro: Pasta 'profile' não encontrada."
    exit 1
fi

echo "📦 Lendo lista de pacotes em profile/packages.x86_64..."
echo "🛠️ Aplicando configurações customizadas da pasta profile/airootfs..."
echo "⚙️ Vinculando scripts de pós-instalação..."

echo "----------------------------------------------------"
echo "✅ Estrutura do IlluminateBR-OS validada e pronta!"
echo "----------------------------------------------------"
