# Analyse Complète des Fonctionnalités 🔍

## Méthodologie
Pour chaque fonctionnalité, analyse du flux complet :
1. **Flutter** (Frontend) → Appels API
2. **Backend** (Rust) → Handlers & Services
3. **Base de données** → Tables & Migrations

Objectifs :
- ✅ Détecter les récidives (code dupliqué)
- ✅ Identifier le code mort
- ✅ Trouver les sources de bugs potentiels

---

## 1. AUTHENTIFICATION 🔐

### Flux Flutter → Backend → BD

#### Flutter (`api_service.dart`)
```dart
// Register
Future<Map<String, dynamic>> register({
  required String email,
  required String password,
  String? name,
})

// Login
Future<Map<String, dynamic>> login({
  required String email,
  required String password,
})

// GetMe
Future<Map<String, dynamic>> getMe()
```

#### Backend (`handlers.rs`)
```rust
// POST /api/auth/register
pub async fn register(...)

// POST /api/auth/login
pub async fn login(...)

// GET /api/auth/me
pub async fn get_me(...)
```

#### Services (`services.rs`)
```rust
// AuthService::register_user
// AuthService::authenticate_user
// AuthService::get_user_by_id
```

#### Base de données
```sql
-- Table: users
CREATE TABLE users (
    id UUID PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

### 🔴 Problèmes Détectés

1. **RÉCIDIVE** : Gestion du token répétée
   - Flutter : `api_service.dart` ligne 27, 60, 98
   - Backend : Vérification JWT répétée dans chaque handler
   - **Solution** : Middleware centralisé (déjà fait mais à vérifier)

2. **BUG POTENTIEL** : Pas de validation email côté backend
   - Flutter valide avec `GetUtils.isEmail()`
   - Backend ne valide pas le format email
   - **Risque** : Injection SQL ou emails invalides en BD

3. **CODE MORT** : `name` optionnel dans register mais jamais utilisé
   - Flutter : `name` peut être null
   - Backend : Stocke `name` mais ne l'utilise pas
   - **Action** : Vérifier si `name` est nécessaire

4. **BUG POTENTIEL** : Pas de limite de tentatives de connexion
   - Risque d'attaque brute force
   - **Solution** : Ajouter rate limiting

---

## 2. MESSAGES 💬

### Flux Flutter → Backend → BD

#### Flutter
```dart
// WebSocketService.sendMessage()
// ApiService.storeEncryptedContent()
// ApiService.getEncryptedContent()
// ApiService.markMessageAsRead()
```

#### Backend
```rust
// WebSocket: handle_message()
// POST /api/messages/:id/content
// GET /api/messages/:id/content
// POST /api/messages/:id/read
```

#### Services
```rust
// MessageService::create_message()
// EncryptedContentService::store_content()
// EncryptedContentService::get_content()
```

#### Base de données
```sql
-- Table: messages (métadonnées uniquement)
CREATE TABLE messages (
    id UUID PRIMARY KEY,
    conversation_id UUID,
    sender_id UUID,
    recipient_id UUID,
    message_type VARCHAR(50),
    timestamp TIMESTAMP,
    session_id VARCHAR(255),
    is_read BOOLEAN,
    read_at TIMESTAMP
);

