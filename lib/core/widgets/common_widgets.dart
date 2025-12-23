import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'adaptive_widgets.dart';
import '../theme/app_theme.dart';

/// Widgets communs réutilisables pour l'application Kisse
/// 
/// NOTE: Ces widgets utilisent maintenant les widgets adaptatifs
/// qui s'adaptent automatiquement à iOS (Cupertino) et Android (Material)
class CommonWidgets {
  /// Bouton personnalisé avec style cohérent (adaptatif iOS/Android)
  static Widget customButton({
    required String text,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? textColor,
    double? width,
    double height = 50,
    BorderRadius? borderRadius,
    bool isLoading = false,
  }) {
    return AdaptiveWidgets.adaptiveButton(
      text: text,
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      textColor: textColor,
      width: width,
      height: height,
      isLoading: isLoading,
    );
  }

  /// Champ de texte personnalisé (adaptatif iOS/Android)
  static Widget customTextField({
    required String label,
    String? hint,
    TextEditingController? controller,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? prefixIcon,
    Widget? suffixIcon,
    int? maxLines = 1,
    bool enabled = true,
    ValueChanged<String>? onChanged,
    TextInputAction? textInputAction,
  }) {
    return AdaptiveWidgets.adaptiveTextField(
      label: label,
      hint: hint,
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      maxLines: maxLines,
      enabled: enabled,
      onChanged: onChanged,
      textInputAction: textInputAction,
    );
  }

  /// Carte personnalisée avec ombre (adaptatif iOS/Android)
  static Widget customCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    double elevation = 4,
    VoidCallback? onTap,
  }) {
    return AdaptiveWidgets.adaptiveCard(
      child: child,
      padding: padding,
      margin: margin,
      backgroundColor: backgroundColor,
      onTap: onTap,
    );
  }

  /// Avatar circulaire avec image ou initiales (adaptatif iOS/Android)
  static Widget avatar({
    String? imageUrl,
    String? initials,
    double size = 50,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return AdaptiveWidgets.adaptiveAvatar(
      imageUrl: imageUrl,
      initials: initials,
      size: size,
      backgroundColor: backgroundColor,
      textColor: textColor,
    );
  }

  /// Indicateur de chargement (adaptatif iOS/Android)
  static Widget loadingIndicator({
    String? message,
    Color? color,
  }) {
    return AdaptiveWidgets.adaptiveLoadingIndicator(
      message: message,
      color: color,
    );
  }

  /// Message d'erreur
  static Widget errorMessage({
    required String message,
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Get.theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Get.theme.textTheme.bodyMedium?.color,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            customButton(
              text: 'Réessayer',
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }

  /// Barre de progression
  static Widget progressBar({
    required double value,
    double height = 8,
    Color? backgroundColor,
    Color? progressColor,
    BorderRadius? borderRadius,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? Get.theme.dividerColor,
        borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: progressColor ?? Get.theme.primaryColor,
            borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }

  /// Badge avec notification
  static Widget badge({
    required Widget child,
    String? count,
    Color? badgeColor,
    double size = 20,
  }) {
    return Stack(
      children: [
        child,
        if (count != null)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: badgeColor ?? Get.theme.colorScheme.error,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  count,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Affiche un snackbar de manière sécurisée (vérifie la disponibilité de l'Overlay)
  static void showSafeSnackbar({
    required String message,
    String? title,
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 3),
    SnackPosition snackPosition = SnackPosition.TOP,
  }) {
    try {
      // Vérifier que le contexte est disponible
      if (Get.context == null) {
        print('⚠️ Contexte non disponible pour le snackbar: $message');
        return;
      }

      // Vérifier que l'Overlay est disponible
      try {
        Overlay.of(Get.context!);
      } catch (e) {
        print('⚠️ Overlay non disponible pour le snackbar: $message');
        return;
      }

      // Vérifier qu'il n'y a pas déjà un dialog ou snackbar ouvert
      final isDialogOpen = Get.isDialogOpen ?? false;
      final isSnackbarOpen = Get.isSnackbarOpen ?? false;
      
      if (isDialogOpen || isSnackbarOpen) {
        // Attendre un peu et réessayer
        Future.delayed(const Duration(milliseconds: 500), () {
          showSafeSnackbar(
            message: message,
            title: title,
            backgroundColor: backgroundColor,
            textColor: textColor,
            duration: duration,
            snackPosition: snackPosition,
          );
        });
        return;
      }

      // Afficher le snackbar
      Get.snackbar(
        title ?? '',
        message,
        backgroundColor: backgroundColor ?? AppTheme.errorColor,
        colorText: textColor ?? Colors.white,
        snackPosition: snackPosition,
        duration: duration,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );
    } catch (e) {
      // Si l'Overlay n'est pas disponible, utiliser un simple print
      print('❌ Erreur lors de l\'affichage du snackbar: $message');
      print('   Erreur: $e');
    }
  }
} 