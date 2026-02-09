# Guide de Test des Appels 📞

## ✅ Configuration Vérifiée

L'App ID Agora est configuré. Vous pouvez maintenant tester les appels !

## 🧪 Tests à Effectuer

### 1. Test d'Appel Audio

**Prérequis :**
- Deux utilisateurs connectés sur différents appareils/émulateurs
- Permissions microphone accordées

**Étapes :**
1. Utilisateur A : Aller dans l'onglet "Appels"
2. Utilisateur A : Cliquer sur un contact
3. Utilisateur A : Cliquer sur l'icône téléphone (appel audio)
4. Utilisateur B : Recevoir la notification d'appel entrant
5. Utilisateur B : Accepter l'appel
6. Vérifier que les deux utilisateurs sont en appel
7. Tester le microphone (mute/unmute)
8. Tester le haut-parleur
9. Terminer l'appel

**Résultat attendu :**
- ✅ L'appel démarre correctement
- ✅ Le son fonctionne dans les deux sens
- ✅ Les contrôles fonctionnent
- ✅ L'appel se termine correctement

### 2. Test d'Appel Vidéo

**Prérequis :**
- Deux utilisateurs connectés
- Permissions microphone ET caméra accordées

**Étapes :**
1. Utilisateur A : Aller dans l'onglet "Appels"
2. Utilisateur A : Cliquer sur un contact
3. Utilisateur A : Cliquer sur l'icône vidéo (appel vidéo)
4. Utilisateur B : Recevoir la notification d'appel entrant
5. Utilisateur B : Accepter l'appel
6. Vérifier que les deux utilisateurs voient la vidéo
7. Tester tous les contrôles (mute, vidéo, haut-parleur, bascule caméra)
8. Terminer l'appel

**Résultat attendu :**
- ✅ L'appel vidéo démarre correctement
- ✅ La vidéo fonctionne dans les deux sens
- ✅ Le son fonctionne
- ✅ Tous les contrôles fonctionnent
- ✅ L'appel se termine correctement

### 3. Test de Rejet d'Appel

**Étapes :**
1. Utilisateur A : Démarrer un appel vers Utilisateur B
2. Utilisateur B : Rejeter l'appel
3. Vérifier que l'appel est bien rejeté
4. Vérifier que l'utilisateur A reçoit la notification de rejet

**Résultat attendu :**
- ✅ L'appel est rejeté correctement
- ✅ L'utilisateur A reçoit la notification
- ✅ Aucun appel n'est en cours

### 4. Test d'Appel Occupé

**Étapes :**
1. Utilisateur A : Démarrer un appel vers Utilisateur B
2. Utilisateur B : Accepter l'appel (appel en cours)
3. Utilisateur C : Essayer d'appeler Utilisateur B
4. Vérifier que Utilisateur C reçoit "busy"

**Résultat attendu :**
- ✅ L'utilisateur C reçoit une notification "occupé"
- ✅ L'appel en cours n'est pas interrompu

### 5. Test d'Historique des Appels

**Étapes :**
1. Effectuer plusieurs appels (acceptés, rejetés, manqués)
2. Aller dans l'onglet "Appels" > "Récents"
3. Vérifier que tous les appels apparaissent
4. Vérifier les informations (durée, type, statut)
5. Tester le rappel depuis l'historique

**Résultat attendu :**
- ✅ Tous les appels apparaissent dans l'historique
- ✅ Les informations sont correctes
- ✅ Le rappel fonctionne

### 6. Test de Rappel depuis Contacts

**Étapes :**
1. Aller dans l'onglet "Appels" > "Contacts"
2. Cliquer sur un contact
3. Cliquer sur l'icône téléphone ou vidéo
4. Vérifier que l'appel démarre

**Résultat attendu :**
- ✅ L'appel démarre depuis les contacts
- ✅ Les informations du contact sont correctes

## 🔍 Vérifications Techniques

### Logs à Surveiller

**Flutter :**
```
✅ Agora RTC initialisé
📞 Rejoindre le canal: [call-id]
✅ Rejoint le canal Agora: [channel-id]
✅ Utilisateur rejoint: [uid]
```

**Backend (Rust) :**
```
✅ Authenticated user: [user-id] for path: /api/calls
📞 Call created: [call-id]
```

### Erreurs Courantes

**"Agora non initialisé"**
- ✅ Vérifier que `AgoraService` est initialisé dans `main.dart`
- ✅ Vérifier que l'App ID est valide

**"Permissions refusées"**
- ✅ Vérifier les permissions dans les paramètres de l'appareil
- ✅ Vérifier les permissions dans `AndroidManifest.xml` / `Info.plist`

**"WebSocket non connecté"**
- ✅ Vérifier la connexion WebSocket
- ✅ Vérifier que le backend est démarré
- ✅ Vérifier l'URL WebSocket dans `app_constants.dart`

**"Impossible de démarrer l'appel"**
- ✅ Vérifier les logs pour plus de détails
- ✅ Vérifier que l'utilisateur destinataire existe
- ✅ Vérifier que l'utilisateur n'est pas déjà en appel

## 📊 Checklist de Test

- [ ] Appel audio fonctionne
- [ ] Appel vidéo fonctionne
- [ ] Appel entrant affiche le dialog
- [ ] Accepter un appel fonctionne
- [ ] Rejeter un appel fonctionne
- [ ] Terminer un appel fonctionne
- [ ] Contrôles (mute, vidéo, haut-parleur) fonctionnent
- [ ] Bascule caméra fonctionne (vidéo)
- [ ] Appel occupé fonctionne
- [ ] Historique des appels s'affiche
- [ ] Rappel depuis l'historique fonctionne
- [ ] Rappel depuis les contacts fonctionne
- [ ] Timer d'appel fonctionne
- [ ] Permissions demandées correctement
- [ ] Gestion des erreurs fonctionne

## 🐛 Dépannage

### L'appel ne démarre pas

1. Vérifier les logs Flutter
2. Vérifier les logs backend
3. Vérifier la connexion WebSocket
4. Vérifier l'App ID Agora
5. Vérifier les permissions

### Pas de son/vidéo

1. Vérifier les permissions
2. Vérifier que le canal Agora est rejoint
3. Vérifier la connexion réseau
4. Vérifier les logs Agora

### L'appel se termine immédiatement

1. Vérifier les logs pour les erreurs
2. Vérifier la connexion réseau
3. Vérifier que les deux utilisateurs sont bien connectés
4. Vérifier l'App ID Agora

## 📝 Notes

- Les appels utilisent Agora RTC pour la communication peer-to-peer
- Le backend gère uniquement la signalisation (métadonnées)
- Les permissions sont demandées automatiquement avant chaque appel
- L'historique des appels est stocké dans la base de données

## ✅ Prêt pour les Tests !

Tout est configuré et prêt. Vous pouvez maintenant tester les appels entre deux appareils/émulateurs.


