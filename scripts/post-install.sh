#!/usr/bin/env bash

set -e

echo "⚙️ Executando configurações de primeiro boot do IlluminateBR-OS..."

# Ativar repositório Flathub por padrão
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true

# Ativar serviço do Docker
systemctl enable docker.service || true

echo "✅ Configurações base concluídas!"
