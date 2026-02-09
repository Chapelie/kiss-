# Architecture des Appels Audio/Vidéo Sécurisés 📞

## Vue d'ensemble

L'application Kisse implémente des appels audio et vidéo sécurisés en utilisant :
- **WebRTC** pour la communication peer-to-peer
- **Signal Protocol** pour le chiffrement end-to-end
- **Backend Rust** comme passerelle aveugle (signalisation uniquement)
- **WebSocket** pour la signalisation en temps réel

## Architecture Actuelle

### Backend (Rust) ✅

Le backend gère uniquement la **signalisation** (métadonnées) :

1. **Modèles de données** (`backend/src/models.rs`)
   - `Call` : Modèle de base pour les appels
   - `CallRequest` : Demande d'appel
   - `CallResponse` : Réponse à un appel (accept, reject, busy, end)
   - `CallHistoryResponse` : Historique des appels

2. **Services** (`backend/src/services.rs`)
   - `CallService::create_call()` : Crée un appel en base
   - `CallService::accept_call()` : Accepte un appel
   - `CallService::end_call()` : Termine un appel
   - `CallService::get_active_call()` : Récupère l'appel actif
   - `CallService::get_user_call_history()` : Récupère l'historique

3. **WebSocket Handlers** (`backend/src/websocket.rs`)
   - `handle_call_request()` : Gère les demandes d'appel
   - `handle_call_response()` : Gère les réponses d'appel
   - Envoie les événements via WebSocket aux clients

4. **API REST** (`backend/src/handlers.rs`)
   - `POST /api/calls` : Démarrer un appel
   - `GET /api/calls/history` : Historique des appels
   - `GET /api/calls/active` : Appel actif

### Frontend (Flutter) ⚠️ Partiellement Implémenté

**Ce qui existe :**
- ✅ Infrastructure de base dans `app_controller.dart`
- ✅ Gestion des événements WebSocket pour les appels
- ✅ Page d'historique des appels (`calls_page.dart`)
- ✅ `agora_rtc_engine` dans les dépendances

**Ce qui manque :**
- ❌ Service WebRTC pour gérer les appels
- ❌ Interface d'appel en cours
- ❌ Intégration avec Signal Protocol pour le chiffrement
- ❌ Gestion des permissions (microphone, caméra)

## Architecture Proposée

### 1. Service WebRTC Flutter

Créer `lib/core/services/webrtc_service.dart` :

```dart
class WebRTCService extends GetxController {
  // Gestion des connexions WebRTC
  // Échange de SDP (Session Description Protocol)
  // Échange de ICE candidates
  // Chiffrement avec Signal Protocol
}
```

**Fonctionnalités :**
- Initialiser une connexion WebRTC
- Créer une offre SDP
- Traiter une réponse SDP
- Échanger les ICE candidates
- Gérer les streams audio/vidéo
- Chiffrer/déchiffrer avec Signal Protocol

### 2. Flux d'Appel Complet

#### 2.1. Initiation d'un Appel

```
1. Utilisateur A clique sur "Appeler"
   ↓
2. Flutter (A)
   ├─ Appelle API: POST /api/calls
   ├─ Initialise WebRTC (créer offre SDP)
   ├─ Chiffre l'offre SDP avec Signal Protocol
   └─ Envoie demande via WebSocket
   ↓
3. Backend Rust
   ├─ Crée l'appel en base (status: "pending")
   ├─ Vérifie que B n'est pas en appel
   └─ Envoie événement WebSocket à B
   ↓
4. Flutter (B)
   ├─ Reçoit demande d'appel (WebSocket)
   ├─ Affiche notification d'appel entrant
   └─ Attend réponse utilisateur
```

#### 2.2. Acceptation d'un Appel

