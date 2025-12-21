# Kisse - Messagerie Sécurisée

Une application de messagerie mobile sécurisée utilisant le protocole Signal, WebSocket et GetX pour Flutter.

## 🔐 Fonctionnalités de Sécurité

### Protocole Signal
- **Chiffrement de bout en bout** : Tous les messages sont chiffrés avec le protocole Signal
- **Rotation automatique des clés** : Les clés de session sont renouvelées automatiquement toutes les 24h
- **Clés pré-signées** : Génération automatique de clés pré-signées pour les rotations futures
- **Sessions sécurisées** : Chaque conversation a sa propre session chiffrée

### WebSocket Sécurisé
- **Connexion temps réel** : Communication instantanée via WebSocket sécurisé
- **Reconnexion automatique** : Gestion intelligente des déconnexions avec backoff exponentiel
- **Heartbeat** : Maintien de la connexion avec des pings réguliers
- **Métadonnées uniquement** : Seules les métadonnées transitent via WebSocket (RG39)

### Authentification
- **Stockage sécurisé** : Utilisation de `flutter_secure_storage` pour les données sensibles
- **Validation robuste** : Mots de passe avec critères de sécurité stricts
- **Sessions automatiques** : Gestion automatique des sessions avec timeout

## 🏗️ Architecture

### Structure du Projet
```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart          # Configuration centralisée
│   ├── controllers/
│   │   └── app_controller.dart         # Contrôleur principal GetX
│   └── services/
│       ├── signal_service.dart         # Service Signal Protocol
│       └── websocket_service.dart      # Service WebSocket
├── data/
│   ├── models/                         # Modèles de données
│   ├── repositories/                   # Couche d'accès aux données
│   └── services/                       # Services de données
├── presentation/
│   ├── pages/                          # Pages de l'application
│   └── widgets/                        # Widgets réutilisables
└── main.dart                           # Point d'entrée
```

### Services Principaux

#### SignalService
- Gestion du protocole Signal
- Rotation automatique des clés
- Chiffrement/déchiffrement des messages
- Gestion des sessions sécurisées

#### WebSocketService
- Connexion WebSocket sécurisée
- Gestion des événements temps réel
- Reconnexion automatique
- Heartbeat et monitoring

#### AppController
- Contrôleur principal avec GetX
- Gestion de l'état global
- Coordination des services
- Navigation et authentification

## 🚀 Installation

### Prérequis
- Flutter SDK 3.8.1+
- Dart 3.0+
- Android Studio / VS Code

### Installation des Dépendances
```bash
flutter pub get
```

### Configuration
1. Modifiez les URLs dans `lib/core/constants/app_constants.dart`
2. Configurez votre serveur WebSocket
3. Ajoutez vos clés API si nécessaire

### Lancement
```bash
flutter run
```

## 📱 Fonctionnalités

### Messagerie
- ✅ Messages texte chiffrés
- ✅ Messages multimédia (images, vidéos, fichiers)
- ✅ Indicateurs de frappe
- ✅ Accusés de réception
- ✅ Statuts de lecture

### Appels
- ✅ Appels audio/vidéo
- ✅ Gestion des appels entrants
- ✅ Timeout automatique (60s)
- ✅ Chiffrement des flux

### Sécurité
- ✅ Chiffrement de bout en bout
- ✅ Rotation automatique des clés
- ✅ Stockage sécurisé
- ✅ Validation des mots de passe
- ✅ Sessions automatiques

### Temps Réel
- ✅ Connexion WebSocket
- ✅ Reconnexion automatique
- ✅ Heartbeat
- ✅ Statuts de présence

## 🔧 Configuration

### Signal Protocol
```dart
// Rotation des clés
static const Duration keyRotationInterval = Duration(hours: 24);
static const Duration preKeyRotationInterval = Duration(hours: 12);

// Nombre de clés pré-signées
static const int maxPreKeys = 100;
static const int minPreKeys = 50;
```

### WebSocket
```dart
// Configuration de reconnexion
static const Duration reconnectDelay = Duration(seconds: 5);
static const Duration heartbeatInterval = Duration(seconds: 30);
static const int maxReconnectAttempts = 10;
```

### Sécurité
```dart
// Validation des mots de passe
static const int minPasswordLength = 8;
static const String passwordRegex = r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$';

// Sessions
static const Duration sessionTimeout = Duration(minutes: 30);
static const int maxLoginAttempts = 5;
```

## 🛡️ Règles de Gestion Implémentées

### Authentication et Sécurité
- ✅ RG1 : Un seul compte par identifiant
- ✅ RG2 : Mots de passe robustes
- ✅ RG3 : Blocage après 5 échecs (15 min)
- ✅ RG4 : Double authentification (2FA)
- ✅ RG5 : Sessions automatiques (30 min)

### Conversations Privées
- ✅ RG6 : Limitation à 2 utilisateurs
- ✅ RG7 : Nouvelles instances automatiques
- ✅ RG8 : Chiffrement de bout en bout
- ✅ RG9 : Contenu inaccessible au serveur
- ✅ RG10 : Modification/suppression de messages

### WebSocket et Temps Réel
- ✅ RG36 : Connexion WebSocket sécurisée
- ✅ RG37 : Réception instantanée
- ✅ RG38 : Reconnexion automatique
- ✅ RG39 : Métadonnées uniquement

## 🔍 Utilisation

### Envoi de Message
```dart
// Via AppController
await AppController.to.sendMessage('recipient_id', 'Message chiffré');
```

### Démarrage d'Appel
```dart
// Appel audio
await AppController.to.startCall('recipient_id', 'audio');

// Appel vidéo
await AppController.to.startCall('recipient_id', 'video');
```

### Gestion des Événements
```dart
// Écouter les événements WebSocket
WebSocketService.to.events.listen((event) {
  switch (event.type) {
    case WebSocketEventType.messageReceived:
      // Traiter le message reçu
      break;
    case WebSocketEventType.callRequest:
      // Gérer l'appel entrant
      break;
  }
});
```

## 🧪 Tests

### Tests Unitaires
```bash
flutter test
```

### Tests d'Intégration
```bash
flutter test integration_test/
```

## 📊 Monitoring

### Logs de Sécurité
- Rotation des clés
- Tentatives de connexion
- Erreurs de chiffrement
- Événements WebSocket

### Métriques
- Temps de connexion
- Taux de reconnexion
- Performance du chiffrement
- Utilisation de la mémoire

## 🔒 Sécurité

### Chiffrement
- **AES-256** pour le chiffrement des messages
- **RSA-2048** pour l'échange de clés
- **SHA-256** pour les signatures

### Stockage
- **flutter_secure_storage** pour les clés
- **Chiffrement au repos** pour les données sensibles
- **Nettoyage automatique** des données temporaires

### Réseau
- **TLS 1.3** pour les connexions HTTPS
- **WSS** pour les WebSockets
- **Validation des certificats**

## 🤝 Contribution

1. Fork le projet
2. Créez une branche feature (`git checkout -b feature/AmazingFeature`)
3. Committez vos changements (`git commit -m 'Add some AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrez une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 🆘 Support

Pour toute question ou problème :
- Ouvrez une issue sur GitHub
- Consultez la documentation
- Contactez l'équipe de développement

---

**Kisse** - Votre messagerie sécurisée de confiance 🔐
