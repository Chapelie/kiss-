import 'dart:convert';
import 'dart:async';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'signal_service.dart';

class WebSocketService extends GetxService {
  static WebSocketService get to => Get.find();
  
  WebSocketChannel? _channel;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // État de la connexion
  final RxBool _isConnected = false.obs;
  final RxBool _isConnecting = false.obs;
  final RxString _connectionStatus = 'Déconnecté'.obs;
  
  // Configuration
  static const String _wsUrl = 'wss://your-server.com/ws';
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
  
  /// Établit la connexion WebSocket
  Future<void> _connect() async {
    if (_isConnecting.value) return;
    
    try {
      _isConnecting.value = true;
      _connectionStatus.value = 'Connexion en cours...';
      
      // Récupérer le token d'authentification
      final token = await _secureStorage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Token d\'authentification non trouvé');
      }
      
      // Établir la connexion WebSocket sécurisée
      final uri = Uri.parse('$_wsUrl?token=$token');
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
      _eventController.add(WebSocketEvent(
        type: WebSocketEventType.connected,
        data: {'timestamp': DateTime.now().toIso8601String()},
      ));
      
      print('✅ WebSocket connecté avec succès');
      
    } catch (e) {
      _isConnecting.value = false;
      _connectionStatus.value = 'Échec de connexion';
      print('❌ Erreur de connexion WebSocket: $e');
      
      // Tenter la reconnexion
      _scheduleReconnect();
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
          _handleCallRequest(payload);
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
    final messageId = payload['messageId'];
    final senderId = payload['senderId'];
    final timestamp = payload['timestamp'];
    final messageType = payload['type']; // 'text', 'file', 'image', etc.
    
    // Émettre l'événement pour que l'UI puisse réagir
    _eventController.add(WebSocketEvent(
      type: WebSocketEventType.messageReceived,
      data: {
        'messageId': messageId,
        'senderId': senderId,
        'timestamp': timestamp,
        'type': messageType,
      },
    ));
    
    print('📨 Message reçu: $messageId de $senderId');
  }
  
  /// Gère les demandes d'appel
  void _handleCallRequest(Map<String, dynamic> payload) {
    final callerId = payload['callerId'];
    final callType = payload['callType']; // 'audio' ou 'video'
    final callId = payload['callId'];
    
    _eventController.add(WebSocketEvent(
      type: WebSocketEventType.callRequest,
      data: {
        'callerId': callerId,
        'callType': callType,
        'callId': callId,
      },
    ));
    
    print('📞 Demande d\'appel reçue: $callType de $callerId');
  }
  
  /// Gère les mises à jour de présence
  void _handlePresenceUpdate(Map<String, dynamic> payload) {
    final userId = payload['userId'];
    final status = payload['status']; // 'online', 'offline', 'away'
    final lastSeen = payload['lastSeen'];
    
    _eventController.add(WebSocketEvent(
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
    
    _eventController.add(WebSocketEvent(
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
    
    _eventController.add(WebSocketEvent(
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
      final messageData = {
        'type': 'message',
        'payload': {
          'messageId': encryptedMessage.id,
          'recipientId': recipientId,
          'timestamp': encryptedMessage.timestamp.toIso8601String(),
          'sessionId': encryptedMessage.sessionId,
          'messageType': 'text',
        },
      };
      
      _channel!.sink.add(jsonEncode(messageData));
      
      // Le contenu chiffré sera envoyé via une autre méthode sécurisée
      await _sendEncryptedContent(encryptedMessage);
      
      print('📤 Message envoyé à $recipientId');
      
    } catch (e) {
      print('❌ Erreur lors de l\'envoi du message: $e');
      rethrow;
    }
  }
  
  /// Envoie le contenu chiffré via une connexion sécurisée séparée
  Future<void> _sendEncryptedContent(EncryptedMessage encryptedMessage) async {
    // Implémentation pour envoyer le contenu chiffré
    // via HTTPS ou une autre méthode sécurisée
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
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _connectionStatus.value = 'Échec de reconnexion';
      print('❌ Nombre maximum de tentatives de reconnexion atteint');
      return;
    }
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
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
  callRequest,
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