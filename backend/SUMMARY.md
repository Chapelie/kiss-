# Résumé du Backend Kisse

## ✅ Fonctionnalités Implémentées

### 🔐 Authentification
- ✅ Inscription (POST /api/auth/register)
- ✅ Connexion (POST /api/auth/login)
- ✅ Informations utilisateur (GET /api/auth/me)
- ✅ JWT avec expiration configurable
- ✅ Hachage bcrypt des mots de passe

### 💬 Messages
- ✅ Création de métadonnées de message
- ✅ Stockage de contenu chiffré (opaque binary)
- ✅ Récupération de contenu chiffré
- ✅ Historique des messages
- ✅ Accusés de réception
- ✅ Statuts de lecture

### 🔌 WebSocket Temps Réel
- ✅ Connexion authentifiée
- ✅ Messages en temps réel
- ✅ Appels (audio/vidéo)
- ✅ Présence (online/offline/away/busy)
- ✅ Indicateurs de frappe
- ✅ Heartbeat

### 📞 Appels
- ✅ Création d'appel
- ✅ Acceptation/Rejet d'appel
- ✅ Gestion des appels actifs
- ✅ Historique des appels
- ✅ Statuts d'appel (pending, accepted, rejected, busy, ended, missed)

### 👤 Présence
- ✅ Mise à jour de statut
- ✅ Récupération de statut
- ✅ Synchronisation avec WebSocket
- ✅ Intégration dans les conversations

### 🗄️ Base de Données
- ✅ Tables: users, conversations, messages, calls, user_presence, encrypted_content
- ✅ Migrations automatiques
- ✅ Indexes pour performance
- ✅ Relations et contraintes

## 🔐 Architecture de Sécurité

### Principe Fondamental
**Le backend est UNIQUEMENT une passerelle de routage. Il ne stocke JAMAIS de contenu chiffré lisible et n'a JAMAIS accès aux clés de chiffrement.**

### Ce qui est Stocké
- ✅ Métadonnées (IDs, timestamps, types)
- ✅ Contenu chiffré comme opaque binary (non lisible)
- ✅ Statuts et présences
- ✅ Historique des appels

### Ce qui N'est PAS Stocké
- ❌ Contenu déchiffré
- ❌ Clés de chiffrement
- ❌ Clés Signal Protocol
- ❌ Données sensibles lisibles

## 📁 Structure du Projet

```
backend/
├── src/
│   ├── main.rs          # Point d'entrée
│   ├── config.rs        # Configuration
│   ├── database.rs      # Gestion PostgreSQL
│   ├── models.rs        # Modèles de données
│   ├── services.rs      # Services métier
│   ├── handlers.rs      # Handlers HTTP
│   ├── routes.rs        # Routes API
│   ├── websocket.rs     # Gestion WebSocket
│   └── security.rs      # Documentation sécurité
├── migrations/
│   ├── 001_initial.sql              # Tables de base
│   ├── 002_calls_and_presence.sql   # Appels et présence
│   └── 003_encrypted_content.sql     # Stockage contenu chiffré
├── Dockerfile
├── docker-compose.yml
├── Cargo.toml
├── README.md
├── SECURITY.md
├── API.md
├── INTEGRATION.md
└── QUICKSTART.md
```

## 🚀 Démarrage Rapide

### Avec Docker
```bash
cd backend
docker-compose up -d
```

### Local
```bash
export DATABASE_URL=postgresql://kisse:password@localhost:5432/kisse
export JWT_SECRET=your-secret-key
cargo run
```

## 📡 Endpoints Principaux

### Authentification
- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/auth/me`

### Messages
- `GET /api/conversations`
- `GET /api/conversations/:id/messages`
- `POST /api/messages/:id/read`
- `POST /api/messages/:id/content` (stockage contenu chiffré)
- `GET /api/messages/:id/content` (récupération contenu chiffré)

### Appels
- `POST /api/calls`
- `GET /api/calls/history`
- `GET /api/calls/active`

### Présence
- `POST /api/presence`
- `GET /api/presence/:id`

### WebSocket
- `WS /ws?token=<jwt>`

## 🔗 Intégration Flutter

Voir [INTEGRATION.md](./INTEGRATION.md) pour le guide complet d'intégration.

### Configuration Flutter
```dart
static const String baseUrl = 'http://localhost:8080';
static const String wsUrl = 'ws://localhost:8080/ws';
static const String apiUrl = 'http://localhost:8080/api';
```

## 📚 Documentation

- [README.md](./README.md) - Documentation principale
- [SECURITY.md](./SECURITY.md) - Architecture de sécurité
- [API.md](./API.md) - Documentation API complète
- [INTEGRATION.md](./INTEGRATION.md) - Guide d'intégration Flutter
- [QUICKSTART.md](./QUICKSTART.md) - Guide de démarrage rapide

## ✅ Statut

Le backend est **complet et prêt pour l'intégration** avec l'application Flutter.

Toutes les fonctionnalités développées dans Flutter sont implémentées côté backend avec une architecture de sécurité respectant le protocole Signal (passerelle aveugle).


