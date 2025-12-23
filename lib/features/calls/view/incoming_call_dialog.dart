import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/adaptive_widgets.dart';
import '../../../core/utils/platform_utils.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/controllers/app_controller.dart';

/// Dialog pour afficher un appel entrant
class IncomingCallDialog extends StatelessWidget {
  final String callerId;
  final String callerName;
  final String? callerAvatar;
  final String callType; // 'audio' or 'video'
  final String callId;
  
  const IncomingCallDialog({
    super.key,
    required this.callerId,
    required this.callerName,
    this.callerAvatar,
    required this.callType,
    required this.callId,
  });
  
  Future<void> _handleAccept() async {
    try {
      await AppController.to.acceptCall(callId);
      Get.back();
      // Navigation vers la page d'appel sera gérée par AppController
    } catch (e) {
      print('❌ Erreur lors de l\'acceptation de l\'appel: $e');
      CommonWidgets.showSafeSnackbar(
        title: 'Erreur',
        message: 'Impossible d\'accepter l\'appel',
        backgroundColor: AppTheme.errorColor,
      );
    }
  }
  
  Future<void> _handleReject() async {
    try {
      await AppController.to.rejectCall(callId);
      Get.back();
    } catch (e) {
      print('❌ Erreur lors du rejet de l\'appel: $e');
      Get.back(); // Fermer quand même le dialog
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isIOS) {
      return CupertinoAlertDialog(
        title: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              'Appel ${callType == 'video' ? 'vidéo' : 'audio'} entrant',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Column(
            children: [
              CommonWidgets.avatar(
                imageUrl: callerAvatar,
                initials: callerName.split(' ').take(2).map((n) => n[0]).join(''),
                size: 80,
              ),
              const SizedBox(height: 16),
              Text(
                callerName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: _handleReject,
            isDestructiveAction: true,
            child: const Text('Rejeter'),
          ),
          CupertinoDialogAction(
            onPressed: _handleAccept,
            isDefaultAction: true,
            child: const Text('Accepter'),
          ),
        ],
      );
    } else {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Appel ${callType == 'video' ? 'vidéo' : 'audio'} entrant',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CommonWidgets.avatar(
              imageUrl: callerAvatar,
              initials: callerName.split(' ').take(2).map((n) => n[0]).join(''),
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              callerName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _handleReject,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Rejeter'),
          ),
          ElevatedButton(
            onPressed: _handleAccept,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Accepter'),
          ),
        ],
      );
    }
  }
}

