# API Documentation - Kisse Backend

## 🔐 Authentification

### POST /api/auth/register
Inscription d'un nouvel utilisateur

**Body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "name": "John Doe"
}
```

**Response:**
```json
{
  "token": "jwt-token",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "John Doe",
    "avatar_url": null,
    "created_at": "2024-01-01T00:00:00Z"
  }
}
```

### POST /api/auth/login
Connexion

**Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:** Même format que register

### GET /api/auth/me
Obtenir les informations de l'utilisateur connecté (requiert auth)

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "name": "John Doe",
  "avatar_url": null,
  "created_at": "2024-01-01T00:00:00Z"
}
```

## 💬 Conversations

### GET /api/conversations
Liste des conversations de l'utilisateur (requiert auth)

**Response:**
```json
[
  {
    "id": "uuid",
    "participant_id": "uuid",
    "participant_name": "Jane Doe",
    "participant_avatar": "https://...",
    "last_message": null,
    "last_message_time": "2024-01-01T00:00:00Z",
    "unread_count": 5,
    "participant_status": "online"
  }
]
```

### GET /api/conversations/:id/messages
Messages d'une conversation (requiert auth)

**Query Parameters:**
- `limit` (optionnel): Nombre de messages (défaut: 50)

**Response:**
```json
[
  {
    "id": "uuid",
    "conversation_id": "uuid",
    "sender_id": "uuid",
    "recipient_id": "uuid",
    "message_type": "text",
    "timestamp": "2024-01-01T00:00:00Z",
    "session_id": "string",
    "is_read": false
  }
]
```

### POST /api/messages/:id/read
Marquer un message comme lu (requiert auth)

### POST /api/messages/:id/content
Stocker le contenu chiffré d'un message (requiert auth)

**Body:**
```json
{
  "message_id": "uuid",
  "content_data": "base64-encoded-encrypted-content",
  "content_hash": "sha256-hash",
  "expires_at": null
}
```

**Note:** Le contenu est stocké comme opaque binary. Le backend ne peut pas le lire ou le déchiffrer.

### GET /api/messages/:id/content
Récupérer le contenu chiffré d'un message (requiert auth)

**Response:**
```json
{
  "message_id": "uuid",
  "content_data": "base64-encoded-encrypted-content",
  "content_hash": "sha256-hash",
  "created_at": "2024-01-01T00:00:00Z"
}
```

**Note:** Le contenu est retourné comme opaque binary. Le déchiffrement se fait côté client.

## 📞 Appels

### POST /api/calls
Démarrer un appel (requiert auth)

**Body:**
```json
{
  "recipient_id": "uuid",
  "call_type": "audio"
}
```

**Response:**
```json
{
  "id": "uuid",
  "call_id": "uuid-string",
  "caller_id": "uuid",
  "recipient_id": "uuid",
  "call_type": "audio",
  "status": "pending",
  "started_at": null,
  "ended_at": null,
  "duration_seconds": null,
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

### GET /api/calls/history
Historique des appels (requiert auth)

**Query Parameters:**
- `limit` (optionnel): Nombre d'appels (défaut: 50)

**Response:**
```json
[
  {
    "id": "uuid",
    "call_id": "uuid-string",
    "caller_id": "uuid",
    "recipient_id": "uuid",
    "call_type": "audio",
    "status": "ended",
    "started_at": "2024-01-01T00:00:00Z",
    "ended_at": "2024-01-01T00:05:00Z",
    "duration_seconds": 300,
    "created_at": "2024-01-01T00:00:00Z",
    "caller_name": "John Doe",
    "recipient_name": "Jane Doe"
  }
]
```

### GET /api/calls/active
Obtenir l'appel actif (requiert auth)

**Response:**
```json
{
  "id": "uuid",
  "call_id": "uuid-string",
  "caller_id": "uuid",
  "recipient_id": "uuid",
  "call_type": "audio",
  "status": "accepted",
  "started_at": "2024-01-01T00:00:00Z",
  "ended_at": null,
  "duration_seconds": null,
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

## 👤 Présence

### POST /api/presence
Mettre à jour le statut de présence (requiert auth)

**Body:**
```json
{
  "status": "online"
}
```

**Statuts possibles:** `online`, `offline`, `away`, `busy`

**Response:**
```json
{
  "user_id": "uuid",
  "status": "online",
  "last_seen": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

### GET /api/presence/:id
Obtenir le statut de présence d'un utilisateur (requiert auth)

**Response:**
```json
{
  "user_id": "uuid",
  "status": "online",
  "last_seen": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

## 🔌 WebSocket

### Connexion
```
WS /ws?token=<jwt_token>
```

### Messages WebSocket

#### Envoyer un message
```json
{
  "type": "message",
  "payload": {
    "recipient_id": "uuid",
    "message_type": "text",
    "session_id": "string"
  }
}
```

#### Démarrer un appel
```json
{
  "type": "call_request",
  "payload": {
    "recipient_id": "uuid",
    "call_type": "audio"
  }
}
```

#### Répondre à un appel
```json
{
  "type": "call_response",
  "payload": {
    "call_id": "uuid-string",
    "response": "accept"
  }
}
```

**Réponses possibles:** `accept`, `reject`, `busy`, `end`

#### Mettre à jour la présence
```json
{
  "type": "presence_update",
  "payload": {
    "status": "online"
  }
}
```

#### Indicateur de frappe
```json
{
  "type": "typing_indicator",
  "payload": {
    "conversation_id": "uuid",
    "is_typing": true
  }
}
```

#### Accusé de réception
```json
{
  "type": "read_receipt",
  "payload": {
    "message_id": "uuid"
  }
}
```

#### Heartbeat
```json
{
  "type": "heartbeat",
  "payload": {
    "timestamp": "2024-01-01T00:00:00Z"
  }
}
```

### Messages reçus via WebSocket

#### Message reçu
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

#### Demande d'appel
```json
{
  "type": "call_request_full",
  "payload": {
    "call_id": "uuid-string",
    "caller_id": "uuid",
    "recipient_id": "uuid",
    "call_type": "audio",
    "timestamp": "2024-01-01T00:00:00Z"
  }
}
```

#### Réponse d'appel
```json
{
  "type": "call_response_full",
  "payload": {
    "call_id": "uuid-string",
    "response": "accept",
    "timestamp": "2024-01-01T00:00:00Z"
  }
}
```

#### Mise à jour de présence
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

## 🔒 Codes de statut HTTP

- `200 OK` - Succès
- `201 Created` - Ressource créée
- `400 Bad Request` - Requête invalide
- `401 Unauthorized` - Non authentifié
- `403 Forbidden` - Accès refusé
- `404 Not Found` - Ressource non trouvée
- `409 Conflict` - Conflit (ex: utilisateur existe déjà, appel actif)
- `500 Internal Server Error` - Erreur serveur

