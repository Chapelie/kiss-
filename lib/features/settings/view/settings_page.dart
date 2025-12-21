import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/common_widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _biometricEnabled = true;
  bool _twoFactorEnabled = false;
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _readReceipts = true;
  bool _typingIndicator = true;
  bool _onlineStatus = true;
  bool _darkMode = false;
  bool _autoBackup = true;
  bool _dataSaver = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(),
            const SizedBox(height: 24),
            _buildSecuritySection(),
            const SizedBox(height: 24),
            _buildNotificationsSection(),
            const SizedBox(height: 24),
            _buildPrivacySection(),
            const SizedBox(height: 24),
            _buildAppearanceSection(),
            const SizedBox(height: 24),
            _buildDataStorageSection(),
            const SizedBox(height: 24),
            _buildAboutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return CommonWidgets.customCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profil',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CommonWidgets.avatar(
                initials: 'JD',
                size: 60,
                backgroundColor: Get.theme.primaryColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'John Doe',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text(
                      'john.doe@kisse.com',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const Text(
                      'En ligne',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Get.snackbar(
                    'Modifier le profil',
                    'Fonctionnalité à implémenter',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return CommonWidgets.customCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sécurité',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingTile(
            icon: Icons.fingerprint,
            title: 'Authentification biométrique',
            subtitle: 'Utiliser l\'empreinte digitale ou Face ID',
            trailing: Switch(
              value: _biometricEnabled,
              onChanged: (value) {
                setState(() {
                  _biometricEnabled = value;
                });
              },
            ),
          ),
          _buildSettingTile(
            icon: Icons.security,
            title: 'Authentification à deux facteurs',
            subtitle: 'Ajouter une couche de sécurité supplémentaire',
            trailing: Switch(
              value: _twoFactorEnabled,
              onChanged: (value) {
                setState(() {
                  _twoFactorEnabled = value;
                });
              },
            ),
          ),
          _buildSettingTile(
            icon: Icons.lock,
            title: 'Changer le mot de passe',
            subtitle: 'Modifier votre mot de passe actuel',
            onTap: () {
              Get.snackbar(
                'Changer le mot de passe',
                'Fonctionnalité à implémenter',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return CommonWidgets.customCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingTile(
            icon: Icons.notifications,
            title: 'Notifications push',
            subtitle: 'Recevoir des notifications sur votre appareil',
            trailing: Switch(
              value: _pushNotifications,
              onChanged: (value) {
                setState(() {
                  _pushNotifications = value;
                });
              },
            ),
          ),
          _buildSettingTile(
            icon: Icons.email,
            title: 'Notifications par email',
            subtitle: 'Recevoir des notifications par email',
            trailing: Switch(
              value: _emailNotifications,
              onChanged: (value) {
                setState(() {
                  _emailNotifications = value;
                });
              },
            ),
          ),
          _buildSettingTile(
            icon: Icons.volume_up,
            title: 'Son',
            subtitle: 'Activer les sons de notification',
            trailing: Switch(
              value: _soundEnabled,
              onChanged: (value) {
                setState(() {
                  _soundEnabled = value;
                });
              },
            ),
          ),
          _buildSettingTile(
            icon: Icons.vibration,
            title: 'Vibration',
            subtitle: 'Activer les vibrations de notification',
            trailing: Switch(
              value: _vibrationEnabled,
              onChanged: (value) {
                setState(() {
                  _vibrationEnabled = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection() {
    return CommonWidgets.customCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Confidentialité',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingTile(
            icon: Icons.done_all,
            title: 'Accusés de réception',
            subtitle: 'Afficher les accusés de réception',
            trailing: Switch(
              value: _readReceipts,
              onChanged: (value) {
                setState(() {
                  _readReceipts = value;
                });
              },
            ),
          ),
          _buildSettingTile(
            icon: Icons.keyboard,
            title: 'Indicateur de frappe',
            subtitle: 'Afficher quand quelqu\'un tape',
            trailing: Switch(
              value: _typingIndicator,
              onChanged: (value) {
                setState(() {
                  _typingIndicator = value;
                });
              },
            ),
          ),
          _buildSettingTile(
            icon: Icons.circle,
            title: 'Statut en ligne',
            subtitle: 'Afficher votre statut en ligne',
            trailing: Switch(
              value: _onlineStatus,
              onChanged: (value) {
                setState(() {
                  _onlineStatus = value;
                });
              },
            ),
          ),
          _buildSettingTile(
            icon: Icons.block,
            title: 'Utilisateurs bloqués',
            subtitle: 'Gérer les utilisateurs bloqués',
            onTap: () {
              Get.snackbar(
                'Utilisateurs bloqués',
                'Fonctionnalité à implémenter',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return CommonWidgets.customCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Apparence',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingTile(
            icon: Icons.dark_mode,
            title: 'Mode sombre',
            subtitle: 'Activer le thème sombre',
            trailing: Switch(
              value: _darkMode,
              onChanged: (value) {
                setState(() {
                  _darkMode = value;
                });
                Get.changeThemeMode(
                  value ? ThemeMode.dark : ThemeMode.light,
                );
              },
            ),
          ),
          _buildSettingTile(
            icon: Icons.color_lens,
            title: 'Couleur du thème',
            subtitle: 'Personnaliser la couleur principale',
            onTap: () {
              Get.snackbar(
                'Couleur du thème',
                'Fonctionnalité à implémenter',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDataStorageSection() {
    return CommonWidgets.customCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Données & Stockage',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingTile(
            icon: Icons.backup,
            title: 'Sauvegarde automatique',
            subtitle: 'Sauvegarder automatiquement vos données',
            trailing: Switch(
              value: _autoBackup,
              onChanged: (value) {
                setState(() {
                  _autoBackup = value;
                });
              },
            ),
          ),
          _buildSettingTile(
            icon: Icons.data_saver_off,
            title: 'Économiseur de données',
            subtitle: 'Réduire l\'utilisation des données',
            trailing: Switch(
              value: _dataSaver,
              onChanged: (value) {
                setState(() {
                  _dataSaver = value;
                });
              },
            ),
          ),
          _buildSettingTile(
            icon: Icons.storage,
            title: 'Espace de stockage',
            subtitle: 'Gérer l\'espace utilisé par l\'application',
            onTap: () {
              Get.snackbar(
                'Espace de stockage',
                'Fonctionnalité à implémenter',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
          _buildSettingTile(
            icon: Icons.delete_forever,
            title: 'Supprimer les données',
            subtitle: 'Supprimer toutes les données de l\'application',
            onTap: () {
              _showDeleteDataDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return CommonWidgets.customCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'À propos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingTile(
            icon: Icons.info,
            title: 'Version',
            subtitle: '1.0.0',
            onTap: null,
          ),
          _buildSettingTile(
            icon: Icons.description,
            title: 'Conditions d\'utilisation',
            subtitle: 'Lire les conditions d\'utilisation',
            onTap: () {
              Get.snackbar(
                'Conditions d\'utilisation',
                'Fonctionnalité à implémenter',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
          _buildSettingTile(
            icon: Icons.privacy_tip,
            title: 'Politique de confidentialité',
            subtitle: 'Lire la politique de confidentialité',
            onTap: () {
              Get.snackbar(
                'Politique de confidentialité',
                'Fonctionnalité à implémenter',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
          _buildSettingTile(
            icon: Icons.help,
            title: 'Aide & Support',
            subtitle: 'Obtenir de l\'aide',
            onTap: () {
              Get.snackbar(
                'Aide & Support',
                'Fonctionnalité à implémenter',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Get.theme.primaryColor,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _showDeleteDataDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Supprimer les données'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer toutes les données de l\'application ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Données supprimées',
                'Toutes les données ont été supprimées',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            },
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
} 