# 🔧 Guide de dépannage - Conteneurs Docker

## Problème : Les conteneurs ne se lancent plus

### 1. Diagnostic rapide

Exécutez le script de diagnostic :
```bash
cd backend
chmod +x diagnose.sh
./diagnose.sh
```

### 2. Solutions courantes

#### Solution 1 : Redémarrer les conteneurs
```bash
cd backend
chmod +x restart.sh
./restart.sh
```

#### Solution 2 : Arrêter et nettoyer
```bash
cd backend
docker-compose down
docker-compose rm -f
docker volume prune -f
docker-compose up -d --build
```

#### Solution 3 : Vérifier Docker
```bash
# Vérifier que Docker est en cours d'exécution
docker info

# Vérifier les conteneurs
docker ps -a | grep kisse

# Vérifier les logs
docker logs kisse-backend
docker logs kisse-postgres
```

#### Solution 4 : Reconstruire complètement
```bash
cd backend

# Arrêter tout
docker-compose down -v

# Supprimer les images
docker rmi kisse-backend_backend 2>/dev/null || true

# Reconstruire
docker-compose build --no-cache
docker-compose up -d
```

### 3. Erreurs courantes

#### Erreur : "Connection refused"
- **Cause** : Le backend n'est pas démarré
- **Solution** : Vérifier les logs avec `docker logs kisse-backend`

#### Erreur : "Port already in use"
- **Cause** : Un autre service utilise le port 8080 ou 5432
- **Solution** : 
  ```bash
  # Trouver le processus utilisant le port
  lsof -i :8080
  lsof -i :5432
  
  # Arrêter le processus ou changer le port dans docker-compose.yml
  ```

#### Erreur : "Failed to build"
- **Cause** : Erreur de compilation Rust
- **Solution** : Vérifier les logs de build
  ```bash
  docker-compose build --no-cache 2>&1 | tee build.log
  ```

#### Erreur : "Database connection failed"
- **Cause** : PostgreSQL n'est pas prêt
- **Solution** : Attendre que PostgreSQL soit démarré
  ```bash
  docker-compose up -d postgres
  sleep 10
  docker-compose up -d backend
  ```

### 4. Commandes utiles

```bash
# Voir l'état des conteneurs
docker-compose ps

# Voir les logs en temps réel
docker-compose logs -f

# Voir les logs d'un service spécifique
docker-compose logs -f backend
docker-compose logs -f postgres

# Entrer dans un conteneur
docker exec -it kisse-backend bash
docker exec -it kisse-postgres psql -U kisse -d kisse

# Redémarrer un service
docker-compose restart backend

# Voir l'utilisation des ressources
docker stats
```

### 5. Vérification de la santé

```bash
# Vérifier que le backend répond
curl http://localhost:8080/health

# Vérifier que PostgreSQL répond
docker exec kisse-postgres pg_isready -U kisse
```

### 6. Réinitialisation complète

⚠️ **Attention** : Cela supprimera toutes les données !

```bash
cd backend

# Arrêter et supprimer tout
docker-compose down -v
docker volume rm backend_postgres_data 2>/dev/null || true

# Reconstruire
docker-compose build --no-cache
docker-compose up -d
```

### 7. Support

Si le problème persiste :
1. Vérifier les logs : `docker-compose logs > logs.txt`
2. Vérifier la version de Docker : `docker --version`
3. Vérifier la version de Docker Compose : `docker-compose --version`
4. Vérifier les ressources système : `docker system df`

