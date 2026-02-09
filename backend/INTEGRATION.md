# Guide d'Intégration Flutter - Backend Rust

Ce guide explique comment intégrer l'application Flutter avec le backend Rust.

## 🔗 Architecture de Communication

```
Flutter App                    Backend Rust
─────────────────              ──────────────
                               
1. Chiffrement Signal          
   (côté client)              
                               
2. Envoi métadonnées           
   via WebSocket ────────────> Routage métadonnées
                               
3. Envoi contenu chiffré       
   via HTTPS ────────────────> Stockage opaque
                               
4. Notification destinataire   
   via WebSocket <──────────── Notification
                               
5. Récupération contenu       
   chiffré via HTTPS <──────── Récupération
                               
6. Déchiffrement Signal        
   (côté client)
```

## 📡 Configuration Flutter

Mettez à jour `lib/core/constants/app_constants.dart` :

```dart
static const String baseUrl = 'http://localhost:8080';
static const String wsUrl = 'ws://localhost:8080/ws';
static const String apiUrl = 'http://localhost:8080/api';
```

Pour un appareil physique, remplacez `localhost` par l'IP de votre machine.

## 🔐 Flux de Message Complet

### 1. Envoi de Message

```dart
// Dans websocket_service.dart

Future<void> sendMessage(String recipientId, String messageContent) async {
  // 1. Chiffrer le message avec Signal Protocol
  final encryptedMessage = await SignalService.to.encryptMessage(
    messageContent, 
    recipientId
  );
  
  // 2. Envoyer les métadonnées via WebSocket
  final messageData = {
    'type': 'message',
    'payload': {
      'messageId': encryptedMessage.id,
      'recipientId': recipientId,
      'timestamp': encryptedMessage.timestamp.toIso8601String(),
      'sessionId': encryptedMessage.sessionId,
      'messageType': 'text',
    },
  };
  _channel!.sink.add(jsonEncode(messageData));
  
  // 3. Envoyer le contenu chiffré via HTTPS
  await _sendEncryptedContent(encryptedMessage);
}

Future<void> _sendEncryptedContent(EncryptedMessage encryptedMessage) async {
  final dio = Dio();
  final token = await _secureStorage.read(key: 'auth_token');
  
  // Encoder le contenu en base64
  final contentBase64 = base64Encode(utf8.encode(encryptedMessage.encryptedContent));
  final keyBase64 = base64Encode(utf8.encode(encryptedMessage.messageKey));
  
  // Calculer le hash pour intégrité
  final hash = sha256.convert(utf8.encode(encryptedMessage.encryptedContent));
  
  final response = await dio.post(
    '${AppConstants.apiUrl}/messages/${encryptedMessage.id}/content',
    data: {
      'message_id': encryptedMessage.id,
      'content_data': contentBase64,
      'content_hash': hash.toString(),
      'expires_at': null, // Ou une date d'expiration
    },
    options: Options(
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ),
  );
}
```

### 2. Réception de Message

