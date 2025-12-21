import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/theme/app_theme.dart';

class FilesPage extends StatefulWidget {
  const FilesPage({super.key});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<FileData> _files = [
    FileData(
      id: '1',
      name: 'document.pdf',
      size: 2048576, // 2MB
      type: FileType.document,
      url: 'https://example.com/document.pdf',
      uploadedBy: 'Alice Martin',
      uploadedAt: DateTime.now().subtract(const Duration(hours: 2)),
      isEncrypted: true,
      isShared: true,
    ),
    FileData(
      id: '2',
      name: 'image.jpg',
      size: 1048576, // 1MB
      type: FileType.image,
      url: 'https://example.com/image.jpg',
      uploadedBy: 'Bob Dupont',
      uploadedAt: DateTime.now().subtract(const Duration(days: 1)),
      isEncrypted: true,
      isShared: false,
    ),
    FileData(
      id: '3',
      name: 'video.mp4',
      size: 52428800, // 50MB
      type: FileType.video,
      url: 'https://example.com/video.mp4',
      uploadedBy: 'Claire Bernard',
      uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
      isEncrypted: true,
      isShared: true,
    ),
    FileData(
      id: '4',
      name: 'audio.mp3',
      size: 3145728, // 3MB
      type: FileType.audio,
      url: 'https://example.com/audio.mp3',
      uploadedBy: 'David Leroy',
      uploadedAt: DateTime.now().subtract(const Duration(hours: 5)),
      isEncrypted: true,
      isShared: false,
    ),
    FileData(
      id: '5',
      name: 'presentation.pptx',
      size: 8388608, // 8MB
      type: FileType.document,
      url: 'https://example.com/presentation.pptx',
      uploadedBy: 'Emma Dubois',
      uploadedAt: DateTime.now().subtract(const Duration(days: 3)),
      isEncrypted: true,
      isShared: true,
    ),
  ];

  List<FileData> _filteredFiles = [];
  String _selectedFilter = 'Tous';

