class AppConstants {
  // Configuration de l'application
  static const String appName = 'Kisse';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Messagerie Sécurisée';
  
  // URLs du serveur
  // Pour développement local: http://localhost:8080
  // Pour émulateur Android: http://10.0.2.2:8080 (10.0.2.2 est l'alias pour localhost de la machine hôte)
  // Pour appareil physique: http://<IP_MACHINE>:8080
  // Pour production: https://kisse.daali.africa
  
  // Mode de l'application (true = production, false = développement)
  static const bool isProduction = false; // Changez à false pour le développement local
  
  // URLs de production
  static const String productionBaseUrl = 'https://kisse.daali.africa';
  static const String productionWsUrl = 'wss://kisse.daali.africa/ws';
  static const String productionApiUrl = 'https://kisse.daali.africa/api';
  
  // URLs de développement
  // Utilise l'IP du serveur directement (port 8080 pour le backend HTTP)
  static const String devBaseUrl = 'http://10.32.81.171:8080';
  static const String devWsUrl = 'ws://10.32.81.171:8080/ws';
  static const String devApiUrl = 'http://10.32.81.171:8080/api';
  // URLs actives (basées sur isProduction)
  static String get baseUrl => isProduction ? productionBaseUrl : devBaseUrl;
  static String get wsUrl => isProduction ? productionWsUrl : devWsUrl;
  static String get apiUrl => isProduction ? productionApiUrl : devApiUrl;
  
  // Configuration Signal Protocol
  static const Duration keyRotationInterval = Duration(hours: 24);
  static const Duration preKeyRotationInterval = Duration(hours: 12);
  static const int maxPreKeys = 100;
  static const int minPreKeys = 50;
  
  // Configuration WebSocket
  static const Duration reconnectDelay = Duration(seconds: 5);
  static const Duration heartbeatInterval = Duration(seconds: 30);
  static const int maxReconnectAttempts = 10;
  static const Duration callTimeout = Duration(seconds: 60);
  
  // Configuration des fichiers
  static const int maxFileSize = 50 * 1024 * 1024; // 50 MB
  static const Duration fileRetentionPeriod = Duration(days: 7);
  
  // Configuration des sessions
  static const Duration sessionTimeout = Duration(minutes: 30);
  static const int maxLoginAttempts = 5;
  static const Duration loginBlockDuration = Duration(minutes: 15);
  
  // Configuration des stories
  static const Duration storyLifetime = Duration(hours: 24);
  
  // Configuration des notifications
  static const Duration notificationTimeout = Duration(seconds: 5);
  
  // Types de messages
  static const String messageTypeText = 'text';
  static const String messageTypeImage = 'image';
  static const String messageTypeVideo = 'video';
  static const String messageTypeAudio = 'audio';
  static const String messageTypeFile = 'file';
  static const String messageTypeLocation = 'location';
  
  // Types d'appels
  static const String callTypeAudio = 'audio';
  static const String callTypeVideo = 'video';
  
  // Statuts de présence
  static const String presenceOnline = 'online';
  static const String presenceOffline = 'offline';
  static const String presenceAway = 'away';
  static const String presenceBusy = 'busy';
  
  // Statuts de lecture
  static const String readStatusSent = 'sent';
  static const String readStatusDelivered = 'delivered';
  static const String readStatusRead = 'read';
  
  // Rôles utilisateur
  static const String roleUser = 'user';
  static const String roleAdmin = 'admin';
  static const String roleModerator = 'moderator';
  
  // Types de canaux
  static const String channelTypePublic = 'public';
  static const String channelTypePrivate = 'private';
  static const String channelTypeAnnouncement = 'announcement';
  
  // Clés de stockage sécurisé
  static const String keyAuthToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyIdentityKey = 'identity_key';
  static const String keyPreKeys = 'pre_keys';
  static const String keySignalSessions = 'signal_sessions';
  static const String keyUserPreferences = 'user_preferences';
  
  // Codes d'erreur
  static const String errorNetwork = 'NETWORK_ERROR';
  static const String errorAuthentication = 'AUTH_ERROR';
  static const String errorEncryption = 'ENCRYPTION_ERROR';
  static const String errorFileTooLarge = 'FILE_TOO_LARGE';
  static const String errorInvalidMessage = 'INVALID_MESSAGE';
  static const String errorUserNotFound = 'USER_NOT_FOUND';
  static const String errorConversationNotFound = 'CONVERSATION_NOT_FOUND';
  static const String errorPermissionDenied = 'PERMISSION_DENIED';
  
  // Messages d'erreur
  static const String messageNetworkError = 'Erreur de connexion réseau';
  static const String messageAuthenticationError = 'Erreur d\'authentification';
  static const String messageEncryptionError = 'Erreur de chiffrement';
  static const String messageFileTooLarge = 'Fichier trop volumineux';
  static const String messageInvalidMessage = 'Message invalide';
  static const String messageUserNotFound = 'Utilisateur non trouvé';
  static const String messageConversationNotFound = 'Conversation non trouvée';
  static const String messagePermissionDenied = 'Permission refusée';
  
  // Validation des mots de passe
  static const int minPasswordLength = 8;
  static const String passwordRegex = r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$';
  
  // Configuration des animations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration splashDuration = Duration(seconds: 3);
  
  // Configuration des images
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1080;
  static const double imageCompressionQuality = 0.8;
  
  // Configuration des vidéos
  static const int maxVideoDuration = 300; // 5 minutes
  static const int maxVideoSize = 100 * 1024 * 1024; // 100 MB
  
  // Configuration des audios
  static const int maxAudioDuration = 300; // 5 minutes
  static const int maxAudioSize = 50 * 1024 * 1024; // 50 MB
  
  // Configuration de la base de données locale
  static const String dbName = 'kisse.db';
  static const int dbVersion = 1;
  
  // Configuration du cache
  static const Duration cacheExpiration = Duration(days: 7);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100 MB
  
  // Configuration des logs
  static const bool enableDebugLogs = true;
  static const bool enableErrorLogs = true;
  static const bool enableSecurityLogs = true;
  
  // Configuration de la sécurité
  static const bool enableBiometricAuth = true;
  static const bool enableAutoLock = true;
  static const Duration autoLockDelay = Duration(minutes: 5);
  
  // Configuration des tests
  static const bool enableTestMode = false;
  static const String testServerUrl = 'https://test-server.com';
  static const String testWsUrl = 'wss://test-server.com/ws';
} 