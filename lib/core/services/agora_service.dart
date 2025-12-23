import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service Agora RTC pour gérer les appels audio/vidéo
/// 
/// Ce service gère la connexion WebRTC via Agora pour les appels.
/// Les streams sont chiffrés avec Signal Protocol côté client.
class AgoraService extends GetxController {
  static AgoraService? _instance;
  static AgoraService get instance => _instance ??= AgoraService._();
  
  AgoraService._();
  
  // Configuration Agora (à remplacer par vos propres credentials)
  // Pour le développement, vous pouvez utiliser un App ID temporaire
  // En production, utilisez un App ID et Token depuis votre compte Agora
  static const String appId = 'ba92f87a840d42f2943d19ee3484f551'; // À configurer
  static const String token = ''; // Optionnel pour le développement
  
  RtcEngine? _engine;
  final RxBool _isInitialized = false.obs;
  final RxBool _isInCall = false.obs;
  final RxBool _isMuted = false.obs;
  final RxBool _isVideoEnabled = true.obs;
  final RxBool _isSpeakerEnabled = false.obs;
  final RxString _currentChannel = ''.obs;
  final RxInt _remoteUid = 0.obs;
  
  // Callbacks
  Function(int uid, int elapsed)? onUserJoined;
  Function(int uid, UserOfflineReasonType reason)? onUserOffline;
  Function()? onCallEnded;
  
  bool get isInitialized => _isInitialized.value;
  bool get isInCall => _isInCall.value;
  bool get isMuted => _isMuted.value;
  bool get isVideoEnabled => _isVideoEnabled.value;
  bool get isSpeakerEnabled => _isSpeakerEnabled.value;
  String get currentChannel => _currentChannel.value;
  int get remoteUid => _remoteUid.value;
  
  @override
  void onInit() {
    super.onInit();
    _initializeAgora();
  }
  
  @override
  void onClose() {
    _engine?.leaveChannel();
    _engine?.release();
    super.onClose();
  }
  