-- Table: encrypted_content
CREATE TABLE encrypted_content (
    message_id UUID PRIMARY KEY,
    content_data BYTEA,
    content_hash VARCHAR(64),
    created_at TIMESTAMP,
    expires_at TIMESTAMP
);
```

### 🔴 Problèmes Détectés

1. **RÉCIDIVE** : Gestion des IDs de message dupliquée
   - Flutter : `websocket_service.dart` ligne 339 et `message_service.dart` ligne 60
   - Même logique répétée pour stocker le contenu chiffré
   - **Solution** : Centraliser dans `MessageService`

2. **BUG CRITIQUE** : `messageKey` vide lors de la récupération
   - `websocket_service.dart` ligne 386 : `messageKey: ''`
   - Le déchiffrement échouera car la clé est manquante
   - **Solution** : Récupérer la clé depuis la session Signal

3. **CODE MORT** : `updateMessageId` dans `MessageService` jamais appelé
   - Méthode définie mais jamais utilisée
   - **Action** : Supprimer ou implémenter correctement

4. **BUG POTENTIEL** : Pas de vérification que le message appartient à l'utilisateur
   - `getEncryptedContent` ne vérifie pas les permissions
   - Risque : Accès non autorisé au contenu
   - **Solution** : Vérifier `sender_id` ou `recipient_id`

5. **RÉCIDIVE** : Hash SHA-256 calculé deux fois
   - Flutter : `websocket_service.dart` ligne 330 et `message_service.dart` ligne 57
   - **Solution** : Fonction utilitaire

---

## 3. CONVERSATIONS 📋

### Flux Flutter → Backend → BD

#### Flutter
```dart
// ApiService.getConversations()
// ApiService.getMessages(conversationId)
```

#### Backend
```rust
// GET /api/conversations
// GET /api/conversations/:id/messages
```

#### Services
```rust
// ConversationService::get_user_conversations()
// MessageService::get_conversation_messages()
```

#### Base de données
```sql
-- Table: conversations
CREATE TABLE conversations (
    id UUID PRIMARY KEY,
    type VARCHAR(50), -- 'direct' or 'group'
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- Table: conversation_participants
CREATE TABLE conversation_participants (
    conversation_id UUID,
    user_id UUID,
    joined_at TIMESTAMP,
    PRIMARY KEY (conversation_id, user_id)
);
```

### 🔴 Problèmes Détectés

1. **BUG POTENTIEL** : Pas de création automatique de conversation
   - Quand un message est envoyé, la conversation n'est pas créée automatiquement
   - **Solution** : Créer la conversation si elle n'existe pas

2. **CODE MORT** : `conversation.type` jamais utilisé
   - Colonne existe mais pas de logique pour gérer les groupes
   - **Action** : Implémenter ou supprimer

3. **RÉCIDIVE** : Calcul `unread_count` répété
   - Backend : Calculé dans `get_user_conversations`
   - Flutter : Recalculé côté client
   - **Solution** : Utiliser uniquement la valeur du backend

---

## 4. APPELS 📞

### Flux Flutter → Backend → BD

#### Flutter
```dart
// ApiService.startCall()
// ApiService.getCallHistory()
// ApiService.getActiveCall()
// WebSocketService.sendCallRequest()
// WebSocketService.sendCallResponse()
```

#### Backend
```rust
// POST /api/calls
// GET /api/calls/history
// GET /api/calls/active
// WebSocket: handle_call_request()
// WebSocket: handle_call_response()
```

#### Services
```rust
// CallService::create_call()
// CallService::update_call_status()
// CallService::get_user_call_history()
// CallService::get_active_call()
```

#### Base de données
```sql
-- Table: calls
CREATE TABLE calls (
    id UUID PRIMARY KEY,
    call_id VARCHAR(255) UNIQUE,
    caller_id UUID,
    recipient_id UUID,
    call_type VARCHAR(50),
    status VARCHAR(50),
    started_at TIMESTAMP,
    ended_at TIMESTAMP,
    duration_seconds INTEGER,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

### 🔴 Problèmes Détectés

1. **BUG CRITIQUE** : Pas de vérification d'appel actif
   - Un utilisateur peut avoir plusieurs appels actifs
   - **Solution** : Vérifier avant de créer un nouvel appel

2. **RÉCIDIVE** : Formatage des timestamps dupliqué
   - Flutter : `_formatTimestamp()` dans `chat_list_page.dart` et `calls_page.dart`
   - **Solution** : Fonction utilitaire globale

3. **CODE MORT** : `call_id` et `id` dans la table `calls`
   - Deux identifiants pour la même entité
   - **Action** : Clarifier l'usage ou supprimer un

4. **BUG POTENTIEL** : Pas de timeout pour les appels en attente
   - Un appel `pending` peut rester indéfiniment
   - **Solution** : Ajouter un timeout automatique

---

## 5. PRÉSENCE 👤

### Flux Flutter → Backend → BD

#### Flutter
```dart
// ApiService.updatePresence()
// ApiService.getPresence(userId)
// WebSocketService.sendPresenceUpdate()
```

#### Backend
```rust
// POST /api/presence
// GET /api/presence/:id
// WebSocket: handle_presence_update()
```

#### Services
```rust
// PresenceService::update_presence()
// PresenceService::get_user_presence()
```

#### Base de données
```sql
-- Table: user_presence
CREATE TABLE user_presence (
    user_id UUID PRIMARY KEY,
    status VARCHAR(50),
    last_seen TIMESTAMP,
    updated_at TIMESTAMP
);
```

### 🔴 Problèmes Détectés

1. **BUG POTENTIEL** : Pas de mise à jour automatique `last_seen`
   - `last_seen` n'est mis à jour que manuellement
   - **Solution** : Mettre à jour automatiquement lors de l'activité

2. **RÉCIDIVE** : Vérification de présence dupliquée
   - Flutter : Vérifie `isOnline` dans plusieurs endroits
   - Backend : Vérifie aussi dans plusieurs handlers
   - **Solution** : Fonction utilitaire

3. **CODE MORT** : `updated_at` jamais utilisé
   - Colonne existe mais pas de logique associée
   - **Action** : Utiliser ou supprimer

---

## 6. CONTENU CHIFFRÉ 🔒

### Flux Flutter → Backend → BD

#### Flutter
```dart
// ApiService.storeEncryptedContent()
// ApiService.getEncryptedContent()
// SignalService.encryptMessage()
// SignalService.decryptMessage()
```

#### Backend
```rust
// POST /api/messages/:id/content
// GET /api/messages/:id/content
```

#### Services
```rust
// EncryptedContentService::store_content()
// EncryptedContentService::get_content()
```

#### Base de données
```sql
-- Table: encrypted_content
CREATE TABLE encrypted_content (
    message_id UUID PRIMARY KEY,
    content_data BYTEA,
    content_hash VARCHAR(64),
    created_at TIMESTAMP,
    expires_at TIMESTAMP
);
```

### 🔴 Problèmes Détectés

1. **BUG CRITIQUE** : `messageKey` manquant lors du déchiffrement
   - `websocket_service.dart` ligne 386 : `messageKey: ''`
   - Le déchiffrement échouera
   - **Solution** : Stocker la clé ou la récupérer depuis la session

2. **BUG POTENTIEL** : Pas de nettoyage automatique des contenus expirés
   - `expires_at` existe mais pas de job de nettoyage
   - **Solution** : Ajouter un cron job

3. **RÉCIDIVE** : Encodage/décodage base64 dupliqué
   - Flutter : `websocket_service.dart` et `message_service.dart`
   - **Solution** : Fonctions utilitaires

4. **BUG POTENTIEL** : Pas de vérification d'intégrité côté backend
   - Le hash est stocké mais jamais vérifié
   - **Solution** : Vérifier le hash lors de la récupération

---

## RÉSUMÉ DES PROBLÈMES

### 🔴 Bugs Critiques (À corriger immédiatement)
1. `messageKey` vide lors du déchiffrement
2. Pas de vérification d'appel actif
3. Pas de vérification de permissions pour `getEncryptedContent`

### ⚠️ Bugs Potentiels (À surveiller)
1. Pas de validation email côté backend
2. Pas de rate limiting pour l'authentification
3. Pas de timeout pour les appels en attente
4. Pas de nettoyage automatique des contenus expirés

### 🔄 Récidives (Code dupliqué)
1. Gestion des tokens (3+ endroits)
2. Calcul du hash SHA-256 (2 endroits)
3. Formatage des timestamps (2 endroits)
4. Encodage/décodage base64 (2 endroits)
5. Gestion des IDs de message (2 endroits)

### 💀 Code Mort
1. `updateMessageId` jamais appelé
2. `conversation.type` jamais utilisé
3. `updated_at` dans `user_presence` jamais utilisé
4. `name` optionnel dans register mais peu utilisé

---

## PLAN D'ACTION

### Priorité 1 (Critique)
- [ ] Corriger `messageKey` vide
- [ ] Ajouter vérification permissions `getEncryptedContent`
- [ ] Ajouter vérification d'appel actif

### Priorité 2 (Important)
- [ ] Ajouter validation email côté backend
- [ ] Ajouter rate limiting
- [ ] Centraliser la gestion des tokens

### Priorité 3 (Amélioration)
- [ ] Supprimer le code mort
- [ ] Créer fonctions utilitaires pour récidives
- [ ] Ajouter nettoyage automatique

