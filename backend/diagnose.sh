#!/bin/bash

echo "🔍 Diagnostic des conteneurs Docker Kisse"
echo "=========================================="
echo ""

# Vérifier si Docker est en cours d'exécution
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker n'est pas en cours d'exécution"
    echo "   Veuillez démarrer Docker Desktop"
    exit 1
fi

echo "✅ Docker est en cours d'exécution"
echo ""

# Vérifier l'état des conteneurs
echo "📦 État des conteneurs:"
docker ps -a | grep kisse || echo "   Aucun conteneur Kisse trouvé"
echo ""

# Vérifier les logs du backend
echo "📋 Logs du backend (dernières 30 lignes):"
docker logs kisse-backend --tail 30 2>&1 || echo "   Le conteneur backend n'existe pas ou n'est pas démarré"
echo ""

# Vérifier les logs de PostgreSQL
echo "📋 Logs de PostgreSQL (dernières 30 lignes):"
docker logs kisse-postgres --tail 30 2>&1 || echo "   Le conteneur postgres n'existe pas ou n'est pas démarré"
echo ""

# Vérifier les ports
echo "🔌 Ports utilisés:"
lsof -i :8080 2>/dev/null || echo "   Port 8080 non utilisé"
lsof -i :5432 2>/dev/null || echo "   Port 5432 non utilisé"
echo ""

# Vérifier les volumes
echo "💾 Volumes Docker:"
docker volume ls | grep kisse || echo "   Aucun volume Kisse trouvé"
echo ""

echo "=========================================="
echo "💡 Commandes utiles:"
echo "   Arrêter: docker-compose down"
echo "   Démarrer: docker-compose up -d"
echo "   Rebuild: docker-compose up -d --build"
echo "   Logs: docker-compose logs -f"
echo ""

