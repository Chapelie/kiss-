import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/theme/app_theme.dart';

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
  bool _isTyping = false;

  // Données fictives pour les messages
  final List<Map<String, dynamic>> _messages = [
    {
      'id': '1',
      'text': 'Salut ! Comment ça va ?',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 10)),
      'isMe': false,
      'sender': 'Alice Martin',
      'status': 'read',
    },
    {
      'id': '2',
      'text': 'Ça va bien, merci ! Et toi ?',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 8)),
      'isMe': true,
      'sender': 'Moi',
      'status': 'read',
    },
    {
      'id': '3',
      'text': 'Très bien aussi ! Tu as vu la nouvelle fonctionnalité ?',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
      'isMe': false,
      'sender': 'Alice Martin',
      'status': 'read',
    },
    {
      'id': '4',
      'text': 'Oui, elle est vraiment géniale ! 👍',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 3)),
      'isMe': true,
      'sender': 'Moi',
      'status': 'sent',
    },
    {
      'id': '5',
      'text': 'Parfait ! On se voit demain ?',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 1)),
      'isMe': false,
      'sender': 'Alice Martin',
      'status': 'read',
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'text': text,
        'timestamp': DateTime.now(),
        'isMe': true,
        'sender': 'Moi',
        'status': 'sending',
      });
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulation d'envoi
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          final lastMessage = _messages.last;
          lastMessage['status'] = 'sent';
        });
      }
    });

    // Simulation de réponse
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'text': 'Message reçu ! 👍',
            'timestamp': DateTime.now(),
            'isMe': false,
            'sender': widget.conversation?['name'] ?? 'Contact',
            'status': 'read',
          });
        });
        _scrollToBottom();
      }
    });
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

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['isMe'];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CommonWidgets.avatar(
              imageUrl: widget.conversation?['avatar'],
              initials: (widget.conversation?['name'] ?? 'C').split(' ').take(2).map((n) => n[0]).join(''),
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
                    message['text'],
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
                        _formatTime(message['timestamp']),
                        style: TextStyle(
                          color: isMe ? Colors.white70 : AppTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message['status'] == 'read' ? Icons.done_all : Icons.done,
                          size: 16,
                          color: message['status'] == 'read' ? Colors.white70 : Colors.white54,
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            CommonWidgets.avatar(
              imageUrl: widget.conversation?['avatar'],
              initials: (widget.conversation?['name'] ?? 'C').split(' ').take(2).map((n) => n[0]).join(''),
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversation?['name'] ?? 'Contact',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    widget.conversation?['isOnline'] == true ? 'En ligne' : 'Hors ligne',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.conversation?['isOnline'] == true 
                          ? AppTheme.successColor 
                          : AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              Get.snackbar(
                'Fonctionnalité',
                'Appel audio à implémenter',
                snackPosition: SnackPosition.TOP,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              Get.snackbar(
                'Fonctionnalité',
                'Appel vidéo à implémenter',
                snackPosition: SnackPosition.TOP,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              Get.snackbar(
                'Fonctionnalité',
                'Menu à implémenter',
                snackPosition: SnackPosition.TOP,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          
          // Indicateur de frappe
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CommonWidgets.avatar(
                    imageUrl: widget.conversation?['avatar'],
                    initials: (widget.conversation?['name'] ?? 'C').split(' ').take(2).map((n) => n[0]).join(''),
                    size: 32,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.messageReceivedColor,
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
          
          // Zone de saisie
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () {
                    Get.snackbar(
                      'Fonctionnalité',
                      'Pièce jointe à implémenter',
                      snackPosition: SnackPosition.TOP,
                    );
                  },
                ),
                Expanded(
                  child: TextField(
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



