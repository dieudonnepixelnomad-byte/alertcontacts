import 'dart:convert';
import 'package:flutter/material.dart';
import '../../features/app_shell/providers/navigation_provider.dart';

/// Service global pour gérer la navigation depuis les notifications
/// 
/// Ce service permet de naviguer dans l'application depuis les notifications
/// en utilisant un contexte global et le NavigationProvider.
class GlobalNavigationService {
  static BuildContext? _context;
  static NavigationProvider? _navigationProvider;

  /// Définit le contexte global pour la navigation
  static void setContext(BuildContext context) {
    _context = context;
  }

  /// Définit le provider de navigation
  static void setNavigationProvider(NavigationProvider provider) {
    _navigationProvider = provider;
  }

  /// Naviguer vers l'onglet des proches depuis une notification
  static Future<void> navigateToProches() async {
    if (_context == null || _navigationProvider == null) {
      debugPrint('❌ Contexte global ou provider non défini pour la navigation');
      return;
    }

    try {
      // Utiliser le NavigationProvider pour naviguer vers l'onglet des proches
      _navigationProvider!.goToProches();
      debugPrint('✅ Navigation vers l\'onglet des proches réussie');
    } catch (e) {
      debugPrint('❌ Erreur lors de la navigation vers les proches: $e');
    }
  }

  /// Gérer la navigation basée sur le payload de notification
  static Future<void> handleNotificationNavigation(String? payload) async {
    if (payload == null) return;

    try {
      debugPrint('🔄 Gestion de la navigation depuis notification: $payload');
      
      // Décoder le payload JSON
      final Map<String, dynamic> data = {};
      try {
        final decoded = Uri.decodeComponent(payload);
        // Essayer de parser comme JSON
        if (decoded.startsWith('{')) {
          final json = jsonDecode(decoded);
          if (json is Map<String, dynamic>) {
            data.addAll(json);
          }
        }
      } catch (e) {
        debugPrint('⚠️ Impossible de parser le payload comme JSON: $e');
      }

      // Vérifier s'il y a une instruction de navigation
      final navigateTo = data['navigate_to'] as String?;
      
      switch (navigateTo) {
        case 'proches':
          await navigateToProches();
          break;
        default:
          debugPrint('ℹ️ Aucune instruction de navigation spécifique trouvée');
          break;
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la gestion de la navigation: $e');
    }
  }
}