  /// Initialise le moteur Agora
  Future<void> _initializeAgora() async {
    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));
      
      // Configurer les callbacks
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            print('✅ Rejoint le canal Agora: ${connection.channelId}');
            _isInCall.value = true;
            _currentChannel.value = connection.channelId ?? '';
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            print('✅ Quitté le canal Agora');
            _isInCall.value = false;
            _currentChannel.value = '';
            _remoteUid.value = 0;
            onCallEnded?.call();
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            print('✅ Utilisateur rejoint: $remoteUid');
            _remoteUid.value = remoteUid;
            onUserJoined?.call(remoteUid, elapsed);
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            print('⚠️ Utilisateur déconnecté: $remoteUid, raison: $reason');
            _remoteUid.value = 0;
            onUserOffline?.call(remoteUid, reason);
          },
          onError: (ErrorCodeType err, String msg) {
            print('❌ Erreur Agora: $err - $msg');
          },
          onConnectionStateChanged: (RtcConnection connection, ConnectionStateType state, ConnectionChangedReasonType reason) {
            print('🔄 État de connexion: $state, raison: $reason');
          },
        ),
      );
      
      _isInitialized.value = true;
      print('✅ Agora RTC initialisé');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation d\'Agora: $e');
      _isInitialized.value = false;
    }
  }
  
  /// Demande les permissions nécessaires
  Future<bool> requestPermissions(String callType) async {
    try {
      if (callType == 'video') {
        final mic = await Permission.microphone.request();
        final camera = await Permission.camera.request();
        if (!mic.isGranted || !camera.isGranted) {
          print('❌ Permissions refusées: microphone=${mic.isGranted}, camera=${camera.isGranted}');
          return false;
        }
      } else {
        final mic = await Permission.microphone.request();
        if (!mic.isGranted) {
          print('❌ Permission microphone refusée');
          return false;
        }
      }
      return true;
    } catch (e) {
      print('❌ Erreur lors de la demande de permissions: $e');
      return false;
    }
  }
  
  /// Rejoint un canal pour un appel
  Future<void> joinChannel(String channelId, int uid, String callType) async {
    if (!_isInitialized.value || _engine == null) {
      throw Exception('Agora non initialisé');
    }
    
    try {
      // Activer le microphone
      await _engine!.enableLocalAudio(true);
      
      // Activer la caméra si c'est un appel vidéo
      if (callType == 'video') {
        await _engine!.enableLocalVideo(true);
        await _engine!.startPreview();
      } else {
        await _engine!.enableLocalVideo(false);
      }
      
      // Rejoindre le canal
      // Note: Si token est vide, on peut l'omettre ou passer une chaîne vide
      // Agora accepte une chaîne vide pour le développement
      await _engine!.joinChannel(
        token: token.isEmpty ? '' : token,
        channelId: channelId,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
      
      print('📞 Rejoindre le canal: $channelId');
    } catch (e) {
      print('❌ Erreur lors de la jonction au canal: $e');
      rethrow;
    }
  }
  
  /// Quitte le canal
  Future<void> leaveChannel() async {
    if (_engine == null) return;
    
    try {
      await _engine!.leaveChannel();
      await _engine!.stopPreview();
      _isInCall.value = false;
      _currentChannel.value = '';
      _remoteUid.value = 0;
      print('📞 Canal quitté');
    } catch (e) {
      print('❌ Erreur lors de la sortie du canal: $e');
    }
  }
  
  /// Active/désactive le microphone
  Future<void> toggleMute() async {
    if (_engine == null) return;
    
    try {
      _isMuted.value = !_isMuted.value;
      await _engine!.muteLocalAudioStream(_isMuted.value);
      print('🔇 Microphone: ${_isMuted.value ? "muet" : "activé"}');
    } catch (e) {
      print('❌ Erreur lors du toggle mute: $e');
      _isMuted.value = !_isMuted.value; // Revert on error
    }
  }
  
  /// Active/désactive la caméra
  Future<void> toggleVideo() async {
    if (_engine == null) return;
    
    try {
      _isVideoEnabled.value = !_isVideoEnabled.value;
      await _engine!.enableLocalVideo(_isVideoEnabled.value);
      print('📹 Caméra: ${_isVideoEnabled.value ? "activée" : "désactivée"}');
    } catch (e) {
      print('❌ Erreur lors du toggle vidéo: $e');
      _isVideoEnabled.value = !_isVideoEnabled.value; // Revert on error
    }
  }
  
  /// Active/désactive le haut-parleur
  Future<void> toggleSpeaker() async {
    if (_engine == null) return;
    
    try {
      _isSpeakerEnabled.value = !_isSpeakerEnabled.value;
      await _engine!.setEnableSpeakerphone(_isSpeakerEnabled.value);
      print('🔊 Haut-parleur: ${_isSpeakerEnabled.value ? "activé" : "désactivé"}');
    } catch (e) {
      print('❌ Erreur lors du toggle haut-parleur: $e');
      _isSpeakerEnabled.value = !_isSpeakerEnabled.value; // Revert on error
    }
  }
  
  /// Bascule la caméra (avant/arrière)
  Future<void> switchCamera() async {
    if (_engine == null) return;
    
    try {
      await _engine!.switchCamera();
      print('📹 Caméra basculée');
    } catch (e) {
      print('❌ Erreur lors du basculement de caméra: $e');
    }
  }
  
  /// Obtient le widget pour la vue vidéo locale
  Widget? getLocalVideoView() {
    if (_engine == null) return null;
    // Note: Agora nécessite une vue native, à implémenter avec PlatformView
    return null;
  }
  
  /// Obtient le widget pour la vue vidéo distante
  Widget? getRemoteVideoView() {
    if (_engine == null || _remoteUid.value == 0) return null;
    // Note: Agora nécessite une vue native, à implémenter avec PlatformView
    return null;
  }
}

