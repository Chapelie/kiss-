import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/theme/app_theme.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<ContactData> _contacts = [
    ContactData(
      id: '1',
      name: 'Alice Martin',
      email: 'alice.martin@email.com',
      phone: '+33 6 12 34 56 78',
      avatar: null,
      initials: 'AM',
      status: ContactStatus.online,
      lastSeen: DateTime.now(),
      isFavorite: true,
    ),
    ContactData(
      id: '2',
      name: 'Bob Dupont',
      email: 'bob.dupont@email.com',
      phone: '+33 6 23 45 67 89',
      avatar: null,
      initials: 'BD',
      status: ContactStatus.offline,
      lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
      isFavorite: false,
    ),
    ContactData(
      id: '3',
      name: 'Claire Bernard',
      email: 'claire.bernard@email.com',
      phone: '+33 6 34 56 78 90',
      avatar: null,
      initials: 'CB',
      status: ContactStatus.away,
      lastSeen: DateTime.now().subtract(const Duration(minutes: 30)),
      isFavorite: true,
    ),
    ContactData(
      id: '4',
      name: 'David Leroy',
      email: 'david.leroy@email.com',
      phone: '+33 6 45 67 89 01',
      avatar: null,
      initials: 'DL',
      status: ContactStatus.online,
      lastSeen: DateTime.now(),
      isFavorite: false,
    ),
    ContactData(
      id: '5',
      name: 'Emma Dubois',
      email: 'emma.dubois@email.com',
      phone: '+33 6 56 78 90 12',
      avatar: null,
      initials: 'ED',
      status: ContactStatus.offline,
      lastSeen: DateTime.now().subtract(const Duration(days: 1)),
      isFavorite: false,
    ),
    ContactData(
      id: '6',
      name: 'François Moreau',
      email: 'francois.moreau@email.com',
      phone: '+33 6 67 89 01 23',
      avatar: null,
      initials: 'FM',
      status: ContactStatus.online,
      lastSeen: DateTime.now(),
      isFavorite: true,
    ),
  ];

  List<ContactData> _filteredContacts = [];

  @override
  void initState() {
    super.initState();
    _filteredContacts = List.from(_contacts);
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = List.from(_contacts);
      } else {
        _filteredContacts = _contacts.where((contact) {
          return contact.name.toLowerCase().contains(query) ||
                 contact.email.toLowerCase().contains(query) ||
                 contact.phone.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _addContact(),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMoreOptions(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: CommonWidgets.customTextField(
              controller: _searchController,
              label: 'Rechercher',
              hint: 'Rechercher un contact...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterContacts();
                      },
                    )
                  : null,
            ),
          ),
          
          // Filtres
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('Tous', true),
                const SizedBox(width: 8),
                _buildFilterChip('En ligne', false),
                const SizedBox(width: 8),
                _buildFilterChip('Favoris', false),
                const SizedBox(width: 8),
                _buildFilterChip('Récents', false),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Liste des contacts
          Expanded(
            child: _filteredContacts.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _filteredContacts[index];
                      return _buildContactTile(contact);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _startNewConversation(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        // Implémenter la logique de filtrage
        Get.snackbar(
          'Filtre',
          'Filtre "$label" sélectionné',
          snackPosition: SnackPosition.TOP,
        );
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  Widget _buildContactTile(ContactData contact) {
    return ListTile(
      leading: Stack(
        children: [
          CommonWidgets.avatar(
            imageUrl: contact.avatar,
            initials: contact.initials,
            size: 50,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _getStatusColor(contact.status),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
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
              contact.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (contact.isFavorite)
            Icon(
              Icons.star,
              size: 16,
              color: AppTheme.warningColor,
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            contact.email,
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 12,
            ),
          ),
          Text(
            _getStatusText(contact.status, contact.lastSeen),
            style: TextStyle(
              color: _getStatusColor(contact.status),
              fontSize: 12,
            ),
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) => _handleContactAction(value, contact),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'message',
            child: Row(
              children: [
                Icon(Icons.message),
                SizedBox(width: 8),
                Text('Message'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'call',
            child: Row(
              children: [
                Icon(Icons.call),
                SizedBox(width: 8),
                Text('Appel'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'video_call',
            child: Row(
              children: [
                Icon(Icons.videocam),
                SizedBox(width: 8),
                Text('Appel vidéo'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'favorite',
            child: Row(
              children: [
                Icon(Icons.star),
                SizedBox(width: 8),
                Text('Favori'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'block',
            child: Row(
              children: [
                Icon(Icons.block),
                SizedBox(width: 8),
                Text('Bloquer'),
              ],
            ),
          ),
        ],
      ),
      onTap: () => _showContactDetails(contact),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun contact trouvé',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez de modifier votre recherche',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ContactStatus status) {
    switch (status) {
      case ContactStatus.online:
        return AppTheme.successColor;
      case ContactStatus.away:
        return AppTheme.warningColor;
      case ContactStatus.offline:
        return AppTheme.textSecondaryColor;
    }
  }

  String _getStatusText(ContactStatus status, DateTime lastSeen) {
    switch (status) {
      case ContactStatus.online:
        return 'En ligne';
      case ContactStatus.away:
        return 'Absent';
      case ContactStatus.offline:
        return 'Vu il y a ${_formatTimeAgo(lastSeen)}';
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} h';
    } else {
      return '${difference.inDays} j';
    }
  }

  void _addContact() {
    Get.snackbar(
      'Ajouter un contact',
      'Fonctionnalité à implémenter',
      snackPosition: SnackPosition.TOP,
    );
  }

  void _showMoreOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.import_contacts),
              title: const Text('Importer des contacts'),
              onTap: () {
                Get.back();
                Get.snackbar('Import', 'Import des contacts');
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('Créer un groupe'),
              onTap: () {
                Get.back();
                Get.snackbar('Groupe', 'Création de groupe');
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort),
              title: const Text('Trier les contacts'),
              onTap: () {
                Get.back();
                Get.snackbar('Tri', 'Tri des contacts');
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Fermer'),
              onTap: () => Get.back(),
            ),
          ],
        ),
      ),
    );
  }

  void _startNewConversation() {
    Get.snackbar(
      'Nouvelle conversation',
      'Fonctionnalité à implémenter',
      snackPosition: SnackPosition.TOP,
    );
  }

  void _showContactDetails(ContactData contact) {
    Get.to(() => ContactDetailsPage(contact: contact));
  }

  void _handleContactAction(String action, ContactData contact) {
    switch (action) {
      case 'message':
        Get.snackbar(
          'Message',
          'Démarrer une conversation avec ${contact.name}',
          snackPosition: SnackPosition.TOP,
        );
        break;
      case 'call':
        Get.snackbar(
          'Appel',
          'Appeler ${contact.name}',
          snackPosition: SnackPosition.TOP,
        );
        break;
      case 'video_call':
        Get.snackbar(
          'Appel vidéo',
          'Appel vidéo avec ${contact.name}',
          snackPosition: SnackPosition.TOP,
        );
        break;
      case 'favorite':
        setState(() {
          contact.isFavorite = !contact.isFavorite;
        });
        Get.snackbar(
          'Favori',
          contact.isFavorite 
              ? '${contact.name} ajouté aux favoris'
              : '${contact.name} retiré des favoris',
          snackPosition: SnackPosition.TOP,
        );
        break;
      case 'block':
        Get.dialog(
          AlertDialog(
            title: const Text('Bloquer le contact'),
            content: Text('Êtes-vous sûr de vouloir bloquer ${contact.name} ?'),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  Get.back();
                  Get.snackbar(
                    'Contact bloqué',
                    '${contact.name} a été bloqué',
                    snackPosition: SnackPosition.TOP,
                  );
                },
                child: const Text('Bloquer'),
              ),
            ],
          ),
        );
        break;
    }
  }
}

class ContactDetailsPage extends StatelessWidget {
  final ContactData contact;
  
  const ContactDetailsPage({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(contact.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showContactOptions(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Photo de profil
            Center(
              child: CommonWidgets.avatar(
                imageUrl: contact.avatar,
                initials: contact.initials,
                size: 120,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Nom et statut
            Text(
              contact.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              contact.email,
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 16,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Actions rapides
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.message,
                  label: 'Message',
                  onTap: () => _sendMessage(),
                ),
                _buildActionButton(
                  icon: Icons.call,
                  label: 'Appel',
                  onTap: () => _makeCall(),
                ),
                _buildActionButton(
                  icon: Icons.videocam,
                  label: 'Vidéo',
                  onTap: () => _makeVideoCall(),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Informations de contact
            CommonWidgets.customCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informations de contact',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.email, 'Email', contact.email),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.phone, 'Téléphone', contact.phone),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Actions supplémentaires
            CommonWidgets.customCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.share),
                    title: const Text('Partager le contact'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _shareContact(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.block),
                    title: const Text('Bloquer'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _blockContact(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.textSecondaryColor,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showContactOptions() {
    Get.snackbar(
      'Options du contact',
      'Fonctionnalité à implémenter',
      snackPosition: SnackPosition.TOP,
    );
  }

  void _sendMessage() {
    Get.snackbar(
      'Message',
      'Démarrer une conversation avec ${contact.name}',
      snackPosition: SnackPosition.TOP,
    );
  }

  void _makeCall() {
    Get.snackbar(
      'Appel',
      'Appeler ${contact.name}',
      snackPosition: SnackPosition.TOP,
    );
  }

  void _makeVideoCall() {
    Get.snackbar(
      'Appel vidéo',
      'Appel vidéo avec ${contact.name}',
      snackPosition: SnackPosition.TOP,
    );
  }

  void _shareContact() {
    Get.snackbar(
      'Partager',
      'Partager le contact ${contact.name}',
      snackPosition: SnackPosition.TOP,
    );
  }

  void _blockContact() {
    Get.dialog(
      AlertDialog(
        title: const Text('Bloquer le contact'),
        content: Text('Êtes-vous sûr de vouloir bloquer ${contact.name} ?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Contact bloqué',
                '${contact.name} a été bloqué',
                snackPosition: SnackPosition.TOP,
              );
            },
            child: const Text('Bloquer'),
          ),
        ],
      ),
    );
  }
}

class ContactData {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatar;
  final String initials;
  final ContactStatus status;
  final DateTime lastSeen;
  bool isFavorite;

  ContactData({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.avatar,
    required this.initials,
    required this.status,
    required this.lastSeen,
    this.isFavorite = false,
  });
}

enum ContactStatus { online, away, offline } 