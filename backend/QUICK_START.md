# ⚡ Démarrage Rapide Docker

## Installation Docker (si nécessaire)

### macOS
```bash
brew install --cask docker
```

**Puis ouvrir Docker Desktop** et attendre qu'il soit démarré.

## 🚀 Démarrage

```bash
cd backend

# Option 1 : Script
./start.sh

# Option 2 : Make
make start

# Option 3 : Docker directement
docker compose build && docker compose up -d
```

## ✅ Vérification

```bash
# Tester
curl http://localhost:8080/health

# Voir les logs
docker compose logs -f
```

## 🛑 Arrêt

```bash
docker compose down
# ou
./stop.sh
# ou
make stop
```

## 📍 URLs

- API: http://localhost:8080
- WebSocket: ws://localhost:8080/ws
- Health: http://localhost:8080/health

---

**C'est tout !** 🎉

