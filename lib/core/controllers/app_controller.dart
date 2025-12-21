import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/signal_service.dart';
import '../services/websocket_service.dart';

class AppController extends GetxController {
  static AppController get to => Get.find();
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // État de l'application
  final RxBool _isAuthenticated = false.obs;
  final RxBool _isInitialized = false.obs;
  final RxString _currentUserId = ''.obs;
  final RxString _appStatus = 'Initialisation...'.obs;
  
  // État des services
  final RxBool _signalReady = false.obs;
  final RxBool _websocketReady = false.obs;
  
  // Messages et conversations
  final RxList<ChatMessage> _messages = <ChatMessage>[].obs;
  final RxList<Conversation> _conversations = <Conversation>[].obs;
  final RxMap<String, bool> _typingUsers = <String, bool>{}.obs;
  
  // Appels
  final RxBool _inCall = false.obs;
  final RxString _currentCallId = ''.obs;
  final RxString _currentCallType = ''.obs;
  
  // Getters
  bool get isAuthenticated => _isAuthenticated.value;
  bool get isInitialized => _isInitialized.value;
  String get currentUserId => _currentUserId.value;
  String get appStatus => _appStatus.value;
  bool get signalReady => _signalReady.value;
  bool get websocketReady => _websocketReady.value;
  List<ChatMessage> get messages => _messages;
  List<Conversation> get conversations => _conversations;
  bool get inCall => _inCall.value;
  
  @override
  void onInit() {
    super.onInit();
    _initializeApp();
  }
  
  /// Initialise l'application
  Future<void> _initializeApp() async {
    try {
      _appStatus.value = 'Vérification de l\'authentification...';
      
      // Vérifier si l'utilisateur est authentifié
      await _checkAuthentication();
      
      if (_isAuthenticated.value) {
        _appStatus.value = 'Initialisation des services...';
        
        // Initialiser Signal Service
        await _initializeSignalService();
        
        // Initialiser WebSocket Service
        await _initializeWebSocketService();
        
        // Charger les conversations
        await _loadConversations();
        
        // Écouter les événements WebSocket
        _listenToWebSocketEvents();
        
        _isInitialized.value = true;
        _appStatus.value = 'Prêt';
        
        print('✅ Application initialisée avec succès');
      } else {
        _appStatus.value = 'Authentification requise';
      }
      
    } catch (e) {
      _appStatus.value = 'Erreur d\'initialisation';
      print('❌ Erreur lors de l\'initialisation: $e');
    }
  }
  
  /// Vérifie l'authentification
  Future<void> _checkAuthentication() async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      final userId = await _secureStorage.read(key: 'user_id');
      
