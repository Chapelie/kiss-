#!/bin/bash

echo "🔄 Redémarrage des conteneurs Kisse"
echo "===================================="
echo ""

# Aller dans le répertoire backend
cd "$(dirname "$0")"

# Arrêter les conteneurs existants
echo "⏹️  Arrêt des conteneurs existants..."
docker-compose down
echo ""

# Nettoyer les conteneurs arrêtés
echo "🧹 Nettoyage des conteneurs arrêtés..."
docker-compose rm -f
echo ""

# Reconstruire et démarrer
echo "🔨 Reconstruction et démarrage des conteneurs..."
docker-compose up -d --build
echo ""

# Attendre que les conteneurs soient prêts
echo "⏳ Attente du démarrage des conteneurs..."
sleep 5

# Vérifier l'état
echo "📊 État des conteneurs:"
docker-compose ps
echo ""

# Afficher les logs
echo "📋 Logs récents:"
docker-compose logs --tail 20
echo ""

echo "✅ Redémarrage terminé!"
echo ""
echo "💡 Pour voir les logs en temps réel: docker-compose logs -f"
echo "💡 Pour arrêter: docker-compose down"

