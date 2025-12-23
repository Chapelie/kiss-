import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/common_widgets.dart';
import 'core/widgets/adaptive_widgets.dart';
import 'core/utils/platform_utils.dart';
import 'features/auth/view/login_page.dart';
import 'features/auth/view/register_page.dart';
import 'features/chat/view/chat_list_page.dart';
import 'features/chat/view/chat_page.dart';
import 'features/calls/view/calls_page.dart';
import 'features/stories/view/stories_page.dart';
import 'features/settings/view/settings_page.dart';
import 'features/contacts/view/contacts_page.dart';
import 'core/controllers/app_controller.dart';
import 'core/services/agora_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser GetX
  await Get.putAsync(() async {
    return AppController();
  });
  
  // Initialiser AgoraService
  Get.put(AgoraService.instance);
  
  runApp(const KisseApp());
}

class KisseApp extends StatelessWidget {
  const KisseApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Utiliser CupertinoApp pour iOS et MaterialApp pour Android
    if (PlatformUtils.isIOS) {
      return GetMaterialApp(
        title: 'Kisse - Messagerie Sécurisée',
        debugShowCheckedModeBanner: false,
        navigatorKey: Get.key,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashPage(),
        getPages: [
          GetPage(name: '/splash', page: () => const SplashPage()),
          GetPage(name: '/login', page: () => const LoginPage()),
          GetPage(name: '/register', page: () => const RegisterPage()),
          GetPage(name: '/home', page: () => const HomePage()),
          GetPage(name: '/chat/:id', page: () => ChatPage(
            chatId: Get.parameters['id'] ?? '',
            conversation: Get.arguments,
          )),
          GetPage(name: '/stories', page: () => const StoriesPage()),
          GetPage(name: '/settings', page: () => const SettingsPage()),
          GetPage(name: '/contacts', page: () => const ContactsPage()),
        ],
        builder: (context, child) {
          return CupertinoTheme(
            data: const CupertinoThemeData(
              primaryColor: CupertinoColors.activeBlue,
              brightness: Brightness.light,
            ),
            child: child!,
          );
        },
      );
    } else {
      return GetMaterialApp(
        title: 'Kisse - Messagerie Sécurisée',
        debugShowCheckedModeBanner: false,
        navigatorKey: Get.key,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashPage(),
        getPages: [
          GetPage(name: '/splash', page: () => const SplashPage()),
          GetPage(name: '/login', page: () => const LoginPage()),
          GetPage(name: '/register', page: () => const RegisterPage()),
          GetPage(name: '/home', page: () => const HomePage()),
          GetPage(name: '/chat/:id', page: () => ChatPage(
            chatId: Get.parameters['id'] ?? '',
            conversation: Get.arguments,
          )),
          GetPage(name: '/stories', page: () => const StoriesPage()),
          GetPage(name: '/settings', page: () => const SettingsPage()),
          GetPage(name: '/contacts', page: () => const ContactsPage()),
        ],
      );
    }
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.forward();
    
    // Attendre l'initialisation et naviguer
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    // Attendre 3 secondes pour l'animation
    await Future.delayed(const Duration(seconds: 3));
    
    // Vérifier l'état de l'application
    final appController = AppController.to;
    
