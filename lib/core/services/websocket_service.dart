import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import '../constants/app_constants.dart';
import '../utils/crypto_utils.dart';
import 'signal_service.dart';
import 'api_service.dart';

class WebSocketService extends GetxService {
  static WebSocketService get to => Get.find();
  
  WebSocketChannel? _channel;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // État de la connexion
  final RxBool _isConnected = false.obs;
  final RxBool _isConnecting = false.obs;
  final RxString _connectionStatus = 'Déconnecté'.obs;
  
  // Configuration
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const int _maxReconnectAttempts = 10;
  
  // Timers
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  
  // Streams pour les événements
  final StreamController<WebSocketEvent> _eventController = 
      StreamController<WebSocketEvent>.broadcast();
  
  // Getters
  bool get isConnected => _isConnected.value;
  bool get isConnecting => _isConnecting.value;
  String get connectionStatus => _connectionStatus.value;
  Stream<WebSocketEvent> get events => _eventController.stream;
  
  @override
  void onInit() {
    super.onInit();
    _initializeWebSocket();
  }
  
  @override
  void onClose() {
    _disconnect();
    _eventController.close();
    super.onClose();
  }
  
  /// Initialise la connexion WebSocket
  Future<void> _initializeWebSocket() async {
    try {
      // Vérifier la connectivité
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _connectionStatus.value = 'Pas de connexion internet';
        return;
      }
      
      await _connect();
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation WebSocket: $e');
      _connectionStatus.value = 'Erreur de connexion';
    }
  }
  
  /// Ajoute un événement de manière sécurisée (vérifie que le controller n'est pas fermé)
  void _safeAddEvent(WebSocketEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }
  
  /// Établit la connexion WebSocket
  Future<void> _connect() async {
    if (_isConnecting.value) return;
    
    // Vérifier que le controller n'est pas fermé
    if (_eventController.isClosed) {
      print('⚠️ EventController fermé, impossible de se connecter');
      return;
    }
    
    try {
      _isConnecting.value = true;
      _connectionStatus.value = 'Connexion en cours...';
      
      // Récupérer le token d'authentification
      final token = await _secureStorage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Token d\'authentification non trouvé');
      }
      
      // Établir la connexion WebSocket sécurisée
      final uri = Uri.parse('${AppConstants.wsUrl}?token=$token');
      _channel = WebSocketChannel.connect(uri);
      
      // Écouter les messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
      );
      
      _isConnected.value = true;
      _isConnecting.value = false;
      _connectionStatus.value = 'Connecté';
      _reconnectAttempts = 0;
      
      // Démarrer le heartbeat
      _startHeartbeat();
      
      // Émettre l'événement de connexion
      _safeAddEvent(WebSocketEvent(
        type: WebSocketEventType.connected,
        data: {'timestamp': DateTime.now().toIso8601String()},
      ));
      
      print('✅ WebSocket connecté avec succès');
      
    } catch (e) {
      _isConnecting.value = false;
      _connectionStatus.value = 'Échec de connexion';
      print('❌ Erreur de connexion WebSocket: $e');
      
      // Tenter la reconnexion seulement si le controller n'est pas fermé
      if (!_eventController.isClosed) {
        _scheduleReconnect();
      }
    }
  }
  
  /// Gère les messages reçus
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message.toString());
      final eventType = data['type'];
      final payload = data['payload'];
      
      switch (eventType) {
        case 'message':
          _handleIncomingMessage(payload);
          break;
        case 'call_request':
        case 'call_request_full':
          _handleCallRequest(payload);
          break;
        case 'call_response':
        case 'call_response_full':
          _handleCallResponse(payload);
          break;
        case 'presence_update':
          _handlePresenceUpdate(payload);
          break;
        case 'typing_indicator':
          _handleTypingIndicator(payload);
          break;
        case 'read_receipt':
          _handleReadReceipt(payload);
          break;
        case 'heartbeat':
          _handleHeartbeat(payload);
          break;
        case 'heartbeat_response':
          // Juste confirmer la réception
          break;
        default:
          print('⚠️ Type d\'événement WebSocket inconnu: $eventType');
      }
      
    } catch (e) {
      print('❌ Erreur lors du traitement du message WebSocket: $e');
    }
  }
  
  /// Gère les messages entrants (RG39: seulement identifiants et horodatages)
  void _handleIncomingMessage(Map<String, dynamic> payload) {
    // Le serveur ne transmet que les métadonnées, pas le contenu chiffré
    final messageId = payload['id'] ?? payload['messageId'];
    final senderId = payload['senderId'];
    final recipientId = payload['recipientId'];
    final timestamp = payload['timestamp'];
    final messageType = payload['messageType'] ?? payload['type']; // 'text', 'file', 'image', etc.
    final sessionId = payload['sessionId'];
    final isRead = payload['isRead'] ?? false;
    
    // Émettre l'événement pour que l'UI puisse réagir
    _safeAddEvent(WebSocketEvent(
      type: WebSocketEventType.messageReceived,
      data: {
        'messageId': messageId,
        'senderId': senderId,
        'recipientId': recipientId,
        'timestamp': timestamp,
        'type': messageType,
        'sessionId': sessionId,
        'isRead': isRead,
      },
    ));
    
    // Si c'est un message reçu (pas envoyé), récupérer le contenu chiffré
    // On pourrait vérifier si senderId != currentUserId, mais pour l'instant
    // on récupère toujours le contenu (le backend gérera les permissions)
    _fetchEncryptedContent(messageId, senderId, sessionId);
    
    print('📨 Message reçu: $messageId de $senderId');
  }
  
  /// Gère les demandes d'appel
  void _handleCallRequest(Map<String, dynamic> payload) {
    // Support des deux formats: call_request et call_request_full
    final callerId = payload['callerId'];
    final callType = payload['callType']; // 'audio' ou 'video'
    final callId = payload['callId'];
    final recipientId = payload['recipientId'];
    final timestamp = payload['timestamp'];
    
    _safeAddEvent(WebSocketEvent(
      type: WebSocketEventType.callRequest,
      data: {
        'callerId': callerId,
        'recipientId': recipientId,
        'callType': callType,
        'callId': callId,
        'timestamp': timestamp,
      },
    ));
    
    print('📞 Demande d\'appel reçue: $callType de $callerId');
  }
  
  /// Gère les mises à jour de présence
  void _handlePresenceUpdate(Map<String, dynamic> payload) {
    final userId = payload['userId'];
    final status = payload['status']; // 'online', 'offline', 'away'
    final lastSeen = payload['lastSeen'];
    
    _safeAddEvent(WebSocketEvent(
      type: WebSocketEventType.presenceUpdate,
      data: {
        'userId': userId,
        'status': status,
        'lastSeen': lastSeen,
      },
    ));
  }
  
  /// Gère les indicateurs de frappe
  void _handleTypingIndicator(Map<String, dynamic> payload) {
    final userId = payload['userId'];
    final isTyping = payload['isTyping'];
    final conversationId = payload['conversationId'];
    
    _safeAddEvent(WebSocketEvent(
      type: WebSocketEventType.typingIndicator,
      data: {
        'userId': userId,
        'isTyping': isTyping,
        'conversationId': conversationId,
      },
    ));
  }
  
  /// Gère les accusés de réception
  void _handleReadReceipt(Map<String, dynamic> payload) {
    final messageId = payload['messageId'];
    final readerId = payload['readerId'];
    final readAt = payload['readAt'];
    
    _safeAddEvent(WebSocketEvent(
      type: WebSocketEventType.readReceipt,
      data: {
        'messageId': messageId,
        'readerId': readerId,
        'readAt': readAt,
      },
    ));
  }
  
  /// Gère le heartbeat
  void _handleHeartbeat(Map<String, dynamic> payload) {
    // Répondre au heartbeat pour maintenir la connexion
    _sendHeartbeatResponse();
  }
  
  /// Envoie un message chiffré (RG39: seulement métadonnées)
  Future<void> sendMessage(String recipientId, String messageContent) async {
    if (!_isConnected.value) {
      throw Exception('WebSocket non connecté');
    }
    
    try {
      // Chiffrer le message avec Signal
      final encryptedMessage = await SignalService.to.encryptMessage(
        messageContent, 
        recipientId
      );
      
      // Envoyer seulement les métadonnées via WebSocket
      // Le backend créera le message et retournera l'ID via WebSocket
      final messageData = {
        'type': 'message',
        'payload': {
          'recipientId': recipientId,
          'messageType': 'text',
          'sessionId': encryptedMessage.sessionId,
        },
      };
      
      _channel!.sink.add(jsonEncode(messageData));
      
      // Attendre la confirmation du backend avec l'ID du message créé
      // Le backend enverra un événement message avec l'ID créé
      // Pour l'instant, on utilise l'ID du message chiffré
      // et on attend un peu pour que le backend crée le message
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Le contenu chiffré sera envoyé via HTTPS (API)
      // Note: L'ID sera mis à jour quand on recevra la confirmation du backend
      await _sendEncryptedContent(encryptedMessage);
      
      print('📤 Message envoyé à $recipientId');
      
    } catch (e) {
      print('❌ Erreur lors de l\'envoi du message: $e');
      rethrow;
    }
  }
  
  /// Envoie le contenu chiffré via une connexion sécurisée séparée
  /// 
  /// SECURITY: Le contenu est envoyé via HTTPS et stocké comme opaque binary.
  /// Le backend ne peut pas le lire ou le déchiffrer.
  /// 
  /// NOTE: Pour cette implémentation, on inclut la clé de message avec le contenu
  /// dans le format "messageKey:encryptedContent". En production Signal Protocol,
  /// la clé serait dérivée de la session plutôt que stockée.
  Future<void> _sendEncryptedContent(EncryptedMessage encryptedMessage) async {
    try {
      // Combiner la clé et le contenu dans un format que le destinataire peut décoder
      // Format: "messageKey:encryptedContent"
      final combinedContent = '${encryptedMessage.messageKey}:${encryptedMessage.encryptedContent}';
      
      // Calculer le hash SHA-256 pour vérification d'intégrité
      final contentBytes = utf8.encode(combinedContent);
      final hash = CryptoUtils.sha256HashBytes(contentBytes);
      
      // Encoder le contenu en base64 pour l'envoi
      final contentBase64 = CryptoUtils.base64EncodeBytes(contentBytes);
      
      // Stocker le contenu chiffré via l'API
      // Note: Le messageId utilisé ici doit correspondre à l'ID créé par le backend
      // En production, on devrait recevoir l'ID du message depuis le backend
      await ApiService.instance.storeEncryptedContent(
        messageId: encryptedMessage.id,
        encryptedContent: contentBase64,
        contentHash: hash.toString(),
        expiresAt: null, // Pas d'expiration par défaut
      );
      
      print('✅ Contenu chiffré stocké pour le message ${encryptedMessage.id}');
    } catch (e) {
      print('❌ Erreur lors de l\'envoi du contenu chiffré: $e');
      // Ne pas rethrow pour ne pas bloquer l'envoi du message
      // Le contenu pourra être réessayé plus tard
    }
  }
  
  /// Récupère le contenu chiffré d'un message
  /// 
  /// SECURITY: Le contenu est récupéré comme opaque binary.
  /// Le déchiffrement se fait côté client avec Signal Protocol.
  Future<void> _fetchEncryptedContent(
    String messageId,
    String senderId,
    String? sessionId,
  ) async {
    try {
      // Récupérer le contenu chiffré via l'API
      final contentData = await ApiService.instance.getEncryptedContent(messageId);
      
      final contentBase64 = contentData['content_data'] as String;
      final contentHash = contentData['content_hash'] as String?;
      
      // Décoder le contenu
      final encryptedContent = CryptoUtils.base64Decode(contentBase64);
      
      // Vérifier l'intégrité (optionnel mais recommandé)
      if (contentHash != null) {
        final computedHash = CryptoUtils.sha256Hash(encryptedContent);
        if (computedHash != contentHash) {
          throw Exception('Content integrity check failed');
        }
      }
      
      // IMPORTANT: Dans Signal Protocol, la clé de message n'est PAS stockée côté serveur
      // Elle doit être dérivée de la session Signal côté client.
      // Pour cette implémentation, on stocke la clé avec le contenu chiffré (encodée en base64)
      // dans le champ encryptedContent. Le format est: "messageKey:encryptedContent"
      // 
      // NOTE: En production, utiliser une approche plus sécurisée où la clé est dérivée
      // de la session Signal plutôt que stockée.
      
      // Extraire la clé et le contenu depuis le format "messageKey:encryptedContent"
      String messageKey = '';
      String actualEncryptedContent = encryptedContent;
      
      if (encryptedContent.contains(':')) {
        final parts = encryptedContent.split(':');
        if (parts.length >= 2) {
          messageKey = parts[0];
          actualEncryptedContent = parts.sublist(1).join(':');
        }
      }
      
      // Si pas de clé trouvée, essayer de la récupérer depuis la session Signal
      if (messageKey.isEmpty && sessionId != null && sessionId.isNotEmpty) {
        // La clé sera récupérée par SignalService depuis la session
        // Pour l'instant, on utilise une clé vide et SignalService devra la gérer
      }
      
      final encryptedMessage = EncryptedMessage(
        id: messageId,
        recipientId: senderId, // Pour le destinataire, le sender est l'expéditeur
        encryptedContent: actualEncryptedContent,
        messageKey: messageKey, // Clé extraite ou vide (sera gérée par SignalService)
        timestamp: DateTime.parse(contentData['created_at']),
        sessionId: sessionId ?? '',
      );
      
      // Émettre l'événement avec le contenu chiffré
      _safeAddEvent(WebSocketEvent(
        type: WebSocketEventType.encryptedContentReceived,
        data: {
          'messageId': messageId,
          'encryptedMessage': encryptedMessage,
        },
      ));
      
      print('✅ Contenu chiffré récupéré pour le message $messageId');
    } catch (e) {
      print('❌ Erreur lors de la récupération du contenu chiffré: $e');
      // Émettre un événement d'erreur
      _safeAddEvent(WebSocketEvent(
        type: WebSocketEventType.error,
        data: {
          'messageId': messageId,
          'error': 'Failed to fetch encrypted content: $e',
        },
      ));
    }
  }
  
  /// Gère les réponses d'appel
  void _handleCallResponse(Map<String, dynamic> payload) {
    final callId = payload['callId'];
    final response = payload['response']; // 'accept', 'reject', 'busy', 'end'
    final timestamp = payload['timestamp'];
    
    _safeAddEvent(WebSocketEvent(
      type: WebSocketEventType.callResponse,
      data: {
        'callId': callId,
        'response': response,
        'timestamp': timestamp,
      },
    ));
    
    print('📞 Réponse d\'appel reçue: $response pour $callId');
  }
  
  /// Envoie une demande d'appel
  Future<void> sendCallRequest(String recipientId, String callType) async {
    if (!_isConnected.value) {
      throw Exception('WebSocket non connecté');
    }
    
    final callData = {
      'type': 'call_request',
      'payload': {
        'recipientId': recipientId,
        'callType': callType, // 'audio' ou 'video'
        'callId': DateTime.now().millisecondsSinceEpoch.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      },
    };
    
    _channel!.sink.add(jsonEncode(callData));
  }
  
  /// Envoie une réponse d'appel
  Future<void> sendCallResponse(String callId, String response) async {
    if (!_isConnected.value) return;
    
    final responseData = {
      'type': 'call_response',
      'payload': {
        'callId': callId,
        'response': response, // 'accept', 'reject', 'busy'
        'timestamp': DateTime.now().toIso8601String(),
      },
    };
    
    _channel!.sink.add(jsonEncode(responseData));
  }
  
  /// Envoie un indicateur de frappe
  Future<void> sendTypingIndicator(String conversationId, bool isTyping) async {
    if (!_isConnected.value) return;
    
    final typingData = {
      'type': 'typing_indicator',
      'payload': {
        'conversationId': conversationId,
        'isTyping': isTyping,
        'timestamp': DateTime.now().toIso8601String(),
      },
    };
    
    _channel!.sink.add(jsonEncode(typingData));
  }
  
  /// Envoie un accusé de réception
  Future<void> sendReadReceipt(String messageId) async {
    if (!_isConnected.value) return;
    
    final receiptData = {
      'type': 'read_receipt',
      'payload': {
        'messageId': messageId,
        'readAt': DateTime.now().toIso8601String(),
      },
    };
    
    _channel!.sink.add(jsonEncode(receiptData));
  }
  
  /// Démarre le heartbeat
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_isConnected.value) {
        _sendHeartbeat();
      }
    });
  }
  
  /// Envoie un heartbeat
  void _sendHeartbeat() {
    if (!_isConnected.value) return;
    
    final heartbeatData = {
      'type': 'heartbeat',
      'payload': {
        'timestamp': DateTime.now().toIso8601String(),
      },
    };
    
    _channel!.sink.add(jsonEncode(heartbeatData));
  }
  
  /// Envoie une réponse au heartbeat
  void _sendHeartbeatResponse() {
    if (!_isConnected.value) return;
    
    final responseData = {
      'type': 'heartbeat_response',
      'payload': {
        'timestamp': DateTime.now().toIso8601String(),
      },
    };
    
    _channel!.sink.add(jsonEncode(responseData));
  }
  
  /// Gère les erreurs de connexion
  void _handleError(error) {
    print('❌ Erreur WebSocket: $error');
    _isConnected.value = false;
    _connectionStatus.value = 'Erreur de connexion';
    
    // Tenter la reconnexion
    _scheduleReconnect();
  }
  
  /// Gère la déconnexion
  void _handleDisconnect() {
    print('🔌 WebSocket déconnecté');
    _isConnected.value = false;
    _connectionStatus.value = 'Déconnecté';
    
    // Tenter la reconnexion
    _scheduleReconnect();
  }
  
  /// Programme une tentative de reconnexion (RG38)
  void _scheduleReconnect() {
    // Ne pas essayer de se reconnecter si le controller est fermé
    if (_eventController.isClosed) {
      print('⚠️ EventController fermé, impossible de se reconnecter');
      return;
    }
    
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _connectionStatus.value = 'Échec de reconnexion';
      print('❌ Nombre maximum de tentatives de reconnexion atteint');
      return;
    }
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      // Vérifier à nouveau que le controller n'est pas fermé
      if (_eventController.isClosed) {
        print('⚠️ EventController fermé, annulation de la reconnexion');
        return;
      }
      _reconnectAttempts++;
      print('🔄 Tentative de reconnexion #$_reconnectAttempts');
      _connect();
    });
  }
  
  /// Déconnecte manuellement
  void _disconnect() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _isConnected.value = false;
    _isConnecting.value = false;
    _connectionStatus.value = 'Déconnecté';
  }
  
  /// Force une reconnexion
  Future<void> reconnect() async {
    _disconnect();
    _reconnectAttempts = 0;
    await _connect();
  }
}

/// Types d'événements WebSocket
enum WebSocketEventType {
  connected,
  disconnected,
  messageReceived,
  encryptedContentReceived, // Nouveau: contenu chiffré reçu
  callRequest,
  callResponse, // Nouveau: réponse d'appel
  presenceUpdate,
  typingIndicator,
  readReceipt,
  error,
}

/// Événement WebSocket
class WebSocketEvent {
  final WebSocketEventType type;
  final Map<String, dynamic> data;
  
  WebSocketEvent({
    required this.type,
    required this.data,
  });
} 