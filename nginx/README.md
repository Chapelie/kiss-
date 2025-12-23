# Configuration Nginx pour Kisse

Cette configuration Nginx permet de :
- Gérer les connexions WebSocket pour la communication en temps réel
- Proxy les requêtes API vers le backend Rust
- Gérer les fichiers statiques (optionnel)
- Support HTTPS pour la production

## Structure des fichiers

- `nginx.conf` : Configuration complète Nginx
- `docker-compose.nginx.yml` : Docker Compose pour Nginx
- `README.md` : Ce fichier

## Installation

### Option 1 : Avec Docker Compose

1. Assurez-vous que votre backend est configuré dans `docker-compose.yml` avec le service nommé `backend` sur le port `8080`

2. Créez les dossiers nécessaires :
```bash
mkdir -p nginx/logs nginx/static
```

3. Lancez Nginx avec Docker Compose :
```bash
cd nginx
docker-compose -f docker-compose.nginx.yml up -d
```

### Option 2 : Installation manuelle

1. Installez Nginx sur votre serveur :
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install nginx

# CentOS/RHEL
sudo yum install nginx
```

2. Copiez la configuration :
```bash
sudo cp nginx/nginx.conf /etc/nginx/nginx.conf
```

3. Testez la configuration :
```bash
sudo nginx -t
```

4. Redémarrez Nginx :
```bash
sudo systemctl restart nginx
```

## Configuration

### Variables importantes

1. **Backend URL** : Par défaut `http://backend:8080`
   - Pour Docker : `backend` est le nom du service
   - Pour installation manuelle : remplacez par `http://localhost:8080` ou l'IP de votre serveur

2. **Domain** : Remplacez `localhost` par votre domaine en production

3. **Ports** :
   - HTTP : 80
   - HTTPS : 443 (décommentez la section SSL)

### WebSocket

La configuration WebSocket est dans le bloc `location /ws` :
- `proxy_http_version 1.1` : Nécessaire pour WebSocket
- `Upgrade` et `Connection` headers : Permettent l'upgrade HTTP vers WebSocket
- Timeouts de 7 jours : Pour maintenir les connexions WebSocket ouvertes

### API REST

La configuration API est dans le bloc `location /api/` :
- Proxy vers le backend Rust
- Support CORS configuré
- Gestion des requêtes OPTIONS pour CORS

## Production avec HTTPS

1. Obtenez un certificat SSL (Let's Encrypt recommandé) :
```bash
sudo certbot certonly --standalone -d your-domain.com
```

2. Décommentez la section HTTPS dans `nginx.conf`

3. Mettez à jour les chemins des certificats :
```nginx
ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
```

4. Redémarrez Nginx

## Redirection HTTP vers HTTPS

Ajoutez ce bloc dans la section HTTP pour rediriger vers HTTPS :
```nginx
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}
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

## Logs

Les logs sont disponibles dans :
- Access log : `/var/log/nginx/kisse_access.log`
- Error log : `/var/log/nginx/kisse_error.log`

Pour Docker, les logs sont dans `nginx/logs/`

## Dépannage

### WebSocket ne fonctionne pas
1. Vérifiez que les headers `Upgrade` et `Connection` sont présents
2. Vérifiez les timeouts (doivent être élevés)
3. Vérifiez que `proxy_buffering` est `off` pour WebSocket

### Erreur 502 Bad Gateway
1. Vérifiez que le backend est accessible depuis Nginx
2. Vérifiez que le backend écoute sur le bon port (8080)
3. Vérifiez les logs : `tail -f /var/log/nginx/kisse_error.log`

### CORS errors
1. Vérifiez que les headers CORS sont correctement configurés
2. Vérifiez que les requêtes OPTIONS sont gérées

## Mise à jour de la configuration Flutter

Après avoir configuré Nginx, mettez à jour les constantes dans Flutter :

```dart
// lib/core/constants/app_constants.dart
static const String baseUrl = 'http://your-domain.com';  // ou https://
static const String wsUrl = 'ws://your-domain.com';      // ou wss://
static const String apiUrl = 'http://your-domain.com/api'; // ou https://
```

Pour HTTPS/WSS :
```dart
static const String baseUrl = 'https://your-domain.com';
static const String wsUrl = 'wss://your-domain.com';
static const String apiUrl = 'https://your-domain.com/api';
```

## Sécurité

- Activez HTTPS en production
- Limitez les tailles de requêtes (`client_max_body_size`)
- Configurez les rate limiting si nécessaire
- Utilisez des certificats SSL valides
- Configurez les headers de sécurité (HSTS, CSP, etc.)

