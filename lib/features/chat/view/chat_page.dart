import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/adaptive_widgets.dart';
import '../../../core/utils/platform_utils.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/controllers/app_controller.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/websocket_service.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final Map<String, dynamic>? conversation;

  const ChatPage({
    super.key,
    required this.chatId,
    this.conversation,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AppController _appController = AppController.to;
  bool _isTyping = false;
  bool _isLoading = true;
  StreamSubscription? _websocketSubscription;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _listenToWebSocketEvents();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _websocketSubscription?.cancel();
    super.dispose();
  }

  /// Charge les messages depuis l'API
  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // widget.chatId est l'ID de la conversation
      final messages = await ApiService.instance.getMessages(widget.chatId, limit: 100);
      
      // Convertir les messages en ChatMessage et les ajouter à AppController
      for (final msgData in messages) {
        // S'assurer que le conversationId est présent dans les données
        if (msgData['conversationId'] == null && msgData['conversation_id'] == null) {
          msgData['conversationId'] = widget.chatId;
        }
        
        final message = ChatMessage.fromJson(msgData);
        // Vérifier si le message n'existe pas déjà
        if (!_appController.messages.any((m) => m.id == message.id)) {
          _appController.messages.add(message);
        }
      }
      
      print('📥 ${messages.length} messages chargés pour la conversation ${widget.chatId}');
      _scrollToBottom();
    } catch (e) {
      print('❌ Erreur lors du chargement des messages: $e');
      CommonWidgets.showSafeSnackbar(
        title: 'Erreur',
        message: 'Impossible de charger les messages',
        backgroundColor: AppTheme.errorColor,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Écoute les événements WebSocket pour les nouveaux messages
  void _listenToWebSocketEvents() {
    if (_appController.websocketReady && Get.isRegistered<WebSocketService>()) {
      _websocketSubscription = WebSocketService.to.events.listen((event) {
        if (event.type == WebSocketEventType.messageReceived) {
          final messageData = event.data;
          final conversationId = messageData['conversationId']?.toString() ?? 
                                  messageData['conversation_id']?.toString() ?? '';
          final senderId = messageData['senderId']?.toString() ?? 
                          messageData['sender_id']?.toString() ?? '';
          final recipientId = messageData['recipientId']?.toString() ?? 
                             messageData['recipient_id']?.toString() ?? '';
          
          // Obtenir le participantId pour cette conversation
          final participantId = _getParticipantId();
          final currentUserId = _appController.currentUserId;
          
          // Si le message est pour cette conversation, mettre à jour l'UI
          // Le message appartient à cette conversation si:
          // - Le senderId est le participant (message reçu)
          // - Le recipientId est le participant (message envoyé)
          if (participantId != null && 
              (senderId == participantId || recipientId == participantId ||
               senderId == currentUserId || recipientId == currentUserId)) {
            setState(() {
              // L'UI sera mise à jour automatiquement via GetX
            });
            _scrollToBottom();
          }
        }
      });
    }
  }

  /// Envoie un message
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Désactiver le champ pendant l'envoi
    setState(() {
      _isTyping = false;
    });

    try {
      // Obtenir le participantId depuis la conversation
      // widget.chatId est l'ID de la conversation
      // Pour une conversation 1-à-1, on doit trouver le participantId
      String? participantId;
      
      // Chercher dans les conversations de AppController
      final conversation = _appController.conversations.firstWhereOrNull(
        (conv) => conv.id == widget.chatId,
      );
      
      if (conversation != null) {
        participantId = conversation.participantId;
      } else if (widget.conversation != null) {
        // Fallback: utiliser les données passées en argument
        participantId = widget.conversation!['participantId']?.toString() ?? 
                        widget.conversation!['participant_id']?.toString();
      }
      
      if (participantId == null || participantId.isEmpty) {
        throw Exception('Impossible de trouver le participant');
      }
      
      // Envoyer le message via AppController
      await _appController.sendMessage(participantId, text);
      
      _messageController.clear();
      _scrollToBottom();
      
      print('✅ Message envoyé: $text');
    } catch (e) {
      print('❌ Erreur lors de l\'envoi du message: $e');
      CommonWidgets.showSafeSnackbar(
        title: 'Erreur',
        message: 'Impossible d\'envoyer le message',
        backgroundColor: AppTheme.errorColor,
      );
    }
  }

  /// Obtient le participantId depuis la conversation
  String? _getParticipantId() {
    // Chercher dans les conversations de AppController
    final conversation = _appController.conversations.firstWhereOrNull(
      (conv) => conv.id == widget.chatId,
    );
    
    if (conversation != null) {
      return conversation.participantId;
    } else if (widget.conversation != null) {
      // Fallback: utiliser les données passées en argument
      return widget.conversation!['participantId']?.toString() ?? 
             widget.conversation!['participant_id']?.toString();
    }
    
    return null;
  }

  /// Démarre un appel audio
  Future<void> _startAudioCall() async {
    try {
      final participantId = _getParticipantId();
      if (participantId == null || participantId.isEmpty) {
        throw Exception('Impossible de trouver le participant');
      }
      
      await _appController.startCall(participantId, 'audio');
      print('📞 Appel audio démarré');
    } catch (e) {
      print('❌ Erreur lors du démarrage de l\'appel audio: $e');
      CommonWidgets.showSafeSnackbar(
        title: 'Erreur',
        message: 'Impossible de démarrer l\'appel audio',
        backgroundColor: AppTheme.errorColor,
      );
    }
  }

  /// Démarre un appel vidéo
  Future<void> _startVideoCall() async {
    try {
      final participantId = _getParticipantId();
      if (participantId == null || participantId.isEmpty) {
        throw Exception('Impossible de trouver le participant');
      }
      
      await _appController.startCall(participantId, 'video');
      print('📹 Appel vidéo démarré');
    } catch (e) {
      print('❌ Erreur lors du démarrage de l\'appel vidéo: $e');
      CommonWidgets.showSafeSnackbar(
        title: 'Erreur',
        message: 'Impossible de démarrer l\'appel vidéo',
        backgroundColor: AppTheme.errorColor,
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  /// Obtient les messages de cette conversation depuis AppController
  List<ChatMessage> _getConversationMessages() {
    // widget.chatId est l'ID de la conversation
    final conversationId = widget.chatId;
    final participantId = _getParticipantId();
    final currentUserId = _appController.currentUserId;
    
    // Filtrer les messages pour cette conversation
    return _appController.messages.where((msg) {
      // Si le message a un conversationId, l'utiliser pour filtrer
      if (msg.conversationId != null && msg.conversationId!.isNotEmpty) {
        return msg.conversationId == conversationId;
      }
      
      // Sinon, fallback sur l'ancienne logique (pour les messages sans conversationId)
      // Message reçu du participant
      if (participantId != null && msg.senderId == participantId && msg.senderId != currentUserId) {
        return true;
      }
      // Message envoyé au participant
      if (msg.senderId == currentUserId && msg.recipientId == participantId) {
        return true;
      }
      return false;
    }).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isMe = message.senderId == _appController.currentUserId;
    final participantName = widget.conversation?['name'] ?? 'Contact';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CommonWidgets.avatar(
              imageUrl: widget.conversation?['avatar'],
              initials: participantName.split(' ').take(2).map((n) => n.isNotEmpty ? n[0] : '').join(''),
              size: 32,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primaryColor : AppTheme.messageReceivedColor,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : AppTheme.textPrimaryColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: isMe ? Colors.white70 : AppTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 16,
                          color: message.isRead ? Colors.white70 : Colors.white54,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final participantName = widget.conversation?['name'] ?? 'Contact';
    final isOnline = widget.conversation?['isOnline'] == true;
    final initials = participantName.split(' ').take(2).map((n) => n.isNotEmpty ? n[0] : '').join('');
    
    final appBar = AdaptiveWidgets.adaptiveAppBar(
      title: participantName,
      automaticallyImplyLeading: true,
      actions: [
        if (PlatformUtils.isIOS)
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _startAudioCall,
            child: const Icon(CupertinoIcons.phone),
          )
        else
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: _startAudioCall,
          ),
        if (PlatformUtils.isIOS)
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _startVideoCall,
            child: const Icon(CupertinoIcons.videocam),
          )
        else
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: _startVideoCall,
          ),
        if (PlatformUtils.isIOS)
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              CommonWidgets.showSafeSnackbar(
                title: 'Menu',
                message: 'Menu à implémenter',
                backgroundColor: AppTheme.primaryColor,
              );
            },
            child: const Icon(CupertinoIcons.ellipsis),
          )
        else
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              CommonWidgets.showSafeSnackbar(
                title: 'Menu',
                message: 'Menu à implémenter',
                backgroundColor: AppTheme.primaryColor,
              );
            },
          ),
      ],
    );
    
    return AdaptiveWidgets.adaptiveScaffold(
      appBar: appBar,
      backgroundColor: PlatformUtils.isIOS 
          ? CupertinoColors.systemBackground 
          : AppTheme.backgroundColor,
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _isLoading
                ? Center(
                    child: PlatformUtils.isIOS
                        ? const CupertinoActivityIndicator()
                        : const CircularProgressIndicator(),
                  )
                : Obx(() {
                    final messages = _getConversationMessages();
                    
                    if (messages.isEmpty) {
                      return Center(
                        child: Text(
                          'Aucun message',
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 16,
                          ),
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessageBubble(messages[index]);
                      },
                    );
                  }),
          ),
          
          // Indicateur de frappe
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CommonWidgets.avatar(
                    imageUrl: widget.conversation?['avatar'],
                    initials: initials,
                    size: 32,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: PlatformUtils.isIOS 
                          ? CupertinoColors.systemGrey6 
                          : AppTheme.messageReceivedColor,
                      borderRadius: BorderRadius.circular(18).copyWith(
                        bottomRight: const Radius.circular(18),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTypingIndicator(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // Zone de saisie adaptative
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PlatformUtils.isIOS 
                  ? CupertinoColors.systemBackground 
                  : AppTheme.surfaceColor,
              boxShadow: PlatformUtils.isIOS ? null : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
              border: PlatformUtils.isIOS 
                  ? Border(
                      top: BorderSide(
                        color: CupertinoColors.separator,
                        width: 0.5,
                      ),
                    )
                  : null,
            ),
            child: Row(
              children: [
                if (PlatformUtils.isIOS)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 0,
                    onPressed: () {
                      CommonWidgets.showSafeSnackbar(
                        title: 'Pièce jointe',
                        message: 'Pièce jointe à implémenter',
                        backgroundColor: AppTheme.primaryColor,
                      );
                    },
                    child: const Icon(CupertinoIcons.paperclip),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: () {
                      CommonWidgets.showSafeSnackbar(
                        title: 'Pièce jointe',
                        message: 'Pièce jointe à implémenter',
                        backgroundColor: AppTheme.primaryColor,
                      );
                    },
                  ),
                Expanded(
                  child: PlatformUtils.isIOS
                      ? CupertinoTextField(
                          controller: _messageController,
                          placeholder: 'Tapez un message...',
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          onChanged: (value) {
                            setState(() {
                              _isTyping = value.isNotEmpty;
                            });
                          },
                        )
                      : TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Tapez un message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: AppTheme.backgroundColor,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          onChanged: (value) {
                            setState(() {
                              _isTyping = value.isNotEmpty;
                            });
                          },
                        ),
                ),
                const SizedBox(width: 8),
                if (PlatformUtils.isIOS)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 0,
                    onPressed: _sendMessage,
                    child: Icon(
                      CupertinoIcons.arrow_up_circle_fill,
                      color: CupertinoColors.activeBlue,
                      size: 32,
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                    color: AppTheme.primaryColor,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDot(0),
        _buildDot(1),
        _buildDot(2),
      ],
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: AppTheme.textSecondaryColor.withOpacity(value),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }
}
