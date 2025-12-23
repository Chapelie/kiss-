# Guide de Configuration Nginx pour Kisse

## Vue d'ensemble

Cette configuration Nginx permet de :
- ✅ Gérer les connexions WebSocket pour la communication en temps réel
- ✅ Proxy les requêtes API vers le backend Rust
- ✅ Gérer les fichiers statiques (optionnel)
- ✅ Support HTTPS pour la production
- ✅ Gérer CORS pour les requêtes cross-origin

## Structure des fichiers

```
nginx/
├── nginx.conf              # Configuration complète Nginx
├── docker-compose.nginx.yml # Docker Compose pour Nginx seul
├── start.sh                # Script de démarrage
├── README.md               # Documentation complète
└── NGINX_SETUP.md          # Ce guide
```

## Installation rapide

### Option 1 : Avec le docker-compose principal (recommandé)

Le fichier `docker-compose.yml` à la racine inclut déjà Nginx :

```bash
# Démarrer tous les services (PostgreSQL, Backend, Nginx)
cd /Users/mac/Desktop/Project/Kisse
docker-compose up -d

# Vérifier le statut
docker-compose ps

# Voir les logs
docker-compose logs -f nginx
```

### Option 2 : Nginx seul (si backend déjà en cours)

```bash
cd nginx
./start.sh
```

## Configuration

### Variables importantes

1. **Backend URL** : `http://backend:8080`
   - `backend` est le nom du service Docker
   - Port interne : 8080 (non exposé publiquement)

2. **Ports Nginx** :
   - HTTP : 80
   - HTTPS : 443 (décommentez la section SSL)

3. **Domain** : Remplacez `localhost` par votre domaine en production

### Routes configurées

- `/ws` → WebSocket (proxy vers backend:8080/ws)
- `/api/*` → API REST (proxy vers backend:8080/api/*)
- `/health` → Health check (proxy vers backend:8080/health)
- `/static/*` → Fichiers statiques (optionnel)

## WebSocket Configuration

La configuration WebSocket est critique pour les connexions en temps réel :

```nginx
location /ws {
    proxy_pass http://backend:8080;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_connect_timeout 7d;
    proxy_send_timeout 7d;
    proxy_read_timeout 7d;
    proxy_buffering off;
}
```

**Points importants** :
- `Upgrade` et `Connection` headers : Essentiels pour l'upgrade HTTP → WebSocket
- Timeouts de 7 jours : Pour maintenir les connexions WebSocket ouvertes
- `proxy_buffering off` : Nécessaire pour WebSocket

## Mise à jour des constantes Flutter

Après avoir configuré Nginx, mettez à jour `lib/core/constants/app_constants.dart` :

### Pour développement local (sans Nginx)
```dart
static const String baseUrl = 'http://10.0.2.2:8080';
static const String wsUrl = 'ws://10.0.2.2:8080/ws';
static const String apiUrl = 'http://10.0.2.2:8080/api';
```

### Pour production avec Nginx (HTTP)
```dart
static const String baseUrl = 'http://your-domain.com';
static const String wsUrl = 'ws://your-domain.com/ws';
static const String apiUrl = 'http://your-domain.com/api';
```

### Pour production avec Nginx (HTTPS/WSS)
```dart
static const String baseUrl = 'https://your-domain.com';
static const String wsUrl = 'wss://your-domain.com/ws';
static const String apiUrl = 'https://your-domain.com/api';
```

## Tests

### Test WebSocket
```bash
# Test de connexion WebSocket
curl -i -N \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" \
  -H "Sec-WebSocket-Key: test" \
  http://localhost/ws?token=YOUR_TOKEN
```

### Test API
```bash
# Test de l'endpoint health
curl http://localhost/health

# Test d'un endpoint API
curl http://localhost/api/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Production avec HTTPS

1. **Obtenir un certificat SSL** (Let's Encrypt recommandé) :
```bash
sudo certbot certonly --standalone -d your-domain.com
```

2. **Décommentez la section HTTPS** dans `nginx/nginx.conf`

3. **Mettez à jour les chemins des certificats** :
```nginx
ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
```

4. **Redémarrez Nginx** :
```bash
docker-compose restart nginx
```

## Dépannage

### WebSocket ne fonctionne pas
1. Vérifiez les headers `Upgrade` et `Connection`
2. Vérifiez que `proxy_buffering` est `off`
3. Vérifiez les timeouts (doivent être élevés)
4. Vérifiez les logs : `docker-compose logs nginx`

### Erreur 502 Bad Gateway
1. Vérifiez que le backend est accessible : `docker-compose ps backend`
2. Vérifiez que le backend écoute sur le port 8080
3. Vérifiez les logs : `docker-compose logs backend`

### CORS errors
1. Vérifiez que les headers CORS sont correctement configurés
2. Vérifiez que les requêtes OPTIONS sont gérées
3. Ajustez `Access-Control-Allow-Origin` selon vos besoins

## Commandes utiles

```bash
# Voir les logs Nginx
docker-compose logs -f nginx

# Redémarrer Nginx
docker-compose restart nginx

# Tester la configuration
docker exec kisse-nginx nginx -t

# Recharger la configuration (sans redémarrer)
docker exec kisse-nginx nginx -s reload

# Arrêter Nginx
docker-compose stop nginx

# Voir le statut
docker-compose ps
```

## Sécurité

- ✅ Activez HTTPS en production
- ✅ Limitez les tailles de requêtes (`client_max_body_size`)
- ✅ Configurez les rate limiting si nécessaire
- ✅ Utilisez des certificats SSL valides
- ✅ Configurez les headers de sécurité (HSTS, CSP, etc.)

## Architecture

```
Client (Flutter)
    ↓
Nginx (Port 80/443)
    ├─ /ws → WebSocket → Backend:8080/ws
    ├─ /api/* → REST API → Backend:8080/api/*
    └─ /health → Health Check → Backend:8080/health
    ↓
Backend Rust (Port 8080, interne)
    ↓
PostgreSQL (Port 5432, interne)
```

## Support

Pour plus d'informations, consultez :
- `nginx/README.md` : Documentation complète
- `nginx/nginx.conf` : Configuration détaillée avec commentaires

