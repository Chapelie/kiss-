import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/adaptive_widgets.dart';
import '../../../core/utils/platform_utils.dart';
import '../../../core/utils/date_utils.dart' as AppDateUtils;
import '../../../core/theme/app_theme.dart';
import '../../../core/controllers/app_controller.dart';
import '../../../core/services/api_service.dart';

class CallsPage extends StatefulWidget {
  const CallsPage({super.key});

  @override
  State<CallsPage> createState() => _CallsPageState();
}

class _CallsPageState extends State<CallsPage> {
  int _selectedIndex = 0;
  final AppController _appController = AppController.to;
  bool _isLoading = false;
  List<Map<String, dynamic>> _recentCalls = [];
  List<Map<String, dynamic>> _contacts = [];
  
  @override
  void initState() {
    super.initState();
    _loadCallHistory();
    _loadContacts();
  }
  
  Future<void> _loadCallHistory() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final calls = await ApiService.instance.getCallHistory(limit: 50);
      setState(() {
        _recentCalls = calls;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur lors du chargement de l\'historique des appels: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadContacts() async {
    try {
      final conversations = _appController.conversations;
      setState(() {
        _contacts = conversations.map((conv) {
          return {
            'id': conv.participantId,
            'name': conv.participantName ?? 'Utilisateur',
            'avatar': conv.participantAvatar,
            'isOnline': conv.participantStatus == 'online',
          };
        }).toList();
      });
    } catch (e) {
      print('❌ Erreur lors du chargement des contacts: $e');
    }
  }
  
  // Données fictives pour les appels (fallback)
  final List<Map<String, dynamic>> _dummyCalls = [
    {
      'id': '1',
      'name': 'Alice Martin',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
      'duration': '05:23',
      'type': 'outgoing',
      'callType': 'audio',
      'status': 'completed',
      'avatar': null,
    },
    {
      'id': '2',
      'name': 'Bob Dupont',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'duration': '12:45',
      'type': 'incoming',
      'callType': 'video',
      'status': 'completed',
      'avatar': null,
    },
    {
      'id': '3',
      'name': 'Claire Dubois',
      'timestamp': DateTime.now().subtract(const Duration(hours: 4)),
      'duration': '00:00',
      'type': 'outgoing',
      'callType': 'audio',
      'status': 'missed',
      'avatar': null,
    },
    {
      'id': '4',
      'name': 'David Wilson',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'duration': '08:12',
      'type': 'incoming',
      'callType': 'video',
      'status': 'completed',
      'avatar': null,
    },
  ];

  // Données fictives pour les contacts (fallback)
  final List<Map<String, dynamic>> _dummyContacts = [
    {
      'id': '1',
      'name': 'Alice Martin',
      'phone': '+33 6 12 34 56 78',
      'avatar': null,
      'isOnline': true,
    },
    {
      'id': '2',
      'name': 'Bob Dupont',
      'phone': '+33 6 23 45 67 89',
      'avatar': null,
      'isOnline': false,
    },
    {
      'id': '3',
      'name': 'Claire Dubois',
      'phone': '+33 6 34 56 78 90',
      'avatar': null,
      'isOnline': true,
    },
    {
      'id': '4',
      'name': 'David Wilson',
      'phone': '+33 6 45 67 89 01',
      'avatar': null,
      'isOnline': false,
    },
  ];

  // Utilise DateUtils pour le formatage (centralisé)
  String _formatTimestamp(DateTime timestamp) {
    return AppDateUtils.DateUtils.formatRelative(timestamp);
  }

  String _formatCallTimestamp(Map<String, dynamic> call) {
    try {
      // Essayer timestamp d'abord
      if (call['timestamp'] != null) {
        final timestampStr = call['timestamp'].toString();
        if (timestampStr.isNotEmpty) {
          final timestamp = DateTime.parse(timestampStr);
          return _formatTimestamp(timestamp);
        }
      }
      
      // Essayer created_at
      if (call['created_at'] != null) {
        final createdAtStr = call['created_at'].toString();
        if (createdAtStr.isNotEmpty) {
          final timestamp = DateTime.parse(createdAtStr);
          return _formatTimestamp(timestamp);
        }
      }
      
      // Essayer started_at
      if (call['started_at'] != null) {
        final startedAtStr = call['started_at'].toString();
        if (startedAtStr.isNotEmpty) {
          final timestamp = DateTime.parse(startedAtStr);
          return _formatTimestamp(timestamp);
        }
      }
      
      return 'Récemment';
    } catch (e) {
      print('⚠️ Erreur de parsing timestamp pour l\'appel: $e');
      return 'Récemment';
    }
  }

  String _getCallInitials(Map<String, dynamic> call) {
    final name = call['name']?.toString() ?? 
                 call['caller_name']?.toString() ?? 
                 call['recipient_name']?.toString() ?? 
                 '';
    
    if (name.isEmpty) {
      return 'U';
    }
    
    final parts = name.split(' ').where((n) => n.isNotEmpty).take(2);
    if (parts.isEmpty) {
      return name.isNotEmpty ? name[0].toUpperCase() : 'U';
    }
    
    return parts.map((n) => n[0].toUpperCase()).join('');
  }

  IconData _getCallIcon(String type, String callType) {
    if (type == 'outgoing') {
      return callType == 'video' ? Icons.call_made : Icons.call_made;
    } else {
      return callType == 'video' ? Icons.call_received : Icons.call_received;
    }
  }

  Color _getCallColor(String type, String status) {
    if (status == 'missed') {
      return AppTheme.errorColor;
    } else if (type == 'outgoing') {
      return AppTheme.successColor;
    } else {
      return AppTheme.primaryColor;
    }
  }

  Future<void> _onCallTap(Map<String, dynamic> contact, String callType) async {
    try {
      final recipientId = contact['id']?.toString() ?? '';
      if (recipientId.isEmpty) {
        CommonWidgets.showSafeSnackbar(
          title: 'Erreur',
          message: 'ID utilisateur invalide',
          backgroundColor: AppTheme.errorColor,
        );
        return;
      }
      
      await _appController.startCall(recipientId, callType);
    } catch (e) {
      print('❌ Erreur lors de l\'appel: $e');
      CommonWidgets.showSafeSnackbar(
        title: 'Erreur',
        message: 'Impossible de démarrer l\'appel: ${e.toString()}',
        backgroundColor: AppTheme.errorColor,
      );
    }
  }

  Future<void> _onRecentCallTap(Map<String, dynamic> call) async {
    try {
      // Extraire l'ID du destinataire depuis l'appel
      final recipientId = call['recipient_id']?.toString() ?? 
                         call['recipientId']?.toString() ?? 
                         call['caller_id']?.toString() ?? 
                         call['callerId']?.toString() ?? '';
      
      if (recipientId.isEmpty) {
        CommonWidgets.showSafeSnackbar(
          title: 'Erreur',
          message: 'Impossible de trouver l\'utilisateur',
          backgroundColor: AppTheme.errorColor,
        );
        return;
      }
      
      final callType = call['call_type']?.toString() ?? 
                       call['callType']?.toString() ?? 
                       'audio';
      
      await _appController.startCall(recipientId, callType);
    } catch (e) {
      print('❌ Erreur lors du rappel: $e');
      CommonWidgets.showSafeSnackbar(
        title: 'Erreur',
        message: 'Impossible de rappeler: ${e.toString()}',
        backgroundColor: AppTheme.errorColor,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AdaptiveWidgets.adaptiveAppBar(
      title: 'Appels',
      actions: [
        if (PlatformUtils.isIOS)
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              CommonWidgets.showSafeSnackbar(
                title: 'Recherche',
                message: 'Recherche à implémenter',
                backgroundColor: AppTheme.primaryColor,
              );
            },
            child: const Icon(CupertinoIcons.search),
          )
        else
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              CommonWidgets.showSafeSnackbar(
                title: 'Recherche',
                message: 'Recherche à implémenter',
                backgroundColor: AppTheme.primaryColor,
              );
            },
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
                  child: _buildTabButton('Récents', 0),
                ),
                Expanded(
                  child: _buildTabButton('Contacts', 1),
                ),
              ],
            ),
          ),
          
          // Contenu
          Expanded(
            child: _isLoading
                ? Center(
                    child: PlatformUtils.isIOS
                        ? const CupertinoActivityIndicator()
                        : const CircularProgressIndicator(),
                  )
                : _selectedIndex == 0 ? _buildRecentCalls() : _buildContacts(),
          ),
        ],
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

  Widget _buildRecentCalls() {
    final calls = _recentCalls.isNotEmpty ? _recentCalls : _dummyCalls;
    
    if (calls.isEmpty) {
      return Center(
        child: Text(
          'Aucun appel récent',
          style: TextStyle(
            color: PlatformUtils.isIOS
                ? CupertinoColors.secondaryLabel
                : AppTheme.textSecondaryColor,
          ),
        ),
      );
    }
    
    return ListView.builder(
      itemCount: calls.length,
      itemBuilder: (context, index) {
        final call = calls[index];
        return AdaptiveWidgets.adaptiveListTile(
          leading: CommonWidgets.avatar(
            imageUrl: call['avatar']?.toString() ?? call['avatar_url']?.toString(),
            initials: _getCallInitials(call),
            size: 50,
          ),
          title: Text(
            call['name']?.toString() ?? 
            call['caller_name']?.toString() ?? 
            call['recipient_name']?.toString() ?? 
            'Utilisateur',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    _getCallIcon(
                      call['type']?.toString() ?? call['call_type']?.toString() ?? 'outgoing',
                      call['callType']?.toString() ?? call['call_type']?.toString() ?? 'audio',
                    ),
                    size: 16,
                    color: _getCallColor(
                      call['type']?.toString() ?? call['call_type']?.toString() ?? 'outgoing',
                      call['status']?.toString() ?? 'completed',
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    (call['status']?.toString() ?? 'completed') == 'missed' 
                        ? 'Appel manqué' 
                        : call['duration']?.toString() ?? 
                          call['duration_seconds']?.toString() ?? 
                          '00:00',
                    style: TextStyle(
                      color: _getCallColor(
                        call['type']?.toString() ?? call['call_type']?.toString() ?? 'outgoing',
                        call['status']?.toString() ?? 'completed',
                      ),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatCallTimestamp(call),
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
          ),
          trailing: PlatformUtils.isIOS
              ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  onPressed: () => _onRecentCallTap(call),
                  child: Icon(
                    (call['callType']?.toString() ?? call['call_type']?.toString() ?? 'audio') == 'video'
                        ? CupertinoIcons.videocam 
                        : CupertinoIcons.phone,
                    color: CupertinoColors.activeBlue,
                  ),
                )
              : IconButton(
                  icon: Icon(
                    (call['callType']?.toString() ?? call['call_type']?.toString() ?? 'audio') == 'video' 
                        ? Icons.videocam 
                        : Icons.call,
                    color: AppTheme.primaryColor,
                  ),
                  onPressed: () => _onRecentCallTap(call),
                ),
          onTap: () => _onRecentCallTap(call),
        );
      },
    );
  }

  Widget _buildContacts() {
    final contacts = _contacts.isNotEmpty ? _contacts : _dummyContacts;
    
    if (contacts.isEmpty) {
      return Center(
        child: Text(
          'Aucun contact',
          style: TextStyle(
            color: PlatformUtils.isIOS
                ? CupertinoColors.secondaryLabel
                : AppTheme.textSecondaryColor,
          ),
        ),
      );
    }
    
    return ListView.builder(
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return AdaptiveWidgets.adaptiveListTile(
          leading: Stack(
            children: [
              CommonWidgets.avatar(
                imageUrl: contact['avatar'],
                initials: contact['name'].split(' ').take(2).map((n) => n[0]).join(''),
                size: 50,
              ),
              if (contact['isOnline'])
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
          ),
          title: Text(
            contact['name'],
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            contact['phone']?.toString() ?? contact['email']?.toString() ?? '',
            style: TextStyle(
              color: PlatformUtils.isIOS 
                  ? CupertinoColors.secondaryLabel 
                  : AppTheme.textSecondaryColor,
              fontSize: 14,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (PlatformUtils.isIOS)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  onPressed: () => _onCallTap(contact, 'audio'),
                  child: const Icon(
                    CupertinoIcons.phone,
                    color: CupertinoColors.activeBlue,
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.call, color: AppTheme.primaryColor),
                  onPressed: () => _onCallTap(contact, 'audio'),
                ),
              if (PlatformUtils.isIOS)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  onPressed: () => _onCallTap(contact, 'video'),
                  child: const Icon(
                    CupertinoIcons.videocam,
                    color: CupertinoColors.activeBlue,
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.videocam, color: AppTheme.primaryColor),
                  onPressed: () => _onCallTap(contact, 'video'),
                ),
            ],
          ),
        );
      },
    );
  }
} 