#!/bin/bash

echo "📊 État des conteneurs Kisse"
echo "============================="
echo ""

# Vérifier l'état des conteneurs
docker-compose ps

echo ""
echo "📋 Logs récents du backend:"
echo "---------------------------"
docker-compose logs --tail 20 backend

echo ""
echo "📋 Logs récents de PostgreSQL:"
echo "------------------------------"
docker-compose logs --tail 10 postgres

echo ""
echo "🔍 Vérification de santé:"
echo "-------------------------"
if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo "✅ Backend répond sur http://localhost:8080/health"
else
    echo "❌ Backend ne répond pas"
fi

echo ""
echo "💡 Commandes utiles:"
echo "   Logs en temps réel: docker-compose logs -f"
echo "   Redémarrer: docker-compose restart"
echo "   Arrêter: docker-compose down"


