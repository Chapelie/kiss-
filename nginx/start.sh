#!/bin/bash
# Script pour démarrer Nginx avec Docker

echo "🚀 Démarrage de Nginx pour Kisse..."

# Créer les dossiers nécessaires
mkdir -p logs static

# Vérifier que la configuration Nginx est valide
echo "📋 Vérification de la configuration Nginx..."
docker run --rm -v "$(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro" nginx:alpine nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuration Nginx valide"
else
    echo "❌ Erreur dans la configuration Nginx"
    exit 1
fi

# Démarrer Nginx
echo "🌐 Démarrage du conteneur Nginx..."
docker-compose -f docker-compose.nginx.yml up -d

if [ $? -eq 0 ]; then
    echo "✅ Nginx démarré avec succès"
    echo "📊 Vérification du statut..."
    docker-compose -f docker-compose.nginx.yml ps
    echo ""
    echo "📝 Logs disponibles dans: nginx/logs/"
    echo "🔍 Pour voir les logs: docker-compose -f docker-compose.nginx.yml logs -f nginx"
else
    echo "❌ Erreur lors du démarrage de Nginx"
    exit 1
fi