```
1. Utilisateur B accepte l'appel
   ↓
2. Flutter (B)
   ├─ Initialise WebRTC (créer réponse SDP)
   ├─ Chiffre la réponse SDP avec Signal Protocol
   ├─ Envoie réponse "accept" via WebSocket
   └─ Envoie réponse SDP chiffrée via WebSocket
   ↓
3. Backend Rust
   ├─ Met à jour l'appel (status: "accepted")
   ├─ Route la réponse SDP à A (WebSocket)
   └─ Route la réponse "accept" à A (WebSocket)
   ↓
4. Flutter (A)
   ├─ Reçoit réponse "accept"
   ├─ Reçoit réponse SDP chiffrée
   ├─ Déchiffre avec Signal Protocol
   ├─ Configure WebRTC avec la réponse SDP
   └─ Démarre l'appel
```

#### 2.3. Échange de Signalisation WebRTC

```
1. Échange SDP (Session Description Protocol)
   - Offre SDP (A → B) : chiffrée avec Signal Protocol
   - Réponse SDP (B → A) : chiffrée avec Signal Protocol
   
2. Échange ICE Candidates
   - ICE candidates (A ↔ B) : chiffrés avec Signal Protocol
   - Permet la connexion peer-to-peer
   
3. Connexion WebRTC Établie
   - Communication directe entre A et B
   - Backend ne voit jamais le contenu (passerelle aveugle)
```

#### 2.4. Chiffrement avec Signal Protocol

```
1. Avant l'envoi (SDP/ICE)
   ├─ Chiffre avec Signal Protocol
   ├─ Utilise la clé de session de l'appel
   └─ Envoie via WebSocket (métadonnées)
   
2. À la réception
   ├─ Reçoit via WebSocket
   ├─ Déchiffre avec Signal Protocol
   └─ Utilise pour configurer WebRTC
```

### 3. Interface Utilisateur

#### 3.1. Page d'Appel en Cours

Créer `lib/features/calls/view/active_call_page.dart` :

```dart
class ActiveCallPage extends StatefulWidget {
  final String callId;
  final String callType; // 'audio' or 'video'
  final bool isIncoming;
  final String callerId;
  
  // Interface d'appel avec :
  // - Vue vidéo (si vidéo)
  // - Contrôles (mute, caméra, haut-parleur)
  // - Bouton raccrocher
  // - Timer d'appel
}
```

**Fonctionnalités :**
- Afficher le stream vidéo local
- Afficher le stream vidéo distant (si vidéo)
- Contrôles : mute, caméra on/off, haut-parleur
- Bouton raccrocher
- Timer d'appel
- Indicateur de connexion

#### 3.2. Notification d'Appel Entrant

Créer `lib/features/calls/view/incoming_call_dialog.dart` :

```dart
class IncomingCallDialog extends StatelessWidget {
  final String callerId;
  final String callType;
  final String callId;
  
  // Dialog avec :
  // - Nom/photo de l'appelant
  // - Type d'appel (audio/vidéo)
  // - Boutons Accepter/Rejeter
}
```

### 4. Intégration avec Signal Protocol

**Clés de Session d'Appel :**
- Générer une clé de session unique pour chaque appel
- Stocker dans `SignalService` avec l'ID d'appel
- Utiliser pour chiffrer/déchiffrer SDP et ICE candidates

**Méthodes à ajouter dans `SignalService` :**
```dart
// Chiffrer l'offre/réponse SDP
Future<String> encryptSDP(String sdp, String callId) async {
  // Générer ou récupérer la clé de session pour cet appel
  // Chiffrer le SDP
  // Retourner le SDP chiffré
}

// Déchiffrer l'offre/réponse SDP
Future<String> decryptSDP(String encryptedSDP, String callId) async {
  // Récupérer la clé de session pour cet appel
  // Déchiffrer le SDP
  // Retourner le SDP en clair
}

// Chiffrer un ICE candidate
Future<String> encryptICECandidate(String candidate, String callId) async {
  // Similaire à encryptSDP
}

// Déchiffrer un ICE candidate
Future<String> decryptICECandidate(String encryptedCandidate, String callId) async {
  // Similaire à decryptSDP
}
```

### 5. Gestion des Permissions

**Permissions requises :**
- Microphone (audio)
- Caméra (vidéo)
- Notifications (appels entrants)

