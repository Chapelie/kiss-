# Architecture de Sécurité - Protocole Signal

## 🔐 Principe Fondamental

**Le backend Rust est UNIQUEMENT une passerelle de routage. Il ne stocke JAMAIS de contenu chiffré et n'a JAMAIS accès aux clés de chiffrement.**

## 🏗️ Architecture

```
┌─────────────────┐
│  Client Flutter │
│  (Chiffrement)  │
└────────┬────────┘
         │
         │ Métadonnées uniquement
         │ (pas de contenu chiffré)
         ▼
┌─────────────────┐
│ Backend Rust    │
│ (Passerelle)    │
└────────┬────────┘
         │
         │ Routage
         ▼
┌─────────────────┐
│  Client Flutter │
│ (Déchiffrement) │
└─────────────────┘
```

## 📋 Ce que le Backend Stocke

### ✅ Métadonnées Stockées

1. **Messages** (table `messages`)
   - `id` : Identifiant unique
   - `conversation_id` : ID de la conversation
   - `sender_id` : ID de l'expéditeur
   - `recipient_id` : ID du destinataire
   - `message_type` : Type (text, image, file, etc.)
   - `timestamp` : Horodatage
   - `session_id` : ID de session Signal (pour référence uniquement)
   - `is_read` : Statut de lecture
   - `read_at` : Date de lecture

   **❌ PAS de champ pour :**
   - Contenu chiffré
   - Clés de chiffrement
   - Données sensibles

2. **Conversations** (table `conversations`)
   - Métadonnées de conversation uniquement
   - Pas de contenu

3. **Appels** (table `calls`)
   - Métadonnées d'appel uniquement
   - Pas de flux audio/vidéo

4. **Présence** (table `user_presence`)
   - Statut utilisateur uniquement

## 🚫 Ce que le Backend NE Fait PAS

1. ❌ **Ne stocke JAMAIS de contenu chiffré**
2. ❌ **N'a JAMAIS accès aux clés de chiffrement**
3. ❌ **Ne peut PAS déchiffrer les messages**
4. ❌ **Ne gère PAS le protocole Signal**
5. ❌ **Ne stocke PAS les clés publiques/privées**

## ✅ Ce que le Backend Fait

1. ✅ **Routage des métadonnées** : Transmet uniquement les informations nécessaires au routage
2. ✅ **Gestion des connexions WebSocket** : Maintient les connexions pour la communication temps réel
3. ✅ **Authentification** : Vérifie l'identité des utilisateurs (JWT)
4. ✅ **Gestion de la présence** : Suit qui est en ligne/hors ligne
5. ✅ **Gestion des appels** : Coordonne les appels (métadonnées uniquement)

## 🔄 Flux de Communication

### Envoi de Message

1. **Client Flutter (Expéditeur)**
   - Chiffre le message avec Signal Protocol
   - Génère les métadonnées (ID, timestamp, session_id)
   - Envoie **UNIQUEMENT les métadonnées** via WebSocket

2. **Backend Rust**
   - Reçoit les métadonnées
   - Stocke les métadonnées en base de données
   - Route les métadonnées au destinataire via WebSocket
   - **Ne voit JAMAIS le contenu chiffré**

3. **Client Flutter (Destinataire)**
   - Reçoit les métadonnées
   - Récupère le contenu chiffré via un canal sécurisé séparé (HTTPS)
   - Déchiffre le message avec Signal Protocol

### Réception de Message

1. **Backend Rust**
   - Notifie le destinataire via WebSocket avec les métadonnées
   - Met à jour le statut en base de données

2. **Client Flutter (Destinataire)**
   - Reçoit la notification avec les métadonnées
   - Récupère le contenu chiffré
   - Déchiffre et affiche

## 🔑 Gestion des Clés Signal

**Toutes les clés sont gérées UNIQUEMENT côté client Flutter :**

- Clés d'identité : Stockées dans `flutter_secure_storage`
- Clés pré-signées : Générées et stockées côté client
- Clés de session : Gérées par le client
- Rotation des clés : Effectuée par le client

Le backend ne connaît que le `session_id` pour référence, mais n'a pas accès aux clés.

## 📡 WebSocket - Métadonnées Uniquement

Tous les messages WebSocket contiennent **UNIQUEMENT des métadonnées** :

```json
{
  "type": "message",
  "payload": {
    "messageId": "uuid",
    "recipientId": "uuid",
    "timestamp": "2024-01-01T00:00:00Z",
    "sessionId": "string",
    "messageType": "text"
  }
}
```

**PAS de contenu chiffré dans le payload WebSocket.**

## 🛡️ Sécurité

### Protection des Données

1. **Chiffrement de bout en bout** : Le contenu est chiffré avant d'être envoyé
2. **Passerelle aveugle** : Le backend ne peut pas lire les messages
3. **Pas de stockage de contenu** : Seules les métadonnées sont stockées
4. **Authentification forte** : JWT pour vérifier l'identité
5. **HTTPS/WSS** : Communication sécurisée

### Conformité

- ✅ **RG39** : Métadonnées uniquement via WebSocket
- ✅ **RG8** : Chiffrement de bout en bout
- ✅ **RG9** : Contenu inaccessible au serveur
- ✅ **Zero-Knowledge** : Le serveur ne peut pas lire les messages

## 📝 Notes Importantes

1. **Le backend est "aveugle"** : Il ne peut pas lire le contenu des messages
2. **Le routage est basé sur les IDs** : Le backend route uniquement sur les identifiants
3. **La synchronisation se fait côté client** : Les clients gèrent leur propre état
4. **Le backend est stateless pour le contenu** : Pas de cache de contenu chiffré

## 🔍 Vérification

Pour vérifier que le backend respecte ces principes :

1. ✅ Vérifier qu'il n'y a pas de champ `content` ou `encrypted_content` dans la table `messages`
2. ✅ Vérifier qu'il n'y a pas de gestion de clés dans le code backend
3. ✅ Vérifier que les WebSocket messages ne contiennent que des métadonnées
4. ✅ Vérifier que le backend ne fait pas de déchiffrement

## 🚀 Implémentation Future

Pour une sécurité maximale, le contenu chiffré pourrait être :
- Stocké dans un service séparé (S3, etc.) avec accès direct client-client
- Ou transmis via un canal P2P sécurisé
- Le backend ne serait alors qu'un annuaire de routage

