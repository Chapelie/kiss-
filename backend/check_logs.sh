#!/bin/bash

echo "📋 Logs du conteneur backend:"
echo "=============================="
docker logs kisse-backend --tail 50
echo ""
echo "=============================="
echo ""
echo "💡 Pour voir les logs en temps réel:"
echo "   docker logs -f kisse-backend"

