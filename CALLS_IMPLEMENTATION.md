# Implémentation des Appels - Guide Complet 📞

## ✅ Implémentation Terminée

L'implémentation complète des appels audio/vidéo est maintenant terminée pour Flutter et le backend Rust.

## 📋 Fichiers Créés/Modifiés

### Backend (Rust) ✅
- **Déjà implémenté** : Infrastructure complète pour les appels
  - `backend/src/models.rs` : Modèles `Call`, `CallRequest`, `CallResponse`
  - `backend/src/services.rs` : `CallService` avec toutes les méthodes
  - `backend/src/handlers.rs` : Handlers API REST pour les appels
  - `backend/src/websocket.rs` : Gestion WebSocket des appels
  - `backend/src/routes.rs` : Routes API pour les appels

### Frontend (Flutter) ✨

#### Nouveaux Fichiers
1. **`lib/core/services/agora_service.dart`**
   - Service Agora RTC pour gérer les appels
   - Gestion des permissions
   - Contrôles (mute, vidéo, haut-parleur)
   - Callbacks pour les événements

2. **`lib/features/calls/view/active_call_page.dart`**
   - Interface d'appel en cours
   - Vue audio et vidéo
   - Contrôles pendant l'appel
   - Timer d'appel

3. **`lib/features/calls/view/incoming_call_dialog.dart`**
   - Dialog pour les appels entrants
   - Boutons Accepter/Rejeter
   - Design adaptatif iOS/Android

#### Fichiers Modifiés
1. **`lib/core/controllers/app_controller.dart`**
   - Méthodes `startCall()`, `acceptCall()`, `rejectCall()`, `endCall()`
   - Gestion des événements WebSocket pour les appels
   - Navigation automatique vers la page d'appel
   - Récupération des informations utilisateur

2. **`lib/features/calls/view/calls_page.dart`**
   - Chargement de l'historique depuis l'API
   - Chargement des contacts depuis les conversations
   - Boutons pour démarrer des appels
   - Rappel depuis l'historique

3. **`lib/main.dart`**
   - Initialisation d'`AgoraService` au démarrage

## 🔧 Configuration Requise

### 1. Agora App ID

**Important** : Vous devez configurer votre App ID Agora dans `lib/core/services/agora_service.dart` :

```dart
static const String appId = 'YOUR_AGORA_APP_ID'; // À remplacer
```

