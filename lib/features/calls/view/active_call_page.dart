import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/adaptive_widgets.dart';
import '../../../core/utils/platform_utils.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/controllers/app_controller.dart';
import '../../../core/services/agora_service.dart';

/// Page d'appel en cours
class ActiveCallPage extends StatefulWidget {
  final String callId;
  final String callType; // 'audio' or 'video'
  final String recipientId;
  final String recipientName;
  final String? recipientAvatar;
  final bool isIncoming;
  
  const ActiveCallPage({
    super.key,
    required this.callId,
    required this.callType,
    required this.recipientId,
    required this.recipientName,
    this.recipientAvatar,
    this.isIncoming = false,
  });
  
  @override
  State<ActiveCallPage> createState() => _ActiveCallPageState();
}

class _ActiveCallPageState extends State<ActiveCallPage> {
  Timer? _callTimer;
  Duration _callDuration = Duration.zero;
  final AgoraService _agoraService = AgoraService.instance;
  
  @override
  void initState() {
    super.initState();
    _startCallTimer();
    _initializeCall();
  }
  
  @override
  void dispose() {
    _callTimer?.cancel();
    super.dispose();
  }
  
  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDuration = Duration(seconds: _callDuration.inSeconds + 1);
        });
      }
    });
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
  
  Future<void> _initializeCall() async {
    try {
      // Générer un UID unique pour cet appel
      final uid = DateTime.now().millisecondsSinceEpoch % 100000;
      
      // Rejoindre le canal Agora
      await _agoraService.joinChannel(
        widget.callId,
        uid,
        widget.callType,
      );
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation de l\'appel: $e');
      if (mounted) {
        CommonWidgets.showSafeSnackbar(
          title: 'Erreur',
          message: 'Impossible de démarrer l\'appel',
          backgroundColor: AppTheme.errorColor,
        );
        Navigator.of(context).pop();
      }
    }
  }
  
  Future<void> _handleEndCall() async {
    try {
      await _agoraService.leaveChannel();
      await AppController.to.endCall();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('❌ Erreur lors de la fin de l\'appel: $e');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
  
  Future<void> _handleToggleMute() async {
    await _agoraService.toggleMute();
  }
  
  Future<void> _handleToggleVideo() async {
    if (widget.callType == 'video') {
      await _agoraService.toggleVideo();
    }
  }
  
  Future<void> _handleToggleSpeaker() async {
    await _agoraService.toggleSpeaker();
  }
  
  Future<void> _handleSwitchCamera() async {
    if (widget.callType == 'video') {
      await _agoraService.switchCamera();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        // Empêcher de quitter avec le bouton retour
        if (didPop) {
          _handleEndCall();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              // En-tête avec timer
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_callDuration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (PlatformUtils.isIOS)
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 0,
                        onPressed: _handleEndCall,
                        child: const Icon(
                          CupertinoIcons.xmark_circle_fill,
                          color: Colors.white,
                          size: 24,
                        ),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _handleEndCall,
                      ),
                  ],
                ),
              ),
              
              // Contenu principal
              Expanded(
                child: widget.callType == 'video'
                    ? _buildVideoCallView()
                    : _buildAudioCallView(),
              ),
              
              // Contrôles
              _buildCallControls(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildVideoCallView() {
    return Stack(
      children: [
        // Vue vidéo distante (plein écran)
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CommonWidgets.avatar(
                  imageUrl: widget.recipientAvatar,
                  initials: widget.recipientName.split(' ').take(2).map((n) => n[0]).join(''),
                  size: 120,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.recipientName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() {
                  final agoraService = AgoraService.instance;
                  return Text(
                    agoraService.isInCall ? 'En appel' : 'Connexion...',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        
        // Vue vidéo locale (petite fenêtre en haut à droite)
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            width: 120,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: Center(
              child: Obx(() {
                final agoraService = AgoraService.instance;
                if (agoraService.isVideoEnabled) {
                  // Ici, on devrait afficher la vue vidéo locale d'Agora
                  // Pour l'instant, on affiche un placeholder
                  return const Icon(
                    Icons.videocam,
                    color: Colors.white,
                    size: 40,
                  );
                } else {
                  return CommonWidgets.avatar(
                    imageUrl: null,
                    initials: 'Moi',
                    size: 60,
                  );
                }
              }),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildAudioCallView() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CommonWidgets.avatar(
              imageUrl: widget.recipientAvatar,
              initials: widget.recipientName.split(' ').take(2).map((n) => n[0]).join(''),
              size: 150,
            ),
            const SizedBox(height: 32),
            Text(
              widget.recipientName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() {
              final agoraService = AgoraService.instance;
              return Text(
                agoraService.isInCall ? 'En appel' : 'Connexion...',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCallControls() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute
          Obx(() {
            final agoraService = AgoraService.instance;
            return _buildControlButton(
              icon: Icon(
                agoraService.isMuted ? Icons.mic_off : Icons.mic,
                color: Colors.white,
                size: 28,
              ),
              onPressed: _handleToggleMute,
              backgroundColor: agoraService.isMuted ? AppTheme.errorColor : Colors.white24,
            );
          }),
          
          // Vidéo (si appel vidéo)
          if (widget.callType == 'video')
            Obx(() {
              final agoraService = AgoraService.instance;
              return _buildControlButton(
                icon: Icon(
                  agoraService.isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: _handleToggleVideo,
                backgroundColor: agoraService.isVideoEnabled ? Colors.white24 : AppTheme.errorColor,
              );
            }),
          
          // Bascule caméra (si appel vidéo)
          if (widget.callType == 'video')
            _buildControlButton(
              icon: const Icon(
                Icons.flip_camera_ios,
                color: Colors.white,
                size: 28,
              ),
              onPressed: _handleSwitchCamera,
              backgroundColor: Colors.white24,
            ),
          
          // Haut-parleur
          Obx(() {
            final agoraService = AgoraService.instance;
            return _buildControlButton(
              icon: Icon(
                agoraService.isSpeakerEnabled ? Icons.volume_up : Icons.volume_down,
                color: Colors.white,
                size: 28,
              ),
              onPressed: _handleToggleSpeaker,
              backgroundColor: agoraService.isSpeakerEnabled ? AppTheme.primaryColor : Colors.white24,
            );
          }),
          
          // Raccrocher
          _buildControlButton(
            icon: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 28,
            ),
            onPressed: _handleEndCall,
            backgroundColor: AppTheme.errorColor,
            size: 64,
          ),
        ],
      ),
    );
  }
  
  Widget _buildControlButton({
    required Widget icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    double size = 56,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: PlatformUtils.isIOS
          ? CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 0,
              onPressed: onPressed,
              child: icon,
            )
          : IconButton(
              icon: icon,
              onPressed: onPressed,
              color: Colors.white,
            ),
    );
  }
}