**Implémentation :**
```dart
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestCallPermissions(String callType) async {
  if (callType == 'video') {
    final mic = await Permission.microphone.request();
    final camera = await Permission.camera.request();
    return mic.isGranted && camera.isGranted;
  } else {
    final mic = await Permission.microphone.request();
    return mic.isGranted;
  }
}
```

### 6. Gestion des États

**États d'un appel :**
- `pending` : En attente de réponse
- `accepted` : Appel accepté, en cours
- `rejected` : Appel rejeté
- `busy` : Destinataire occupé
- `ended` : Appel terminé
- `missed` : Appel manqué

**Gestion dans `AppController` :**
```dart
final RxBool _inCall = false.obs;
final RxString _currentCallId = ''.obs;
final RxString _currentCallType = ''.obs; // 'audio' or 'video'
final RxBool _isCallMuted = false.obs;
final RxBool _isCameraOn = false.obs;
```

## Implémentation WebRTC avec `agora_rtc_engine`

### Alternative : Utiliser Agora RTC

**Avantages :**
- Infrastructure gérée (pas besoin de serveur TURN/STUN)
- Meilleure qualité de connexion
- Support natif iOS/Android

**Inconvénients :**
- Service tiers (nécessite compte Agora)
- Coûts potentiels à grande échelle
- Moins de contrôle sur le chiffrement

**Si on utilise Agora :**
1. Créer un compte Agora
2. Obtenir App ID et Token
3. Utiliser `agora_rtc_engine` pour les appels
4. Chiffrer les streams avec Signal Protocol (optionnel mais recommandé)

### Alternative : WebRTC Natif

**Avantages :**
- Contrôle total
- Pas de dépendance externe
- Chiffrement complet avec Signal Protocol

**Inconvénients :**
- Plus complexe à implémenter
- Nécessite serveur TURN/STUN
- Gestion manuelle des connexions

**Si on utilise WebRTC natif :**
1. Utiliser `flutter_webrtc` package
2. Configurer serveur STUN/TURN
3. Implémenter l'échange SDP/ICE
4. Chiffrer avec Signal Protocol

## Recommandation

**Pour MVP :** Utiliser `agora_rtc_engine` avec chiffrement optionnel
- Plus rapide à implémenter
- Meilleure qualité de connexion
- Infrastructure gérée

**Pour Production :** Migrer vers WebRTC natif avec Signal Protocol
- Contrôle total
- Chiffrement end-to-end garanti
- Pas de dépendance externe

## Prochaines Étapes

1. ✅ Backend : Infrastructure complète
2. ⏳ Flutter : Service WebRTC
3. ⏳ Flutter : Interface d'appel en cours
4. ⏳ Flutter : Notification d'appel entrant
5. ⏳ Flutter : Intégration Signal Protocol
6. ⏳ Flutter : Gestion des permissions
7. ⏳ Tests : Appels audio/vidéo
8. ⏳ Tests : Chiffrement end-to-end

## Sécurité

**Backend (Passerelle Aveugle) :**
- ✅ Ne stocke que les métadonnées (qui, quand, durée)
- ✅ Ne voit jamais le contenu des appels
- ✅ Ne stocke pas les clés de chiffrement
- ✅ Route uniquement la signalisation chiffrée

**Frontend (Chiffrement Client-Side) :**
- ✅ SDP chiffré avec Signal Protocol
- ✅ ICE candidates chiffrés avec Signal Protocol
- ✅ Streams audio/vidéo chiffrés (si WebRTC natif)
- ✅ Clés de session stockées localement (secure storage)

## Notes Techniques

1. **STUN/TURN Servers :**
   - STUN : Pour découvrir l'adresse IP publique
   - TURN : Pour relayer le trafic si connexion directe impossible
   - Options : Google STUN, Twilio TURN, ou serveur privé

2. **ICE Candidates :**
   - Host candidate (même réseau)
   - Server reflexive candidate (via STUN)
   - Relay candidate (via TURN)

3. **Codecs Audio/Video :**
   - Audio : Opus (recommandé)
   - Vidéo : VP8/VP9 ou H.264

4. **Qualité d'Appel :**
   - Adaptation automatique selon la bande passante
   - Réduction de qualité si connexion faible
   - Indicateur de qualité pour l'utilisateur