**Pour obtenir un App ID :**
1. Créer un compte sur [Agora.io](https://www.agora.io)
2. Créer un nouveau projet
3. Récupérer l'App ID depuis le dashboard
4. Le configurer dans le code

**Note** : Pour le développement, vous pouvez utiliser un App ID temporaire. En production, utilisez un App ID avec authentification par token.

### 2. Permissions

Les permissions suivantes sont requises dans `android/app/src/main/AndroidManifest.xml` et `ios/Runner/Info.plist` :

**Android :**
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
```

**iOS :**
```xml
<key>NSMicrophoneUsageDescription</key>
<string>Nous avons besoin d'accéder au microphone pour les appels audio</string>
<key>NSCameraUsageDescription</key>
<string>Nous avons besoin d'accéder à la caméra pour les appels vidéo</string>
```

## 🚀 Utilisation

### Démarrer un Appel

```dart
// Depuis n'importe où dans l'app
await AppController.to.startCall(
  recipientId: 'user-id-here',
  callType: 'audio', // ou 'video'
);
```

### Gérer un Appel Entrant

Lorsqu'un appel entrant arrive, un dialog s'affiche automatiquement avec les boutons Accepter/Rejeter.

### Contrôles Pendant l'Appel

- **Mute** : Activer/désactiver le microphone
- **Vidéo** : Activer/désactiver la caméra (appels vidéo uniquement)
- **Haut-parleur** : Activer/désactiver le haut-parleur
- **Bascule caméra** : Changer entre caméra avant/arrière (appels vidéo uniquement)
- **Raccrocher** : Terminer l'appel

## 📱 Flux d'Appel

### 1. Initiation d'un Appel

```
Utilisateur A → startCall()
  ↓
API: POST /api/calls (créer l'appel en base)
  ↓
WebSocket: Envoyer demande d'appel à B
  ↓
Agora: Rejoindre le canal
  ↓
Navigation: Afficher ActiveCallPage
```

### 2. Réception d'un Appel

```
Backend → WebSocket: call_request_full
  ↓
AppController: _handleCallRequest()
  ↓
Afficher: IncomingCallDialog
  ↓
Utilisateur B: Accepter/Rejeter
```

### 3. Acceptation d'un Appel

```
Utilisateur B → acceptCall()
  ↓
WebSocket: Envoyer réponse "accept" à A
  ↓
Agora: Rejoindre le canal
  ↓
Navigation: Afficher ActiveCallPage
```

### 4. Terminaison d'un Appel

```
Utilisateur → endCall()
  ↓
WebSocket: Envoyer réponse "end"
  ↓
Agora: Quitter le canal
  ↓
Navigation: Retour à l'écran précédent
```

## 🔒 Sécurité

### Backend (Passerelle Aveugle)
- ✅ Ne stocke que les métadonnées (qui, quand, durée)
- ✅ Ne voit jamais le contenu des appels
- ✅ Route uniquement la signalisation

### Frontend
- ✅ Permissions demandées avant chaque appel
- ✅ Gestion des erreurs robuste
- ✅ Validation des données avant envoi

**Note** : Les streams audio/vidéo sont gérés par Agora. Pour un chiffrement end-to-end complet, il faudrait utiliser WebRTC natif avec Signal Protocol (voir `CALLS_ARCHITECTURE.md`).

## 🐛 Dépannage

### L'appel ne démarre pas

1. Vérifier que l'App ID Agora est configuré
2. Vérifier les permissions (microphone, caméra)
3. Vérifier la connexion WebSocket
4. Vérifier les logs dans la console

### L'appel se connecte mais pas de son/vidéo

1. Vérifier les permissions
2. Vérifier que le canal Agora est correctement rejoint
3. Vérifier la connexion réseau
4. Vérifier les logs Agora

### Erreur "Agora non initialisé"

1. Vérifier que `AgoraService` est initialisé dans `main.dart`
2. Vérifier que l'App ID est valide
3. Vérifier les logs d'initialisation

## 📝 Notes Techniques

### Agora RTC Engine

- **Version** : 6.2.6 (définie dans `pubspec.yaml`)
- **Documentation** : [Agora Flutter SDK](https://docs.agora.io/en/video-calling/get-started/get-started-sdk?platform=flutter)

### WebSocket

Les appels utilisent WebSocket pour la signalisation :
- `call_request` : Demande d'appel
- `call_response` : Réponse à un appel
- `call_request_full` : Demande complète (backend → frontend)
- `call_response_full` : Réponse complète (backend → frontend)

### États d'Appel

- `pending` : En attente de réponse
- `accepted` : Appel accepté, en cours
- `rejected` : Appel rejeté
- `busy` : Destinataire occupé
- `ended` : Appel terminé
- `missed` : Appel manqué

## 🎯 Prochaines Étapes (Optionnel)

1. **Vues Vidéo Natives** : Implémenter les vues vidéo Agora avec `AgoraVideoView`
2. **Notifications Push** : Ajouter des notifications pour les appels entrants
3. **Enregistrement** : Ajouter l'enregistrement des appels (si nécessaire)
4. **Chiffrement E2E** : Migrer vers WebRTC natif avec Signal Protocol pour un chiffrement complet

## ✅ Checklist de Déploiement

- [ ] Configurer l'App ID Agora
- [ ] Vérifier les permissions Android/iOS
- [ ] Tester les appels audio
- [ ] Tester les appels vidéo
- [ ] Tester les appels entrants
- [ ] Tester les appels sortants
- [ ] Tester la terminaison d'appel
- [ ] Vérifier l'historique des appels
- [ ] Tester sur différents appareils
- [ ] Vérifier la gestion des erreurs

## 📚 Ressources

- [Documentation Agora Flutter](https://docs.agora.io/en/video-calling/get-started/get-started-sdk?platform=flutter)
- [Architecture des Appels](./CALLS_ARCHITECTURE.md)
- [API Backend](./backend/API.md)

