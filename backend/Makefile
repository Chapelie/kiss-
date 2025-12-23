.PHONY: help docker-build docker-up docker-down docker-logs docker-restart docker-clean test

help: ## Affiche l'aide
	@echo "Commandes disponibles:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

docker-build: ## Construire les images Docker
	docker compose build

docker-up: ## Démarrer les services Docker
	docker compose up -d

docker-down: ## Arrêter les services Docker
	docker compose down

docker-logs: ## Voir les logs des services
	docker compose logs -f

docker-restart: ## Redémarrer les services
	docker compose restart

docker-clean: ## Nettoyer complètement (supprime volumes)
	docker compose down -v

docker-rebuild: ## Reconstruire et redémarrer
	docker compose build --no-cache
	docker compose up -d

test: ## Tester l'API
	@echo "Test du health check..."
	@curl -s http://localhost:8080/health || echo "❌ Le serveur n'est pas démarré"
	@echo ""
	@echo "État des conteneurs:"
	@docker compose ps

start: docker-build docker-up ## Construire et démarrer (commande complète)
	@echo "✅ Services démarrés !"
	@echo "📍 API: http://localhost:8080"
	@echo "📍 WebSocket: ws://localhost:8080/ws"
	@echo ""
	@echo "Pour voir les logs: make docker-logs"

stop: docker-down ## Arrêter les services
