#!/bin/bash

# Script d'installation et démarrage automatique de Docker et du backend

set -e

echo "🚀 Installation et démarrage automatique du backend Kisse"
echo ""

# Vérifier si Docker est installé
if command -v docker &> /dev/null; then
    echo "✅ Docker est déjà installé"
    DOCKER_CMD="docker"
elif [ -f "/Applications/Docker.app/Contents/Resources/bin/docker" ]; then
    echo "✅ Docker trouvé dans /Applications"
    DOCKER_CMD="/Applications/Docker.app/Contents/Resources/bin/docker"
else
    echo "📦 Installation de Docker Desktop..."
    echo "   (Cela nécessitera votre mot de passe administrateur)"
    echo ""
    
    # Installer Docker via Homebrew
    if command -v brew &> /dev/null; then
        brew install --cask docker
    else
        echo "❌ Homebrew n'est pas installé."
        echo "   Veuillez installer Docker Desktop manuellement depuis:"
        echo "   https://www.docker.com/products/docker-desktop/"
        exit 1
    fi
    
    echo ""
    echo "⏳ Attente de l'installation..."
    sleep 5
    
    # Essayer de trouver Docker après installation
    if [ -f "/Applications/Docker.app/Contents/Resources/bin/docker" ]; then
        DOCKER_CMD="/Applications/Docker.app/Contents/Resources/bin/docker"
    elif command -v docker &> /dev/null; then
        DOCKER_CMD="docker"
    else
        echo "⚠️  Docker installé mais pas encore dans le PATH"
        echo "   Veuillez ouvrir Docker Desktop manuellement, puis relancer ce script"
        open -a Docker 2>/dev/null || echo "   Ouvrez Docker Desktop depuis Applications"
        exit 1
    fi
fi

# Ouvrir Docker Desktop si nécessaire
echo "🔧 Vérification de Docker Desktop..."
if ! $DOCKER_CMD ps &> /dev/null; then
    echo "   Ouverture de Docker Desktop..."
    open -a Docker 2>/dev/null || true
    
    echo "   Attente que Docker soit prêt (cela peut prendre 30-60 secondes)..."
    for i in {1..30}; do
        if $DOCKER_CMD ps &> /dev/null; then
            echo "   ✅ Docker est prêt !"
            break
        fi
        sleep 2
        echo -n "."
    done
    echo ""
    
    if ! $DOCKER_CMD ps &> /dev/null; then
        echo "❌ Docker n'est pas encore prêt. Veuillez attendre que Docker Desktop soit complètement démarré, puis relancez:"
        echo "   ./install_and_start.sh"
        exit 1
    fi
fi

# Détecter docker compose
if $DOCKER_CMD compose version &> /dev/null; then
    COMPOSE_CMD="$DOCKER_CMD compose"
elif $DOCKER_CMD-compose version &> /dev/null; then
    COMPOSE_CMD="$DOCKER_CMD-compose"
else
    echo "❌ Docker Compose n'est pas disponible"
    exit 1
fi

echo ""
echo "🔨 Construction des images Docker..."
cd "$(dirname "$0")"
$COMPOSE_CMD build

echo ""
echo "▶️  Démarrage des services..."
$COMPOSE_CMD down 2>/dev/null || true
$COMPOSE_CMD up -d

echo ""
echo "⏳ Attente que les services soient prêts..."
sleep 5

echo ""
echo "📊 État des conteneurs:"
$COMPOSE_CMD ps

echo ""
echo "✅ Backend démarré avec succès !"
echo ""
echo "📍 Services disponibles:"
echo "   - API: http://localhost:8080"
echo "   - WebSocket: ws://localhost:8080/ws"
echo "   - Health: http://localhost:8080/health"
echo ""
echo "📝 Pour voir les logs:"
echo "   $COMPOSE_CMD logs -f"
echo ""
echo "🛑 Pour arrêter:"
echo "   $COMPOSE_CMD down"


