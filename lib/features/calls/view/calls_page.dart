import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/theme/app_theme.dart';

class CallsPage extends StatefulWidget {
  const CallsPage({super.key});

  @override
  State<CallsPage> createState() => _CallsPageState();
}

class _CallsPageState extends State<CallsPage> {
  int _selectedIndex = 0;

  // Données fictives pour les appels
  final List<Map<String, dynamic>> _recentCalls = [
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

  final List<Map<String, dynamic>> _contacts = [
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

  void _onCallTap(Map<String, dynamic> contact, String callType) {
    Get.snackbar(
      'Appel',
      'Appel ${callType == 'video' ? 'vidéo' : 'audio'} vers ${contact['name']}',
      snackPosition: SnackPosition.TOP,
    );
  }

  void _onRecentCallTap(Map<String, dynamic> call) {
    Get.snackbar(
      'Appel récent',
      'Rappeler ${call['name']}',
      snackPosition: SnackPosition.TOP,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Appels'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Get.snackbar(
                'Fonctionnalité',
                'Recherche à implémenter',
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
          // Onglets
          Container(
            color: AppTheme.surfaceColor,
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
            child: _selectedIndex == 0 ? _buildRecentCalls() : _buildContacts(),
          ),
        ],
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

  Widget _buildRecentCalls() {
    return ListView.builder(
      itemCount: _recentCalls.length,
      itemBuilder: (context, index) {
        final call = _recentCalls[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CommonWidgets.avatar(
            imageUrl: call['avatar'],
            initials: call['name'].split(' ').take(2).map((n) => n[0]).join(''),
            size: 50,
          ),
          title: Text(
            call['name'],
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
                    _getCallIcon(call['type'], call['callType']),
                    size: 16,
                    color: _getCallColor(call['type'], call['status']),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    call['status'] == 'missed' ? 'Appel manqué' : call['duration'],
                    style: TextStyle(
                      color: _getCallColor(call['type'], call['status']),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTimestamp(call['timestamp']),
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  call['callType'] == 'video' ? Icons.videocam : Icons.call,
                  color: AppTheme.primaryColor,
                ),
                onPressed: () => _onRecentCallTap(call),
              ),
            ],
          ),
          onTap: () => _onRecentCallTap(call),
        );
      },
    );
  }

  Widget _buildContacts() {
    return ListView.builder(
      itemCount: _contacts.length,
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        color: AppTheme.surfaceColor,
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
            contact['phone'],
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 14,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.call, color: AppTheme.primaryColor),
                onPressed: () => _onCallTap(contact, 'audio'),
              ),
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