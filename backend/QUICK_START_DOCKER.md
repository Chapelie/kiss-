# 🚀 Démarrage rapide - Docker uniquement

## ✅ État actuel

- ✅ Compilation réussie
- ✅ Volume PostgreSQL supprimé (base de données vide)
- ✅ Migration corrigée pour gérer les usernames

## 📋 Commandes de démarrage

### 1. Attendre la fin du build

Le build est en cours. Attendez qu'il se termine.

### 2. Démarrer les conteneurs

```bash
cd backend
docker-compose up -d
```

### 3. Vérifier l'état

```bash
docker-compose ps
```

Vous devriez voir :
- `kisse-postgres` : `Up` et `healthy`
- `kisse-backend` : `Up` (pas `Restarting`)

### 4. Vérifier les logs

```bash
# Logs du backend
docker-compose logs -f backend
```

Vous devriez voir :
```
✅ Connected to database
✅ Database migrations completed
🚀 Server listening on 0.0.0.0:8080
```

### 5. Tester l'API

```bash
curl http://localhost:8080/health
```

Devrait retourner : `OK`

## 🔧 Si le backend est toujours en "Restarting"

### Vérifier les logs

```bash
docker logs kisse-backend --tail 50
```

### Si erreur de migration

La base de données est maintenant vide, donc la migration devrait fonctionner. Si vous voyez encore une erreur :

```bash
# Arrêter
docker-compose down

# Supprimer le volume (si nécessaire)
docker volume rm backend_postgres_data

# Redémarrer
docker-compose up -d --build
```

## 📊 Vérification complète

```bash
# État des conteneurs
docker-compose ps

# Logs en temps réel
docker-compose logs -f

# Test de santé
curl http://localhost:8080/health

# Test de l'API (après inscription/connexion)
curl http://localhost:8080/api/auth/me
```

## 🎯 Configuration Docker

- **Backend** : `http://localhost:8080`
- **PostgreSQL** : `postgres:5432` (dans Docker), `localhost:5432` (depuis l'extérieur)
- **WebSocket** : `ws://localhost:8080/ws`
- **Pour Android** : `http://10.0.2.2:8080`

## ✅ Checklist de démarrage

- [ ] Build terminé sans erreur
- [ ] Conteneurs démarrés (`docker-compose ps`)
- [ ] PostgreSQL est `healthy`
- [ ] Backend est `Up` (pas `Restarting`)
- [ ] `/health` retourne `OK`
- [ ] Logs montrent "Server listening"

Une fois toutes ces étapes validées, votre backend est prêt ! 🎉