  @override
  void initState() {
    super.initState();
    _filteredFiles = List.from(_files);
    _searchController.addListener(_filterFiles);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterFiles() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty && _selectedFilter == 'Tous') {
        _filteredFiles = List.from(_files);
      } else {
        _filteredFiles = _files.where((file) {
          final matchesQuery = query.isEmpty || 
              file.name.toLowerCase().contains(query) ||
              file.uploadedBy.toLowerCase().contains(query);
          
          final matchesFilter = _selectedFilter == 'Tous' ||
              (_selectedFilter == 'Partagés' && file.isShared) ||
              (_selectedFilter == 'Documents' && file.type == FileType.document) ||
              (_selectedFilter == 'Images' && file.type == FileType.image) ||
              (_selectedFilter == 'Vidéos' && file.type == FileType.video) ||
              (_selectedFilter == 'Audio' && file.type == FileType.audio);
          
          return matchesQuery && matchesFilter;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Fichiers partagés'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: () => _uploadFile(),
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
              hint: 'Rechercher un fichier...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterFiles();
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
                _buildFilterChip('Tous', _selectedFilter == 'Tous'),
                const SizedBox(width: 8),
                _buildFilterChip('Partagés', _selectedFilter == 'Partagés'),
                const SizedBox(width: 8),
                _buildFilterChip('Documents', _selectedFilter == 'Documents'),
                const SizedBox(width: 8),
                _buildFilterChip('Images', _selectedFilter == 'Images'),
                const SizedBox(width: 8),
                _buildFilterChip('Vidéos', _selectedFilter == 'Vidéos'),
                const SizedBox(width: 8),
                _buildFilterChip('Audio', _selectedFilter == 'Audio'),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Statistiques
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.folder, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  '${_filteredFiles.length} fichier${_filteredFiles.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTotalSize(),
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Liste des fichiers
          Expanded(
            child: _filteredFiles.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredFiles.length,
                    itemBuilder: (context, index) {
                      final file = _filteredFiles[index];
                      return _buildFileTile(file);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
        });
        _filterFiles();
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  Widget _buildFileTile(FileData file) {
    return CommonWidgets.customCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getFileTypeColor(file.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getFileTypeIcon(file.type),
            color: _getFileTypeColor(file.type),
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                file.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (file.isEncrypted)
              Icon(
                Icons.lock,
                size: 16,
                color: AppTheme.successColor,
              ),
            if (file.isShared)
              Icon(
                Icons.share,
                size: 16,
                color: AppTheme.primaryColor,
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_formatFileSize(file.size)} • ${file.uploadedBy}',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
            Text(
              'Il y a ${_formatTimeAgo(file.uploadedAt)}',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleFileAction(value, file),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'download',
              child: Row(
                children: [
                  Icon(Icons.download),
                  SizedBox(width: 8),
                  Text('Télécharger'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share),
                  SizedBox(width: 8),
                  Text('Partager'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'preview',
              child: Row(
                children: [
                  Icon(Icons.preview),
                  SizedBox(width: 8),
                  Text('Aperçu'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete),
                  SizedBox(width: 8),
                  Text('Supprimer'),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _showFileDetails(file),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun fichier trouvé',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez de modifier votre recherche ou vos filtres',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getFileTypeColor(FileType type) {
    switch (type) {
      case FileType.document:
        return Colors.blue;
      case FileType.image:
        return Colors.green;
      case FileType.video:
        return Colors.red;
      case FileType.audio:
        return Colors.orange;
    }
  }

  IconData _getFileTypeIcon(FileType type) {
    switch (type) {
      case FileType.document:
        return Icons.description;
      case FileType.image:
        return Icons.image;
      case FileType.video:
        return Icons.video_file;
      case FileType.audio:
        return Icons.audio_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  String _formatTotalSize() {
    final totalBytes = _filteredFiles.fold<int>(0, (sum, file) => sum + file.size);
    return _formatFileSize(totalBytes);
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

  void _uploadFile() {
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
              leading: const Icon(Icons.photo_camera),
              title: const Text('Prendre une photo'),
              onTap: () {
                Get.back();
                _uploadFileFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Prendre une vidéo'),
              onTap: () {
                Get.back();
                _uploadFileFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir depuis la galerie'),
              onTap: () {
                Get.back();
                _uploadFileFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Choisir un fichier'),
              onTap: () {
                Get.back();
                _uploadFileFromDevice();
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Annuler'),
              onTap: () => Get.back(),
            ),
          ],
        ),
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
              leading: const Icon(Icons.sort),
              title: const Text('Trier par'),
              onTap: () {
                Get.back();
                _showSortOptions();
              },
            ),
            ListTile(
              leading: const Icon(Icons.grid_view),
              title: const Text('Vue en grille'),
              onTap: () {
                Get.back();
                Get.snackbar('Vue', 'Changement de vue');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Paramètres'),
              onTap: () {
                Get.back();
                Get.snackbar('Paramètres', 'Paramètres des fichiers');
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

  void _uploadFileFromCamera() {
    Get.snackbar(
      'Caméra',
      'Ouverture de la caméra...',
      snackPosition: SnackPosition.TOP,
    );
  }

  void _uploadFileFromGallery() {
    Get.snackbar(
      'Galerie',
      'Ouverture de la galerie...',
      snackPosition: SnackPosition.TOP,
    );
  }

  void _uploadFileFromDevice() {
    Get.snackbar(
      'Fichier',
      'Sélection d\'un fichier...',
      snackPosition: SnackPosition.TOP,
    );
  }

  void _showSortOptions() {
    Get.snackbar(
      'Tri',
      'Options de tri',
      snackPosition: SnackPosition.TOP,
    );
  }

  void _showFileDetails(FileData file) {
    Get.to(() => FileDetailsPage(file: file));
  }

  void _handleFileAction(String action, FileData file) {
    switch (action) {
      case 'download':
        Get.snackbar(
          'Téléchargement',
          'Téléchargement de ${file.name}...',
          snackPosition: SnackPosition.TOP,
        );
        break;
      case 'share':
        Get.snackbar(
          'Partage',
          'Partage de ${file.name}',
          snackPosition: SnackPosition.TOP,
        );
        break;
      case 'preview':
        Get.snackbar(
          'Aperçu',
          'Aperçu de ${file.name}',
          snackPosition: SnackPosition.TOP,
        );
        break;
      case 'delete':
        Get.dialog(
          AlertDialog(
            title: const Text('Supprimer le fichier'),
            content: Text('Êtes-vous sûr de vouloir supprimer ${file.name} ?'),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  Get.back();
                  setState(() {
                    _files.remove(file);
                    _filterFiles();
                  });
                  Get.snackbar(
                    'Fichier supprimé',
                    '${file.name} a été supprimé',
                    snackPosition: SnackPosition.TOP,
                  );
                },
                child: const Text('Supprimer'),
              ),
            ],
          ),
        );
        break;
    }
  }
}

class FileDetailsPage extends StatelessWidget {
  final FileData file;
  
  const FileDetailsPage({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(file.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showFileOptions(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Aperçu du fichier
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: _getFileTypeColor(file.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getFileTypeIcon(file.type),
                  color: _getFileTypeColor(file.type),
                  size: 80,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Actions rapides
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.download,
                  label: 'Télécharger',
                  onTap: () => _downloadFile(),
                ),
                _buildActionButton(
                  icon: Icons.share,
                  label: 'Partager',
                  onTap: () => _shareFile(),
                ),
                _buildActionButton(
                  icon: Icons.preview,
                  label: 'Aperçu',
                  onTap: () => _previewFile(),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Informations du fichier
            CommonWidgets.customCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informations du fichier',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Nom', file.name),
                  _buildInfoRow('Taille', _formatFileSize(file.size)),
                  _buildInfoRow('Type', _getFileTypeName(file.type)),
                  _buildInfoRow('Uploadé par', file.uploadedBy),
                  _buildInfoRow('Date d\'upload', _formatDate(file.uploadedAt)),
                  _buildInfoRow('Statut', file.isShared ? 'Partagé' : 'Privé'),
                  _buildInfoRow('Sécurité', file.isEncrypted ? 'Chiffré' : 'Non chiffré'),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Color _getFileTypeColor(FileType type) {
    switch (type) {
      case FileType.document:
        return Colors.blue;
      case FileType.image:
        return Colors.green;
      case FileType.video:
        return Colors.red;
      case FileType.audio:
        return Colors.orange;
    }
  }

  IconData _getFileTypeIcon(FileType type) {
    switch (type) {
      case FileType.document:
        return Icons.description;
      case FileType.image:
        return Icons.image;
      case FileType.video:
        return Icons.video_file;
      case FileType.audio:
        return Icons.audio_file;
    }
  }

  String _getFileTypeName(FileType type) {
    switch (type) {
      case FileType.document:
        return 'Document';
      case FileType.image:
        return 'Image';
      case FileType.video:
        return 'Vidéo';
      case FileType.audio:
        return 'Audio';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} à ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showFileOptions() {
    Get.snackbar(
      'Options du fichier',
      'Fonctionnalité à implémenter',
      snackPosition: SnackPosition.TOP,
    );
  }

  void _downloadFile() {
    Get.snackbar(
      'Téléchargement',
      'Téléchargement de ${file.name}...',
      snackPosition: SnackPosition.TOP,
    );
  }

  void _shareFile() {
    Get.snackbar(
      'Partage',
      'Partage de ${file.name}',
      snackPosition: SnackPosition.TOP,
    );
  }

  void _previewFile() {
    Get.snackbar(
      'Aperçu',
      'Aperçu de ${file.name}',
      snackPosition: SnackPosition.TOP,
    );
  }
}

class FileData {
  final String id;
  final String name;
  final int size;
  final FileType type;
  final String url;
  final String uploadedBy;
  final DateTime uploadedAt;
  final bool isEncrypted;
  final bool isShared;

  FileData({
    required this.id,
    required this.name,
    required this.size,
    required this.type,
    required this.url,
    required this.uploadedBy,
    required this.uploadedAt,
    required this.isEncrypted,
    required this.isShared,
  });
}

enum FileType { document, image, video, audio } 