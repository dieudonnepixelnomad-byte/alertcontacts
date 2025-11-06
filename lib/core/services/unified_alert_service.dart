import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';

/// Types d'alertes disponibles
enum AlertType {
  dangerZone,
  safeZone,
  critical,
  warning,
  info,
}

/// Intensité des vibrations
enum VibrationIntensity {
  light,
  medium,
  heavy,
  critical,
}

/// Configuration d'une alerte
class AlertConfig {
  final AlertType type;
  final String? voiceMessage;
  final VibrationIntensity vibrationIntensity;
  final bool enableVoice;
  final bool enableVibration;
  final double voiceVolume;
  final double voicePitch;
  final double voiceRate;
  final String? voiceLanguage;

  const AlertConfig({
    required this.type,
    this.voiceMessage,
    this.vibrationIntensity = VibrationIntensity.medium,
    this.enableVoice = true,
    this.enableVibration = true,
    this.voiceVolume = 1.0,
    this.voicePitch = 1.0,
    this.voiceRate = 0.5,
    this.voiceLanguage = 'fr-FR',
  });
}

/// Service unifié pour la gestion des alertes vocales et vibrations
/// Centralise toutes les fonctionnalités d'alerte tactile et auditive
class UnifiedAlertService {
  static final UnifiedAlertService _instance = UnifiedAlertService._internal();
  factory UnifiedAlertService() => _instance;
  UnifiedAlertService._internal();

  FlutterTts? _flutterTts;
  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _vibrationSupported = false;

  /// Paramètres globaux des alertes
  bool _globalVoiceEnabled = true;
  bool _globalVibrationEnabled = true;
  double _globalVolume = 1.0;
  double _globalPitch = 1.0;
  double _globalRate = 0.5;
  String _globalLanguage = 'fr-FR';

  /// Cooldown supprimé - géré uniquement côté backend (24h par zone)

  /// Initialise le service d'alertes
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Initialiser TTS
      _flutterTts = FlutterTts();
      await _initializeTts();

      // Vérifier le support des vibrations
      _vibrationSupported = await Vibration.hasVibrator() ?? false;

