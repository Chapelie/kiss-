import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/signal_service.dart';
import '../services/websocket_service.dart';
import '../services/api_service.dart';
import '../services/agora_service.dart';
import '../../features/calls/view/incoming_call_dialog.dart';
import '../../features/calls/view/active_call_page.dart';

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
  final RxString _currentCallRecipientId = ''.obs;
  final RxString _currentCallRecipientName = ''.obs;
  final Rx<String?> _currentCallRecipientAvatar = Rx<String?>(null);
  
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
      _appStatus.value = 'Initialisation de l\'API...';
      
      // Initialiser le service API
      ApiService.instance.initialize();
      
      _appStatus.value = 'Vérification de l\'authentification...';
      
      // Vérifier si l'utilisateur est authentifié
      await _checkAuthentication();
      
      if (_isAuthenticated.value) {
        _appStatus.value = 'Initialisation des services...';
        
        // Initialiser Signal Service
        await _initializeSignalService();
        
        // Initialiser WebSocket Service
        await _initializeWebSocketService();
        
        // Charger les conversations depuis l'API
        await _loadConversations();
        
        // Charger automatiquement tous les utilisateurs et créer des conversations
        await _loadAllUsersAndCreateConversations();
        
        // Écouter les événements WebSocket
        _listenToWebSocketEvents();
        
        // Mettre à jour la présence
        await ApiService.instance.updatePresence(AppConstants.presenceOnline);
        
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
      final token = await _secureStorage.read(key: AppConstants.keyAuthToken);
      final userId = await _secureStorage.read(key: AppConstants.keyUserId);
      
      if (token != null) {
        // Vérifier que le token est toujours valide
        try {
          final userData = await ApiService.instance.getMe();
          _isAuthenticated.value = true;
          _currentUserId.value = userData['id']?.toString() ?? userId ?? '';
          if (userData['id'] != null) {
            await _secureStorage.write(
              key: AppConstants.keyUserId,
              value: userData['id'].toString(),
            );
          }
          print('✅ Utilisateur authentifié: ${_currentUserId.value}');
        } catch (e) {
          // Token invalide, déconnecter
          await logout();
        }
      } else {
        _isAuthenticated.value = false;
        print('❌ Aucun utilisateur authentifié');
      }
    } catch (e) {
      _isAuthenticated.value = false;
      print('❌ Erreur lors de la vérification d\'authentification: $e');
    }
  }
  
  /// Connexion via l'API
  Future<bool> login(String email, String password) async {
    try {
      final response = await ApiService.instance.login(
        email: email,
        password: password,
      );
      
      // Vérifier que la réponse est bien une Map
      if (response is! Map<String, dynamic>) {
        print('❌ Réponse invalide (pas une Map): ${response.runtimeType}');
        return false;
      }
      
      // Vérifier que la réponse contient un token
      if (response['token'] == null) {
        print('❌ Pas de token dans la réponse');
        return false;
      }
      
      _isAuthenticated.value = true;
      
      // Extraire l'ID utilisateur de manière sécurisée
      try {
        final userData = response['user'];
        if (userData != null) {
          if (userData is Map<String, dynamic>) {
            // Si c'est une Map, extraire l'ID directement
            _currentUserId.value = userData['id']?.toString() ?? '';
          } else if (userData is Map) {
            // Si c'est une Map non typée, convertir
            try {
              final userMap = Map<String, dynamic>.from(userData);
              _currentUserId.value = userMap['id']?.toString() ?? '';
            } catch (e) {
              print('⚠️ Erreur lors de la conversion de la Map: $e');
              _currentUserId.value = '';
            }
          } else if (userData is String) {
            // Si c'est une String, essayer de la parser en JSON
            try {
              final userMap = jsonDecode(userData) as Map<String, dynamic>;
              _currentUserId.value = userMap['id']?.toString() ?? '';
            } catch (e) {
              print('⚠️ Impossible de parser user (String): $userData');
              _currentUserId.value = '';
            }
          } else {
            print('⚠️ Type inattendu pour user: ${userData.runtimeType}');
            _currentUserId.value = '';
          }
        } else {
          _currentUserId.value = '';
        }
      } catch (e) {
        print('⚠️ Erreur lors de l\'extraction de l\'ID utilisateur: $e');
        _currentUserId.value = '';
      }
      
      // Initialiser les services après connexion
      await _initializeSignalService();
      await _initializeWebSocketService();
      await _loadConversations();
      _listenToWebSocketEvents();
      await ApiService.instance.updatePresence(AppConstants.presenceOnline);
      
      _isInitialized.value = true;
      _appStatus.value = 'Prêt';
      
      return true;
    } catch (e) {
      print('❌ Erreur lors de la connexion: $e');
      // Réinitialiser l'état en cas d'erreur
      _isAuthenticated.value = false;
      _isInitialized.value = false;
      return false;
    }
  }
  
  /// Inscription via l'API
  Future<bool> register(String email, String username, String password, {String? name}) async {
    try {
      final response = await ApiService.instance.register(
        email: email,
        username: username,
        password: password,
        name: name,
      );
      
      // Vérifier que la réponse contient un token
      if (response['token'] == null) {
        print('❌ Pas de token dans la réponse d\'inscription');
        return false;
      }
      
      _isAuthenticated.value = true;
      _currentUserId.value = response['user']?['id']?.toString() ?? '';
      
      // Initialiser les services après inscription
      await _initializeSignalService();
      await _initializeWebSocketService();
      await _loadConversations();
      _listenToWebSocketEvents();
      await ApiService.instance.updatePresence(AppConstants.presenceOnline);
      
      _isInitialized.value = true;
      _appStatus.value = 'Prêt';
      
      return true;
    } catch (e) {
      print('❌ Erreur lors de l\'inscription: $e');
      // Réinitialiser l'état en cas d'erreur
      _isAuthenticated.value = false;
      _isInitialized.value = false;
      return false;
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
  
  /// Vérifie si le service WebSocket est disponible
  bool get _isWebSocketServiceAvailable {
    return Get.isRegistered<WebSocketService>() && _websocketReady.value;
  }
  
  /// Vérifie si le service Signal est disponible
  bool get _isSignalServiceAvailable {
    return Get.isRegistered<SignalService>() && _signalReady.value;
  }
  
  /// Écoute les événements WebSocket
  void _listenToWebSocketEvents() {
    // Vérifier que WebSocketService est disponible
    if (!Get.isRegistered<WebSocketService>()) {
      print('⚠️ WebSocketService n\'est pas encore enregistré');
      return;
    }
    
    try {
      WebSocketService.to.events.listen((event) {
        switch (event.type) {
          case WebSocketEventType.connected:
            _handleWebSocketConnected(event);
            break;
          case WebSocketEventType.messageReceived:
            _handleMessageReceived(event);
            break;
          case WebSocketEventType.encryptedContentReceived:
            _handleEncryptedContentReceived(event);
            break;
          case WebSocketEventType.callRequest:
            _handleCallRequest(event);
            break;
          case WebSocketEventType.callResponse:
            _handleCallResponse(event);
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
    } catch (e) {
      print('❌ Erreur lors de l\'écoute des événements WebSocket: $e');
    }
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
  
  /// Gère les messages reçus (métadonnées uniquement)
  void _handleMessageReceived(WebSocketEvent event) {
    // Gérer les valeurs null du backend
    final messageId = event.data['messageId']?.toString() ?? event.data['id']?.toString() ?? '';
    final senderId = event.data['senderId']?.toString() ?? event.data['sender_id']?.toString() ?? '';
    final recipientId = event.data['recipientId']?.toString() ?? event.data['recipient_id']?.toString();
    final conversationId = event.data['conversationId']?.toString() ?? event.data['conversation_id']?.toString();
    final timestampStr = event.data['timestamp']?.toString();
    final messageType = event.data['type']?.toString() ?? event.data['message_type']?.toString() ?? 'text';
    
    if (messageId.isEmpty || senderId.isEmpty) {
      print('⚠️ Message reçu avec des données incomplètes: $event.data');
      return;
    }
    
    DateTime timestamp;
    if (timestampStr != null && timestampStr.isNotEmpty) {
      try {
        timestamp = DateTime.parse(timestampStr);
      } catch (e) {
        print('⚠️ Erreur de parsing timestamp: $timestampStr');
        timestamp = DateTime.now();
      }
    } else {
      timestamp = DateTime.now();
    }
    
    // Créer un nouveau message avec métadonnées uniquement
    // Le contenu sera déchiffré quand encryptedContentReceived sera reçu
    final message = ChatMessage(
      id: messageId,
      senderId: senderId,
      recipientId: recipientId,
      conversationId: conversationId,
      content: '', // Le contenu sera déchiffré séparément
      timestamp: timestamp,
      type: messageType,
      isEncrypted: true,
    );
    
    // Ajouter le message à la liste
    _messages.add(message);
    
    // Mettre à jour la conversation
    _updateConversation(senderId, message);
    
    print('📨 Nouveau message reçu: $messageId (conversation: $conversationId)');
  }
  
  /// Gère la réception du contenu chiffré
  Future<void> _handleEncryptedContentReceived(WebSocketEvent event) async {
    try {
      final messageId = event.data['messageId'];
      final encryptedMessage = event.data['encryptedMessage'] as EncryptedMessage;
      
      // Déchiffrer le message avec Signal Protocol
      final decryptedContent = await SignalService.to.decryptMessage(encryptedMessage);
      
      // Mettre à jour le message avec le contenu déchiffré
      final messageIndex = _messages.indexWhere((m) => m.id == messageId);
      if (messageIndex != -1) {
        final oldMessage = _messages[messageIndex];
        _messages[messageIndex] = ChatMessage(
          id: oldMessage.id,
          senderId: oldMessage.senderId,
          recipientId: oldMessage.recipientId,
          conversationId: oldMessage.conversationId,
          content: decryptedContent,
          timestamp: oldMessage.timestamp,
          type: oldMessage.type,
          isEncrypted: false, // Maintenant déchiffré
          isSent: oldMessage.isSent,
          isRead: oldMessage.isRead,
          readAt: oldMessage.readAt,
        );
      }
      
      // Marquer comme lu
      await ApiService.instance.markMessageAsRead(messageId);
      
      print('✅ Message déchiffré: $messageId');
    } catch (e) {
      print('❌ Erreur lors du déchiffrement: $e');
    }
  }
  
  /// Gère les réponses d'appel
  void _handleCallResponse(WebSocketEvent event) {
    final callId = event.data['callId']?.toString() ?? '';
    final response = event.data['response']?.toString() ?? ''; // 'accept', 'reject', 'busy', 'end'
    
    if (callId.isEmpty || response.isEmpty) {
      print('⚠️ Données de réponse d\'appel incomplètes');
      return;
    }
    
    if (response == 'accept') {
      // L'appel a été accepté, on reste sur la page d'appel
      _inCall.value = true;
      _currentCallId.value = callId;
      print('📞 Appel accepté par le destinataire');
    } else if (response == 'reject' || response == 'busy') {
      // L'appel a été rejeté ou le destinataire est occupé
      _inCall.value = false;
      _currentCallId.value = '';
      _currentCallType.value = '';
      _currentCallRecipientId.value = '';
      _currentCallRecipientName.value = '';
      _currentCallRecipientAvatar.value = null;
      
      // Quitter le canal Agora si on était en appel
      AgoraService.instance.leaveChannel();
      
      // Fermer la page d'appel si elle est ouverte
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      if (Navigator.canPop(Get.context!)) {
        Get.back();
      }
      
      // Afficher un message
      final message = response == 'busy' ? 'Le destinataire est occupé' : 'Appel rejeté';
      Get.snackbar(
        'Appel',
        message,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
      
      print('📞 Appel rejeté/occupé: $response');
    } else if (response == 'end') {
      // L'appel a été terminé
      _inCall.value = false;
      _currentCallId.value = '';
      _currentCallType.value = '';
      _currentCallRecipientId.value = '';
      _currentCallRecipientName.value = '';
      _currentCallRecipientAvatar.value = null;
      
      // Quitter le canal Agora
      AgoraService.instance.leaveChannel();
      
      // Fermer la page d'appel si elle est ouverte
      if (Navigator.canPop(Get.context!)) {
        Get.back();
      }
      
      print('📞 Appel terminé');
    }
  }
  
  /// Gère les demandes d'appel
  void _handleCallRequest(WebSocketEvent event) {
    final callerId = event.data['callerId']?.toString() ?? '';
    final callType = event.data['callType']?.toString() ?? 'audio';
    final callId = event.data['callId']?.toString() ?? '';
    
    if (callerId.isEmpty || callId.isEmpty) {
      print('⚠️ Données d\'appel incomplètes');
      return;
    }
    
    // Vérifier si on est déjà en appel
    if (_inCall.value) {
      // Rejeter l'appel si on est occupé
      if (_isWebSocketServiceAvailable) {
        WebSocketService.to.sendCallResponse(callId, 'busy');
      }
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
      
      // Trouver la conversation pour obtenir son ID
      String? conversationId;
      try {
        final conversation = _conversations.firstWhere(
          (conv) => conv.participantId == recipientId,
        );
        conversationId = conversation.id;
      } catch (e) {
        // Conversation non trouvée, on utilisera null
        conversationId = null;
      }
      
      // Envoyer le message via WebSocket
      if (_isWebSocketServiceAvailable) {
        await WebSocketService.to.sendMessage(recipientId, content);
      }
      
      // Créer le message local
      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: _currentUserId.value,
        recipientId: recipientId,
        conversationId: conversationId,
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
      
      print('📤 Message envoyé à $recipientId (conversation: $conversationId)');
      
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
      
      // Obtenir les informations du destinataire depuis les conversations
      final recipientInfo = _getRecipientInfo(recipientId);
      
      // Demander les permissions
      final agoraService = AgoraService.instance;
      final hasPermissions = await agoraService.requestPermissions(callType);
      if (!hasPermissions) {
        throw Exception('Permissions refusées');
      }
      
      // Créer l'appel via l'API
      final callData = await ApiService.instance.startCall(
        recipientId: recipientId,
        callType: callType,
      );
      
      final callId = callData['call_id']?.toString() ?? callData['callId']?.toString() ?? '';
      
      // Envoyer la demande d'appel via WebSocket
      if (_isWebSocketServiceAvailable) {
        await WebSocketService.to.sendCallRequest(recipientId, callType);
      }
      
      // Mettre à jour l'état de l'appel
      _inCall.value = true;
      _currentCallId.value = callId;
      _currentCallType.value = callType;
      _currentCallRecipientId.value = recipientId;
      _currentCallRecipientName.value = recipientInfo['name'] ?? 'Utilisateur';
      _currentCallRecipientAvatar.value = recipientInfo['avatar'];
      
      // Naviguer vers la page d'appel
      Get.to(() => ActiveCallPage(
        callId: callId,
        callType: callType,
        recipientId: recipientId,
        recipientName: _currentCallRecipientName.value,
        recipientAvatar: _currentCallRecipientAvatar.value,
        isIncoming: false,
      ));
      
      print('📞 Appel $callType initié vers $recipientId');
      
    } catch (e) {
      print('❌ Erreur lors de l\'initiation de l\'appel: $e');
      rethrow;
    }
  }
  
  /// Accepte un appel
  Future<void> acceptCall(String callId) async {
    try {
      // Demander les permissions
      final agoraService = AgoraService.instance;
      final hasPermissions = await agoraService.requestPermissions(_currentCallType.value);
      if (!hasPermissions) {
        throw Exception('Permissions refusées');
      }
      
      if (_isWebSocketServiceAvailable) {
        await WebSocketService.to.sendCallResponse(callId, 'accept');
      }
      
      // Mettre à jour l'état
      _inCall.value = true;
      _currentCallId.value = callId;
      
      // Naviguer vers la page d'appel
      Get.to(() => ActiveCallPage(
        callId: callId,
        callType: _currentCallType.value,
        recipientId: _currentCallRecipientId.value,
        recipientName: _currentCallRecipientName.value,
        recipientAvatar: _currentCallRecipientAvatar.value,
        isIncoming: true,
      ));
      
      print('📞 Appel accepté: $callId');
      
    } catch (e) {
      print('❌ Erreur lors de l\'acceptation de l\'appel: $e');
      rethrow;
    }
  }
  
  /// Rejette un appel
  Future<void> rejectCall(String callId) async {
    try {
      if (_isWebSocketServiceAvailable) {
        await WebSocketService.to.sendCallResponse(callId, 'reject');
      }
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
      // Envoyer la réponse "end" via WebSocket
      if (_isWebSocketServiceAvailable && _currentCallId.value.isNotEmpty) {
        await WebSocketService.to.sendCallResponse(_currentCallId.value, 'end');
      }
      
      // Quitter le canal Agora
      final agoraService = AgoraService.instance;
      await agoraService.leaveChannel();
      
      // Réinitialiser l'état
      _inCall.value = false;
      _currentCallId.value = '';
      _currentCallType.value = '';
      _currentCallRecipientId.value = '';
      _currentCallRecipientName.value = '';
      _currentCallRecipientAvatar.value = null;
      
      print('📞 Appel terminé');
      
    } catch (e) {
      print('❌ Erreur lors de la terminaison de l\'appel: $e');
      // Réinitialiser quand même l'état
      _inCall.value = false;
      _currentCallId.value = '';
      _currentCallType.value = '';
    }
  }
  
  /// Envoie un indicateur de frappe
  Future<void> sendTypingIndicator(String conversationId, bool isTyping) async {
    try {
      if (_isWebSocketServiceAvailable) {
        await WebSocketService.to.sendTypingIndicator(conversationId, isTyping);
      }
    } catch (e) {
      print('❌ Erreur lors de l\'envoi de l\'indicateur de frappe: $e');
    }
  }
  
  /// Envoie un accusé de réception
  Future<void> sendReadReceipt(String messageId) async {
    try {
      if (_isWebSocketServiceAvailable) {
        await WebSocketService.to.sendReadReceipt(messageId);
      }
    } catch (e) {
      print('❌ Erreur lors de l\'envoi de l\'accusé de réception: $e');
    }
  }
  
  /// Charge les conversations depuis l'API
  Future<void> _loadConversations() async {
    try {
      final conversationsData = await ApiService.instance.getConversations();
      _conversations.value = conversationsData
          .map((data) => Conversation.fromJson(data))
          .toList();
      print('✅ ${_conversations.length} conversations chargées');
    } catch (e) {
      print('❌ Erreur lors du chargement des conversations: $e');
    }
  }
  
  /// Charge tous les utilisateurs et crée automatiquement des conversations
  Future<void> _loadAllUsersAndCreateConversations() async {
    try {
      print('📥 Chargement de tous les utilisateurs...');
      
      // Récupérer tous les utilisateurs (sans query pour avoir tous)
      final allUsers = await ApiService.instance.searchUsers(
        query: '', // Query vide = tous les utilisateurs
        limit: 1000, // Limite élevée pour avoir tous
      );
      
      print('📥 ${allUsers.length} utilisateurs trouvés dans la base de données');
      
      // Pour chaque utilisateur, créer une conversation s'il n'en existe pas déjà
      int createdCount = 0;
      int existingCount = 0;
      
      for (final user in allUsers) {
        final userId = user['id']?.toString() ?? '';
        if (userId.isEmpty || userId == _currentUserId.value) {
          continue; // Ignorer les utilisateurs sans ID ou soi-même
        }
        
        // Vérifier si une conversation existe déjà
        final conversationExists = _conversations.any(
          (conv) => conv.participantId == userId,
        );
        
        if (!conversationExists) {
          try {
            // Créer la conversation automatiquement
            await ApiService.instance.createConversation(userId);
            createdCount++;
            print('✅ Conversation créée pour: ${user['name'] ?? user['email'] ?? userId}');
          } catch (e) {
            print('⚠️ Erreur lors de la création de la conversation pour $userId: $e');
            // Continuer avec les autres utilisateurs même en cas d'erreur
          }
        } else {
          existingCount++;
        }
      }
      
      // Recharger les conversations pour avoir les nouvelles
      await _loadConversations();
      
      print('✅ ${createdCount} nouvelles conversations créées, ${existingCount} existantes');
      print('📥 Total: ${_conversations.length} conversations disponibles');
      
    } catch (e) {
      print('❌ Erreur lors du chargement automatique des utilisateurs: $e');
      // Ne pas bloquer l'initialisation en cas d'erreur
    }
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
    // Obtenir les informations de l'appelant depuis les conversations
    final callerInfo = _getRecipientInfo(callerId);
    
    // Mettre à jour l'état
    _currentCallId.value = callId;
    _currentCallType.value = callType;
    _currentCallRecipientId.value = callerId;
    _currentCallRecipientName.value = callerInfo['name'] ?? 'Utilisateur';
    _currentCallRecipientAvatar.value = callerInfo['avatar'];
    
    // Afficher le dialog
    Get.dialog(
      IncomingCallDialog(
        callerId: callerId,
        callerName: _currentCallRecipientName.value,
        callerAvatar: _currentCallRecipientAvatar.value,
        callType: callType,
        callId: callId,
      ),
      barrierDismissible: false,
    );
  }
  
  /// Obtient les informations d'un utilisateur depuis les conversations
  Map<String, dynamic> _getRecipientInfo(String userId) {
    // Chercher dans les conversations
    for (final conv in _conversations) {
      if (conv.participantId == userId) {
        return {
          'name': conv.participantName ?? 'Utilisateur',
          'avatar': conv.participantAvatar,
        };
      }
    }
    
    // Si pas trouvé, retourner des valeurs par défaut
    return {
      'name': 'Utilisateur',
      'avatar': null,
    };
  }
  
  /// Déconnecte l'utilisateur
  Future<void> logout() async {
    try {
      // Mettre à jour la présence
      try {
        await ApiService.instance.updatePresence(AppConstants.presenceOffline);
      } catch (e) {
        print('⚠️ Erreur lors de la mise à jour de la présence: $e');
      }
      
      // Nettoyer les services
      if (_isWebSocketServiceAvailable) {
        if (_isWebSocketServiceAvailable) {
          WebSocketService.to.onClose();
        }
      }
      if (Get.isRegistered<SignalService>()) {
        SignalService.to.onClose();
      }
      
      // Déconnexion via l'API
      await ApiService.instance.logout();
      
      // Réinitialiser l'état
      _isAuthenticated.value = false;
      _isInitialized.value = false;
      _currentUserId.value = '';
      _appStatus.value = 'Déconnecté';
      _messages.clear();
      _conversations.clear();
      _inCall.value = false;
      _currentCallId.value = '';
      _currentCallType.value = '';
      
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
  final String? recipientId; // ID du destinataire (pour les messages envoyés)
  final String? conversationId; // ID de la conversation
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
    this.recipientId,
    this.conversationId,
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
      'recipientId': recipientId,
      'conversationId': conversationId,
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
    // Gérer les valeurs null du backend
    final id = json['id']?.toString() ?? json['id']?.toString() ?? '';
    final senderId = json['senderId']?.toString() ?? json['sender_id']?.toString() ?? '';
    final recipientId = json['recipientId']?.toString() ?? json['recipient_id']?.toString();
    final conversationId = json['conversationId']?.toString() ?? json['conversation_id']?.toString();
    final content = json['content']?.toString() ?? '';
    final timestampStr = json['timestamp']?.toString();
    final type = json['type']?.toString() ?? json['message_type']?.toString() ?? 'text';
    
    DateTime timestamp;
    if (timestampStr != null && timestampStr.isNotEmpty) {
      try {
        timestamp = DateTime.parse(timestampStr);
      } catch (e) {
        timestamp = DateTime.now();
      }
    } else {
      timestamp = DateTime.now();
    }
    
    DateTime? readAt;
    if (json['readAt'] != null || json['read_at'] != null) {
      final readAtStr = json['readAt']?.toString() ?? json['read_at']?.toString();
      if (readAtStr != null && readAtStr.isNotEmpty) {
        try {
          readAt = DateTime.parse(readAtStr);
        } catch (e) {
          readAt = null;
        }
      }
    }
    
    return ChatMessage(
      id: id,
      senderId: senderId,
      recipientId: recipientId,
      conversationId: conversationId,
      content: content,
      timestamp: timestamp,
      type: type,
      isEncrypted: json['isEncrypted'] ?? json['is_encrypted'] ?? false,
      isSent: json['isSent'] ?? json['is_sent'] ?? false,
      isRead: json['isRead'] ?? json['is_read'] ?? false,
      readAt: readAt,
    );
  }
}

/// Modèle de conversation
class Conversation {
  final String id;
  final String participantId;
  final String? participantName;
  final String? participantAvatar;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final String participantStatus; // 'online', 'offline', 'away'
  final DateTime? lastSeen;
  
  Conversation({
    required this.id,
    required this.participantId,
    this.participantName,
    this.participantAvatar,
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
      'participantAvatar': participantAvatar,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'unreadCount': unreadCount,
      'participantStatus': participantStatus,
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }
  
  factory Conversation.fromJson(Map<String, dynamic> json) {
    // Gérer les valeurs null et les différents formats de noms de champs
    final id = json['id']?.toString() ?? '';
    final participantId = json['participantId']?.toString() ?? 
                         json['participant_id']?.toString() ?? '';
    final participantName = json['participantName']?.toString() ?? 
                           json['participant_name']?.toString();
    final participantAvatar = json['participantAvatar']?.toString() ?? 
                             json['participant_avatar']?.toString();
    final lastMessage = json['lastMessage']?.toString() ?? 
                       json['last_message']?.toString();
    
    DateTime? lastMessageTime;
    final lastMessageTimeStr = json['lastMessageTime']?.toString() ?? 
                              json['last_message_time']?.toString();
    if (lastMessageTimeStr != null && lastMessageTimeStr.isNotEmpty) {
      try {
        lastMessageTime = DateTime.parse(lastMessageTimeStr);
      } catch (e) {
        print('⚠️ Erreur de parsing lastMessageTime: $lastMessageTimeStr');
        lastMessageTime = null;
      }
    }
    
    int unreadCount = 0;
    if (json['unreadCount'] != null) {
      if (json['unreadCount'] is int) {
        unreadCount = json['unreadCount'];
      } else if (json['unreadCount'] is String) {
        unreadCount = int.tryParse(json['unreadCount']) ?? 0;
      }
    } else if (json['unread_count'] != null) {
      if (json['unread_count'] is int) {
        unreadCount = json['unread_count'];
      } else if (json['unread_count'] is String) {
        unreadCount = int.tryParse(json['unread_count']) ?? 0;
      }
    }
    
    final participantStatus = json['participantStatus']?.toString() ?? 
                             json['participant_status']?.toString() ?? 
                             'offline';
    
    DateTime? lastSeen;
    final lastSeenStr = json['lastSeen']?.toString() ?? 
                        json['last_seen']?.toString();
    if (lastSeenStr != null && lastSeenStr.isNotEmpty) {
      try {
        lastSeen = DateTime.parse(lastSeenStr);
      } catch (e) {
        print('⚠️ Erreur de parsing lastSeen: $lastSeenStr');
        lastSeen = null;
      }
    }
    
    return Conversation(
      id: id,
      participantId: participantId,
      participantName: participantName,
      participantAvatar: participantAvatar,
      lastMessage: lastMessage,
      lastMessageTime: lastMessageTime,
      unreadCount: unreadCount,
      participantStatus: participantStatus,
      lastSeen: lastSeen,
    );
  }
} 