      if (token != null && userId != null) {
        _isAuthenticated.value = true;
        _currentUserId.value = userId;
        print('✅ Utilisateur authentifié: $userId');
      } else {
        _isAuthenticated.value = false;
        print('❌ Aucun utilisateur authentifié');
      }
    } catch (e) {
      _isAuthenticated.value = false;
      print('❌ Erreur lors de la vérification d\'authentification: $e');
    }
  }
  
  /// Initialise le service Signal
  Future<void> _initializeSignalService() async {
    try {
      // Initialiser Signal Service
      await Get.putAsync(() async {
        final service = SignalService();
        service.onInit();
        return service;
      });
      
      _signalReady.value = true;
      print('✅ Signal Service initialisé');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation Signal: $e');
      rethrow;
    }
  }
  
  /// Initialise le service WebSocket
  Future<void> _initializeWebSocketService() async {
    try {
      // Initialiser WebSocket Service
      await Get.putAsync(() async {
        final service = WebSocketService();
        service.onInit();
        return service;
      });
      
      _websocketReady.value = true;
      print('✅ WebSocket Service initialisé');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation WebSocket: $e');
      rethrow;
    }
  }
  
  /// Écoute les événements WebSocket
  void _listenToWebSocketEvents() {
    WebSocketService.to.events.listen((event) {
      switch (event.type) {
        case WebSocketEventType.connected:
          _handleWebSocketConnected(event);
          break;
        case WebSocketEventType.messageReceived:
          _handleMessageReceived(event);
          break;
        case WebSocketEventType.callRequest:
          _handleCallRequest(event);
          break;
        case WebSocketEventType.presenceUpdate:
          _handlePresenceUpdate(event);
          break;
        case WebSocketEventType.typingIndicator:
          _handleTypingIndicator(event);
          break;
        case WebSocketEventType.readReceipt:
          _handleReadReceipt(event);
          break;
        case WebSocketEventType.disconnected:
          _handleWebSocketDisconnected(event);
          break;
        case WebSocketEventType.error:
          _handleWebSocketError(event);
          break;
      }
    });
  }
  
  /// Gère la connexion WebSocket
  void _handleWebSocketConnected(WebSocketEvent event) {
    print('🔗 WebSocket connecté');
    _websocketReady.value = true;
  }
  
  /// Gère la déconnexion WebSocket
  void _handleWebSocketDisconnected(WebSocketEvent event) {
    print('🔌 WebSocket déconnecté');
    _websocketReady.value = false;
  }
  
  /// Gère les erreurs WebSocket
  void _handleWebSocketError(WebSocketEvent event) {
    print('❌ Erreur WebSocket: ${event.data}');
  }
  
  /// Gère les messages reçus
  void _handleMessageReceived(WebSocketEvent event) {
    final messageId = event.data['messageId'];
    final senderId = event.data['senderId'];
    final timestamp = DateTime.parse(event.data['timestamp']);
    final messageType = event.data['type'];
    
    // Créer un nouveau message
    final message = ChatMessage(
      id: messageId,
      senderId: senderId,
      content: '', // Le contenu sera déchiffré séparément
      timestamp: timestamp,
      type: messageType,
      isEncrypted: true,
    );
    
    // Ajouter le message à la liste
    _messages.add(message);
    
    // Mettre à jour la conversation
    _updateConversation(senderId, message);
    
    print('📨 Nouveau message reçu: $messageId');
  }
  
  /// Gère les demandes d'appel
  void _handleCallRequest(WebSocketEvent event) {
    final callerId = event.data['callerId'];
    final callType = event.data['callType'];
    final callId = event.data['callId'];
    
    // Vérifier si on est déjà en appel
    if (_inCall.value) {
      // Rejeter l'appel si on est occupé
      WebSocketService.to.sendCallResponse(callId, 'busy');
      return;
    }
    
    // Afficher la notification d'appel entrant
    _showIncomingCallNotification(callerId, callType, callId);
  }
  
  /// Gère les mises à jour de présence
  void _handlePresenceUpdate(WebSocketEvent event) {
    final userId = event.data['userId'];
    final status = event.data['status'];
    final lastSeen = DateTime.parse(event.data['lastSeen']);
    
    // Mettre à jour la présence dans les conversations
    _updateUserPresence(userId, status, lastSeen);
  }
  
  /// Gère les indicateurs de frappe
  void _handleTypingIndicator(WebSocketEvent event) {
    final userId = event.data['userId'];
    final isTyping = event.data['isTyping'];
    final conversationId = event.data['conversationId'];
    
    _typingUsers[userId] = isTyping;
  }
  
  /// Gère les accusés de réception
  void _handleReadReceipt(WebSocketEvent event) {
    final messageId = event.data['messageId'];
    final readerId = event.data['readerId'];
    final readAt = DateTime.parse(event.data['readAt']);
    
    // Mettre à jour le statut de lecture du message
    _updateMessageReadStatus(messageId, readerId, readAt);
  }
  
  /// Envoie un message
  Future<void> sendMessage(String recipientId, String content) async {
    try {
      // Vérifier que les services sont prêts
      if (!_signalReady.value || !_websocketReady.value) {
        throw Exception('Services non prêts');
      }
      
      // Envoyer le message via WebSocket
      await WebSocketService.to.sendMessage(recipientId, content);
      
      // Créer le message local
      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: _currentUserId.value,
        content: content,
        timestamp: DateTime.now(),
        type: 'text',
        isEncrypted: true,
        isSent: true,
      );
      
      // Ajouter à la liste des messages
      _messages.add(message);
      
      // Mettre à jour la conversation
      _updateConversation(recipientId, message);
      
      print('📤 Message envoyé à $recipientId');
      
    } catch (e) {
      print('❌ Erreur lors de l\'envoi du message: $e');
      rethrow;
    }
  }
  
  /// Démarre un appel
  Future<void> startCall(String recipientId, String callType) async {
    try {
      if (_inCall.value) {
        throw Exception('Déjà en appel');
      }
      
      // Envoyer la demande d'appel
      await WebSocketService.to.sendCallRequest(recipientId, callType);
      
      // Mettre à jour l'état de l'appel
      _inCall.value = true;
      _currentCallId.value = DateTime.now().millisecondsSinceEpoch.toString();
      _currentCallType.value = callType;
      
      print('📞 Appel $callType initié vers $recipientId');
      
    } catch (e) {
      print('❌ Erreur lors de l\'initiation de l\'appel: $e');
      rethrow;
    }
  }
  
  /// Accepte un appel
  Future<void> acceptCall(String callId) async {
    try {
      await WebSocketService.to.sendCallResponse(callId, 'accept');
      
      // Démarrer l'appel (intégration avec Agora)
      _startAgoraCall();
      
    } catch (e) {
      print('❌ Erreur lors de l\'acceptation de l\'appel: $e');
      rethrow;
    }
  }
  
  /// Rejette un appel
  Future<void> rejectCall(String callId) async {
    try {
      await WebSocketService.to.sendCallResponse(callId, 'reject');
      _inCall.value = false;
      _currentCallId.value = '';
      _currentCallType.value = '';
    } catch (e) {
      print('❌ Erreur lors du rejet de l\'appel: $e');
    }
  }
  
  /// Termine un appel
  Future<void> endCall() async {
    try {
      _inCall.value = false;
      _currentCallId.value = '';
      _currentCallType.value = '';
      
      // Terminer l'appel Agora
      _endAgoraCall();
      
    } catch (e) {
      print('❌ Erreur lors de la terminaison de l\'appel: $e');
    }
  }
  
  /// Envoie un indicateur de frappe
  Future<void> sendTypingIndicator(String conversationId, bool isTyping) async {
    try {
      await WebSocketService.to.sendTypingIndicator(conversationId, isTyping);
    } catch (e) {
      print('❌ Erreur lors de l\'envoi de l\'indicateur de frappe: $e');
    }
  }
  
  /// Envoie un accusé de réception
  Future<void> sendReadReceipt(String messageId) async {
    try {
      await WebSocketService.to.sendReadReceipt(messageId);
    } catch (e) {
      print('❌ Erreur lors de l\'envoi de l\'accusé de réception: $e');
    }
  }
  
  /// Charge les conversations
  Future<void> _loadConversations() async {
    // Implémentation pour charger les conversations depuis la base de données locale
  }
  
  /// Met à jour une conversation
  void _updateConversation(String userId, ChatMessage message) {
    // Implémentation pour mettre à jour une conversation
  }
  
  /// Met à jour la présence d'un utilisateur
  void _updateUserPresence(String userId, String status, DateTime lastSeen) {
    // Implémentation pour mettre à jour la présence
  }
  
  /// Met à jour le statut de lecture d'un message
  void _updateMessageReadStatus(String messageId, String readerId, DateTime readAt) {
    // Implémentation pour mettre à jour le statut de lecture
  }
  
  /// Affiche la notification d'appel entrant
  void _showIncomingCallNotification(String callerId, String callType, String callId) {
    // Implémentation pour afficher la notification d'appel
  }
  
  /// Démarre l'appel Agora
  void _startAgoraCall() {
    // Implémentation pour démarrer l'appel Agora
  }
  
  /// Termine l'appel Agora
  void _endAgoraCall() {
    // Implémentation pour terminer l'appel Agora
  }
  
  /// Déconnecte l'utilisateur
  Future<void> logout() async {
    try {
      // Nettoyer les services
      WebSocketService.to.onClose();
      SignalService.to.onClose();
      
      // Supprimer les données d'authentification
      await _secureStorage.delete(key: 'auth_token');
      await _secureStorage.delete(key: 'user_id');
      
      // Réinitialiser l'état
      _isAuthenticated.value = false;
      _isInitialized.value = false;
      _currentUserId.value = '';
      _appStatus.value = 'Déconnecté';
      
      print('✅ Déconnexion réussie');
      
    } catch (e) {
      print('❌ Erreur lors de la déconnexion: $e');
    }
  }
}

