#!/bin/bash

echo "🔧 Correction de la base de données"
echo "===================================="
echo ""

# Vérifier que PostgreSQL est en cours d'exécution
if ! docker ps | grep -q kisse-postgres; then
    echo "❌ Le conteneur PostgreSQL n'est pas en cours d'exécution"
    echo "   Démarrez-le avec: docker-compose up -d postgres"
    exit 1
fi

echo "✅ PostgreSQL est en cours d'exécution"
echo ""

# Exécuter le script de correction
echo "📝 Exécution du script de correction..."
docker exec -i kisse-postgres psql -U kisse -d kisse < scripts/fix_username_constraint.sql

if [ $? -eq 0 ]; then
    echo "✅ Base de données corrigée avec succès"
    echo ""
    echo "🔄 Redémarrez le backend avec:"
    echo "   docker-compose restart backend"
else
    echo "❌ Erreur lors de la correction"
    exit 1
fi

