# 🐳 Configuration Docker - Backend Kisse

## ✅ Configuration optimisée pour Docker uniquement

Le backend est configuré pour fonctionner **uniquement dans Docker**. Tous les chemins et configurations sont optimisés pour l'environnement Docker.

## 📋 Configuration Docker

### Services Docker Compose

1. **PostgreSQL** (`kisse-postgres`)
   - Image : `postgres:16-alpine`
   - Port : `5432:5432`
   - Base de données : `kisse`
   - Utilisateur : `kisse` / Mot de passe : `password`
   - Volume persistant : `postgres_data`

2. **Backend** (`kisse-backend`)
   - Build depuis `Dockerfile`
   - Port : `8080:8080`
   - Écoute sur : `0.0.0.0:8080` (accessible depuis l'extérieur)
   - Base de données : `postgresql://kisse:password@postgres:5432/kisse`
   - Dépend de PostgreSQL (attend qu'il soit `healthy`)

### Chemins dans Docker

- **Working directory** : `/app`
- **Migrations** : `/app/migrations` (copiées dans l'image)
- **Binaire** : `/app/kisse-backend`

## 🚀 Commandes Docker

### Démarrer les conteneurs

```bash
cd backend
docker-compose up -d
```

### Vérifier l'état

```bash
docker-compose ps
```

### Voir les logs

```bash
# Tous les services
docker-compose logs -f

# Backend uniquement
docker-compose logs -f backend

# PostgreSQL uniquement
docker-compose logs -f postgres
```

### Reconstruire et redémarrer

```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Arrêter

```bash
docker-compose down
```

### Arrêter et supprimer les volumes (⚠️ supprime les données)

```bash
docker-compose down -v
```

## 🔧 Configuration réseau Docker

### Connexion entre conteneurs

- **Backend → PostgreSQL** : Utilise le nom du service `postgres` (pas `localhost`)
- **URL de connexion** : `postgresql://kisse:password@postgres:5432/kisse`

### Accès depuis l'extérieur

- **API REST** : `http://localhost:8080/api`
- **WebSocket** : `ws://localhost:8080/ws`
- **Health Check** : `http://localhost:8080/health`

### Pour l'émulateur Android

- Utilisez `http://10.0.2.2:8080` au lieu de `localhost`

## 📁 Structure dans Docker

```
/app/
├── kisse-backend          # Binaire compilé
└── migrations/            # Fichiers de migration SQL
    ├── 001_initial.sql
    ├── 002_calls_and_presence.sql
    ├── 003_encrypted_content.sql
    ├── 004_add_username.sql
    ├── 005_stories.sql
    └── 006_channels.sql
```

## 🔍 Vérification

### Vérifier que le backend répond

```bash
curl http://localhost:8080/health
```

Devrait retourner : `OK`

### Vérifier la connexion à la base de données

```bash
docker exec kisse-postgres psql -U kisse -d kisse -c "SELECT version();"
```

### Entrer dans le conteneur backend

```bash
docker exec -it kisse-backend bash
```

### Voir les variables d'environnement

```bash
docker exec kisse-backend env | grep -E "SERVER_ADDRESS|DATABASE_URL|JWT"
```

## 🐛 Dépannage

### Le backend est en "Restarting"

1. Voir les logs : `docker logs kisse-backend --tail 50`
2. Vérifier la connexion à PostgreSQL : `docker exec kisse-postgres pg_isready -U kisse`
3. Corriger la base de données si nécessaire : `./fix_database.sh`

### Erreur de migration

```bash
# Arrêter le backend
docker-compose stop backend

# Corriger la base de données
./fix_database.sh

# Redémarrer
docker-compose up -d backend
```

### Port déjà utilisé

```bash
# Vérifier quel processus utilise le port
lsof -i :8080
lsof -i :5432

# Arrêter le processus ou changer le port dans docker-compose.yml
```

## 📝 Notes importantes

1. **Migrations** : Les migrations sont **copiées dans l'image Docker** au moment du build. Pas besoin de volume mount.

2. **Base de données** : Utilise le nom du service Docker `postgres`, pas `localhost`.

3. **Variables d'environnement** : Définies dans `docker-compose.yml`, pas besoin de fichier `.env`.

4. **Persistance** : Les données PostgreSQL sont stockées dans le volume Docker `postgres_data`.

5. **Restart policy** : `unless-stopped` - les conteneurs redémarrent automatiquement sauf si arrêtés manuellement.

