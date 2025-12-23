# Guide de Build pour Kisse

Ce guide vous explique comment build l'application Kisse pour Android et iOS.

## Prérequis

### Android
- Flutter SDK (version 3.8.1 ou supérieure)
- Android Studio avec Android SDK
- JDK 11 ou supérieur
- Android SDK Platform 33 ou supérieur
- Android SDK Build-Tools

### iOS
- macOS avec Xcode installé
- CocoaPods installé
- Certificat de développement Apple (pour les builds sur appareil)

## Permissions Configurées

### Android
Les permissions suivantes ont été ajoutées dans `AndroidManifest.xml` :
- ✅ Internet et Réseau
- ✅ Microphone (appels audio)
- ✅ Caméra (appels vidéo)
- ✅ Stockage (fichiers, images, vidéos)
- ✅ Notifications
- ✅ Biométrie (authentification)
- ✅ Bluetooth (pour les écouteurs)

### iOS
Les permissions suivantes ont été ajoutées dans `Info.plist` :
- ✅ Microphone
- ✅ Caméra
- ✅ Galerie de photos
- ✅ Notifications
- ✅ Face ID
- ✅ VoIP (appels)

## Build Android

### 1. Vérifier la configuration

```bash
flutter doctor
```

### 2. Nettoyer le projet

```bash
flutter clean
flutter pub get
```

### 3. Build Debug

```bash
flutter build apk --debug
```

ou pour un seul ABI :

```bash
flutter build apk --debug --split-per-abi
```

### 4. Build Release

```bash
flutter build apk --release
```

ou pour App Bundle (recommandé pour Google Play) :

```bash
flutter build appbundle --release
```

### 5. Signer l'APK (Production)

Pour la production, vous devez signer l'APK. Créez un fichier `android/key.properties` :

```properties
storePassword=VOTRE_MOT_DE_PASSE
keyPassword=VOTRE_MOT_DE_PASSE
keyAlias=kisse
storeFile=../keystore/kisse.jks
```

Puis créez le keystore :

```bash
keytool -genkey -v -keystore android/keystore/kisse.jks -keyalg RSA -keysize 2048 -validity 10000 -alias kisse
```

Mettez à jour `android/app/build.gradle.kts` pour utiliser la signature :

```kotlin
android {
    signingConfigs {
        create("release") {
            val keystorePropertiesFile = rootProject.file("key.properties")
            val keystoreProperties = java.util.Properties()
            keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
            
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

## Build iOS

### 1. Installer les dépendances CocoaPods

```bash
cd ios
pod install
cd ..
```

### 2. Ouvrir le projet dans Xcode

```bash
open ios/Runner.xcworkspace
```

### 3. Configurer le certificat et le provisioning profile

Dans Xcode :
1. Sélectionnez le target "Runner"
2. Allez dans "Signing & Capabilities"
3. Sélectionnez votre équipe de développement
4. Xcode générera automatiquement le certificat et le provisioning profile

### 4. Build depuis la ligne de commande

```bash
flutter build ios --release
```

ou pour un build avec codesign :

```bash
flutter build ipa --release
```

### 5. Build depuis Xcode

1. Ouvrez `ios/Runner.xcworkspace` dans Xcode
2. Sélectionnez un appareil ou un simulateur
3. Cliquez sur "Product" > "Build" (⌘B)
4. Pour installer sur un appareil : "Product" > "Run" (⌘R)

## Configuration des Permissions Runtime (Android 13+)

Pour Android 13 (API 33) et supérieur, certaines permissions nécessitent une demande runtime. Le package `permission_handler` gère cela automatiquement, mais assurez-vous que votre code demande les permissions au bon moment :

```dart
// Exemple dans AgoraService
final mic = await Permission.microphone.request();
final camera = await Permission.camera.request();
```

## Vérification des Permissions

### Android
Vérifiez que toutes les permissions sont présentes dans `android/app/src/main/AndroidManifest.xml`

### iOS
Vérifiez que toutes les descriptions d'utilisation sont présentes dans `ios/Runner/Info.plist`

## Problèmes Courants

### Android

**Erreur : "Permission denied"**
- Vérifiez que les permissions sont dans `AndroidManifest.xml`
- Pour Android 13+, certaines permissions nécessitent une demande runtime

**Erreur : "minSdkVersion too low"**
- Vérifiez que `minSdkVersion` est au moins 21 (Android 5.0)
- Pour certaines fonctionnalités, vous pourriez avoir besoin de 23+ (Android 6.0)

**Erreur : "Agora RTC not found"**
- Vérifiez que `agora_rtc_engine` est dans `pubspec.yaml`
- Exécutez `flutter pub get`

### iOS

**Erreur : "Missing permission description"**
- Vérifiez que toutes les clés `NS*UsageDescription` sont dans `Info.plist`
- Les descriptions doivent être en français ou anglais selon votre marché

**Erreur : "Code signing failed"**
- Vérifiez votre certificat de développement dans Xcode
- Assurez-vous que le Bundle Identifier est unique

**Erreur : "Pod install failed"**
- Exécutez `cd ios && pod deintegrate && pod install`
- Vérifiez que CocoaPods est à jour : `sudo gem install cocoapods`

## Commandes Utiles

```bash
# Nettoyer et reconstruire
flutter clean
flutter pub get
flutter build apk --release

# Vérifier les dépendances
flutter pub outdated

# Analyser le code
flutter analyze

# Vérifier la configuration
flutter doctor -v
```

## Notes Importantes

1. **Sécurité** : Ne commitez jamais vos fichiers de signature (`key.properties`, `keystore/*.jks`) dans Git
2. **Version** : Mettez à jour `version` dans `pubspec.yaml` avant chaque release
3. **Permissions** : Testez toutes les permissions sur un appareil réel, pas seulement sur un émulateur
4. **Notifications** : Pour les notifications push, configurez Firebase Cloud Messaging

## Prochaines Étapes

1. Configurez Firebase pour les notifications push
2. Créez un keystore pour signer l'APK de production
3. Configurez les certificats iOS pour la distribution
4. Testez toutes les permissions sur des appareils réels