      _isInitialized = true;
      debugPrint('✅ UnifiedAlertService initialisé avec succès');
      debugPrint('📳 Support vibration: $_vibrationSupported');
      
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation des alertes: $e');
      return false;
    }
  }

  /// Initialise le moteur TTS
  Future<void> _initializeTts() async {
    if (_flutterTts == null) return;

    try {
      // Configuration de base
      await _flutterTts!.setLanguage(_globalLanguage);
      await _flutterTts!.setVolume(_globalVolume);
      await _flutterTts!.setPitch(_globalPitch);
      await _flutterTts!.setSpeechRate(_globalRate);

      // Configuration spécifique à la plateforme
      if (Platform.isAndroid) {
        await _flutterTts!.setEngine('com.google.android.tts');
        await _flutterTts!.awaitSpeakCompletion(true);
      } else if (Platform.isIOS) {
        await _flutterTts!.setSharedInstance(true);
        await _flutterTts!.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
          IosTextToSpeechAudioMode.defaultMode,
        );
      }

      // Callbacks
      _flutterTts!.setStartHandler(() {
        _isSpeaking = true;
        debugPrint('🔊 TTS démarré');
      });

      _flutterTts!.setCompletionHandler(() {
        _isSpeaking = false;
        debugPrint('🔇 TTS terminé');
      });

      _flutterTts!.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('❌ Erreur TTS: $msg');
      });

      debugPrint('✅ TTS initialisé');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation TTS: $e');
    }
  }

  /// Déclenche une alerte complète (voix + vibration)
  Future<void> triggerAlert(AlertConfig config) async {
    if (!_isInitialized) {
      debugPrint('⚠️ Service non initialisé, tentative d\'initialisation...');
      final initialized = await initialize();
      if (!initialized) {
        debugPrint('❌ Impossible d\'initialiser le service d\'alertes');
        return;
      }
    }

    // Cooldown supprimé - géré côté backend

    try {
      // Déclencher vibration et voix en parallèle
      final List<Future> alertFutures = [];

      if (config.enableVibration && _globalVibrationEnabled) {
        alertFutures.add(_triggerVibration(config.vibrationIntensity));
      }

      if (config.enableVoice && _globalVoiceEnabled && config.voiceMessage != null) {
        alertFutures.add(_triggerVoiceAlert(config));
      }

      // Attendre que toutes les alertes se terminent
      await Future.wait(alertFutures);

      debugPrint('✅ Alerte ${config.type} déclenchée avec succès');
    } catch (e) {
      debugPrint('❌ Erreur lors du déclenchement de l\'alerte: $e');
    }
  }

  /// Déclenche une vibration selon l'intensité
  Future<void> _triggerVibration(VibrationIntensity intensity) async {
    if (!_vibrationSupported) {
      debugPrint('⚠️ Vibration non supportée sur cet appareil');
      return;
    }

    try {
      switch (intensity) {
        case VibrationIntensity.light:
          await Vibration.vibrate(duration: 200);
          break;
        case VibrationIntensity.medium:
          await Vibration.vibrate(duration: 500);
          break;
        case VibrationIntensity.heavy:
          await Vibration.vibrate(duration: 1000);
          break;
        case VibrationIntensity.critical:
          // Pattern critique: 3 vibrations courtes
          await Vibration.vibrate(
            pattern: [0, 300, 100, 300, 100, 300],
            intensities: [0, 255, 0, 255, 0, 255],
          );
          break;
      }
      debugPrint('📳 Vibration ${intensity.name} déclenchée');
    } catch (e) {
      debugPrint('❌ Erreur lors de la vibration: $e');
    }
  }

  /// Déclenche une alerte vocale
  Future<void> _triggerVoiceAlert(AlertConfig config) async {
    if (_flutterTts == null || config.voiceMessage == null) return;

    try {
      // Arrêter toute lecture en cours
      if (_isSpeaking) {
        await _flutterTts!.stop();
      }

      // Configurer les paramètres pour cette alerte
      await _flutterTts!.setLanguage(config.voiceLanguage ?? _globalLanguage);
      await _flutterTts!.setVolume(config.voiceVolume);
      await _flutterTts!.setPitch(config.voicePitch);
      await _flutterTts!.setSpeechRate(config.voiceRate);

      // Lancer la lecture
      await _flutterTts!.speak(config.voiceMessage!);
      debugPrint('🔊 Message vocal: "${config.voiceMessage}"');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'alerte vocale: $e');
    }
  }

  /// Méthode _isInCooldown supprimée - cooldown géré côté backend

  /// Arrête toutes les alertes en cours
  Future<void> stopAllAlerts() async {
    try {
      // Arrêter TTS
      if (_flutterTts != null && _isSpeaking) {
        await _flutterTts!.stop();
      }

      // Arrêter vibrations
      if (_vibrationSupported) {
        await Vibration.cancel();
      }

      debugPrint('🛑 Toutes les alertes arrêtées');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'arrêt des alertes: $e');
    }
  }

  /// Déclenche une alerte de zone de danger
  Future<void> triggerDangerZoneAlert({
    required String zoneName,
    required int distanceMeters,
  }) async {
    final message = 'Attention ! Vous approchez d\'une zone de danger : $zoneName. Distance : $distanceMeters mètres.';
    
    await triggerAlert(AlertConfig(
      type: AlertType.dangerZone,
      voiceMessage: message,
      vibrationIntensity: VibrationIntensity.critical,
      enableVoice: true,
      enableVibration: true,
      voiceVolume: 1.0,
      voicePitch: 1.2,
      voiceRate: 0.4,
    ));
  }

  /// Déclenche une alerte de sortie de zone de sécurité
  Future<void> triggerSafeZoneExitAlert({
    required String zoneName,
    required String contactName,
  }) async {
    final message = '$contactName a quitté la zone de sécurité : $zoneName.';
    
    await triggerAlert(AlertConfig(
      type: AlertType.safeZone,
      voiceMessage: message,
      vibrationIntensity: VibrationIntensity.medium,
      enableVoice: true,
      enableVibration: true,
      voiceVolume: 0.8,
      voicePitch: 1.0,
      voiceRate: 0.5,
    ));
  }

  /// Déclenche une alerte critique
  Future<void> triggerCriticalAlert({
    required String message,
  }) async {
    await triggerAlert(AlertConfig(
      type: AlertType.critical,
      voiceMessage: 'Alerte critique ! $message',
      vibrationIntensity: VibrationIntensity.critical,
      enableVoice: true,
      enableVibration: true,
      voiceVolume: 1.0,
      voicePitch: 1.3,
      voiceRate: 0.3,
    ));
  }

  /// Configuration globale des alertes vocales
  Future<void> configureVoiceSettings({
    bool? enabled,
    double? volume,
    double? pitch,
    double? rate,
    String? language,
  }) async {
    if (enabled != null) _globalVoiceEnabled = enabled;
    if (volume != null) _globalVolume = volume;
    if (pitch != null) _globalPitch = pitch;
    if (rate != null) _globalRate = rate;
    if (language != null) _globalLanguage = language;

    // Appliquer les nouveaux paramètres au TTS
    if (_flutterTts != null) {
      await _flutterTts!.setLanguage(_globalLanguage);
      await _flutterTts!.setVolume(_globalVolume);
      await _flutterTts!.setPitch(_globalPitch);
      await _flutterTts!.setSpeechRate(_globalRate);
    }

    debugPrint('⚙️ Paramètres vocaux mis à jour');
  }

  /// Configuration globale des vibrations
  void configureVibrationSettings({
    bool? enabled,
  }) {
    if (enabled != null) _globalVibrationEnabled = enabled;
    debugPrint('⚙️ Paramètres de vibration mis à jour');
  }

  /// Teste les alertes
  Future<void> testAlerts() async {
    debugPrint('🧪 Test des alertes...');
    
    await triggerAlert(AlertConfig(
      type: AlertType.info,
      voiceMessage: 'Test des alertes AlertContact',
      vibrationIntensity: VibrationIntensity.light,
      enableVoice: true,
      enableVibration: true,
    ));
  }

  /// Obtient les langues disponibles pour TTS
  Future<List<String>> getAvailableLanguages() async {
    if (_flutterTts == null) return [];
    
    try {
      final languages = await _flutterTts!.getLanguages;
      return List<String>.from(languages);
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des langues: $e');
      return [];
    }
  }

  /// Vérifie si TTS est en cours
  bool get isSpeaking => _isSpeaking;

  /// Vérifie si les vibrations sont supportées
  bool get isVibrationSupported => _vibrationSupported;

  /// Vérifie si le service est initialisé
  bool get isInitialized => _isInitialized;

  /// Getters pour les paramètres globaux
  bool get isVoiceEnabled => _globalVoiceEnabled;
  bool get isVibrationEnabled => _globalVibrationEnabled;
  double get globalVolume => _globalVolume;
  double get globalPitch => _globalPitch;
  double get globalRate => _globalRate;
  String get globalLanguage => _globalLanguage;

  /// Dispose des ressources
  Future<void> dispose() async {
    try {
      await stopAllAlerts();
      _flutterTts = null;
      _isInitialized = false;
      debugPrint('🗑️ UnifiedAlertService disposé');
    } catch (e) {
      debugPrint('❌ Erreur lors du dispose: $e');
    }
  }
}