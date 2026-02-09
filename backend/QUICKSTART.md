# Guide de Démarrage Rapide - Kisse Backend

## 🚀 Démarrage avec Docker (Recommandé)

### 1. Prérequis
- Docker et Docker Compose installés

### 2. Démarrer les services

```bash
cd backend
docker-compose up -d
```

Cela va :
- Démarrer PostgreSQL sur le port 5432
- Démarrer le backend Rust sur le port 8080
- Exécuter automatiquement les migrations

### 3. Vérifier que tout fonctionne

```bash
# Vérifier les logs
docker-compose logs -f backend

# Tester l'endpoint de santé
curl http://localhost:8080/health
```

### 4. Arrêter les services

```bash
docker-compose down
```

## 🔧 Démarrage Local (Sans Docker)

### 1. Prérequis
- Rust 1.75+
- PostgreSQL 16+
- SQLx CLI: `cargo install sqlx-cli`

### 2. Configuration

```bash
# Créer la base de données
createdb kisse

# Configurer les variables d'environnement
export DATABASE_URL=postgresql://kisse:password@localhost:5432/kisse
export JWT_SECRET=your-secret-key-change-in-production
export JWT_EXPIRATION=3600
export SERVER_ADDRESS=0.0.0.0:8080
```

Ou créer un fichier `.env`:

```bash
cp .env.example .env
# Éditer .env avec vos valeurs
```

### 3. Migrations

```bash
sqlx migrate run
```

### 4. Lancer le serveur

```bash
cargo run
```

## 📡 Tester l'API

### Inscription

```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "name": "Test User"
  }'
```

### Connexion

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

Vous recevrez un token JWT. Utilisez-le pour les requêtes authentifiées:

```bash
TOKEN="votre-token-jwt"

# Obtenir les informations de l'utilisateur
curl http://localhost:8080/api/auth/me \
  -H "Authorization: Bearer $TOKEN"

# Obtenir les conversations
curl http://localhost:8080/api/conversations \
  -H "Authorization: Bearer $TOKEN"
```

## 🔌 Tester WebSocket

Vous pouvez utiliser un client WebSocket comme `websocat`:

```bash
# Installer websocat
cargo install websocat

# Se connecter (remplacez TOKEN par votre token JWT)
websocat "ws://localhost:8080/ws?token=TOKEN"
```

## 📱 Configuration Flutter

Mettez à jour `lib/core/constants/app_constants.dart`:

```dart
static const String baseUrl = 'http://localhost:8080';
static const String wsUrl = 'ws://localhost:8080/ws';
static const String apiUrl = 'http://localhost:8080/api';
```

Pour tester sur un appareil physique, remplacez `localhost` par l'IP de votre machine.

## 🐛 Dépannage

### Le backend ne démarre pas

```bash
# Vérifier les logs
docker-compose logs backend

# Vérifier que PostgreSQL est prêt
docker-compose ps
```

### Erreurs de connexion à la base de données

Vérifiez que:
- PostgreSQL est démarré
- Les variables d'environnement sont correctes
- La base de données existe

### Erreurs de migration

```bash
# Réinitialiser la base de données (⚠️ supprime toutes les données)
docker-compose down -v
docker-compose up -d
```

## 📚 Documentation

Voir `README.md` pour plus de détails.


