import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Utilitaires pour le chiffrement et le hachage
class CryptoUtils {
  /// Calcule le hash SHA-256 d'une chaîne
  static String sha256Hash(String input) {
    final bytes = utf8.encode(input);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
  
  /// Calcule le hash SHA-256 de bytes
  static String sha256HashBytes(List<int> bytes) {
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
  
  /// Encode une chaîne en base64
  static String base64Encode(String input) {
    final bytes = utf8.encode(input);
    return base64EncodeBytes(bytes);
  }
  
  /// Encode des bytes en base64
  static String base64EncodeBytes(List<int> bytes) {
    return base64.encode(bytes);
  }
  
  /// Décode une chaîne base64
  static String base64Decode(String input) {
    final bytes = base64DecodeBytes(input);
    return utf8.decode(bytes);
  }
  
  /// Décode une chaîne base64 en bytes
  static List<int> base64DecodeBytes(String input) {
    return base64.decode(input);
  }
}

