# 🐳 Démarrage Docker - Guide Rapide

## Installation Docker (si nécessaire)

### macOS
```bash
# Via Homebrew
brew install --cask docker

# Ou télécharger depuis https://www.docker.com/products/docker-desktop/
```

**Important** : Ouvrez Docker Desktop après l'installation et attendez qu'il soit complètement démarré.

## 🚀 Démarrage en 3 étapes

```bash
# 1. Aller dans le dossier backend
cd backend

# 2. Lancer Docker (choisir une méthode)

# Méthode A : Script automatique
./start.sh

# Méthode B : Commandes manuelles
docker compose build
docker compose up -d

# 3. Vérifier que tout fonctionne
curl http://localhost:8080/health
```

## ✅ Vérification

```bash
# Voir l'état des conteneurs
docker compose ps

# Voir les logs
docker compose logs -f

# Tester l'API
curl http://localhost:8080/health
```

## 🛑 Arrêt

```bash
# Arrêter les services
docker compose down

# Ou utiliser le script
./stop.sh
```

## 📍 Services disponibles

- **API** : http://localhost:8080
- **WebSocket** : ws://localhost:8080/ws
- **PostgreSQL** : localhost:5432

## 🐛 Problèmes courants

**Docker n'est pas démarré** :
```bash
open -a Docker
```

**Port déjà utilisé** :
- Modifier le port dans `docker-compose.yml` (ligne 32)

**Erreur de build** :
```bash
docker compose build --no-cache
docker compose up -d
```

---

**Pour plus de détails** : Voir `DOCKER_SETUP.md`