    if (appController.isAuthenticated && appController.isInitialized) {
      Get.offAllNamed('/home');
    } else if (appController.isAuthenticated) {
      // Attendre l'initialisation complète
      await Future.delayed(const Duration(seconds: 2));
      if (appController.isInitialized) {
        Get.offAllNamed('/home');
      } else {
        Get.offAllNamed('/login');
      }
    } else {
      Get.offAllNamed('/login');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo de l'application
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.security,
                        size: 60,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Nom de l'application
                    Text(
                      'Kisse',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // Sous-titre
                    Text(
                      'Messagerie Sécurisée',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    
                    const SizedBox(height: 50),
                    
                    // Indicateur de chargement
                    Obx(() {
                      final appController = AppController.to;
                      return Column(
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            appController.appStatus,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Page d'accueil avec navigation
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const ChatListPage(),
    const StoriesPage(),
    const ContactsPage(),
    const CallsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomNavBar = AdaptiveWidgets.adaptiveBottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      items: [
        AdaptiveBottomNavigationBarItem(
          icon: Icon(PlatformUtils.isIOS 
              ? CupertinoIcons.chat_bubble 
              : Icons.chat_bubble_outline),
          activeIcon: Icon(PlatformUtils.isIOS 
              ? CupertinoIcons.chat_bubble_fill 
              : Icons.chat_bubble),
          label: 'Chats',
        ),
        AdaptiveBottomNavigationBarItem(
          icon: Icon(PlatformUtils.isIOS 
              ? CupertinoIcons.book 
              : Icons.auto_stories_outlined),
          activeIcon: Icon(PlatformUtils.isIOS 
              ? CupertinoIcons.book_fill 
              : Icons.auto_stories),
          label: 'Stories',
        ),
        AdaptiveBottomNavigationBarItem(
          icon: Icon(PlatformUtils.isIOS 
              ? CupertinoIcons.person_2 
              : Icons.people_outline),
          activeIcon: Icon(PlatformUtils.isIOS 
              ? CupertinoIcons.person_2_fill 
              : Icons.people),
          label: 'Contacts',
        ),
        AdaptiveBottomNavigationBarItem(
          icon: Icon(PlatformUtils.isIOS 
              ? CupertinoIcons.phone 
              : Icons.call_outlined),
          activeIcon: Icon(PlatformUtils.isIOS 
              ? CupertinoIcons.phone_fill 
              : Icons.call),
          label: 'Appels',
        ),
        AdaptiveBottomNavigationBarItem(
          icon: Icon(PlatformUtils.isIOS 
              ? CupertinoIcons.person 
              : Icons.person_outline),
          activeIcon: Icon(PlatformUtils.isIOS 
              ? CupertinoIcons.person_fill 
              : Icons.person),
          label: 'Profil',
        ),
      ],
    );
    
    if (PlatformUtils.isIOS) {
      return CupertinoPageScaffold(
        child: Column(
          children: [
            Expanded(child: _pages[_currentIndex]),
            bottomNavBar,
          ],
        ),
      );
    } else {
      return Scaffold(
        body: _pages[_currentIndex],
        bottomNavigationBar: bottomNavBar,
      );
    }
  }
}

// Page de profil temporaire
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AppController.to.logout();
              Get.offAllNamed('/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Statut de connexion
            Obx(() {
              final appController = AppController.to;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: appController.websocketReady 
                      ? AppTheme.successColor.withOpacity(0.1) 
                      : AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      appController.websocketReady ? Icons.wifi : Icons.wifi_off,
                      color: appController.websocketReady ? AppTheme.successColor : AppTheme.errorColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      appController.websocketReady ? 'Connecté' : 'Déconnecté',
                      style: TextStyle(
                        color: appController.websocketReady ? AppTheme.successColor : AppTheme.errorColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (appController.signalReady)
                      const Icon(Icons.security, color: AppTheme.successColor),
                  ],
                ),
              );
            }),
            
            const SizedBox(height: 24),
            
            // Informations du profil
            CommonWidgets.customCard(
              child: Column(
                children: [
                  CommonWidgets.avatar(
                    imageUrl: null,
                    initials: 'U',
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Utilisateur Test',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'test@kisse.com',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Actions rapides
            Row(
              children: [
                Expanded(
                  child: CommonWidgets.customButton(
                    text: 'Paramètres',
                    onPressed: () => Get.toNamed('/settings'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CommonWidgets.customButton(
                    text: 'Contacts',
                    onPressed: () => Get.toNamed('/contacts'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Boutons de test
            CommonWidgets.customButton(
              text: 'Tester l\'envoi de message',
              onPressed: () {
                AppController.to.sendMessage('test_user', 'Message de test');
                Get.snackbar(
                  'Test',
                  'Message envoyé',
                  snackPosition: SnackPosition.TOP,
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            CommonWidgets.customButton(
              text: 'Tester un appel',
              onPressed: () {
                AppController.to.startCall('test_user', 'audio');
                Get.snackbar(
                  'Test',
                  'Appel initié',
                  snackPosition: SnackPosition.TOP,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
