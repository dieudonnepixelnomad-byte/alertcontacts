import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Service pour détecter le type d'appareil et l'environnement d'exécution
class DeviceDetectionService {
  static DeviceDetectionService? _instance;
  static DeviceDetectionService get instance => _instance ??= DeviceDetectionService._();
  
  DeviceDetectionService._();

  bool? _isEmulator;
  bool? _isPhysicalDevice;
  String? _deviceModel;
  String? _deviceManufacturer;

  /// Détecte si l'app s'exécute sur un émulateur Android
  Future<bool> isAndroidEmulator() async {
    if (_isEmulator != null) return _isEmulator!;

    if (!Platform.isAndroid) {
      _isEmulator = false;
      return false;
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      // Méthodes de détection d'émulateur Android
      final isEmulator = _checkEmulatorIndicators(androidInfo);
      
      _isEmulator = isEmulator;
      _isPhysicalDevice = !isEmulator;
      _deviceModel = androidInfo.model;
      _deviceManufacturer = androidInfo.manufacturer;

      if (kDebugMode) {
        print('🔍 Device Detection:');
        print('  Model: ${androidInfo.model}');
        print('  Manufacturer: ${androidInfo.manufacturer}');
        print('  Product: ${androidInfo.product}');
        print('  Device: ${androidInfo.device}');
        print('  Hardware: ${androidInfo.hardware}');
        print('  Is Physical Device: ${androidInfo.isPhysicalDevice}');
        print('  Is Emulator: $isEmulator');
      }

      return isEmulator;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la détection d\'émulateur: $e');
      }
      // En cas d'erreur, on assume que c'est un appareil physique
      _isEmulator = false;
      return false;
    }
  }

  /// Vérifie les indicateurs d'émulateur
  bool _checkEmulatorIndicators(AndroidDeviceInfo androidInfo) {
    // Vérification via isPhysicalDevice (le plus fiable)
    if (!androidInfo.isPhysicalDevice) {
      return true;
    }

    // Vérifications supplémentaires pour plus de robustesse
    final model = androidInfo.model.toLowerCase();
    final manufacturer = androidInfo.manufacturer.toLowerCase();
    final product = androidInfo.product.toLowerCase();
    final device = androidInfo.device.toLowerCase();
    final hardware = androidInfo.hardware.toLowerCase();

    // Indicateurs d'émulateur Android
    final emulatorIndicators = [
      // Modèles d'émulateur
      'sdk',
      'emulator',
      'simulator',
      'android sdk built for',
      
      // Fabricants d'émulateur
      'google',
      'generic',
      'unknown',
      
      // Produits d'émulateur
      'sdk_gphone',
      'google_sdk',
      'aosp_',
      'sdk_',
      'generic_',
      
      // Hardware d'émulateur
      'goldfish',
      'ranchu',
      'vbox',
      'ttvm',
    ];

    // Vérifier si l'un des indicateurs est présent
    for (final indicator in emulatorIndicators) {
      if (model.contains(indicator) ||
          manufacturer.contains(indicator) ||
          product.contains(indicator) ||
          device.contains(indicator) ||
          hardware.contains(indicator)) {
        return true;
      }
    }

    return false;
  }

  /// Détecte si l'app s'exécute sur un appareil physique
  Future<bool> isPhysicalDevice() async {
    final isEmulator = await isAndroidEmulator();
    return !isEmulator;
  }

  /// Obtient le modèle de l'appareil
  String? get deviceModel => _deviceModel;

  /// Obtient le fabricant de l'appareil
  String? get deviceManufacturer => _deviceManufacturer;

  /// Réinitialise le cache de détection (utile pour les tests)
  void resetCache() {
    _isEmulator = null;
    _isPhysicalDevice = null;
    _deviceModel = null;
    _deviceManufacturer = null;
  }

  /// Obtient des informations détaillées sur l'appareil
  Future<Map<String, dynamic>> getDeviceInfo() async {
    await isAndroidEmulator(); // S'assurer que la détection a été faite

    return {
      'platform': Platform.operatingSystem,
      'isEmulator': _isEmulator ?? false,
      'isPhysicalDevice': _isPhysicalDevice ?? true,
      'model': _deviceModel ?? 'Unknown',
      'manufacturer': _deviceManufacturer ?? 'Unknown',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}