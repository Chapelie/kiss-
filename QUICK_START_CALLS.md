# 🚀 Démarrage Rapide - Tests des Appels

## ✅ Configuration Complète

Votre App ID Agora est configuré : `ba92f87a840d42f2943d19ee3484f551`

## 🧪 Test Rapide (2 minutes)

### Étape 1 : Préparer deux utilisateurs

1. **Appareil/Émulateur 1** : Connectez-vous avec un utilisateur (ex: user1@test.com)
2. **Appareil/Émulateur 2** : Connectez-vous avec un autre utilisateur (ex: user2@test.com)
3. **Important** : Les deux utilisateurs doivent être dans leurs contacts respectifs

### Étape 2 : Tester un appel audio

1. Sur **Appareil 1** :
   - Aller dans l'onglet "Appels"
   - Cliquer sur "Contacts"
   - Trouver l'utilisateur 2
   - Cliquer sur l'icône 📞 (téléphone)

2. Sur **Appareil 2** :
   - Une notification d'appel entrant apparaît
   - Cliquer sur "Accepter"

3. Vérifier :
   - ✅ Les deux appareils affichent la page d'appel
   - ✅ Le timer d'appel fonctionne
   - ✅ Le son fonctionne (parler dans un appareil, écouter dans l'autre)

4. Tester les contrôles :
   - 🔇 Mute/Unmute
   - 🔊 Haut-parleur
   - ❌ Raccrocher

### Étape 3 : Tester un appel vidéo

1. Sur **Appareil 1** :
   - Aller dans l'onglet "Appels" > "Contacts"
   - Cliquer sur l'icône 📹 (vidéo) pour l'utilisateur 2

2. Sur **Appareil 2** :
   - Accepter l'appel

3. Vérifier :
   - ✅ La vidéo s'affiche (actuellement placeholder, mais la connexion fonctionne)
   - ✅ Le son fonctionne
   - ✅ Tous les contrôles fonctionnent

## 🔍 Vérification des Logs

### Flutter (Console)
Recherchez ces messages :
```
✅ Agora RTC initialisé
📞 Rejoindre le canal: [call-id]
✅ Rejoint le canal Agora: [channel-id]
✅ Utilisateur rejoint: [uid]
```

### Backend (Terminal Docker)
Recherchez ces messages :
```
✅ Authenticated user: [user-id] for path: /api/calls
📞 Call created: [call-id]
```

## ⚠️ Problèmes Courants

### "Permissions refusées"
- **Solution** : Aller dans les paramètres de l'appareil et autoriser microphone/caméra

### "WebSocket non connecté"
- **Solution** : Vérifier que le backend Docker est démarré
- **Commande** : `cd backend && docker-compose ps`

### "Agora non initialisé"
- **Solution** : Redémarrer l'application Flutter

### Pas de son
- **Solution** : 
  1. Vérifier le volume de l'appareil
  2. Vérifier que le microphone n'est pas muet
  3. Vérifier les permissions

## 📋 Checklist Rapide

- [ ] Deux utilisateurs connectés
- [ ] Permissions accordées (microphone, caméra si vidéo)
- [ ] Backend Docker démarré
- [ ] WebSocket connecté (vérifier dans le profil)
- [ ] Appel audio testé
- [ ] Appel vidéo testé
- [ ] Contrôles testés
- [ ] Historique vérifié

## 🎉 C'est Prêt !

Tout est configuré. Vous pouvez maintenant tester les appels entre deux appareils.

Pour plus de détails, voir `TEST_CALLS.md` et `CALLS_IMPLEMENTATION.md`.

