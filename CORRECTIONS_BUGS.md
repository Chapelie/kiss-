# Corrections des Bugs Critiques 🔧

## Bugs Critiques Corrigés

### 1. ❌ BUG CRITIQUE : `messageKey` vide lors du déchiffrement

**Problème** : Dans `websocket_service.dart` ligne 386, `messageKey` est vide, ce qui empêche le déchiffrement.

**Solution** : Le `messageKey` doit être stocké avec le contenu chiffré ou récupéré depuis la session Signal. Cependant, selon l'architecture Signal Protocol, la clé de message est générée à chaque message et ne peut pas être stockée côté serveur (sécurité).

**Correction** : Modifier le flux pour que le `messageKey` soit inclus dans le contenu chiffré lui-même, ou utiliser une approche différente.

### 2. ✅ BUG CORRIGÉ : Vérification des permissions pour `getEncryptedContent`

**Statut** : ✅ DÉJÀ CORRIGÉ dans `handlers.rs` ligne 286
```rust
if message.sender_id != user_id && message.recipient_id != user_id {
    return Err(StatusCode::FORBIDDEN);
}
```

### 3. ✅ BUG CORRIGÉ : Vérification d'appel actif

**Statut** : ✅ DÉJÀ CORRIGÉ dans `handlers.rs` ligne 147
```rust
if let Ok(Some(_)) = crate::services::CallService::get_active_call(state.db.pool(), user_id).await {
    return Err(StatusCode::CONFLICT);
}
```

## Bugs Potentiels à Corriger

### 4. ⚠️ Validation email côté backend

**Problème** : Pas de validation du format email côté backend.

**Solution** : Ajouter validation avec regex ou crate `validator`.

### 5. ⚠️ Rate limiting pour authentification

**Problème** : Pas de protection contre les attaques brute force.

**Solution** : Ajouter middleware de rate limiting.

### 6. ⚠️ Timeout pour appels en attente

**Problème** : Appels `pending` peuvent rester indéfiniment.

**Solution** : Ajouter un job qui marque les appels `pending` comme `missed` après 60 secondes.

## Code Mort à Supprimer

### 7. 💀 `updateMessageId` jamais appelé

**Fichier** : `lib/core/services/message_service.dart` ligne 49

**Action** : Supprimer ou implémenter correctement.

### 8. 💀 Colonnes inutilisées en BD

- `conversations.type` : Colonne n'existe pas dans la migration mais référencée dans le code
- `user_presence.updated_at` : Jamais utilisé dans les requêtes

## Récidives à Centraliser

### 9. 🔄 Gestion des tokens (3+ endroits)

**Fichiers** :
- `api_service.dart` ligne 27, 60, 98
- `websocket_service.dart` ligne 83
- `app_controller.dart` (plusieurs endroits)

**Solution** : Déjà centralisé dans l'intercepteur Dio, mais peut être amélioré.

### 10. 🔄 Calcul hash SHA-256 (2 endroits)

**Fichiers** :
- `websocket_service.dart` ligne 330
- `message_service.dart` ligne 57

**Solution** : Créer fonction utilitaire.

### 11. 🔄 Formatage timestamps (2 endroits)

**Fichiers** :
- `chat_list_page.dart` ligne 71
- `calls_page.dart` ligne 91

**Solution** : Créer extension ou fonction utilitaire.

### 12. 🔄 Encodage/décodage base64 (2 endroits)

**Fichiers** :
- `websocket_service.dart` ligne 333, 370
- `message_service.dart` ligne 58

**Solution** : Créer fonctions utilitaires.


