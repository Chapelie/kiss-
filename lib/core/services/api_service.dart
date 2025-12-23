import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

/// Service API pour communiquer avec le backend Rust
/// 
/// Ce service gère toutes les requêtes HTTP vers le backend.
/// Le backend est une passerelle aveugle - il ne peut pas lire le contenu chiffré.
class ApiService {
  static ApiService? _instance;
  static ApiService get instance => _instance ??= ApiService._();
  
  ApiService._();
  
  final Dio _dio = Dio();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  /// Initialise le service API
  void initialize() {
    _dio.options.baseUrl = AppConstants.apiUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    // Ne pas lancer d'exception pour les codes < 500 - on les gère manuellement
    _dio.options.validateStatus = (status) => status != null && status < 500;
    
    // Intercepteur pour ajouter le token d'authentification
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _secureStorage.read(key: AppConstants.keyAuthToken);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Token expiré ou invalide
          _secureStorage.delete(key: AppConstants.keyAuthToken);
        }
        handler.next(error);
      },
    ));
  }
  
  /// Authentification - Inscription
  Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String password,
    String? name,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'email': email,
          'username': username,
          'password': password,
          'name': name,
        },
        options: Options(
          validateStatus: (status) => status != null && status < 500, // Accepter les codes d'erreur comme réponse valide
        ),
      );
      
      // Vérifier le code de statut
      if (response.statusCode == 409) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'Un compte avec cet email ou ce nom d\'utilisateur existe déjà',
        );
      }
      
      if (response.statusCode != null && response.statusCode! >= 400) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'Erreur lors de l\'inscription',
        );
      }
      
      // Sauvegarder le token
      if (response.data != null && response.data['token'] != null) {
        await _secureStorage.write(
          key: AppConstants.keyAuthToken,
          value: response.data['token'],
        );
      }
      
      // Sauvegarder l'ID utilisateur
      if (response.data != null && response.data['user'] != null && response.data['user']['id'] != null) {
        await _secureStorage.write(
          key: AppConstants.keyUserId,
          value: response.data['user']['id'].toString(),
        );
      }
      
      return response.data ?? {};
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          type: DioExceptionType.badResponse,
          message: 'Un compte avec cet email ou ce nom d\'utilisateur existe déjà',
        );
      }
      print('❌ Erreur lors de l\'inscription: $e');
      rethrow;
    } catch (e) {
      print('❌ Erreur lors de l\'inscription: $e');
      rethrow;
    }
  }
  
  /// Authentification - Connexion
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      
      // Vérifier que response.data est bien une Map
      Map<String, dynamic> responseData;
      if (response.data == null) {
        responseData = {};
      } else if (response.data is Map<String, dynamic>) {
        responseData = response.data as Map<String, dynamic>;
      } else if (response.data is Map) {
        // Convertir une Map non typée en Map<String, dynamic>
        try {
          responseData = Map<String, dynamic>.from(response.data);
        } catch (e) {
          print('⚠️ Erreur lors de la conversion de response.data: $e');
          responseData = {};
        }
      } else if (response.data is String) {
        // Si c'est une String, essayer de la parser en JSON
        try {
          responseData = jsonDecode(response.data) as Map<String, dynamic>;
        } catch (e) {
          print('⚠️ Impossible de parser response.data (String): ${response.data}');
          responseData = {};
        }
      } else {
        print('⚠️ Type inattendu pour response.data: ${response.data.runtimeType}');
        responseData = {};
      }
      
      // Sauvegarder le token
      if (responseData['token'] != null) {
        final token = responseData['token'];
        if (token is String) {
          await _secureStorage.write(
            key: AppConstants.keyAuthToken,
            value: token,
          );
        }
      }
      
      // Sauvegarder l'ID utilisateur
      if (responseData['user'] != null) {
        final userData = responseData['user'];
        String? userId;
        
        if (userData is Map<String, dynamic>) {
          userId = userData['id']?.toString();
        } else if (userData is Map) {
          try {
            final userMap = Map<String, dynamic>.from(userData);
            userId = userMap['id']?.toString();
          } catch (e) {
            print('⚠️ Erreur lors de la conversion de user: $e');
          }
        } else if (userData is String) {
          try {
            final userMap = jsonDecode(userData) as Map<String, dynamic>;
            userId = userMap['id']?.toString();
          } catch (e) {
            print('⚠️ Impossible de parser user (String): $userData');
          }
        }
        
        if (userId != null) {
          await _secureStorage.write(
            key: AppConstants.keyUserId,
            value: userId,
          );
        }
      }
      
      return responseData;
    } on DioException catch (e) {
      // Si c'est une erreur 401, la transformer en message clair
      if (e.response?.statusCode == 401) {
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          type: DioExceptionType.badResponse,
          message: 'Email ou mot de passe incorrect. Si vous n\'avez pas de compte, veuillez vous inscrire.',
        );
      }
      // Si erreur 500, transformer en message clair
      if (e.response?.statusCode == 500) {
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          type: DioExceptionType.badResponse,
          message: 'Erreur serveur. Veuillez réessayer plus tard.',
        );
      }
      print('❌ Erreur lors de la connexion: $e');
      rethrow;
    } catch (e) {
      print('❌ Erreur lors de la connexion: $e');
      rethrow;
    }
  }
  
  /// Obtenir les informations de l'utilisateur connecté
  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _dio.get(
        '/auth/me',
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      
      // Vérifier que response.data est bien un Map
      if (response.data == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'Réponse vide du serveur',
        );
      }
      
      // Si c'est une String, essayer de la parser en JSON
      if (response.data is String) {
        try {
          return jsonDecode(response.data as String) as Map<String, dynamic>;
        } catch (e) {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            message: 'Réponse invalide du serveur: ${response.data}',
          );
        }
      }
      
      // Si c'est déjà un Map, le retourner
      if (response.data is Map) {
        return response.data as Map<String, dynamic>;
      }
      
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Format de réponse inattendu: ${response.data.runtimeType}',
      );
    } catch (e) {
      print('❌ Erreur lors de la récupération des infos utilisateur: $e');
      rethrow;
    }
  }
  
  /// Obtenir les conversations
  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final response = await _dio.get(
        '/conversations',
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      
      // Vérifier que response.data est bien une liste
      if (response.data == null) {
        return [];
      }
      
      // Si c'est une String, retourner une liste vide
      if (response.data is String) {
        print('⚠️ Le backend a retourné une String au lieu d\'un tableau: ${response.data}');
        return [];
      }
      
      // Si c'est déjà une liste, la convertir
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      
      // Sinon, essayer de convertir
      return List<Map<String, dynamic>>.from([response.data]);
    } on DioException catch (e) {
      // Si erreur 500, retourner une liste vide plutôt que de lancer une exception
      if (e.response?.statusCode == 500) {
        print('⚠️ Erreur serveur (500) lors de la récupération des conversations, retour d\'une liste vide');
        return [];
      }
      print('❌ Erreur lors de la récupération des conversations: $e');
      // Retourner une liste vide en cas d'erreur pour éviter de bloquer l'application
      return [];
    } catch (e) {
      print('❌ Erreur lors de la récupération des conversations: $e');
      // Retourner une liste vide en cas d'erreur pour éviter de bloquer l'application
      return [];
    }
  }
  
  /// Obtenir les messages d'une conversation
  Future<List<Map<String, dynamic>>> getMessages(String conversationId, {int? limit}) async {
    try {
      final response = await _dio.get(
        '/conversations/$conversationId/messages',
        queryParameters: limit != null ? {'limit': limit} : null,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      
      // Vérifier que response.data est bien une liste
      if (response.data == null) {
        return [];
      }
      
      // Si c'est une String, retourner une liste vide
      if (response.data is String) {
        print('⚠️ Le backend a retourné une String au lieu d\'un tableau pour les messages: ${response.data}');
        return [];
      }
      
      // Si c'est déjà une liste, la convertir
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(
          (response.data as List).map((item) {
            if (item is Map) {
              return item as Map<String, dynamic>;
            } else if (item is String) {
              // Essayer de parser si c'est une String JSON
              try {
                return jsonDecode(item) as Map<String, dynamic>;
              } catch (e) {
                return <String, dynamic>{};
              }
            }
            return <String, dynamic>{};
          }),
        );
      }
      
      // Sinon, retourner une liste vide
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 500) {
        print('⚠️ Erreur serveur (500) lors de la récupération des messages');
        return [];
      }
      print('❌ Erreur lors de la récupération des messages: $e');
      return [];
    } catch (e) {
      print('❌ Erreur lors de la récupération des messages: $e');
      return [];
    }
  }
  
  /// Marquer un message comme lu
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _dio.post('/messages/$messageId/read');
    } catch (e) {
      print('❌ Erreur lors du marquage du message comme lu: $e');
      rethrow;
    }
  }
  
  /// Stocker le contenu chiffré d'un message
  /// 
  /// SECURITY: Le contenu est stocké comme opaque binary.
  /// Le backend ne peut pas le lire ou le déchiffrer.
  Future<void> storeEncryptedContent({
    required String messageId,
    required String encryptedContent, // Base64 encoded
    String? contentHash, // SHA-256 hash
    DateTime? expiresAt,
  }) async {
    try {
      await _dio.post(
        '/messages/$messageId/content',
        data: {
          'message_id': messageId,
          'content_data': encryptedContent,
          'content_hash': contentHash,
          'expires_at': expiresAt?.toIso8601String(),
        },
      );
    } catch (e) {
      print('❌ Erreur lors du stockage du contenu chiffré: $e');
      rethrow;
    }
  }
  
  /// Récupérer le contenu chiffré d'un message
  /// 
  /// SECURITY: Le contenu est retourné comme opaque binary.
  /// Le déchiffrement se fait côté client avec Signal Protocol.
  Future<Map<String, dynamic>> getEncryptedContent(String messageId) async {
    try {
      final response = await _dio.get('/messages/$messageId/content');
      return response.data;
    } catch (e) {
      print('❌ Erreur lors de la récupération du contenu chiffré: $e');
      rethrow;
    }
  }
  
  /// Démarrer un appel
  Future<Map<String, dynamic>> startCall({
    required String recipientId,
    required String callType, // 'audio' or 'video'
  }) async {
    try {
      final response = await _dio.post(
        '/calls',
        data: {
          'recipient_id': recipientId,
          'call_type': callType,
        },
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      
      if (response.statusCode != null && response.statusCode! >= 400) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'Erreur lors du démarrage de l\'appel',
        );
      }
      
      // Gérer les valeurs null
      if (response.data == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'Réponse vide du serveur',
        );
      }
      
      // Si c'est une String, essayer de la parser en JSON
      if (response.data is String) {
        try {
          return jsonDecode(response.data as String) as Map<String, dynamic>;
        } catch (e) {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            message: 'Format de réponse invalide',
          );
        }
      }
      
      // Si c'est déjà un Map, le retourner
      if (response.data is Map) {
        return response.data as Map<String, dynamic>;
      }
      
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Format de réponse inattendu',
      );
    } catch (e) {
      print('❌ Erreur lors du démarrage de l\'appel: $e');
      rethrow;
    }
  }
  
  /// Obtenir l'historique des appels
  Future<List<Map<String, dynamic>>> getCallHistory({int? limit}) async {
    try {
      final response = await _dio.get(
        '/calls/history',
        queryParameters: limit != null ? {'limit': limit} : null,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      
      // Vérifier que response.data est bien une liste
      if (response.data == null) {
        return [];
      }
      
      // Si c'est une String, retourner une liste vide
      if (response.data is String) {
        print('⚠️ Le backend a retourné une String au lieu d\'un tableau pour l\'historique des appels: ${response.data}');
        return [];
      }
      
      // Si c'est déjà une liste, la convertir
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(
          (response.data as List).map((item) {
            if (item is Map) {
              return item as Map<String, dynamic>;
            } else if (item is String) {
              try {
                return jsonDecode(item) as Map<String, dynamic>;
              } catch (e) {
                return <String, dynamic>{};
              }
            }
            return <String, dynamic>{};
          }),
        );
      }
      
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 500) {
        print('⚠️ Erreur serveur (500) lors de la récupération de l\'historique des appels');
        return [];
      }
      print('❌ Erreur lors de la récupération de l\'historique des appels: $e');
      return [];
    } catch (e) {
      print('❌ Erreur lors de la récupération de l\'historique des appels: $e');
      return [];
    }
  }
  
  /// Obtenir l'appel actif
  Future<Map<String, dynamic>?> getActiveCall() async {
    try {
      final response = await _dio.get(
        '/calls/active',
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      
      if (response.statusCode == 404) {
        return null; // Pas d'appel actif
      }
      
      // Vérifier que response.data est bien un Map
      if (response.data == null) {
        return null;
      }
      
      // Si c'est une String, essayer de la parser en JSON
      if (response.data is String) {
        try {
          return jsonDecode(response.data as String) as Map<String, dynamic>;
        } catch (e) {
          print('⚠️ Impossible de parser la réponse de l\'appel actif: ${response.data}');
          return null;
        }
      }
      
      // Si c'est déjà un Map, le retourner
      if (response.data is Map) {
        return response.data as Map<String, dynamic>;
      }
      
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // Pas d'appel actif
      }
      print('❌ Erreur lors de la récupération de l\'appel actif: $e');
      return null;
    } catch (e) {
      print('❌ Erreur lors de la récupération de l\'appel actif: $e');
      return null;
    }
  }
  
  /// Mettre à jour le statut de présence
  Future<Map<String, dynamic>> updatePresence(String status) async {
    try {
      final response = await _dio.post(
        '/presence',
        data: {
          'status': status,
        },
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      
      // Vérifier que response.data est bien un Map
      if (response.data == null) {
        print('⚠️ Réponse de présence vide');
        return {'status': status, 'last_seen': DateTime.now().toIso8601String()};
      }
      
      // Logger la réponse pour debug
      print('📊 Réponse updatePresence: ${response.data} (type: ${response.data.runtimeType})');
      
      // Si c'est une String, essayer de la parser en JSON
      if (response.data is String) {
        try {
          final decoded = jsonDecode(response.data as String);
          if (decoded is Map) {
            final data = Map<String, dynamic>.from(decoded);
            // Normaliser les champs (snake_case et camelCase)
            return {
              'user_id': data['user_id']?.toString() ?? data['userId']?.toString() ?? '',
              'status': data['status']?.toString() ?? status,
              'last_seen': data['last_seen']?.toString() ?? data['lastSeen']?.toString() ?? DateTime.now().toIso8601String(),
              'updated_at': data['updated_at']?.toString() ?? data['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
            };
          }
        } catch (e) {
          print('⚠️ Impossible de parser la réponse de présence (String): ${response.data}');
          print('   Erreur: $e');
          return {'status': status, 'last_seen': DateTime.now().toIso8601String()};
        }
      }
      
      // Si c'est déjà un Map, le normaliser
      if (response.data is Map) {
        final data = Map<String, dynamic>.from(response.data as Map);
        // Normaliser les champs (snake_case et camelCase)
        // Gérer les types (Uuid peut être String, DateTime peut être String)
        return {
          'user_id': data['user_id']?.toString() ?? data['userId']?.toString() ?? '',
          'status': data['status']?.toString() ?? status,
          'last_seen': data['last_seen']?.toString() ?? 
                       data['lastSeen']?.toString() ?? 
                       (data['last_seen'] is DateTime ? (data['last_seen'] as DateTime).toIso8601String() : null) ??
                       DateTime.now().toIso8601String(),
          'updated_at': data['updated_at']?.toString() ?? 
                       data['updatedAt']?.toString() ?? 
                       (data['updated_at'] is DateTime ? (data['updated_at'] as DateTime).toIso8601String() : null) ??
                       DateTime.now().toIso8601String(),
        };
      }
      
      // Par défaut, retourner un statut
      print('⚠️ Format de réponse inattendu pour updatePresence: ${response.data.runtimeType}');
      return {'status': status, 'last_seen': DateTime.now().toIso8601String()};
    } on DioException catch (e) {
      // Si erreur 400, 500, ou autre, retourner un statut par défaut
      if (e.response?.statusCode != null) {
        print('⚠️ Erreur serveur (${e.response?.statusCode}) lors de la mise à jour de la présence');
        print('   Détails: ${e.response?.data}');
        
        // Si c'est une erreur de validation (400), essayer de parser le message d'erreur
        if (e.response?.statusCode == 400) {
          final errorData = e.response?.data;
          if (errorData is String) {
            print('   Message d\'erreur: $errorData');
          }
        }
      } else {
        print('❌ Erreur de connexion lors de la mise à jour de la présence: $e');
      }
      // Retourner un statut par défaut en cas d'erreur pour éviter de bloquer l'application
      return {'status': status, 'last_seen': DateTime.now().toIso8601String()};
    } catch (e) {
      print('❌ Erreur inattendue lors de la mise à jour de la présence: $e');
      // Retourner un statut par défaut en cas d'erreur pour éviter de bloquer l'application
      return {'status': status, 'last_seen': DateTime.now().toIso8601String()};
    }
  }
  
  /// Obtenir le statut de présence d'un utilisateur
  Future<Map<String, dynamic>> getPresence(String userId) async {
    try {
      final response = await _dio.get(
        '/presence/$userId',
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      
      // Vérifier que response.data est bien un Map
      if (response.data == null) {
        return {'user_id': userId, 'status': 'offline', 'last_seen': DateTime.now().toIso8601String()};
      }
      
      // Si c'est une String, essayer de la parser en JSON
      if (response.data is String) {
        try {
          final decoded = jsonDecode(response.data as String) as Map<String, dynamic>;
          // Normaliser les champs (snake_case et camelCase)
          return {
            'user_id': decoded['user_id'] ?? decoded['userId'] ?? userId,
            'status': decoded['status'] ?? 'offline',
            'last_seen': decoded['last_seen'] ?? decoded['lastSeen'] ?? DateTime.now().toIso8601String(),
            'updated_at': decoded['updated_at'] ?? decoded['updatedAt'] ?? DateTime.now().toIso8601String(),
          };
        } catch (e) {
          print('⚠️ Impossible de parser la réponse de présence: ${response.data}');
          print('   Erreur: $e');
          return {'user_id': userId, 'status': 'offline', 'last_seen': DateTime.now().toIso8601String()};
        }
      }
      
      // Si c'est déjà un Map, le normaliser
      if (response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        // Normaliser les champs (snake_case et camelCase)
        return {
          'user_id': data['user_id'] ?? data['userId'] ?? userId,
          'status': data['status'] ?? 'offline',
          'last_seen': data['last_seen'] ?? data['lastSeen'] ?? DateTime.now().toIso8601String(),
          'updated_at': data['updated_at'] ?? data['updatedAt'] ?? DateTime.now().toIso8601String(),
        };
      }
      
      return {'user_id': userId, 'status': 'offline', 'last_seen': DateTime.now().toIso8601String()};
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return {'user_id': userId, 'status': 'offline', 'last_seen': DateTime.now().toIso8601String()};
      }
      print('❌ Erreur lors de la récupération de la présence: $e');
      return {'user_id': userId, 'status': 'offline', 'last_seen': DateTime.now().toIso8601String()};
    } catch (e) {
      print('❌ Erreur lors de la récupération de la présence: $e');
      return {'user_id': userId, 'status': 'offline', 'last_seen': DateTime.now().toIso8601String()};
    }
  }
  
  /// Rechercher des utilisateurs
  Future<List<Map<String, dynamic>>> searchUsers({String? query, int? limit}) async {
    try {
      // Construire les paramètres de requête
      final queryParams = <String, dynamic>{};
      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query;
      }
      if (limit != null) {
        queryParams['limit'] = limit;
      }
      
      print('🔍 Recherche d\'utilisateurs avec query: "$query", limit: $limit');
      print('🔍 Paramètres de requête: $queryParams');
      
      final response = await _dio.get(
        '/users/search',
        queryParameters: queryParams.isEmpty ? null : queryParams,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      
      print('🔍 Réponse du serveur - Status: ${response.statusCode}');
      print('🔍 Type de données: ${response.data.runtimeType}');
      
      // Vérifier que response.data est bien une liste
      if (response.data == null) {
        print('⚠️ Réponse vide du serveur');
        return [];
      }
      
      // Si c'est une String, retourner une liste vide
      if (response.data is String) {
        print('⚠️ Le backend a retourné une String au lieu d\'un tableau: ${response.data}');
        return [];
      }
      
      // Si c'est déjà une liste, la convertir
      if (response.data is List) {
        final results = List<Map<String, dynamic>>.from(
          (response.data as List).map((item) {
            if (item is Map) {
              return item as Map<String, dynamic>;
            } else {
              print('⚠️ Item inattendu dans la liste: ${item.runtimeType}');
              return <String, dynamic>{};
            }
          }),
        );
        print('✅ ${results.length} utilisateur(s) trouvé(s)');
        return results;
      }
      
      // Sinon, essayer de convertir
      print('⚠️ Format de réponse inattendu, tentative de conversion');
      return List<Map<String, dynamic>>.from([response.data]);
    } on DioException catch (e) {
      if (e.response?.statusCode == 500) {
        print('⚠️ Erreur serveur (500) lors de la recherche d\'utilisateurs');
        print('   Détails: ${e.response?.data}');
        return [];
      }
      if (e.response?.statusCode == 401) {
        print('⚠️ Non autorisé (401) lors de la recherche d\'utilisateurs');
        return [];
      }
      print('❌ Erreur lors de la recherche d\'utilisateurs: $e');
      print('   Status: ${e.response?.statusCode}');
      print('   Data: ${e.response?.data}');
      return [];
    } catch (e) {
      print('❌ Erreur inattendue lors de la recherche d\'utilisateurs: $e');
      return [];
    }
  }
  
  /// Trouver un utilisateur par email
  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    try {
      final response = await _dio.get(
        '/users/find-by-email',
        queryParameters: {
          'email': email,
        },
        options: Options(
          validateStatus: (status) => status != null && status < 500, // Accepter les codes < 500
        ),
      );
      
      // Si erreur 404, utilisateur non trouvé
      if (response.statusCode == 404) {
        return null;
      }
      
      // Si erreur 400 (Bad Request), probablement l'utilisateur actuel
      if (response.statusCode == 400) {
        return null;
      }
      
      // Si erreur 500, retourner null et logger l'erreur
      if (response.statusCode == 500) {
        print('❌ Erreur serveur (500) lors de la recherche par email: $email');
        return null;
      }
      
      // Si autre erreur, retourner null
      if (response.statusCode != null && response.statusCode! >= 400) {
        print('⚠️ Erreur ${response.statusCode} lors de la recherche par email');
        return null;
      }
      
      // Gérer les valeurs null
      if (response.data == null) {
        return null;
      }
      
      // Si c'est une String, essayer de la parser en JSON
      if (response.data is String) {
        try {
          return jsonDecode(response.data as String) as Map<String, dynamic>;
        } catch (e) {
          print('⚠️ Impossible de parser la réponse findUserByEmail: ${response.data}');
          return null;
        }
      }
      
      // Si c'est déjà un Map, le retourner
      if (response.data is Map) {
        return response.data as Map<String, dynamic>;
      }
      
      return null;
    } on DioException catch (e) {
      // Gérer les erreurs 500 et autres erreurs Dio
      if (e.response?.statusCode == 500) {
        print('❌ Erreur serveur (500) lors de la recherche par email: $email');
        return null;
      }
      if (e.response?.statusCode == 404) {
        return null; // Utilisateur non trouvé
      }
      if (e.response?.statusCode == 400) {
        return null; // Bad Request (probablement l'utilisateur actuel)
      }
      print('❌ Erreur lors de la recherche par email: $e');
      return null;
    } catch (e) {
      print('❌ Erreur inattendue lors de la recherche par email: $e');
      return null;
    }
  }
  
  /// Créer une conversation avec un utilisateur
  Future<Map<String, dynamic>> createConversation(String participantId) async {
    try {
      final response = await _dio.post(
        '/conversations',
        data: {
          'participant_id': participantId,
        },
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      
      if (response.statusCode == 404) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'Utilisateur non trouvé',
        );
      }
      
      if (response.statusCode == 400) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'Impossible de créer une conversation avec vous-même',
        );
      }
      
      if (response.statusCode != null && response.statusCode! >= 400) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'Erreur lors de la création de la conversation: ${response.statusMessage ?? "Erreur inconnue"}',
        );
      }
      
      // Gérer les valeurs null
      if (response.data == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'Réponse vide du serveur',
        );
      }
      
      // Si c'est une String, essayer de la parser en JSON
      if (response.data is String) {
        try {
          return jsonDecode(response.data as String) as Map<String, dynamic>;
        } catch (e) {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            message: 'Format de réponse invalide',
          );
        }
      }
      
      // Si c'est déjà un Map, le retourner
      if (response.data is Map) {
        return response.data as Map<String, dynamic>;
      }
      
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Format de réponse inattendu',
      );
    } on DioException catch (e) {
      print('❌ Erreur lors de la création de la conversation: $e');
      if (e.response?.statusCode == 404) {
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          type: DioExceptionType.badResponse,
          message: 'Utilisateur non trouvé',
        );
      }
      rethrow;
    } catch (e) {
      print('❌ Erreur lors de la création de la conversation: $e');
      rethrow;
    }
  }
  
  /// Déconnexion
  Future<void> logout() async {
    await _secureStorage.delete(key: AppConstants.keyAuthToken);
    await _secureStorage.delete(key: AppConstants.keyUserId);
  }
  
  // ==================== STORIES ====================
  
  /// Créer une story
  Future<Map<String, dynamic>> createStory({
    String? contentText,
    String? mediaUrl,
    required String mediaType, // 'image' or 'video'
  }) async {
    try {
      final response = await _dio.post(
        '/stories',
        data: {
          if (contentText != null) 'content_text': contentText,
          if (mediaUrl != null) 'media_url': mediaUrl,
          'media_type': mediaType,
        },
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      
      if (response.statusCode != null && response.statusCode! >= 400) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'Erreur lors de la création de la story',
        );
      }
      
      // Gérer les valeurs null
      if (response.data == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'Réponse vide du serveur',
        );
      }
      
      if (response.data is String) {
        try {
          return jsonDecode(response.data as String) as Map<String, dynamic>;
        } catch (e) {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            message: 'Format de réponse invalide',
          );
        }
      }
      
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('❌ Erreur lors de la création de la story: $e');
      rethrow;
    }
  }
  
  /// Obtenir toutes les stories
  Future<List<Map<String, dynamic>>> getStories({int? limit}) async {
    try {
      final response = await _dio.get(
        '/stories',
        queryParameters: limit != null ? {'limit': limit} : null,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      
      if (response.data == null) {
        return [];
      }
      
      if (response.data is String) {
        print('⚠️ Le backend a retourné une String au lieu d\'un tableau pour les stories: ${response.data}');
        return [];
      }
      
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(
          (response.data as List).map((item) {
            if (item is Map) {
              return item as Map<String, dynamic>;
            } else if (item is String) {
              try {
                return jsonDecode(item) as Map<String, dynamic>;
              } catch (e) {
                return <String, dynamic>{};
              }
            }
            return <String, dynamic>{};
          }),
        );
      }
      
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 500) {
        print('⚠️ Erreur serveur (500) lors de la récupération des stories');
        return [];
      }
      print('❌ Erreur lors de la récupération des stories: $e');
      return [];
    } catch (e) {
      print('❌ Erreur lors de la récupération des stories: $e');
      return [];
    }
  }
  
  /// Marquer une story comme vue
  Future<void> viewStory(String storyId) async {
    try {
      await _dio.post(
        '/stories/$storyId/view',
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
    } catch (e) {
      print('❌ Erreur lors du marquage de la story comme vue: $e');
      // Ne pas lancer d'exception pour cette opération non critique
    }
  }
  
  // ==================== CHANNELS ====================
  
  /// Créer un channel
  Future<Map<String, dynamic>> createChannel({
    required String name,
    String? description,
    String? avatarUrl,
    bool isPrivate = false,
  }) async {
    try {
      final response = await _dio.post(
        '/channels',
        data: {
          'name': name,
          if (description != null) 'description': description,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
          'is_private': isPrivate,
        },
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      
      if (response.statusCode != null && response.statusCode! >= 400) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'Erreur lors de la création du channel',
        );
      }
      
      if (response.data == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'Réponse vide du serveur',
        );
      }
      
      if (response.data is String) {
        try {
          return jsonDecode(response.data as String) as Map<String, dynamic>;
        } catch (e) {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            message: 'Format de réponse invalide',
          );
        }
      }
      
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('❌ Erreur lors de la création du channel: $e');
      rethrow;
    }
  }
  
  /// Obtenir tous les channels de l'utilisateur
  Future<List<Map<String, dynamic>>> getChannels() async {
    try {
      final response = await _dio.get(
        '/channels',
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      
      if (response.data == null) {
        return [];
      }
      
      if (response.data is String) {
        print('⚠️ Le backend a retourné une String au lieu d\'un tableau pour les channels: ${response.data}');
        return [];
      }
      
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(
          (response.data as List).map((item) {
            if (item is Map) {
              return item as Map<String, dynamic>;
            } else if (item is String) {
              try {
                return jsonDecode(item) as Map<String, dynamic>;
              } catch (e) {
                return <String, dynamic>{};
              }
            }
            return <String, dynamic>{};
          }),
        );
      }
      
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 500) {
        print('⚠️ Erreur serveur (500) lors de la récupération des channels');
        return [];
      }
      print('❌ Erreur lors de la récupération des channels: $e');
      return [];
    } catch (e) {
      print('❌ Erreur lors de la récupération des channels: $e');
      return [];
    }
  }
  
  /// Obtenir les messages d'un channel
  Future<List<Map<String, dynamic>>> getChannelMessages(String channelId, {int? limit}) async {
    try {
      final response = await _dio.get(
        '/channels/$channelId/messages',
        queryParameters: limit != null ? {'limit': limit} : null,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      
      if (response.data == null) {
        return [];
      }
      
      if (response.data is String) {
        print('⚠️ Le backend a retourné une String au lieu d\'un tableau pour les messages du channel: ${response.data}');
        return [];
      }
      
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(
          (response.data as List).map((item) {
            if (item is Map) {
              return item as Map<String, dynamic>;
            } else if (item is String) {
              try {
                return jsonDecode(item) as Map<String, dynamic>;
              } catch (e) {
                return <String, dynamic>{};
              }
            }
            return <String, dynamic>{};
          }),
        );
      }
      
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 500) {
        print('⚠️ Erreur serveur (500) lors de la récupération des messages du channel');
        return [];
      }
      print('❌ Erreur lors de la récupération des messages du channel: $e');
      return [];
    } catch (e) {
      print('❌ Erreur lors de la récupération des messages du channel: $e');
      return [];
    }
  }
}

