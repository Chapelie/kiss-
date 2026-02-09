# Configuration Nginx pour Kisse

Cette configuration Nginx sert de reverse proxy pour l'application Kisse avec support SSL/HTTPS et WebSocket.

## 🚀 Démarrage Rapide

### 1. Générer les certificats SSL

```bash
sudo certbot certonly --standalone -d kisse.daali.africa -d www.kisse.daali.africa
```

### 2. Démarrer les services

```bash
docker-compose -f docker-compose.nginx.yml up -d
```

### 3. Vérifier les logs

```bash
docker-compose -f docker-compose.nginx.yml logs -f nginx
```

## 📋 Configuration

### Fichiers

- `nginx.conf` : Configuration principale Nginx
- `docker-compose.nginx.yml` : Configuration Docker Compose
- `logs/` : Dossier pour les logs (créé automatiquement)

### Domaines configurés

- `kisse.daali.africa` (production)
- `www.kisse.daali.africa` (redirection vers kisse.daali.africa)
- `localhost` (développement local)

### Ports

- **80** : HTTP (redirige vers HTTPS)
- **443** : HTTPS (production)

### Chemins

- `/api/` → Backend API (port 8080)
- `/ws` → WebSocket (port 8080)
- `/health` → Health check
- `/static/` → Fichiers statiques (optionnel)

## 🔒 SSL/TLS

### Certificats Let's Encrypt

Les certificats sont montés depuis `/etc/letsencrypt` dans le conteneur.

### Configuration SSL

- Protocoles : TLSv1.2, TLSv1.3
- Ciphers : Modernes et sécurisés
- OCSP Stapling : Activé
- HSTS : Activé (max-age=31536000)

### Renouvellement automatique

Ajoutez une tâche cron :

```bash
0 0 * * * certbot renew --quiet --deploy-hook "docker-compose -f /chemin/vers/kisse/nginx/docker-compose.nginx.yml restart nginx"
```

## 🌐 WebSocket

La configuration WebSocket supporte :
- ✅ Connexions longues (7 jours)
- ✅ Upgrade HTTP → WebSocket
- ✅ Headers corrects (Upgrade, Connection)
- ✅ Support WSS (WebSocket Secure)

## 🔧 Personnalisation

### Modifier la configuration

1. Éditez `nginx.conf`
2. Redémarrez le conteneur :

```bash
docker-compose -f docker-compose.nginx.yml restart nginx
```

### Ajouter des fichiers statiques

1. Créez le dossier `static/`
2. Placez vos fichiers dedans
3. Les fichiers seront accessibles via `https://kisse.daali.africa/static/`

## 📊 Monitoring

### Logs d'accès

```bash
tail -f logs/kisse_ssl_access.log
```

### Logs d'erreur

```bash
tail -f logs/kisse_ssl_error.log
```

### Logs Docker

```bash
docker-compose -f docker-compose.nginx.yml logs -f nginx
```

## 🐛 Dépannage

### Erreur : Certificat SSL non trouvé

Vérifiez que les certificats sont montés :

```bash
docker exec kisse-nginx ls -la /etc/letsencrypt/live/kisse.daali.africa/
```

### Erreur : Backend non accessible

Vérifiez que le backend est démarré et sur le réseau `kisse-network` :

```bash
docker network inspect kisse-network
```

### Erreur : WebSocket ne fonctionne pas

Vérifiez les logs Nginx pour les erreurs de proxy :

```bash
docker-compose -f docker-compose.nginx.yml logs nginx | grep -i websocket
```

## 📝 Notes

- Le backend doit être accessible via le nom `backend` sur le réseau Docker
- Les certificats SSL doivent être renouvelés tous les 90 jours
- Les logs sont stockés dans `./logs/` (monté comme volume)

## 🔗 Liens utiles

- [Documentation Nginx](https://nginx.org/en/docs/)
- [Let's Encrypt](https://letsencrypt.org/)
- [Certbot](https://certbot.eff.org/)
