# 🚀 Guide de démarrage - Backend Kisse

## ✅ Compilation réussie !

Le backend a été compilé avec succès. Vous pouvez maintenant démarrer les conteneurs.

## 📋 Étapes de démarrage

### 1. Démarrer les conteneurs

```bash
cd backend
docker-compose up -d
```

### 2. Vérifier l'état

```bash
docker-compose ps
```

Vous devriez voir :
- `kisse-postgres` : `Up` et `healthy`
- `kisse-backend` : `Up` (pas `Restarting`)

### 3. Voir les logs

```bash
# Logs en temps réel
docker-compose logs -f

# Logs du backend uniquement
docker-compose logs -f backend

# Logs de PostgreSQL uniquement
docker-compose logs -f postgres
```

### 4. Vérifier que le backend répond

```bash
curl http://localhost:8080/health
```

Vous devriez recevoir : `OK`

## 🔧 Si le backend est en état "Restarting"

### Problème : Erreur de migration username

Si vous voyez l'erreur `duplicate key value violates unique constraint "users_username_key"` :

```bash
# 1. Arrêter le backend
docker-compose stop backend

# 2. Corriger la base de données
chmod +x fix_database.sh
./fix_database.sh

# 3. Redémarrer
docker-compose up -d backend
```

### Problème : Autre erreur

```bash
# Voir les logs détaillés
docker logs kisse-backend --tail 100

# Utiliser le script de diagnostic
chmod +x diagnose.sh
./diagnose.sh
```

## 🛑 Arrêter les conteneurs

```bash
docker-compose down
```

## 🔄 Redémarrer complètement

```bash
docker-compose down
docker-compose up -d --build
```

## 📊 Vérifier le statut

```bash
chmod +x status.sh
./status.sh
```

## 🌐 URLs de l'API

Une fois démarré, le backend est accessible sur :

- **API REST** : `http://localhost:8080/api`
- **WebSocket** : `ws://localhost:8080/ws`
- **Health Check** : `http://localhost:8080/health`

Pour l'émulateur Android, utilisez `http://10.0.2.2:8080` au lieu de `localhost`.

## ✅ Vérification finale

1. ✅ Compilation réussie
2. ✅ Conteneurs démarrés
3. ✅ Backend répond sur `/health`
4. ✅ PostgreSQL est `healthy`

Si toutes ces étapes sont OK, votre backend est prêt ! 🎉

