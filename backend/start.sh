#!/bin/bash

# Script de démarrage pour le backend Kisse avec Docker

set -e

echo "🚀 Démarrage du backend Kisse avec Docker..."
echo ""

# Vérifier que Docker est installé
if ! command -v docker &> /dev/null; then
    echo "❌ Docker n'est pas installé. Veuillez installer Docker Desktop."
    exit 1
fi

# Vérifier que Docker Compose est disponible
if ! docker compose version &> /dev/null && ! docker-compose version &> /dev/null; then
    echo "❌ Docker Compose n'est pas disponible."
    exit 1
fi

# Arrêter les conteneurs existants
echo "🛑 Arrêt des conteneurs existants..."
docker compose down 2>/dev/null || docker-compose down 2>/dev/null || true

# Construire les images
echo "🔨 Construction des images Docker..."
if docker compose build 2>/dev/null; then
    COMPOSE_CMD="docker compose"
elif docker-compose build 2>/dev/null; then
    COMPOSE_CMD="docker-compose"
else
    echo "❌ Impossible de construire les images."
    exit 1
fi

# Démarrer les services
echo "▶️  Démarrage des services..."
$COMPOSE_CMD up -d

# Attendre que PostgreSQL soit prêt
echo "⏳ Attente de PostgreSQL..."
sleep 5

# Vérifier l'état des conteneurs
echo ""
echo "📊 État des conteneurs:"
$COMPOSE_CMD ps

echo ""
echo "✅ Backend démarré !"
echo ""
echo "📍 Services disponibles:"
echo "   - API: http://localhost:8080"
echo "   - WebSocket: ws://localhost:8080/ws"
echo "   - Health check: http://localhost:8080/health"
echo "   - PostgreSQL: localhost:5432"
echo ""
echo "📝 Pour voir les logs:"
echo "   $COMPOSE_CMD logs -f"
echo ""
echo "🛑 Pour arrêter:"
echo "   $COMPOSE_CMD down"


