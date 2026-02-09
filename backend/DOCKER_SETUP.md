# Guide d'Installation et Démarrage Docker 🐳

## 📋 Prérequis

### 1. Installer Docker Desktop

**Sur macOS :**
```bash
# Option 1: Via Homebrew (recommandé)
brew install --cask docker

# Option 2: Télécharger depuis le site officiel
# https://www.docker.com/products/docker-desktop/
```

**Après installation :**
1. Ouvrez Docker Desktop
2. Attendez que Docker soit complètement démarré (icône Docker dans la barre de menu)
3. Vérifiez l'installation :
```bash
docker --version
docker compose version
```

## 🚀 Démarrage Rapide

### Méthode 1 : Script automatique (Recommandé)

```bash
cd backend
./start.sh
```

### Méthode 2 : Commandes manuelles

```bash
cd backend

# 1. Arrêter les conteneurs existants (si nécessaire)
docker compose down

# 2. Construire les images
docker compose build

# 3. Démarrer les services
docker compose up -d

# 4. Voir les logs
docker compose logs -f
```

## 📊 Vérification

### Vérifier que tout fonctionne :

```bash
# Vérifier l'état des conteneurs
docker compose ps

# Tester l'API
curl http://localhost:8080/health

# Voir les logs du backend
docker compose logs backend

# Voir les logs de PostgreSQL
docker compose logs postgres
```

## 🔧 Commandes Utiles

### Voir les logs en temps réel
```bash
docker compose logs -f
```

### Arrêter les services
```bash
docker compose down
```

### Redémarrer les services
```bash
docker compose restart
```

### Reconstruire après modification du code
```bash
docker compose build --no-cache
docker compose up -d
```

### Accéder à la base de données
```bash
docker compose exec postgres psql -U kisse -d kisse
```

### Nettoyer complètement (supprime les volumes)
```bash
docker compose down -v
```

## 🌐 URLs des Services

Une fois démarré, les services sont disponibles sur :

- **API REST** : http://localhost:8080
- **WebSocket** : ws://localhost:8080/ws
- **Health Check** : http://localhost:8080/health
- **PostgreSQL** : localhost:5432
  - User: `kisse`
  - Password: `password`
  - Database: `kisse`

## 🐛 Dépannage

### Docker n'est pas démarré
```bash
# Ouvrir Docker Desktop manuellement
open -a Docker
```

### Port déjà utilisé
```bash
# Vérifier quel processus utilise le port 8080
lsof -i :8080

# Ou changer le port dans docker-compose.yml
# ports:
#   - "8081:8080"  # Utiliser 8081 au lieu de 8080
```

### Erreur de build
```bash
# Nettoyer et reconstruire
docker compose down
docker compose build --no-cache
docker compose up -d
```

### Base de données ne démarre pas
```bash
# Vérifier les logs
docker compose logs postgres

# Supprimer le volume et redémarrer
docker compose down -v
docker compose up -d
```

### Le backend ne se connecte pas à la base
```bash
# Vérifier que PostgreSQL est prêt
docker compose exec postgres pg_isready -U kisse

# Vérifier les variables d'environnement
docker compose exec backend env | grep DATABASE_URL
```

## 📝 Configuration

Les variables d'environnement sont définies dans `docker-compose.yml` :

```yaml
environment:
  SERVER_ADDRESS: 0.0.0.0:8080
  DATABASE_URL: postgresql://kisse:password@postgres:5432/kisse
  JWT_SECRET: your-secret-key-change-in-production
  JWT_EXPIRATION: 3600
```

Pour modifier ces valeurs, éditez `docker-compose.yml` et redémarrez :
```bash
docker compose down
docker compose up -d
```

## ✅ Checklist de Démarrage

- [ ] Docker Desktop installé et démarré
- [ ] `docker --version` fonctionne
- [ ] `docker compose version` fonctionne
- [ ] Dans le répertoire `backend/`
- [ ] Exécuté `./start.sh` ou `docker compose up -d`
- [ ] Vérifié avec `docker compose ps`
- [ ] Testé `curl http://localhost:8080/health`

## 🎯 Prochaines Étapes

Une fois Docker démarré :

1. **Tester l'API** :
   ```bash
   curl http://localhost:8080/health
   ```

2. **Créer un utilisateur** :
   ```bash
   curl -X POST http://localhost:8080/api/auth/register \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"password123","name":"Test User"}'
   ```

3. **Connecter l'application Flutter** :
   - Modifier `lib/core/constants/app_constants.dart` si nécessaire
   - L'URL par défaut est déjà `http://localhost:8080`

---

**Besoin d'aide ?** Consultez les logs avec `docker compose logs -f`


