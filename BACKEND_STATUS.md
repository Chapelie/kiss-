# 🔧 État du Backend Docker

## ⚠️ Problème actuel

Le backend Docker ne compile pas à cause d'erreurs Rust. Il faut corriger les erreurs de compilation avant de pouvoir démarrer les conteneurs.

## ✅ Corrections appliquées pour Flutter

1. **URL de l'API corrigée** : 
   - Changé de `localhost:8080` à `10.0.2.2:8080` pour l'émulateur Android
   - `10.0.2.2` est l'alias spécial pour accéder à `localhost` de la machine hôte depuis un émulateur Android

2. **Erreur Overlay corrigée** :
   - Ajout de `navigatorKey: Get.key` dans GetMaterialApp pour Android
   - Vérification du contexte avant d'afficher les snackbars

## 🚀 Pour démarrer le backend

Une fois les erreurs Rust corrigées :

```bash
cd backend
docker compose build
docker compose up -d
```

## 📝 Note importante

Pour un **appareil physique** (pas un émulateur), vous devez :
1. Trouver l'IP de votre machine : `ifconfig` ou `ipconfig`
2. Modifier `app_constants.dart` pour utiliser cette IP au lieu de `10.0.2.2`
3. S'assurer que le téléphone et l'ordinateur sont sur le même réseau WiFi

---

**Prochaine étape** : Corriger les erreurs de compilation Rust dans le backend.


