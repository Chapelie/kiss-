import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/adaptive_widgets.dart';
import '../../../core/utils/platform_utils.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/controllers/app_controller.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim().isEmpty 
        ? null 
        : _nameController.text.trim();

    try {
      final success = await AppController.to.register(
        email,
        username,
        password,
        name: name,
      );

      if (success) {
        // Navigation vers la page principale
        Get.offAllNamed('/home');

        // Afficher le snackbar après la navigation
        Future.delayed(const Duration(milliseconds: 500), () {
          if (Get.isDialogOpen == false) {
            Get.snackbar(
              'Inscription réussie',
              'Bienvenue sur Kisse !',
              backgroundColor: AppTheme.successColor,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
              duration: const Duration(seconds: 2),
            );
          }
        });
      } else {
        if (mounted && Get.context != null) {
          Get.snackbar(
            'Erreur d\'inscription',
            'Impossible de créer le compte. Vérifiez vos informations.',
            backgroundColor: AppTheme.errorColor,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 3),
          );
        }
      }
    } catch (e) {
      if (mounted && Get.context != null) {
        String errorMessage = 'Une erreur est survenue';
        
        if (e.toString().contains('409') || e.toString().contains('existe déjà')) {
          errorMessage = 'Un compte avec cet email existe déjà';
        } else if (e.toString().contains('Connection refused') || e.toString().contains('SocketException')) {
          errorMessage = 'Impossible de se connecter au serveur. Vérifiez que le backend est démarré.';
        } else if (e.toString().contains('400') || e.toString().contains('Bad Request')) {
          errorMessage = 'Vérifiez que votre email est valide et que le mot de passe contient au moins 8 caractères';
        } else {
          errorMessage = 'Erreur: ${e.toString()}';
        }

        Get.snackbar(
          'Erreur',
          errorMessage,
          backgroundColor: AppTheme.errorColor,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AdaptiveWidgets.adaptiveAppBar(
      title: 'Inscription',
      automaticallyImplyLeading: true,
    );

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),

            // Logo et titre
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: PlatformUtils.isIOS
                          ? CupertinoColors.activeBlue
                          : AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PlatformUtils.isIOS
                          ? CupertinoIcons.person_add_solid
                          : Icons.person_add_outlined,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Créer un compte',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: PlatformUtils.isIOS
                              ? CupertinoColors.activeBlue
                              : AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rejoignez Kisse pour commencer',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Champ nom (optionnel)
            CommonWidgets.customTextField(
              label: 'Nom (optionnel)',
              hint: 'Votre nom',
              controller: _nameController,
              prefixIcon: const Icon(Icons.person_outline),
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 16),

            // Champ username
            CommonWidgets.customTextField(
              label: 'Nom d\'utilisateur',
              hint: 'nom_utilisateur',
              controller: _usernameController,
              keyboardType: TextInputType.text,
              prefixIcon: const Icon(Icons.person_outline),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un nom d\'utilisateur';
                }
                if (value.length < 3) {
                  return 'Le nom d\'utilisateur doit contenir au moins 3 caractères';
                }
                if (value.length > 50) {
                  return 'Le nom d\'utilisateur ne peut pas dépasser 50 caractères';
                }
                // Vérifier que le username ne contient que des caractères alphanumériques et underscore
                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                  return 'Le nom d\'utilisateur ne peut contenir que des lettres, chiffres et underscore';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Champ email
            CommonWidgets.customTextField(
              label: 'Email',
              hint: 'votre@email.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre email';
                }
                if (!GetUtils.isEmail(value)) {
                  return 'Veuillez entrer un email valide';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Champ mot de passe
            CommonWidgets.customTextField(
              label: 'Mot de passe',
              hint: 'Au moins 8 caractères',
              controller: _passwordController,
              obscureText: _obscurePassword,
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un mot de passe';
                }
                if (value.length < 8) {
                  return 'Le mot de passe doit contenir au moins 8 caractères';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Champ confirmation mot de passe
            CommonWidgets.customTextField(
              label: 'Confirmer le mot de passe',
              hint: 'Répétez votre mot de passe',
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez confirmer votre mot de passe';
                }
                if (value != _passwordController.text) {
                  return 'Les mots de passe ne correspondent pas';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Bouton d'inscription
            CommonWidgets.customButton(
              text: 'S\'inscrire',
              onPressed: _handleRegister,
              isLoading: _isLoading,
            ),

            const SizedBox(height: 24),

            // Lien de connexion
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Déjà un compte ? ',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                TextButton(
                  onPressed: () {
                    Get.back();
                  },
                  child: const Text('Se connecter'),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return AdaptiveWidgets.adaptiveScaffold(
      appBar: appBar,
      body: SafeArea(child: content),
      backgroundColor: PlatformUtils.isIOS
          ? CupertinoColors.systemBackground
          : AppTheme.backgroundColor,
    );
  }
}

