import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/theme/app_theme.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  int _selectedIndex = 0;

  // Données fictives pour les conversations
  final List<Map<String, dynamic>> _conversations = [
    {
      'id': '1',
      'name': 'Alice Martin',
      'lastMessage': 'Salut ! Comment ça va ?',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
      'unreadCount': 2,
      'avatar': null,
      'isOnline': true,
      'isGroup': false,
    },
    {
      'id': '2',
      'name': 'Bob Dupont',
      'lastMessage': 'Merci pour l\'info !',
      'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
      'unreadCount': 0,
      'avatar': null,
      'isOnline': false,
      'isGroup': false,
    },
    {
      'id': '3',
      'name': 'Équipe Développement',
      'lastMessage': 'Marie: Réunion à 14h',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'unreadCount': 5,
      'avatar': null,
      'isOnline': true,
      'isGroup': true,
      'memberCount': 8,
    },
    {
      'id': '4',
      'name': 'Claire Dubois',
      'lastMessage': 'À bientôt ! 👋',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'unreadCount': 0,
      'avatar': null,
      'isOnline': false,
      'isGroup': false,
    },
    {
      'id': '5',
      'name': 'David Wilson',
      'lastMessage': 'Document envoyé',
      'timestamp': DateTime.now().subtract(const Duration(days: 2)),
      'unreadCount': 1,
      'avatar': null,
      'isOnline': true,
      'isGroup': false,
    },
  ];

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Maintenant';
    }
  }

  void _onConversationTap(Map<String, dynamic> conversation) {
    Get.toNamed('/chat/${conversation['id']}', arguments: conversation);
  }

  void _onSearchTap() {
    Get.snackbar(
      'Fonctionnalité',
      'Recherche à implémenter',
      snackPosition: SnackPosition.TOP,
    );
  }

  void _onNewChatTap() {
    Get.snackbar(
      'Fonctionnalité',
      'Nouvelle conversation à implémenter',
      snackPosition: SnackPosition.TOP,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Conversations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _onSearchTap,
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
          // Onglets
          Container(
            color: AppTheme.surfaceColor,
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton('Conversations', 0),
                ),
                Expanded(
                  child: _buildTabButton('Channels', 1),
                ),
                Expanded(
                  child: _buildTabButton('Stories', 2),
                ),
              ],
            ),
          ),
          
          // Liste des conversations
          Expanded(
            child: ListView.builder(
              itemCount: _conversations.length,
              itemBuilder: (context, index) {
                final conversation = _conversations[index];
                return _buildConversationTile(conversation);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onNewChatTap,
        child: const Icon(Icons.chat),
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> conversation) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CommonWidgets.avatar(
            imageUrl: conversation['avatar'],
            initials: conversation['name'].split(' ').take(2).map((n) => n[0]).join(''),
            size: 50,
          ),
          if (conversation['isOnline'])
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.successColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.surfaceColor,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation['name'],
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (conversation['isGroup'])
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${conversation['memberCount']}',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  conversation['lastMessage'],
                  style: TextStyle(
                    color: conversation['unreadCount'] > 0
                        ? AppTheme.textPrimaryColor
                        : AppTheme.textSecondaryColor,
                    fontWeight: conversation['unreadCount'] > 0
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatTimestamp(conversation['timestamp']),
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: conversation['unreadCount'] > 0
          ? CommonWidgets.badge(
              child: const SizedBox.shrink(),
              count: conversation['unreadCount'].toString(),
              size: 20,
            )
          : null,
      onTap: () => _onConversationTap(conversation),
    );
  }
} 