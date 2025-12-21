import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/theme/app_theme.dart';

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

  // Données fictives pour les tests
  final Map<String, String> _testUsers = {
    'admin@kisse.com': 'password123',
    'user@kisse.com': 'password123',
    'test@kisse.com': 'password123',
  };

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

    // Simulation d'un délai de connexion
    await Future.delayed(const Duration(seconds: 2));

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Vérification avec les données fictives
    if (_testUsers.containsKey(email) && _testUsers[email] == password) {
      // Connexion réussie
      Get.snackbar(
        'Connexion réussie',
        'Bienvenue sur Kisse !',
        backgroundColor: AppTheme.successColor,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      
      // Navigation vers la page principale
      Get.offAllNamed('/home');
    } else {
      // Échec de connexion
      Get.snackbar(
        'Erreur de connexion',
        'Email ou mot de passe incorrect',
        backgroundColor: AppTheme.errorColor,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
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
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Kisse',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppTheme.primaryColor,
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
                    Get.snackbar(
                      'Fonctionnalité',
                      'Récupération de mot de passe à implémenter',
                      snackPosition: SnackPosition.TOP,
                    );
                  },
                  child: const Text('Mot de passe oublié ?'),
                ),
                
                const SizedBox(height: 40),
                
                // Comptes de test
                CommonWidgets.customCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comptes de test :',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ..._testUsers.entries.map((entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${entry.key} / ${entry.value}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                _emailController.text = entry.key;
                                _passwordController.text = entry.value;
                              },
                              child: const Text('Utiliser'),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
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
                        Get.snackbar(
                          'Fonctionnalité',
                          'Inscription à implémenter',
                          snackPosition: SnackPosition.TOP,
                        );
                      },
                      child: const Text('S\'inscrire'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 