/// Modèle de message
class ChatMessage {
  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final String type; // 'text', 'image', 'file', 'audio', 'video'
  final bool isEncrypted;
  final bool isSent;
  final bool isRead;
  final DateTime? readAt;
  
  ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.type,
    this.isEncrypted = false,
    this.isSent = false,
    this.isRead = false,
    this.readAt,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'isEncrypted': isEncrypted,
      'isSent': isSent,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
    };
  }
  
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      senderId: json['senderId'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      type: json['type'],
      isEncrypted: json['isEncrypted'] ?? false,
      isSent: json['isSent'] ?? false,
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
    );
  }
}

/// Modèle de conversation
class Conversation {
  final String id;
  final String participantId;
  final String participantName;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final String participantStatus; // 'online', 'offline', 'away'
  final DateTime? lastSeen;
  
  Conversation({
    required this.id,
    required this.participantId,
    required this.participantName,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.participantStatus = 'offline',
    this.lastSeen,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participantId': participantId,
      'participantName': participantName,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'unreadCount': unreadCount,
      'participantStatus': participantStatus,
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }
  
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      participantId: json['participantId'],
      participantName: json['participantName'],
      lastMessage: json['lastMessage'],
      lastMessageTime: json['lastMessageTime'] != null 
          ? DateTime.parse(json['lastMessageTime']) 
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      participantStatus: json['participantStatus'] ?? 'offline',
      lastSeen: json['lastSeen'] != null 
          ? DateTime.parse(json['lastSeen']) 
          : null,
    );
  }
} 