import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/theme/app_theme.dart';

class StoriesPage extends StatefulWidget {
  const StoriesPage({super.key});

  @override
  State<StoriesPage> createState() => _StoriesPageState();
}

class _StoriesPageState extends State<StoriesPage> {
  final List<StoryData> _stories = [
    StoryData(
      id: '1',
      userId: 'user1',
      userName: 'Alice Martin',
      userAvatar: null,
      userInitials: 'AM',
      content: 'Story content 1',
      mediaUrl: 'https://picsum.photos/300/400',
      mediaType: MediaType.image,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      expiresAt: DateTime.now().add(const Duration(hours: 22)),
      isViewed: false,
    ),
    StoryData(
      id: '2',
      userId: 'user2',
      userName: 'Bob Dupont',
      userAvatar: null,
      userInitials: 'BD',
      content: 'Story content 2',
      mediaUrl: 'https://picsum.photos/300/400',
      mediaType: MediaType.image,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      expiresAt: DateTime.now().add(const Duration(hours: 23)),
      isViewed: true,
    ),
    StoryData(
      id: '3',
      userId: 'user3',
      userName: 'Claire Bernard',
      userAvatar: null,
      userInitials: 'CB',
      content: 'Story content 3',
      mediaUrl: 'https://picsum.photos/300/400',
      mediaType: MediaType.image,
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      expiresAt: DateTime.now().add(const Duration(hours: 23, minutes: 30)),
      isViewed: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Stories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateStoryDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stories horizontales en haut
          Container(
            height: 120,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _stories.length + 1, // +1 pour le bouton "Ajouter"
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildAddStoryButton();
                }
                final story = _stories[index - 1];
                return _buildStoryPreview(story);
              },
            ),
          ),
          
          const Divider(),
          
          // Liste des stories
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _stories.length,
              itemBuilder: (context, index) {
                final story = _stories[index];
                return _buildStoryCard(story);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddStoryButton() {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppTheme.primaryColor,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Icon(
              Icons.add,
              color: AppTheme.primaryColor,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajouter',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStoryPreview(StoryData story) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _viewStory(story),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: story.isViewed 
                      ? AppTheme.textSecondaryColor.withValues(alpha: 0.3)
                      : AppTheme.primaryColor,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: story.userAvatar != null
                    ? Image.network(
                        story.userAvatar!,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        child: Center(
                          child: Text(
                            story.userInitials,
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            story.userName.split(' ').first,
            style: TextStyle(
              fontSize: 12,
              color: story.isViewed 
                  ? AppTheme.textSecondaryColor.withValues(alpha: 0.6)
                  : AppTheme.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard(StoryData story) {
    final timeRemaining = story.expiresAt.difference(DateTime.now());
    final hoursRemaining = timeRemaining.inHours;
    final minutesRemaining = timeRemaining.inMinutes % 60;

    return CommonWidgets.customCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CommonWidgets.avatar(
                imageUrl: story.userAvatar,
                initials: story.userInitials,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Il y a ${_formatTimeAgo(story.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${hoursRemaining}h ${minutesRemaining}m',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.warningColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          if (story.content.isNotEmpty) ...[
            Text(
              story.content,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
          ],
          
          GestureDetector(
            onTap: () => _viewStory(story),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppTheme.surfaceColor,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: story.mediaType == MediaType.image
                    ? Image.network(
                        story.mediaUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppTheme.surfaceColor,
                            child: Icon(
                              Icons.image,
                              size: 50,
                              color: AppTheme.textSecondaryColor,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: AppTheme.surfaceColor,
                        child: Icon(
                          Icons.video_library,
                          size: 50,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Icon(
                story.isViewed ? Icons.visibility : Icons.visibility_off,
                size: 16,
                color: AppTheme.textSecondaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                story.isViewed ? 'Vu' : 'Non vu',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showStoryOptions(story),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _viewStory(StoryData story) {
    // Marquer comme vu
    setState(() {
      story.isViewed = true;
    });
    
    // Naviguer vers la vue plein écran
    Get.to(() => StoryViewPage(story: story));
  }

  void _showCreateStoryDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Créer une story'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Prendre une photo'),
              onTap: () {
                Get.back();
                _createStory(MediaType.image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Prendre une vidéo'),
              onTap: () {
                Get.back();
                _createStory(MediaType.video);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir depuis la galerie'),
              onTap: () {
                Get.back();
                _createStory(MediaType.image);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _createStory(MediaType mediaType) {
    // Simuler la création d'une story
    Get.snackbar(
      'Story créée',
      'Votre story a été créée avec succès',
      snackPosition: SnackPosition.TOP,
    );
  }

  void _showStoryOptions(StoryData story) {
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
              leading: const Icon(Icons.share),
              title: const Text('Partager'),
              onTap: () {
                Get.back();
                Get.snackbar('Partagé', 'Story partagée');
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Signaler'),
              onTap: () {
                Get.back();
                Get.snackbar('Signalé', 'Story signalée');
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
}

class StoryViewPage extends StatefulWidget {
  final StoryData story;
  
  const StoryViewPage({super.key, required this.story});

  @override
  State<StoryViewPage> createState() => _StoryViewPageState();
}

class _StoryViewPageState extends State<StoryViewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Contenu de la story
          Center(
            child: widget.story.mediaType == MediaType.image
                ? Image.network(
                    widget.story.mediaUrl,
                    fit: BoxFit.contain,
                  )
                : Container(
                    color: Colors.black,
                    child: const Icon(
                      Icons.video_library,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
          ),
          
          // En-tête
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  CommonWidgets.avatar(
                    imageUrl: widget.story.userAvatar,
                    initials: widget.story.userInitials,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.story.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Il y a ${_formatTimeAgo(widget.story.createdAt)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
          ),
          
          // Barre de progression
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 3,
              child: LinearProgressIndicator(
                value: 0.3, // Simuler la progression
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
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
}

class StoryData {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String userInitials;
  final String content;
  final String mediaUrl;
  final MediaType mediaType;
  final DateTime createdAt;
  final DateTime expiresAt;
  bool isViewed;

  StoryData({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.userInitials,
    required this.content,
    required this.mediaUrl,
    required this.mediaType,
    required this.createdAt,
    required this.expiresAt,
    this.isViewed = false,
  });
}

enum MediaType { image, video } 