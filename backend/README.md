# Kisse Backend - Rust/Tokio

Backend pour l'application Kisse, une messagerie sécurisée avec chiffrement de bout en bout.

## 🔐 Architecture de Sécurité

**IMPORTANT : Ce backend est UNIQUEMENT une passerelle de routage. Il ne stocke JAMAIS de contenu chiffré et n'a JAMAIS accès aux clés de chiffrement.**

Le protocole Signal est géré entièrement côté client Flutter. Le backend :
- ✅ Route uniquement les métadonnées (IDs, timestamps, types)
- ✅ Gère les connexions WebSocket
- ✅ Authentifie les utilisateurs
- ❌ Ne stocke JAMAIS de contenu chiffré
- ❌ N'a JAMAIS accès aux clés de chiffrement
- ❌ Ne peut PAS déchiffrer les messages

Voir [SECURITY.md](./SECURITY.md) pour plus de détails sur l'architecture de sécurité.

## 🚀 Technologies

- **Rust** - Langage de programmation
- **Tokio** - Runtime asynchrone
- **Axum** - Framework web moderne
- **SQLx** - ORM asynchrone pour PostgreSQL
- **WebSocket** - Communication temps réel
- **JWT** - Authentification
- **Docker** - Containerisation

## 📋 Prérequis

- Rust 1.75+
- Docker & Docker Compose
- PostgreSQL (ou via Docker)

## 🛠️ Installation

### Avec Docker (Recommandé)

1. Clonez le repository
2. Copiez le fichier `.env.example` vers `.env` et modifiez les valeurs si nécessaire
3. Lancez les services avec Docker Compose:

```bash
docker-compose up -d
```

Le backend sera accessible sur `http://localhost:8080`

### Installation locale

1. Installez Rust: https://rustup.rs/
2. Installez PostgreSQL
3. Créez une base de données:

```sql
CREATE DATABASE kisse;
```

4. Copiez `.env.example` vers `.env` et configurez:

```bash
cp .env.example .env
```

5. Exécutez les migrations:

```bash
sqlx migrate run
```

6. Lancez le serveur:

```bash
cargo run
```

## 📡 API Endpoints

### Authentification

- `POST /api/auth/register` - Inscription
- `POST /api/auth/login` - Connexion
- `GET /api/auth/me` - Informations utilisateur (requiert auth)

### Conversations

- `GET /api/conversations` - Liste des conversations (requiert auth)
- `GET /api/conversations/:id/messages` - Messages d'une conversation (requiert auth)
- `POST /api/messages/:id/read` - Marquer un message comme lu (requiert auth)

### WebSocket

- `WS /ws?token=<jwt_token>` - Connexion WebSocket pour communication temps réel

## 🔌 WebSocket Messages

### Types de messages

```json
{
  "type": "message",
  "payload": {
    "id": "uuid",
    "conversation_id": "uuid",
    "sender_id": "uuid",
    "recipient_id": "uuid",
    "message_type": "text",
    "timestamp": "2024-01-01T00:00:00Z",
    "session_id": "string",
    "is_read": false
  }
}
```

```json
{
  "type": "call_request",
  "payload": {
    "call_id": "string",
    "caller_id": "uuid",
    "recipient_id": "uuid",
    "call_type": "audio",
    "timestamp": "2024-01-01T00:00:00Z"
  }
}
```

```json
{
  "type": "typing_indicator",
  "payload": {
    "user_id": "uuid",
    "conversation_id": "uuid",
    "is_typing": true,
    "timestamp": "2024-01-01T00:00:00Z"
  }
}
```

```json
{
  "type": "presence_update",
  "payload": {
    "user_id": "uuid",
    "status": "online",
    "last_seen": "2024-01-01T00:00:00Z"
  }
}
```

## 🔐 Sécurité

- **JWT Authentication** - Tous les endpoints protégés nécessitent un token JWT
- **Chiffrement de bout en bout** - Le contenu des messages n'est jamais stocké en clair
- **Métadonnées uniquement** - Seules les métadonnées transitent via WebSocket (RG39)
- **Hachage des mots de passe** - Utilisation de bcrypt

## 🗄️ Base de données

### Tables principales

- `users` - Utilisateurs
- `conversations` - Conversations entre utilisateurs
- `messages` - Métadonnées des messages (pas le contenu chiffré)

### Migrations

Les migrations SQL sont dans le dossier `migrations/`. Pour créer une nouvelle migration:

```bash
sqlx migrate add <nom_migration>
```

## 🧪 Tests

```bash
cargo test
```

## 📝 Configuration

Variables d'environnement:

- `SERVER_ADDRESS` - Adresse du serveur (défaut: `0.0.0.0:8080`)
- `DATABASE_URL` - URL de connexion PostgreSQL
- `JWT_SECRET` - Clé secrète pour JWT
- `JWT_EXPIRATION` - Durée d'expiration du token en secondes

## 🐳 Docker

### Build

```bash
docker-compose build
```

### Logs

```bash
docker-compose logs -f backend
```

### Arrêt

```bash
docker-compose down
```

### Nettoyage complète

```bash
docker-compose down -v
```

## 🔄 Intégration avec Flutter

Le backend est conçu pour fonctionner avec l'application Flutter Kisse. 

### Configuration Flutter

Mettez à jour les URLs dans `lib/core/constants/app_constants.dart`:

```dart
static const String baseUrl = 'http://localhost:8080';
static const String wsUrl = 'ws://localhost:8080/ws';
static const String apiUrl = 'http://localhost:8080/api';
```

Pour les tests sur un appareil physique, utilisez l'IP de votre machine au lieu de `localhost`.

## 📚 Structure du projet

```
backend/
├── src/
│   ├── main.rs          # Point d'entrée
│   ├── config.rs        # Configuration
│   ├── database.rs      # Gestion de la base de données
│   ├── models.rs        # Modèles de données
│   ├── services.rs      # Services métier
│   ├── handlers.rs      # Handlers HTTP
│   ├── routes.rs         # Routes API
│   └── websocket.rs      # Gestion WebSocket
├── migrations/          # Migrations SQL
├── Dockerfile
├── docker-compose.yml
└── Cargo.toml
```

## 🐛 Débogage

Pour activer les logs détaillés:

```bash
RUST_LOG=debug cargo run
```

Ou dans Docker:

```bash
docker-compose up -e RUST_LOG=debug
```

## 📄 Licence

Voir le fichier LICENSE du projet principal.

