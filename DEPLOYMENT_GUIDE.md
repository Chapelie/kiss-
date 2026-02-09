# Guide de Déploiement - Kisse

Ce guide explique comment déployer l'application Kisse avec le domaine `kisse.daali.africa`.

## 📋 Prérequis

1. **Serveur avec Docker et Docker Compose**
2. **Domaine configuré** : `kisse.daali.africa` pointant vers l'IP du serveur
3. **Ports ouverts** : 80 (HTTP), 443 (HTTPS), 8080 (Backend - interne)
4. **Certificat SSL** : Let's Encrypt recommandé

## 🔐 Configuration SSL avec Let's Encrypt

### 1. Installation de Certbot

```bash
sudo apt-get update
sudo apt-get install certbot python3-certbot-nginx
```

### 2. Génération des certificats SSL

```bash
sudo certbot certonly --standalone -d kisse.daali.africa -d www.kisse.daali.africa
```

Les certificats seront générés dans :
- `/etc/letsencrypt/live/kisse.daali.africa/fullchain.pem`
- `/etc/letsencrypt/live/kisse.daali.africa/privkey.pem`
- `/etc/letsencrypt/live/kisse.daali.africa/chain.pem`

### 3. Renouvellement automatique

Ajoutez une tâche cron pour renouveler automatiquement :

```bash
sudo crontab -e
```

Ajoutez cette ligne :
```
0 0 * * * certbot renew --quiet --deploy-hook "docker-compose -f /chemin/vers/kisse/nginx/docker-compose.nginx.yml restart nginx"
```

## 🐳 Configuration Docker

### Structure des fichiers

```
kisse/
├── backend/
│   ├── docker-compose.yml
│   └── ...
├── nginx/
│   ├── nginx.conf
│   ├── docker-compose.nginx.yml
│   └── ...
└── ...
```

### 1. Configuration Nginx

Le fichier `nginx/nginx.conf` est déjà configuré pour :
- ✅ Redirection HTTP → HTTPS
- ✅ Configuration SSL moderne
- ✅ Proxy vers le backend sur le port 8080
- ✅ Support WebSocket (wss://)
- ✅ Headers de sécurité

**Important** : Vérifiez que les chemins des certificats SSL dans `nginx.conf` correspondent à vos certificats Let's Encrypt.

### 2. Montage des certificats SSL

Dans `docker-compose.nginx.yml`, assurez-vous que les volumes montent les certificats :

```yaml
volumes:
  - ./nginx.conf:/etc/nginx/nginx.conf:ro
  - /etc/letsencrypt:/etc/letsencrypt:ro
  - ./logs:/var/log/nginx
```

### 3. Démarrage des services

```bash
# Démarrer le backend
cd backend
docker-compose up -d

# Démarrer Nginx
cd ../nginx
docker-compose -f docker-compose.nginx.yml up -d
```

## 📱 Configuration de l'Application Flutter

### Mode Production

Dans `lib/core/constants/app_constants.dart`, assurez-vous que :

```dart
static const bool isProduction = true;
```

Cela utilisera automatiquement :
- `https://kisse.daali.africa` pour l'API
- `wss://kisse.daali.africa/ws` pour WebSocket

### Mode Développement

Pour le développement local, changez :

```dart
static const bool isProduction = false;
```

### Build de l'application

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## 🔧 Configuration Backend

### Variables d'environnement

Créez un fichier `.env` dans le dossier `backend/` :

```env
SERVER_ADDRESS=0.0.0.0:8080
DATABASE_URL=postgresql://kisse:password@postgres:5432/kisse
JWT_SECRET=votre-secret-jwt-tres-securise-changez-moi
JWT_EXPIRATION=3600
RUST_LOG=info
```

### CORS

Le backend doit accepter les requêtes depuis `https://kisse.daali.africa`. Vérifiez la configuration CORS dans le backend Rust.

## 🌐 Configuration DNS

Assurez-vous que votre domaine pointe vers votre serveur :

```
Type    Name    Value
A       @       VOTRE_IP_SERVEUR
A       www     VOTRE_IP_SERVEUR
```

## ✅ Vérification

### 1. Vérifier que le backend répond

```bash
curl https://kisse.daali.africa/health
```

### 2. Vérifier que l'API fonctionne

```bash
curl https://kisse.daali.africa/api/health
```

### 3. Vérifier SSL

```bash
curl -I https://kisse.daali.africa
```

Ou utilisez [SSL Labs](https://www.ssllabs.com/ssltest/) pour un test complet.

### 4. Vérifier WebSocket

Vous pouvez tester avec un client WebSocket ou directement depuis l'application Flutter.

## 🔒 Sécurité

### Headers de sécurité

Nginx est configuré avec :
- ✅ HSTS (HTTP Strict Transport Security)
- ✅ X-Frame-Options
- ✅ X-Content-Type-Options
- ✅ X-XSS-Protection
- ✅ Referrer-Policy

### Firewall

Configurez votre firewall pour n'autoriser que :
- Port 80 (HTTP) - redirige vers HTTPS
- Port 443 (HTTPS)
- Port 22 (SSH) - pour l'administration

```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

## 📊 Monitoring

### Logs Nginx

```bash
# Logs d'accès
docker-compose -f nginx/docker-compose.nginx.yml logs -f nginx | grep access

# Logs d'erreur
docker-compose -f nginx/docker-compose.nginx.yml logs -f nginx | grep error
```

### Logs Backend

```bash
cd backend
docker-compose logs -f backend
```

## 🐛 Dépannage

### Problème : Certificat SSL non trouvé

**Solution** : Vérifiez que les certificats sont montés dans le conteneur Docker :
```bash
docker exec -it nginx_container ls -la /etc/letsencrypt/live/kisse.daali.africa/
```

### Problème : WebSocket ne fonctionne pas

**Solution** : Vérifiez que :
1. Le backend écoute sur `0.0.0.0:8080` (pas `127.0.0.1`)
2. Les headers `Upgrade` et `Connection` sont bien passés
3. Le proxy WebSocket dans Nginx est correctement configuré

### Problème : CORS errors

**Solution** : Vérifiez la configuration CORS dans :
1. Nginx (`nginx.conf`)
2. Backend Rust (si configuré)

### Problème : Redirection infinie HTTP → HTTPS

**Solution** : Vérifiez que le bloc de redirection HTTP est bien configuré et que le serveur HTTPS écoute sur le port 443.

## 📝 Checklist de Déploiement

- [ ] Domaine DNS configuré et propagé
- [ ] Certificats SSL générés avec Let's Encrypt
- [ ] Nginx configuré avec les bons chemins de certificats
- [ ] Backend démarré et accessible
- [ ] Variables d'environnement backend configurées
- [ ] Application Flutter en mode production (`isProduction = true`)
- [ ] Application Flutter buildée et testée
- [ ] Firewall configuré
- [ ] Logs configurés et accessibles
- [ ] Monitoring en place
- [ ] Renouvellement automatique SSL configuré

## 🚀 Mise à jour

Pour mettre à jour l'application :

1. **Backend** :
```bash
cd backend
docker-compose pull
docker-compose up -d --build
```

2. **Nginx** :
```bash
cd nginx
docker-compose -f docker-compose.nginx.yml pull
docker-compose -f docker-compose.nginx.yml up -d
```

3. **Application Flutter** :
- Rebuild et redistribuer via les stores

## 📞 Support

En cas de problème, vérifiez :
1. Les logs Docker
2. Les logs Nginx
3. La configuration DNS
4. Les certificats SSL
5. La connectivité réseau


