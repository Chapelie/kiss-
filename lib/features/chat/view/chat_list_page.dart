import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/adaptive_widgets.dart';
import '../../../core/utils/platform_utils.dart';
import '../../../core/utils/date_utils.dart' as AppDateUtils;
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  int _selectedIndex = 0;
  bool _isLoading = false;
  
  // Conversations chargées depuis le backend
  final List<Map<String, dynamic>> _conversations = [];
  
  @override
  void initState() {
    super.initState();
    _loadConversations();
  }
  
  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final conversations = await ApiService.instance.getConversations();
      setState(() {
        _conversations.clear();
        _conversations.addAll(conversations.map((conv) {
          return {
            'id': conv['id']?.toString() ?? '',
            'name': conv['participant_name'] ?? 'Utilisateur',
            'lastMessage': conv['last_message'] ?? '',
            'timestamp': conv['last_message_time'] != null 
                ? DateTime.parse(conv['last_message_time'])
                : DateTime.now(),
            'unreadCount': conv['unread_count'] ?? 0,
            'avatar': conv['participant_avatar'],
            'isOnline': conv['participant_status'] == 'online',
            'isGroup': false,
            'participant_id': conv['participant_id']?.toString() ?? '',
          };
        }).toList());
      });
    } catch (e) {
      print('❌ Erreur lors du chargement des conversations: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Utilise DateUtils pour le formatage (centralisé)
  String _formatTimestamp(DateTime timestamp) {
    return AppDateUtils.DateUtils.formatRelative(timestamp);
  }

  void _onConversationTap(Map<String, dynamic> conversation) {
    Get.toNamed('/chat/${conversation['id']}', arguments: conversation);
  }

  void _onSearchTap() {
    // Navigation vers la recherche de contacts
    Get.toNamed('/contacts');
  }

  void _onNewChatTap() {
    // Navigation vers la page de contacts pour démarrer une nouvelle conversation
    Get.toNamed('/contacts');
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AdaptiveWidgets.adaptiveAppBar(
      title: 'Conversations',
      actions: [
        if (PlatformUtils.isIOS)
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _onSearchTap,
            child: const Icon(CupertinoIcons.search),
          )
        else
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _onSearchTap,
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
          // Onglets adaptatifs
          Container(
            color: PlatformUtils.isIOS 
                ? CupertinoColors.systemGrey6 
                : AppTheme.surfaceColor,
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
          
          // Contenu selon l'onglet sélectionné
          Expanded(
            child: _selectedIndex == 0
                ? _buildConversationsList()
                : _selectedIndex == 1
                    ? _buildChannelsList()
                    : _buildStoriesList(),
          ),
        ],
      ),
      floatingActionButton: PlatformUtils.isIOS 
          ? null 
          : FloatingActionButton(
              onPressed: _onNewChatTap,
              child: const Icon(Icons.chat),
            ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedIndex == index;
    final selectedColor = PlatformUtils.isIOS 
        ? CupertinoColors.activeBlue 
        : AppTheme.primaryColor;
    final unselectedColor = PlatformUtils.isIOS 
        ? CupertinoColors.secondaryLabel 
        : AppTheme.textSecondaryColor;
    
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
              color: isSelected ? selectedColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? selectedColor : unselectedColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> conversation) {
    final initials = conversation['name'].split(' ').take(2).map((n) => n[0]).join('');
    final isOnline = conversation['isOnline'] == true;
    final unreadCount = conversation['unreadCount'] ?? 0;
    
    final leading = Stack(
      children: [
        CommonWidgets.avatar(
          imageUrl: conversation['avatar'],
          initials: initials,
          size: 50,
        ),
        if (isOnline)
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
                  color: PlatformUtils.isIOS 
                      ? CupertinoColors.systemBackground 
                      : AppTheme.surfaceColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
    
    final title = Row(
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
        if (conversation['isGroup'] == true)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: (PlatformUtils.isIOS 
                  ? CupertinoColors.activeBlue 
                  : AppTheme.primaryColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${conversation['memberCount']}',
              style: TextStyle(
                color: PlatformUtils.isIOS 
                    ? CupertinoColors.activeBlue 
                    : AppTheme.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
    
    final subtitle = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                conversation['lastMessage'],
                style: TextStyle(
                  color: unreadCount > 0
                      ? (PlatformUtils.isIOS 
                          ? CupertinoColors.label 
                          : AppTheme.textPrimaryColor)
                      : (PlatformUtils.isIOS 
                          ? CupertinoColors.secondaryLabel 
                          : AppTheme.textSecondaryColor),
                  fontWeight: unreadCount > 0
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
                color: PlatformUtils.isIOS 
                    ? CupertinoColors.secondaryLabel 
                    : AppTheme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
    
    final trailing = unreadCount > 0
        ? CommonWidgets.badge(
            child: const SizedBox.shrink(),
            count: unreadCount.toString(),
            size: 20,
          )
        : null;
    
    return AdaptiveWidgets.adaptiveListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: () => _onConversationTap(conversation),
    );
  }

  Widget _buildConversationsList() {
    if (_isLoading) {
      return Center(
        child: AdaptiveWidgets.adaptiveLoadingIndicator(
          message: 'Chargement des conversations...',
        ),
      );
    }
    
    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PlatformUtils.isIOS
                  ? CupertinoIcons.chat_bubble
                  : Icons.chat_bubble_outline,
              size: 80,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune conversation',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Commencez une nouvelle conversation',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            CommonWidgets.customButton(
              text: 'Nouvelle conversation',
              onPressed: _onNewChatTap,
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          return _buildConversationTile(_conversations[index]);
        },
      ),
    );
  }

  Widget _buildChannelsList() {
    // Placeholder for Channels list
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PlatformUtils.isIOS
                ? CupertinoIcons.group
                : Icons.group_outlined,
            size: 80,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun channel',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez ou rejoignez un channel',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          CommonWidgets.customButton(
            text: 'Nouveau Channel',
            onPressed: () {
              CommonWidgets.showSafeSnackbar(
                title: 'Channel',
                message: 'Créer un channel à implémenter',
                backgroundColor: AppTheme.primaryColor,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesList() {
    // Placeholder for Stories list
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PlatformUtils.isIOS
                ? CupertinoIcons.photo_on_rectangle
                : Icons.collections_bookmark_outlined,
            size: 80,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune story',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Partagez vos moments en stories',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          CommonWidgets.customButton(
            text: 'Créer une Story',
            onPressed: () {
              CommonWidgets.showSafeSnackbar(
                title: 'Story',
                message: 'Créer une story à implémenter',
                backgroundColor: AppTheme.primaryColor,
              );
            },
          ),
        ],
      ),
    );
  }
} 