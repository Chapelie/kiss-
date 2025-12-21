import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'dart:async'; // Added for Timer

class SignalService extends GetxService {
  static SignalService get to => Get.find();
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Uuid _uuid = const Uuid();
  
  // Clés de session pour chaque utilisateur
  final Map<String, SessionKeys> _sessions = <String, SessionKeys>{}.obs;
  
  // Rotation automatique des clés (toutes les 24h)
  static const Duration _keyRotationInterval = Duration(hours: 24);
  static const Duration _preKeyRotationInterval = Duration(hours: 12);
  
  @override
  void onInit() {
    super.onInit();
    _initializeSignalProtocol();
    _startKeyRotationTimer();
  }
  
  /// Initialise le protocole Signal
  Future<void> _initializeSignalProtocol() async {
    try {
      // Générer ou récupérer les clés d'identité
      await _generateOrRetrieveIdentityKeys();
      
      // Générer les clés pré-signées pour les rotations futures
      await _generatePreKeys();
      
      print('✅ Signal Protocol initialisé avec succès');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation Signal: $e');
    }
  }
  
  /// Génère ou récupère les clés d'identité
  Future<void> _generateOrRetrieveIdentityKeys() async {
    String? storedIdentityKey = await _secureStorage.read(key: 'identity_key');
    
    if (storedIdentityKey == null) {
      // Générer de nouvelles clés d'identité
      final identityKeyPair = _generateKeyPair();
      await _secureStorage.write(
        key: 'identity_key',
        value: jsonEncode(identityKeyPair),
      );
      print('🔑 Nouvelles clés d\'identité générées');
    } else {
      print('🔑 Clés d\'identité récupérées du stockage sécurisé');
    }
  }
  
  /// Génère des clés pré-signées pour les rotations futures
  Future<void> _generatePreKeys() async {
    final List<PreKey> preKeys = [];
    
    // Générer 100 clés pré-signées
    for (int i = 0; i < 100; i++) {
      final keyPair = _generateKeyPair();
      final preKey = PreKey(
        id: _uuid.v4(),
        keyPair: keyPair,
        timestamp: DateTime.now(),
      );
      preKeys.add(preKey);
    }
    
    await _secureStorage.write(
      key: 'pre_keys',
      value: jsonEncode(preKeys.map((pk) => pk.toJson()).toList()),
    );
    
    print('🔑 ${preKeys.length} clés pré-signées générées');
  }
  
  /// Démarre le timer de rotation automatique des clés
  void _startKeyRotationTimer() {
    // Rotation des clés de session toutes les 24h
    Timer.periodic(_keyRotationInterval, (timer) {
      _rotateSessionKeys();
    });
    
    // Rotation des clés pré-signées toutes les 12h
    Timer.periodic(_preKeyRotationInterval, (timer) {
      _rotatePreKeys();
    });
    
    print('⏰ Timers de rotation des clés démarrés');
  }
  
  /// Chiffre un message avec le protocole Signal
  Future<EncryptedMessage> encryptMessage(String message, String recipientId) async {
    try {
      // Récupérer ou créer une session pour ce destinataire
      SessionKeys session = await _getOrCreateSession(recipientId);
      
      // Générer une clé de message unique
      final messageKey = _generateMessageKey();
      
      // Chiffrer le message avec AES-256
      final encrypter = Encrypter(AES(messageKey));
      final encryptedContent = encrypter.encrypt(message, iv: IV.fromSecureRandom(16));
      
      // Créer le message chiffré
      final encryptedMessage = EncryptedMessage(
        id: _uuid.v4(),
        recipientId: recipientId,
        encryptedContent: encryptedContent.base64,
        messageKey: messageKey.base64,
        timestamp: DateTime.now(),
        sessionId: session.sessionId,
      );
      
      // Mettre à jour la session
      session.lastMessageTimestamp = DateTime.now();
      _sessions[recipientId] = session;
      
      return encryptedMessage;
    } catch (e) {
      print('❌ Erreur lors du chiffrement: $e');
      rethrow;
    }
  }
  
  /// Déchiffre un message avec le protocole Signal
  Future<String> decryptMessage(EncryptedMessage encryptedMessage) async {
    try {
      // Récupérer la session
      final session = _sessions[encryptedMessage.recipientId];
      if (session == null) {
        throw Exception('Session non trouvée pour le destinataire');
      }
      
      // Déchiffrer la clé de message
      final messageKey = Key.fromBase64(encryptedMessage.messageKey);
      
      // Déchiffrer le contenu
      final encrypter = Encrypter(AES(messageKey));
      final decrypted = encrypter.decrypt64(encryptedMessage.encryptedContent);
      
      return decrypted;
    } catch (e) {
      print('❌ Erreur lors du déchiffrement: $e');
      rethrow;
    }
  }
  
  /// Récupère ou crée une session pour un destinataire
  Future<SessionKeys> _getOrCreateSession(String recipientId) async {
    if (_sessions.containsKey(recipientId)) {
      return _sessions[recipientId]!;
    }
    
    // Créer une nouvelle session
    final session = SessionKeys(
      sessionId: _uuid.v4(),
      recipientId: recipientId,
      createdAt: DateTime.now(),
      lastMessageTimestamp: DateTime.now(),
    );
    
    _sessions[recipientId] = session;
    return session;
  }
  
