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
  static Map<String, dynamic>? _pendingNotificationData;

  /// Définit le contexte global pour la navigation
  static void setContext(BuildContext context) {
    _context = context;
  }

  /// Définit le provider de navigation
  static void setNavigationProvider(NavigationProvider provider) {
    _navigationProvider = provider;
    final pendingData = _pendingNotificationData;
    if (pendingData != null) {
      _pendingNotificationData = null;
      Future.microtask(() => handleNotificationData(pendingData));
    }
  }

  /// Naviguer vers l'onglet des proches depuis une notification
  static Future<void> navigateToProches() async {
    if (_navigationProvider == null) {
      debugPrint('❌ NavigationProvider non défini pour la navigation');
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

  /// Naviguer vers l'onglet des alertes depuis une notification.
  static Future<void> navigateToAlertes() async {
    if (_navigationProvider == null) {
      debugPrint('❌ NavigationProvider non défini pour la navigation');
      return;
    }

    _navigationProvider!.goToAlertes();
    debugPrint('✅ Navigation vers l\'onglet des alertes réussie');
  }

  /// Ouvre l'onglet Carte et centre sa caméra sur une position précise.
  ///
  /// Ce point d'entrée est aussi utilisable depuis une route poussée au-dessus
  /// de l'AppShell, dont le BuildContext ne contient pas NavigationProvider.
  static void navigateToMapLocation({required double lat, required double lng}) {
    if (_navigationProvider == null) {
      debugPrint('❌ NavigationProvider non défini pour la navigation vers la carte');
      return;
    }

    _navigationProvider!.focusLocation(lat: lat, lng: lng);
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

      await handleNotificationData(data);
    } catch (e) {
      debugPrint('❌ Erreur lors de la gestion de la navigation: $e');
    }
  }

  /// Traite directement les données FCM, y compris si l'app n'a pas encore
  /// construit son AppShell (cas d'un lancement depuis une notification).
  static Future<void> handleNotificationData(Map<String, dynamic> data) async {
    if (_navigationProvider == null) {
      _pendingNotificationData = Map<String, dynamic>.from(data);
      debugPrint('ℹ️ Navigation de notification différée : AppShell indisponible');
      return;
    }

    switch (data['navigate_to'] as String?) {
      case 'proches':
        await navigateToProches();
        break;
      case 'alertes':
      // Il n'existe pas de page autonome de prévisualisation sans une recherche
      // d'itinéraire. L'onglet Alertes est la destination utile de repli.
      case 'route_preview':
        await navigateToAlertes();
        break;
      default:
        debugPrint('ℹ️ Aucune instruction de navigation spécifique trouvée');
    }
  }
}
