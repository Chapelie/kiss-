import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Widgets communs réutilisables pour l'application Kisse
class CommonWidgets {
  /// Bouton personnalisé avec style cohérent
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
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Get.theme.primaryColor,
          foregroundColor: textColor ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  /// Champ de texte personnalisé
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
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Get.theme.primaryColor,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Get.theme.cardColor,
      ),
    );
  }

  /// Carte personnalisée avec ombre
  static Widget customCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    double elevation = 4,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.all(8),
      child: Card(
        elevation: elevation,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
        color: backgroundColor,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }

  /// Avatar circulaire avec image ou initiales
  static Widget avatar({
    String? imageUrl,
    String? initials,
    double size = 50,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? Get.theme.primaryColor,
        image: imageUrl != null
            ? DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: imageUrl == null && initials != null
          ? Center(
              child: Text(
                initials.toUpperCase(),
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  /// Indicateur de chargement
  static Widget loadingIndicator({
    String? message,
    Color? color,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? Get.theme.primaryColor,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Get.theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ],
      ),
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
} 