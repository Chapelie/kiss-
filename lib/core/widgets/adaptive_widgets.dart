import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../utils/platform_utils.dart';
import '../theme/app_theme.dart';

/// Widgets adaptatifs qui utilisent Cupertino pour iOS et Material pour Android
class AdaptiveWidgets {
  /// Bouton adaptatif (CupertinoButton pour iOS, ElevatedButton pour Android)
  static Widget adaptiveButton({
    required String text,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? textColor,
    double? width,
    double height = 50,
    bool isLoading = false,
    EdgeInsetsGeometry? padding,
  }) {
    if (PlatformUtils.isIOS) {
      return SizedBox(
        width: width,
        height: height,
        child: CupertinoButton(
          onPressed: isLoading ? null : onPressed,
          color: backgroundColor ?? CupertinoColors.activeBlue,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
          borderRadius: BorderRadius.circular(12),
          child: isLoading
              ? const CupertinoActivityIndicator(color: CupertinoColors.white)
              : Text(
                  text,
                  style: TextStyle(
                    color: textColor ?? CupertinoColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      );
    } else {
      return SizedBox(
        width: width,
        height: height,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? Get.theme.primaryColor,
            foregroundColor: textColor ?? Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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
  }
  
  /// Champ de texte adaptatif
  static Widget adaptiveTextField({
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
    if (PlatformUtils.isIOS) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: CupertinoTextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          enabled: enabled,
          onChanged: onChanged,
          textInputAction: textInputAction,
          placeholder: hint ?? label,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CupertinoColors.separator,
              width: 0.5,
            ),
          ),
          prefix: prefixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: prefixIcon,
                )
              : null,
          suffix: suffixIcon,
        ),
      );
    } else {
      return TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        enabled: enabled,
        onChanged: onChanged,
        textInputAction: textInputAction,
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
  }
  
  /// AppBar adaptative
  static PreferredSizeWidget adaptiveAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
  }) {
    if (PlatformUtils.isIOS) {
      return CupertinoNavigationBar(
        middle: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: actions != null && actions.isNotEmpty
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: actions,
              )
            : null,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
      );
    } else {
      return AppBar(
        title: Text(title),
        actions: actions,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        elevation: 0,
      );
    }
  }
  
  /// Scaffold adaptatif
  static Widget adaptiveScaffold({
    required PreferredSizeWidget appBar,
    required Widget body,
    Widget? floatingActionButton,
    Widget? bottomNavigationBar,
    Widget? drawer,
    Color? backgroundColor,
    bool resizeToAvoidBottomInset = true,
  }) {
    if (PlatformUtils.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: appBar as CupertinoNavigationBar,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(child: body),
              if (bottomNavigationBar != null) bottomNavigationBar,
            ],
          ),
        ),
        backgroundColor: backgroundColor ?? CupertinoColors.systemBackground,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      );
    } else {
      return Scaffold(
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
        drawer: drawer,
        backgroundColor: backgroundColor,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      );
    }
  }
  
  /// Carte adaptative
  static Widget adaptiveCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? backgroundColor,
    VoidCallback? onTap,
  }) {
    if (PlatformUtils.isIOS) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          margin: margin ?? const EdgeInsets.all(8),
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor ?? CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CupertinoColors.separator,
              width: 0.5,
            ),
          ),
          child: child,
        ),
      );
    } else {
      return Container(
        margin: margin ?? const EdgeInsets.all(8),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: backgroundColor,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      );
    }
  }
  
  /// Indicateur de chargement adaptatif
  static Widget adaptiveLoadingIndicator({
    String? message,
    Color? color,
  }) {
    if (PlatformUtils.isIOS) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CupertinoActivityIndicator(radius: 16),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.label,
                ),
              ),
            ],
          ],
        ),
      );
    } else {
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
  }
  
  /// Dialog adaptatif
  static Future<T?> showAdaptiveDialog<T>({
    required BuildContext context,
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) {
    if (PlatformUtils.isIOS) {
      return showCupertinoDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            if (cancelText != null)
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.of(context).pop();
                  onCancel?.call();
                },
                child: Text(cancelText),
              ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm?.call();
              },
              child: Text(confirmText ?? 'OK'),
            ),
          ],
        ),
      );
    } else {
      return showDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            if (cancelText != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onCancel?.call();
                },
                child: Text(cancelText),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm?.call();
              },
              child: Text(confirmText ?? 'OK'),
            ),
          ],
        ),
      );
    }
  }
  
  /// Bottom Navigation Bar adaptatif
  static Widget adaptiveBottomNavigationBar({
    required int currentIndex,
    required ValueChanged<int> onTap,
    required List<AdaptiveBottomNavigationBarItem> items,
  }) {
    if (PlatformUtils.isIOS) {
      return CupertinoTabBar(
        currentIndex: currentIndex,
        onTap: onTap,
        items: items.map((item) => BottomNavigationBarItem(
          icon: item.icon,
          activeIcon: item.activeIcon,
          label: item.label,
        )).toList(),
        backgroundColor: CupertinoColors.systemBackground,
        activeColor: CupertinoColors.activeBlue,
        inactiveColor: CupertinoColors.inactiveGray,
      );
    } else {
      return BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        items: items.map((item) => BottomNavigationBarItem(
          icon: item.icon,
          activeIcon: item.activeIcon,
          label: item.label,
        )).toList(),
      );
    }
  }
  
  /// Switch adaptatif
  static Widget adaptiveSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? activeColor,
  }) {
    if (PlatformUtils.isIOS) {
      return CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor ?? CupertinoColors.activeGreen,
      );
    } else {
      return Switch(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor,
      );
    }
  }
  
  /// ListTile adaptatif
  static Widget adaptiveListTile({
    required Widget title,
    Widget? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    if (PlatformUtils.isIOS) {
      return GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            border: Border(
              bottom: BorderSide(
                color: CupertinoColors.separator,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading,
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTextStyle(
                      style: TextStyle(
                        fontSize: 17,
                        color: enabled
                            ? CupertinoColors.label
                            : CupertinoColors.quaternaryLabel,
                      ),
                      child: title,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      DefaultTextStyle(
                        style: TextStyle(
                          fontSize: 15,
                          color: enabled
                              ? CupertinoColors.secondaryLabel
                              : CupertinoColors.quaternaryLabel,
                        ),
                        child: subtitle,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 16),
                trailing,
              ],
            ],
          ),
        ),
      );
    } else {
      return ListTile(
        title: title,
        subtitle: subtitle,
        leading: leading,
        trailing: trailing,
        onTap: enabled ? onTap : null,
        enabled: enabled,
      );
    }
  }
  
  /// Avatar adaptatif
  static Widget adaptiveAvatar({
    String? imageUrl,
    String? initials,
    double size = 50,
    Color? backgroundColor,
    Color? textColor,
  }) {
    if (PlatformUtils.isIOS) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor ?? CupertinoColors.activeBlue,
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
                    color: textColor ?? CupertinoColors.white,
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      );
    } else {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: backgroundColor ?? Get.theme.primaryColor,
        backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
        child: imageUrl == null && initials != null
            ? Text(
                initials.toUpperCase(),
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      );
    }
  }
  
  /// Snackbar adaptatif
  static void showAdaptiveSnackbar({
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
    Color? textColor,
  }) {
    if (PlatformUtils.isIOS) {
      Get.snackbar(
        title ?? '',
        message,
        snackPosition: SnackPosition.TOP,
        duration: duration,
        backgroundColor: backgroundColor ?? CupertinoColors.systemGrey6,
        colorText: textColor ?? CupertinoColors.label,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );
    } else {
      Get.snackbar(
        title ?? '',
        message,
        snackPosition: SnackPosition.BOTTOM,
        duration: duration,
        backgroundColor: backgroundColor ?? Get.theme.snackBarTheme.backgroundColor,
        colorText: textColor ?? Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );
    }
  }
}

/// Item pour la Bottom Navigation Bar adaptative
class AdaptiveBottomNavigationBarItem {
  final Widget icon;
  final Widget? activeIcon;
  final String label;
  
  AdaptiveBottomNavigationBarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

