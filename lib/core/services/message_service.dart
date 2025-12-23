import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import '../constants/app_constants.dart';
import '../utils/crypto_utils.dart';
import 'api_service.dart';
import 'signal_service.dart';
import 'websocket_service.dart';

/// Service pour gérer les messages
/// 
/// Ce service coordonne l'envoi et la réception des messages
/// en utilisant WebSocket pour les métadonnées et HTTPS pour le contenu chiffré.
class MessageService extends GetxService {
  static MessageService get to => Get.find();
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Map<String, String> _pendingMessages = {}; // messageId -> encryptedContent
  
  /// Envoie un message complet (chiffrement + envoi)
  Future<void> sendMessage({
    required String recipientId,
    required String content,
    String messageType = 'text',
  }) async {
    try {
      // 1. Chiffrer le message avec Signal Protocol
      final encryptedMessage = await SignalService.to.encryptMessage(
        content,
        recipientId,
      );
      
      // 2. Stocker temporairement le contenu chiffré
      _pendingMessages[encryptedMessage.id] = encryptedMessage.encryptedContent;
      
      // 3. Envoyer les métadonnées via WebSocket
      await WebSocketService.to.sendMessage(recipientId, content);
      
      // 4. Le contenu chiffré sera envoyé automatiquement par WebSocketService
      // après réception de la confirmation du backend avec l'ID du message
      
    } catch (e) {
      print('❌ Erreur lors de l\'envoi du message: $e');
      rethrow;
    }
  }
  
  // NOTE: Cette méthode n'est plus utilisée car le backend crée directement l'ID du message
  // et le client envoie le contenu avec cet ID. Conservée pour référence future si nécessaire.
  // 
  // /// Met à jour l'ID du message après confirmation du backend
  // Future<void> updateMessageId(String oldId, String newId) async {
  //   ...
  // }
}

