import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'pending_deep_link_service.dart';
import 'prefs_service.dart';

class DeepLinkService {
  static const MethodChannel _channel = MethodChannel('alertcontact/deep_links');
  static StreamSubscription<String>? _linkSubscription;
  
  /// Initialise le service de deep links
  static Future<void> initialize(GoRouter router) async {
    try {
      log('Initialisation du DeepLinkService');
      
      // Configurer le MethodChannel
      _channel.setMethodCallHandler((call) async {
        switch (call.method) {
          case 'onDeepLink':
            final url = call.arguments as String?;
            if (url != null) {
              log('Deep link reçu via MethodChannel: $url');
              await _processDeepLink(url, router);
            }
            break;
          default:
            log('Méthode non supportée: ${call.method}');
        }
      });

      // Vérifier s'il y a un lien initial
      try {
        final initialLink = await _channel.invokeMethod<String>('getInitialLink');
        if (initialLink != null && initialLink.isNotEmpty) {
          log('Lien initial trouvé: $initialLink');
          await _processDeepLink(initialLink, router);
        } else {
          log('Aucun lien initial trouvé');
        }
      } catch (e) {
        log('Erreur lors de la récupération du lien initial: $e');
      }
    } catch (e) {
      log('Erreur lors de l\'initialisation du DeepLinkService: $e');
    }
  }
  
  /// Traite un deep link reçu
  static Future<void> _processDeepLink(String link, GoRouter router) async {
    try {
      log('Deep link reçu: $link');
      debugPrint('🔗 DEEP LINK REÇU: $link');
      
      final uri = Uri.parse(link);
      
      // Gérer les liens alertcontact://
      if (uri.scheme == 'alertcontact') {
        await _handleAlertContactLink(uri, router);
      } else {
        log('Schéma de deep link non supporté: ${uri.scheme}');
      }
    } catch (e) {
      log('Erreur lors du traitement du deep link: $e');
    }
  }
  
  /// Traite les liens alertcontact://
  static Future<void> _handleAlertContactLink(Uri uri, GoRouter router) async {
    try {
      log('Traitement du lien AlertContact: $uri');
      log('Host: ${uri.host}, Path segments: ${uri.pathSegments}');
      
      // Supporter les deux formats :
      // alertcontact://invitations/accept?t=TOKEN (format complet)
      // alertcontact://invitation?t=TOKEN (format simplifié)
      bool isInvitationLink = false;
      
      if (uri.host == 'invitations' && uri.pathSegments.isNotEmpty && uri.pathSegments[0] == 'accept') {
        isInvitationLink = true;
      } else if (uri.host == 'invitation') {
        isInvitationLink = true;
      }
      
      if (isInvitationLink) {
        final token = uri.queryParameters['t'];
        final pin = uri.queryParameters['pin'];
        
        if (token != null && token.isNotEmpty) {
          log('Traitement invitation avec token: $token');
          await _handleInvitationLink(token, pin, router);
          return;
        } else {
          log('Token manquant dans le deep link');
        }
      }
      
      log('Deep link AlertContact non supporté: $uri');
    } catch (e) {
      log('Erreur lors du traitement du lien AlertContact: $e');
    }
  }
  
  /// Traite un lien d'invitation en vérifiant l'authentification
  static Future<void> _handleInvitationLink(String token, String? pin, GoRouter router) async {
    try {
      log('Vérification de l\'authentification pour l\'invitation');
      
      // Vérifier si l'utilisateur est authentifié
      final prefsService = PrefsService();
      final bearerToken = await prefsService.getBearerToken();
      final isAuthenticated = bearerToken != null && bearerToken.isNotEmpty;
      
      if (isAuthenticated) {
        log('Utilisateur authentifié, redirection directe vers l\'invitation');
        
        // Construire l'URL de redirection
        String redirectUrl = '/invitations/accept?t=$token';
        if (pin != null && pin.isNotEmpty) {
          redirectUrl += '&pin=$pin';
        }
        
        log('URL de redirection: $redirectUrl');
        debugPrint('🔗 DEEP LINK: Navigation vers $redirectUrl');
        router.go(redirectUrl);
      } else {
        log('Utilisateur non authentifié, mémorisation du token et redirection vers auth');
        
        // Mémoriser le token d'invitation
        await PendingDeepLinkService.savePendingInvitationToken(token, pin: pin);
        
        log('Token d\'invitation mémorisé, redirection vers login');
        
        // Rediriger vers la page de connexion
        router.go('/auth');
      }
    } catch (e) {
      log('Erreur lors du traitement de l\'invitation: $e');
      // En cas d'erreur, rediriger vers l'accueil
      router.go('/');
    }
  }
  
  /// Rejoue un deep link en attente après authentification
  static Future<void> replayPendingDeepLink(GoRouter router) async {
    try {
      log('Vérification des deep links en attente');
      
      final pendingData = await PendingDeepLinkService.getPendingDeepLinkData();
      if (pendingData != null) {
        final token = pendingData['token']!;
        final pin = pendingData['pin'];
        
        log('Deep link en attente trouvé: $token');
        
        // Construire l'URL de redirection
        String redirectUrl = '/invitations/accept?t=$token';
        if (pin != null && pin.isNotEmpty) {
          redirectUrl += '&pin=$pin';
        }
        
        log('Rejeu du deep link: $redirectUrl');
        
        // Nettoyer le deep link en attente
        await PendingDeepLinkService.clearPendingDeepLink();
        
        // Attendre un peu pour que l'authentification soit complètement terminée
        await Future.delayed(const Duration(milliseconds: 500));
        router.go(redirectUrl);
      } else {
        log('Aucun deep link en attente');
      }
    } catch (e) {
      log('Erreur lors du rejeu du deep link: $e');
    }
  }
  
  /// Nettoie les ressources
  static void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }
}