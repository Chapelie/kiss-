import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/adaptive_widgets.dart';
import '../../../core/utils/platform_utils.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/controllers/app_controller.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<ContactData> _contacts = [];
  bool _isLoading = false;
  String _currentFilter = 'Tous';
  List<ContactData> _filteredContacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadContacts({String? searchQuery}) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Si pas de query, charger tous les utilisateurs depuis les conversations
      // Sinon, faire une recherche
      List<Map<String, dynamic>> users;
      
      if (searchQuery == null || searchQuery.isEmpty) {
        // Charger depuis les conversations (déjà chargées automatiquement)
        final conversations = AppController.to.conversations;
        users = conversations.map((conv) {
          return {
            'id': conv.participantId,
            'name': conv.participantName ?? 'Utilisateur',
            'email': '', // Pas disponible dans Conversation
            'username': null,
            'avatar_url': conv.participantAvatar,
            'created_at': DateTime.now().toIso8601String(),
          };
        }).toList();
        
        // Si aucune conversation, charger depuis l'API
        if (users.isEmpty) {
          users = await ApiService.instance.searchUsers(
            query: '', // Query vide = tous les utilisateurs
            limit: 1000,
          );
        }
      } else {
        // Recherche avec query
        users = await ApiService.instance.searchUsers(
          query: searchQuery,
          limit: 50,
        );
      }
      
      setState(() {
        _contacts.clear();
        _contacts.addAll(users.map((user) {
          // Gérer les valeurs null du backend
          final id = user['id']?.toString() ?? '';
          if (id.isEmpty) {
            return null; // Ignorer les utilisateurs sans ID
          }
          
          final username = user['username']?.toString() ?? '';
          final name = user['name']?.toString() ?? 
                      (username.isNotEmpty ? username : user['email']?.toString() ?? 'Utilisateur');
          final email = user['email']?.toString() ?? '';
          final displayName = name;
          final avatarUrl = user['avatar_url']?.toString() ?? user['avatarUrl']?.toString();
          
          // Générer les initiales
          final initials = displayName.split(' ').take(2).map((n) => 
            n.isNotEmpty ? n[0].toUpperCase() : ''
          ).join('');
          final displayInitials = initials.isNotEmpty 
              ? initials 
              : (username.isNotEmpty 
                  ? username[0].toUpperCase() 
                  : (email.isNotEmpty 
                      ? email[0].toUpperCase() 
                      : 'U'));
          
          // Parser la date de création
          DateTime lastSeen = DateTime.now();
          final createdAtStr = user['created_at']?.toString() ?? user['createdAt']?.toString();
          if (createdAtStr != null && createdAtStr.isNotEmpty) {
            try {
              lastSeen = DateTime.parse(createdAtStr);
            } catch (e) {
              print('⚠️ Erreur de parsing created_at: $createdAtStr');
              lastSeen = DateTime.now();
            }
          }
          
          // Déterminer le statut depuis les conversations
          ContactStatus status = ContactStatus.offline;
          final conversations = AppController.to.conversations;
          final conversation = conversations.firstWhere(
            (conv) => conv.participantId == id,
            orElse: () => Conversation(
              id: '',
              participantId: id,
              participantName: displayName,
              participantAvatar: avatarUrl,
              lastMessage: null,
              lastMessageTime: null,
              unreadCount: 0,
              participantStatus: 'offline',
            ),
          );
          
          if (conversation.participantStatus == 'online') {
            status = ContactStatus.online;
          } else if (conversation.participantStatus == 'away') {
            status = ContactStatus.away;
          }
          
          return ContactData(
            id: id,
            name: displayName,
            email: email,
            username: username.isNotEmpty ? username : null, // Ajouter username
            phone: '', // Pas de téléphone dans le backend pour l'instant
            avatar: avatarUrl,
            initials: displayInitials,
            status: status,
            lastSeen: lastSeen,
            isFavorite: false,
          );
        }).whereType<ContactData>().toList());
        
        _applyFilters();
      });
    } catch (e) {
      print('❌ Erreur lors du chargement des contacts: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _loadContacts();
    } else {
      _loadContacts(searchQuery: query);
    }
  }

  void _filterContacts() {
    _applyFilters();
  }
  
  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      var filtered = List<ContactData>.from(_contacts);
      
      // Filtre par recherche
      if (query.isNotEmpty) {
        filtered = filtered.where((contact) {
          return contact.name.toLowerCase().contains(query) ||
                 contact.email.toLowerCase().contains(query);
        }).toList();
      }
      
      // Filtre par statut
      if (_currentFilter == 'En ligne') {
        filtered = filtered.where((contact) => contact.status == ContactStatus.online).toList();
      } else if (_currentFilter == 'Favoris') {
        filtered = filtered.where((contact) => contact.isFavorite).toList();
      }
      
      _filteredContacts = filtered;
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
                _buildFilterChip('Tous', _currentFilter == 'Tous'),
                const SizedBox(width: 8),
                _buildFilterChip('En ligne', _currentFilter == 'En ligne'),
                const SizedBox(width: 8),
                _buildFilterChip('Favoris', _currentFilter == 'Favoris'),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Liste des contacts
          Expanded(
            child: _isLoading
                ? Center(
                    child: AdaptiveWidgets.adaptiveLoadingIndicator(
                      message: 'Chargement des contacts...',
                    ),
                  )
                : _filteredContacts.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => _loadContacts(searchQuery: _searchController.text.trim().isEmpty ? null : _searchController.text.trim()),
                        child: ListView.builder(
                          itemCount: _filteredContacts.length,
                          itemBuilder: (context, index) {
                            final contact = _filteredContacts[index];
                            return _buildContactTile(contact);
                          },
                        ),
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
        setState(() {
          _currentFilter = label;
        });
        _applyFilters();
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
    // Afficher un dialogue pour rechercher un utilisateur par email ou username
    showDialog(
      context: context,
      builder: (context) => _AddContactDialog(
        onContactAdded: (contact) async {
          // Créer automatiquement une conversation avec ce contact
          try {
            final conversation = await ApiService.instance.createConversation(contact.id);
            setState(() {
              _contacts.add(contact);
              _applyFilters();
            });
            // Naviguer vers la conversation
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Get.back();
            }
            Get.toNamed('/chat/${conversation['id']}', arguments: {
              'participant_id': contact.id,
              'participant_name': contact.name,
              'participant_avatar': contact.avatar,
            });
          } catch (e) {
            print('❌ Erreur lors de la création de la conversation: $e');
            // Ajouter quand même le contact à la liste
            setState(() {
              _contacts.add(contact);
              _applyFilters();
            });
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Get.back();
            }
            Get.snackbar(
              'Contact ajouté',
              'Le contact a été ajouté mais la conversation n\'a pas pu être créée',
              snackPosition: SnackPosition.TOP,
            );
          }
        },
      ),
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
                if (Get.isDialogOpen == true) {
                  Get.back();
                }
                Get.snackbar('Import', 'Import des contacts');
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('Créer un groupe'),
              onTap: () {
                if (Get.isDialogOpen == true) {
                  Get.back();
                }
                Get.snackbar('Groupe', 'Création de groupe');
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort),
              title: const Text('Trier les contacts'),
              onTap: () {
                if (Get.isDialogOpen == true) {
                  Get.back();
                }
                Get.snackbar('Tri', 'Tri des contacts');
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Fermer'),
              onTap: () {
                if (Get.isDialogOpen == true) {
                  Get.back();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _startNewConversation() {
    // Navigation vers la page de contacts pour sélectionner un contact
    _addContact();
  }
  
  void _startConversationWithContact(ContactData contact) {
    // Créer ou ouvrir une conversation avec ce contact
    Get.toNamed('/chat/${contact.id}', arguments: {
      'participant_id': contact.id,
      'participant_name': contact.name,
      'participant_avatar': contact.avatar,
    });
  }

  void _showContactDetails(ContactData contact) {
    Get.to(() => ContactDetailsPage(contact: contact));
  }

  void _handleContactAction(String action, ContactData contact) {
    switch (action) {
      case 'message':
        // Démarrer une conversation avec ce contact
        _startConversationWithContact(contact);
        break;
      case 'call':
        // Démarrer un appel audio
        AppController.to.startCall(contact.id, 'audio');
        if (Get.isDialogOpen == true) {
          Get.back(); // Retourner à la page précédente
        }
        break;
      case 'video_call':
        // Démarrer un appel vidéo
        AppController.to.startCall(contact.id, 'video');
        if (Get.isDialogOpen == true) {
          Get.back(); // Retourner à la page précédente
        }
        break;
      case 'favorite':
        setState(() {
          contact.isFavorite = !contact.isFavorite;
        });
        break;
      case 'block':
        Get.dialog(
          AlertDialog(
            title: const Text('Bloquer le contact'),
            content: Text('Êtes-vous sûr de vouloir bloquer ${contact.name} ?'),
            actions: [
              TextButton(
                onPressed: () {
                  if (Get.isDialogOpen == true) {
                    Get.back();
                  }
                },
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  if (Get.isDialogOpen == true) {
                    Get.back();
                  }
                  // TODO: Implémenter le blocage côté backend
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
    // Ouvrir la conversation avec ce contact
    Get.back(); // Fermer la page de détails
    Get.toNamed('/chat/${contact.id}', arguments: {
      'participant_id': contact.id,
      'participant_name': contact.name,
      'participant_avatar': contact.avatar,
    });
  }

  void _makeCall() {
    // Démarrer un appel audio
    Get.back(); // Fermer la page de détails
    AppController.to.startCall(contact.id, 'audio');
  }

  void _makeVideoCall() {
    // Démarrer un appel vidéo
    Get.back(); // Fermer la page de détails
    AppController.to.startCall(contact.id, 'video');
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
            onPressed: () {
              if (Get.isDialogOpen == true) {
                Get.back();
              }
            },
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (Get.isDialogOpen == true) {
                Get.back();
              }
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
  final String? username; // Ajout du champ username
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
    this.username, // Optionnel car peut être null
    required this.phone,
    this.avatar,
    required this.initials,
    required this.status,
    required this.lastSeen,
    this.isFavorite = false,
  });
}

enum ContactStatus { online, away, offline }

// Dialogue pour ajouter un contact
class _AddContactDialog extends StatefulWidget {
  final Function(ContactData) onContactAdded;
  
  const _AddContactDialog({required this.onContactAdded});
  
  @override
  State<_AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<_AddContactDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
  
  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchUsers();
    });
  }
  
  Future<void> _searchUsers() async {
    final query = _searchController.text.trim();
    print('🔍 Recherche dans le modal - Query: "$query"');
    
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }
    
    if (!mounted) return;
    
    setState(() {
      _isSearching = true;
    });
    
    try {
      // Si c'est un email, chercher directement par email
      if (GetUtils.isEmail(query)) {
        print('🔍 Détection d\'un email, utilisation de findUserByEmail');
        final user = await ApiService.instance.findUserByEmail(query);
        print('🔍 Résultat findUserByEmail: ${user != null ? "trouvé" : "non trouvé"}');
        if (user != null) {
          print('🔍 Utilisateur trouvé: ${user['email']} / ${user['username']}');
        }
        if (mounted) {
          setState(() {
            _searchResults = user != null ? [user] : [];
          });
          print('🔍 Résultats mis à jour: ${_searchResults.length} utilisateur(s)');
        }
      } else {
        // Sinon, faire une recherche normale
        print('🔍 Recherche par username/nom, utilisation de searchUsers');
        final users = await ApiService.instance.searchUsers(query: query, limit: 10);
        print('🔍 Résultat searchUsers: ${users.length} utilisateur(s) trouvé(s)');
        if (users.isNotEmpty) {
          print('🔍 Premiers résultats:');
          for (var i = 0; i < users.length && i < 3; i++) {
            print('   - ${users[i]['email']} / ${users[i]['username']}');
          }
        }
        if (mounted) {
          setState(() {
            _searchResults = users;
          });
          print('🔍 Résultats mis à jour: ${_searchResults.length} utilisateur(s)');
        }
      }
    } catch (e, stackTrace) {
      print('❌ Erreur lors de la recherche: $e');
      print('   Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _searchResults = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un contact'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CommonWidgets.customTextField(
              controller: _searchController,
              label: 'Email ou nom d\'utilisateur',
              hint: 'Entrez un email ou un nom d\'utilisateur...',
              prefixIcon: const Icon(Icons.search),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            Text(
              'Entrez l\'email d\'une personne pour vérifier si elle est sur Kisse',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 16),
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              )
            else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.person_off, size: 48, color: AppTheme.textSecondaryColor),
                    const SizedBox(height: 8),
                    Text(
                      GetUtils.isEmail(_searchController.text.trim())
                          ? 'Aucun utilisateur trouvé avec cet email'
                          : 'Aucun résultat trouvé',
                      style: TextStyle(color: AppTheme.textSecondaryColor),
                    ),
                    if (GetUtils.isEmail(_searchController.text.trim()))
                      const SizedBox(height: 4),
                    if (GetUtils.isEmail(_searchController.text.trim()))
                      Text(
                        'Cette personne n\'est pas encore sur Kisse',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    // Gérer les valeurs null du backend
                    final id = user['id']?.toString() ?? '';
                    if (id.isEmpty) {
                      return const SizedBox.shrink(); // Ignorer les utilisateurs sans ID
                    }
                    
                    final username = user['username']?.toString() ?? '';
                    final name = user['name']?.toString() ?? 
                                (username.isNotEmpty ? username : user['email']?.toString() ?? 'Utilisateur');
                    final email = user['email']?.toString() ?? '';
                    final displayName = name;
                    final avatarUrl = user['avatar_url']?.toString() ?? user['avatarUrl']?.toString();
                    
                    // Générer les initiales
                    final initials = displayName.split(' ').take(2).map((n) => 
                      n.isNotEmpty ? n[0].toUpperCase() : ''
                    ).join('');
                    final displayInitials = initials.isNotEmpty 
                        ? initials 
                        : (username.isNotEmpty 
                            ? username[0].toUpperCase() 
                            : (email.isNotEmpty 
                                ? email[0].toUpperCase() 
                                : 'U'));
                    
                    return ListTile(
                      leading: CommonWidgets.avatar(
                        imageUrl: avatarUrl,
                        initials: displayInitials,
                        size: 40,
                      ),
                      title: Text(displayName),
                      subtitle: Text(username.isNotEmpty ? '@$username' : (email.isNotEmpty ? email : '')),
                      onTap: () {
                        final contact = ContactData(
                          id: id,
                          name: displayName,
                          email: email,
                          username: username.isNotEmpty ? username : null, // Ajouter username
                          phone: '',
                          avatar: avatarUrl,
                          initials: displayInitials,
                          status: ContactStatus.offline,
                          lastSeen: DateTime.now(),
                          isFavorite: false,
                        );
                        widget.onContactAdded(contact);
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else if (Get.isDialogOpen == true) {
                          Get.back();
                        }
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Get.back();
            }
          },
          child: const Text('Annuler'),
        ),
      ],
    );
  }
} 