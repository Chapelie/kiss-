import 'dart:io';
import 'package:flutter/foundation.dart';

/// Utilitaires pour la détection de la plateforme
class PlatformUtils {
  /// Vérifie si on est sur iOS
  static bool get isIOS {
    if (kIsWeb) return false;
    return Platform.isIOS;
  }
  
  /// Vérifie si on est sur Android
  static bool get isAndroid {
    if (kIsWeb) return false;
    return Platform.isAndroid;
  }
  
  /// Vérifie si on est sur macOS
  static bool get isMacOS {
    if (kIsWeb) return false;
    return Platform.isMacOS;
  }
  
  /// Vérifie si on est sur Web
  static bool get isWeb => kIsWeb;
  
  /// Retourne le nom de la plateforme
  static String get platformName {
    if (isIOS) return 'iOS';
    if (isAndroid) return 'Android';
    if (isMacOS) return 'macOS';
    if (isWeb) return 'Web';
    return 'Unknown';
  }
}