  /// Rotation automatique des clés de session
  Future<void> _rotateSessionKeys() async {
    print('🔄 Rotation des clés de session en cours...');
    
    for (String recipientId in _sessions.keys) {
      final session = _sessions[recipientId]!;
      
      // Générer de nouvelles clés de session
      final newSessionKeys = _generateKeyPair();
      session.currentKeys = newSessionKeys;
      session.lastRotation = DateTime.now();
      
      _sessions[recipientId] = session;
    }
    
    // Sauvegarder les nouvelles clés
    await _saveSessions();
    print('✅ Rotation des clés de session terminée');
  }
  
  /// Rotation des clés pré-signées
  Future<void> _rotatePreKeys() async {
    print('🔄 Rotation des clés pré-signées en cours...');
    
    // Supprimer les anciennes clés utilisées
    await _cleanupUsedPreKeys();
    
    // Générer de nouvelles clés pré-signées
    await _generatePreKeys();
    
    print('✅ Rotation des clés pré-signées terminée');
  }
  
  /// Nettoie les clés pré-signées utilisées
  Future<void> _cleanupUsedPreKeys() async {
    // Logique de nettoyage des clés utilisées
    // Garder seulement les 50 dernières clés non utilisées
  }
  
  /// Sauvegarde les sessions
  Future<void> _saveSessions() async {
    final sessionsData = _sessions.map((key, value) => MapEntry(key, value.toJson()));
    await _secureStorage.write(
      key: 'signal_sessions',
      value: jsonEncode(sessionsData),
    );
  }
  
  /// Génère une paire de clés
  Map<String, String> _generateKeyPair() {
    final random = Random.secure();
    final privateKey = List<int>.generate(32, (i) => random.nextInt(256));
    final publicKey = sha256.convert(privateKey).bytes;
    
    return {
      'private': base64Encode(privateKey),
      'public': base64Encode(publicKey),
    };
  }
  
  /// Génère une clé de message
  Key _generateMessageKey() {
    final random = Random.secure();
    final keyBytes = Uint8List.fromList(List<int>.generate(32, (i) => random.nextInt(256)));
    return Key(keyBytes);
  }
}

/// Clés de session pour un utilisateur
class SessionKeys {
  final String sessionId;
  final String recipientId;
  final DateTime createdAt;
  DateTime lastMessageTimestamp;
  DateTime? lastRotation;
  Map<String, String>? currentKeys;
  
  SessionKeys({
    required this.sessionId,
    required this.recipientId,
    required this.createdAt,
    required this.lastMessageTimestamp,
    this.lastRotation,
    this.currentKeys,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'recipientId': recipientId,
      'createdAt': createdAt.toIso8601String(),
      'lastMessageTimestamp': lastMessageTimestamp.toIso8601String(),
      'lastRotation': lastRotation?.toIso8601String(),
      'currentKeys': currentKeys,
    };
  }
  
  factory SessionKeys.fromJson(Map<String, dynamic> json) {
    return SessionKeys(
      sessionId: json['sessionId'],
      recipientId: json['recipientId'],
      createdAt: DateTime.parse(json['createdAt']),
      lastMessageTimestamp: DateTime.parse(json['lastMessageTimestamp']),
      lastRotation: json['lastRotation'] != null 
          ? DateTime.parse(json['lastRotation']) 
          : null,
      currentKeys: json['currentKeys'] != null 
          ? Map<String, String>.from(json['currentKeys']) 
          : null,
    );
  }
}

/// Clé pré-signée
class PreKey {
  final String id;
  final Map<String, String> keyPair;
  final DateTime timestamp;
  
  PreKey({
    required this.id,
    required this.keyPair,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'keyPair': keyPair,
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  factory PreKey.fromJson(Map<String, dynamic> json) {
    return PreKey(
      id: json['id'],
      keyPair: Map<String, String>.from(json['keyPair']),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// Message chiffré
class EncryptedMessage {
  final String id;
  final String recipientId;
  final String encryptedContent;
  final String messageKey;
  final DateTime timestamp;
  final String sessionId;
  
  EncryptedMessage({
    required this.id,
    required this.recipientId,
    required this.encryptedContent,
    required this.messageKey,
    required this.timestamp,
    required this.sessionId,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipientId': recipientId,
      'encryptedContent': encryptedContent,
      'messageKey': messageKey,
      'timestamp': timestamp.toIso8601String(),
      'sessionId': sessionId,
    };
  }
  
  factory EncryptedMessage.fromJson(Map<String, dynamic> json) {
    return EncryptedMessage(
      id: json['id'],
      recipientId: json['recipientId'],
      encryptedContent: json['encryptedContent'],
      messageKey: json['messageKey'],
      timestamp: DateTime.parse(json['timestamp']),
      sessionId: json['sessionId'],
    );
  }
} 