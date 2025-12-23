import 'package:intl/intl.dart';

/// Utilitaires pour le formatage des dates
class DateUtils {
  /// Formate un timestamp relatif (ex: "5m", "2h", "3j")
  static String formatRelative(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Maintenant';
    }
  }
  
  /// Formate une date complète
  static String formatFull(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
  
  /// Formate une date courte
  static String formatShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
  
  /// Formate une heure
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }
}

