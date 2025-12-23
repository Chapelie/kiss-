#!/bin/bash

# Script d'arrêt pour le backend Kisse

set -e

echo "🛑 Arrêt du backend Kisse..."

# Détecter la commande Docker Compose
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
elif docker-compose version &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    echo "❌ Docker Compose n'est pas disponible."
    exit 1
fi

# Arrêter les conteneurs
$COMPOSE_CMD down

echo "✅ Backend arrêté !"

