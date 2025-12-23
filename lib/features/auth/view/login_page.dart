import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/adaptive_widgets.dart';
import '../../../core/utils/platform_utils.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/controllers/app_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      // Connexion via l'API
      final success = await AppController.to.login(email, password);
      
      if (success) {
        // Navigation vers la page principale
        Get.offAllNamed('/home');
        
        // Ne pas afficher de snackbar après navigation pour éviter l'erreur Overlay
        // La navigation elle-même indique le succès
      } else {
        // Échec de connexion
        if (mounted) {
          _showError('Email ou mot de passe incorrect');
        }
      }
    } catch (e) {
      // Gérer les erreurs de connexion
      if (mounted) {
        String errorMessage = 'Erreur de connexion';
        final errorStr = e.toString();
        
        if (errorStr.contains('Connection refused') || 
            errorStr.contains('SocketException') ||
            errorStr.contains('Failed host lookup')) {
          errorMessage = 'Impossible de se connecter au serveur.\nVérifiez que le backend est démarré sur http://10.0.2.2:8080';
        } else if (errorStr.contains('timeout') || errorStr.contains('TimeoutException')) {
          errorMessage = 'Délai d\'attente dépassé.\nVérifiez votre connexion réseau.';
        } else if (errorStr.contains('401') || errorStr.contains('UNAUTHORIZED')) {
          errorMessage = 'Email ou mot de passe incorrect';
        } else if (errorStr.contains('500') || errorStr.contains('INTERNAL_SERVER_ERROR')) {
          errorMessage = 'Erreur serveur.\nVeuillez réessayer plus tard.';
        } else if (errorStr.contains('Network')) {
          errorMessage = 'Erreur réseau.\nVérifiez votre connexion internet.';
        }
        
        print('❌ Erreur de connexion: $e');
        _showError(errorMessage);
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AdaptiveWidgets.adaptiveAppBar(
      title: 'Connexion',
      automaticallyImplyLeading: false,
    );
    
    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                const SizedBox(height: 60),
                
                // Logo et titre
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: PlatformUtils.isIOS 
                              ? CupertinoColors.activeBlue 
                              : AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          PlatformUtils.isIOS 
                              ? CupertinoIcons.chat_bubble_2_fill
                              : Icons.chat_bubble_outline,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Kisse',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: PlatformUtils.isIOS 
                              ? CupertinoColors.activeBlue 
                              : AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Messagerie sécurisée',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // Formulaire de connexion
                CommonWidgets.customTextField(
                  label: 'Email',
                  hint: 'Entrez votre email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
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
                
                CommonWidgets.customTextField(
                  label: 'Mot de passe',
                  hint: 'Entrez votre mot de passe',
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre mot de passe';
                    }
                    if (value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Bouton de connexion
                CommonWidgets.customButton(
                  text: 'Se connecter',
                  onPressed: _handleLogin,
                  isLoading: _isLoading,
                ),
                
                const SizedBox(height: 16),
                
                  // Lien "Mot de passe oublié"
                TextButton(
                  onPressed: () {
                    _showInfo('Récupération de mot de passe à implémenter');
                  },
                  child: const Text('Mot de passe oublié ?'),
                ),
                
                const SizedBox(height: 24),
                
                // Lien d'inscription
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Pas encore de compte ? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Get.toNamed('/register');
                      },
                      child: const Text('S\'inscrire'),
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
  
  /// Affiche un message d'erreur de manière sécurisée
  void _showError(String message) {
    if (!mounted) return;
    
    // Utiliser un délai pour s'assurer que le contexte est disponible
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      CommonWidgets.showSafeSnackbar(
        title: 'Erreur',
        message: message,
        backgroundColor: AppTheme.errorColor,
        textColor: Colors.white,
        duration: const Duration(seconds: 4),
      );
    });
  }
  
  /// Affiche un message d'information de manière sécurisée
  void _showInfo(String message) {
    if (!mounted) return;
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      CommonWidgets.showSafeSnackbar(
        title: 'Information',
        message: message,
        backgroundColor: AppTheme.primaryColor,
        textColor: Colors.white,
        duration: const Duration(seconds: 3),
      );
    });
  }
} 