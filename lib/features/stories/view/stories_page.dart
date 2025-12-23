import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/adaptive_widgets.dart';
import '../../../core/utils/platform_utils.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';

class StoriesPage extends StatefulWidget {
  const StoriesPage({super.key});

  @override
  State<StoriesPage> createState() => _StoriesPageState();
}

class _StoriesPageState extends State<StoriesPage> {
  final List<StoryData> _stories = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadStories();
  }
  
  Future<void> _loadStories() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final storiesData = await ApiService.instance.getStories(limit: 50);
      setState(() {
        _stories.clear();
        _stories.addAll(
          storiesData.map((data) => StoryData.fromJson(data)).whereType<StoryData>().toList(),
        );
      });
    } catch (e) {
      print('❌ Erreur lors du chargement des stories: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AdaptiveWidgets.adaptiveAppBar(
      title: 'Stories',
      actions: [
        if (PlatformUtils.isIOS)
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _showCreateStoryDialog(),
            child: const Icon(CupertinoIcons.add_circled),
          )
        else
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateStoryDialog(),
          ),
      ],
    );
    
    return AdaptiveWidgets.adaptiveScaffold(
      appBar: appBar,
      backgroundColor: PlatformUtils.isIOS
          ? CupertinoColors.systemBackground
          : AppTheme.backgroundColor,
      body: _isLoading
          ? Center(
              child: AdaptiveWidgets.adaptiveLoadingIndicator(
                message: 'Chargement des stories...',
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadStories,
              child: Column(
                children: [
                  // Stories horizontales en haut
                  if (_stories.isNotEmpty)
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
                  
                  if (_stories.isNotEmpty) const Divider(),
                  
                  // Liste des stories
                  Expanded(
                    child: _stories.isEmpty
                        ? Center(
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
                                  onPressed: () => _showCreateStoryDialog(),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
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
                child: story.mediaUrl != null && story.mediaUrl!.isNotEmpty
                    ? (story.mediaType == MediaType.image
                        ? Image.network(
                            story.mediaUrl!,
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
                          ))
                    : Container(
                        color: AppTheme.surfaceColor,
                        child: Icon(
                          story.mediaType == MediaType.image 
                              ? Icons.image 
                              : Icons.video_library,
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

  Future<void> _viewStory(StoryData story) async {
    // Marquer comme vu via l'API
    try {
      await ApiService.instance.viewStory(story.id);
      setState(() {
        story.isViewed = true;
      });
    } catch (e) {
      print('⚠️ Erreur lors du marquage de la story comme vue: $e');
      // Marquer quand même localement
      setState(() {
        story.isViewed = true;
      });
    }
    
    // Naviguer vers la vue plein écran
    if (Navigator.canPop(context)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StoryViewPage(story: story),
        ),
      );
    } else {
      Get.to(() => StoryViewPage(story: story));
    }
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
                if (Get.isDialogOpen ?? false) {
                  Navigator.of(context).pop();
                }
                _createStory(MediaType.image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Prendre une vidéo'),
              onTap: () {
                if (Get.isDialogOpen ?? false) {
                  Navigator.of(context).pop();
                }
                _createStory(MediaType.video);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir depuis la galerie'),
              onTap: () {
                if (Get.isDialogOpen ?? false) {
                  Navigator.of(context).pop();
                }
                _createStory(MediaType.image);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (Get.isDialogOpen ?? false) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Future<void> _createStory(MediaType mediaType) async {
    // TODO: Implémenter la sélection de média (image picker, camera, etc.)
    // Pour l'instant, on simule avec une URL de test
    final mediaUrl = 'https://picsum.photos/300/400'; // URL de test
    final mediaTypeStr = mediaType == MediaType.image ? 'image' : 'video';
    
    try {
      final storyData = await ApiService.instance.createStory(
        mediaUrl: mediaUrl,
        mediaType: mediaTypeStr,
      );
      
      // Ajouter la story à la liste
      final newStory = StoryData.fromJson(storyData);
      if (newStory != null) {
        setState(() {
          _stories.insert(0, newStory);
        });
        
        if (mounted) {
          CommonWidgets.showSafeSnackbar(
            title: 'Story créée',
            message: 'Votre story a été créée avec succès',
            backgroundColor: AppTheme.successColor,
          );
        }
      }
    } catch (e) {
      print('❌ Erreur lors de la création de la story: $e');
      if (mounted) {
        CommonWidgets.showSafeSnackbar(
          title: 'Erreur',
          message: 'Impossible de créer la story. Veuillez réessayer.',
          backgroundColor: AppTheme.errorColor,
        );
      }
    }
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
                if (Get.isBottomSheetOpen ?? false) {
                  Navigator.of(context).pop();
                }
                CommonWidgets.showSafeSnackbar(
                  title: 'Partagé',
                  message: 'Story partagée',
                  backgroundColor: AppTheme.successColor,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Signaler'),
              onTap: () {
                if (Get.isBottomSheetOpen ?? false) {
                  Navigator.of(context).pop();
                }
                CommonWidgets.showSafeSnackbar(
                  title: 'Signalé',
                  message: 'Story signalée',
                  backgroundColor: AppTheme.warningColor,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Fermer'),
              onTap: () {
                if (Get.isBottomSheetOpen ?? false) {
                  Navigator.of(context).pop();
                }
              },
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
            child: widget.story.mediaUrl != null && widget.story.mediaUrl!.isNotEmpty
                ? (widget.story.mediaType == MediaType.image
                    ? Image.network(
                        widget.story.mediaUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.black,
                            child: const Icon(
                              Icons.image,
                              size: 100,
                              color: Colors.white,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.black,
                        child: const Icon(
                          Icons.video_library,
                          size: 100,
                          color: Colors.white,
                        ),
                      ))
                : Container(
                    color: Colors.black,
                    child: Icon(
                      widget.story.mediaType == MediaType.image 
                          ? Icons.image 
                          : Icons.video_library,
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
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else if (Get.isDialogOpen ?? false) {
                        Navigator.of(context).pop();
                      }
                    },
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
  final String? mediaUrl;
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
    this.mediaUrl,
    required this.mediaType,
    required this.createdAt,
    required this.expiresAt,
    this.isViewed = false,
  });
  
  static StoryData? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    
    // Gérer les valeurs null du backend
    final id = json['id']?.toString() ?? '';
    final userId = json['user_id']?.toString() ?? json['userId']?.toString() ?? '';
    final userName = json['user_name']?.toString() ?? 
                     json['userName']?.toString() ?? 
                     'Utilisateur';
    final userAvatar = json['user_avatar']?.toString() ?? 
                       json['userAvatar']?.toString();
    final contentText = json['content_text']?.toString() ?? 
                        json['contentText']?.toString() ?? '';
    final mediaUrl = json['media_url']?.toString() ?? 
                     json['mediaUrl']?.toString();
    final mediaTypeStr = json['media_type']?.toString() ?? 
                         json['mediaType']?.toString() ?? 
                         'image';
    final mediaType = mediaTypeStr.toLowerCase() == 'video' 
        ? MediaType.video 
        : MediaType.image;
    
    // Générer les initiales
    final initials = userName.split(' ').take(2).map((n) => 
      n.isNotEmpty ? n[0].toUpperCase() : ''
    ).join('');
    final userInitials = initials.isNotEmpty 
        ? initials 
        : (userName.isNotEmpty ? userName[0].toUpperCase() : 'U');
    
    // Parser les dates
    DateTime createdAt;
    final createdAtStr = json['created_at']?.toString() ?? 
                          json['createdAt']?.toString();
    if (createdAtStr != null && createdAtStr.isNotEmpty) {
      try {
        createdAt = DateTime.parse(createdAtStr);
      } catch (e) {
        print('⚠️ Erreur de parsing createdAt: $createdAtStr');
        createdAt = DateTime.now();
      }
    } else {
      createdAt = DateTime.now();
    }
    
    DateTime expiresAt;
    final expiresAtStr = json['expires_at']?.toString() ?? 
                         json['expiresAt']?.toString();
    if (expiresAtStr != null && expiresAtStr.isNotEmpty) {
      try {
        expiresAt = DateTime.parse(expiresAtStr);
      } catch (e) {
        print('⚠️ Erreur de parsing expiresAt: $expiresAtStr');
        expiresAt = DateTime.now().add(const Duration(hours: 24));
      }
    } else {
      expiresAt = DateTime.now().add(const Duration(hours: 24));
    }
    
    final isViewed = json['is_viewed'] ?? json['isViewed'] ?? false;
    
    if (id.isEmpty || userId.isEmpty) {
      print('⚠️ Story avec des données incomplètes: $json');
      return null;
    }
    
    return StoryData(
      id: id,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      userInitials: userInitials,
      content: contentText,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      createdAt: createdAt,
      expiresAt: expiresAt,
      isViewed: isViewed is bool ? isViewed : false,
    );
  }
}

enum MediaType { image, video } 