```dart
// Dans websocket_service.dart

void _handleIncomingMessage(Map<String, dynamic> payload) {
  final messageId = payload['messageId'];
  final senderId = payload['senderId'];
  final timestamp = DateTime.parse(payload['timestamp']);
  final messageType = payload['type'];
  
  // 1. Émettre l'événement pour l'UI
  _eventController.add(WebSocketEvent(
    type: WebSocketEventType.messageReceived,
    data: {
      'messageId': messageId,
      'senderId': senderId,
      'timestamp': timestamp.toIso8601String(),
      'type': messageType,
    },
  ));
  
  // 2. Récupérer le contenu chiffré via HTTPS
  _fetchEncryptedContent(messageId);
}

Future<void> _fetchEncryptedContent(String messageId) async {
  final dio = Dio();
  final token = await _secureStorage.read(key: 'auth_token');
  
  try {
    final response = await dio.get(
      '${AppConstants.apiUrl}/messages/$messageId/content',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
    
    final contentBase64 = response.data['content_data'];
    final contentHash = response.data['content_hash'];
    
    // Décoder le contenu
    final encryptedContent = utf8.decode(base64Decode(contentBase64));
    
    // Vérifier l'intégrité (optionnel)
    if (contentHash != null) {
      final computedHash = sha256.convert(utf8.encode(encryptedContent));
      if (computedHash.toString() != contentHash) {
        throw Exception('Content integrity check failed');
      }
    }
    
    // 3. Déchiffrer avec Signal Protocol
    final encryptedMessage = EncryptedMessage(
      id: messageId,
      recipientId: _currentUserId,
      encryptedContent: encryptedContent,
      messageKey: '', // À récupérer depuis la session Signal
      timestamp: DateTime.now(),
      sessionId: response.data['session_id'],
    );
    
    final decryptedContent = await SignalService.to.decryptMessage(encryptedMessage);
    
    // 4. Mettre à jour l'UI avec le contenu déchiffré
    _eventController.add(WebSocketEvent(
      type: WebSocketEventType.messageDecrypted,
      data: {
        'messageId': messageId,
        'content': decryptedContent,
      },
    ));
    
  } catch (e) {
    print('❌ Erreur lors de la récupération du contenu: $e');
  }
}
```

## 🔌 WebSocket Events

### Événements Envoyés (Flutter → Backend)

```dart
// Message
{
  'type': 'message',
  'payload': {
    'recipientId': 'uuid',
    'messageType': 'text',
    'sessionId': 'string'
  }
}

// Appel
{
  'type': 'call_request',
  'payload': {
    'recipientId': 'uuid',
    'callType': 'audio'
  }
}

// Présence
{
  'type': 'presence_update',
  'payload': {
    'status': 'online'
  }
}
```

### Événements Reçus (Backend → Flutter)

```dart
// Message reçu
{
  'type': 'message',
  'payload': {
    'id': 'uuid',
    'senderId': 'uuid',
    'recipientId': 'uuid',
    'messageType': 'text',
    'timestamp': '2024-01-01T00:00:00Z',
    'sessionId': 'string',
    'isRead': false
  }
}

// Appel entrant
{
  'type': 'call_request_full',
  'payload': {
    'callId': 'uuid-string',
    'callerId': 'uuid',
    'recipientId': 'uuid',
    'callType': 'audio',
    'timestamp': '2024-01-01T00:00:00Z'
  }
}
```

## 🔑 Authentification

### Connexion

```dart
// 1. Login
final response = await dio.post(
  '${AppConstants.apiUrl}/auth/login',
  data: {
    'email': email,
    'password': password,
  },
);

final token = response.data['token'];
await _secureStorage.write(key: 'auth_token', value: token);

// 2. Connexion WebSocket
final uri = Uri.parse('${AppConstants.wsUrl}?token=$token');
_channel = WebSocketChannel.connect(uri);
```

## 📝 Exemple Complet

Voir le fichier `lib/core/services/websocket_service.dart` pour l'implémentation complète.

## 🛡️ Sécurité

- ✅ Contenu chiffré stocké comme opaque binary
- ✅ Backend ne peut pas lire les messages
- ✅ Hash SHA-256 pour vérification d'intégrité
- ✅ Expiration optionnelle du contenu
- ✅ Authentification JWT requise

## 🐛 Dépannage

### Erreur de connexion WebSocket

```dart
// Vérifier le token
final token = await _secureStorage.read(key: 'auth_token');
if (token == null) {
  // Re-authentifier
}
```

### Contenu non trouvé

```dart
// Vérifier que le message existe
// Vérifier les permissions (sender ou recipient)
// Vérifier l'expiration
```

### Erreur de déchiffrement

```dart
// Vérifier la session Signal
// Vérifier les clés de session
// Vérifier l'intégrité du hash
```


