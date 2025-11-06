// lib/core/services/share_service.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum ShareContext {
  general,
  afterPositiveFeedback,
  fromSettings,
  afterSuccessfulZoneCreation,
  afterInvitingContact,
}

class ShareService {
  static const String _appName = 'AlertContact';
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.alertcontacts.app';
  static const String _appStoreUrl =
      'https://apps.apple.com/app/alertcontact/id123456789';
  static const String _websiteUrl = 'https://alertcontacts.net';

  /// Partage l'application avec un message adapté au contexte
  static Future<void> shareApp({
    required BuildContext context,
    ShareContext shareContext = ShareContext.general,
    String? customMessage,
  }) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = packageInfo.version;

      final shareData = _getShareData(
        context: shareContext,
        appVersion: appVersion,
        customMessage: customMessage,
      );

      // Partager avec position si possible (pour les réseaux sociaux)
      final box = context.findRenderObject() as RenderBox?;
      final sharePositionOrigin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null;

      await Share.share(
        shareData.text,
        subject: shareData.subject,
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      debugPrint('Erreur lors du partage: $e');
      // Fallback en cas d'erreur
      await _shareBasic(context);
    }
  }

  /// Partage avec des statistiques personnalisées (pour les utilisateurs premium)
  static Future<void> shareWithStats({
    required BuildContext context,
    required int zonesCreated,
    required int contactsProtected,
    required int alertsReceived,
  }) async {
    final statsMessage =
        '''
🛡️ $_appName - Mon bilan sécurité

Grâce à $_appName, j'ai :
• Créé $zonesCreated zones de sécurité
• Protégé $contactsProtected proches
• Reçu $alertsReceived alertes importantes

Cette app m'aide à protéger ma famille au quotidien !

📱 Téléchargez-la aussi :
${_getStoreUrl()}

#AlertContact #Sécurité #Protection #Famille
''';

    await Share.share(
      statsMessage,
      subject: 'Mon bilan sécurité avec $_appName',
    );
  }

  /// Partage une zone de danger spécifique
  static Future<void> shareDangerZone({
    required BuildContext context,
    required String zoneName,
    required String zoneType,
    required String location,
  }) async {
    final message =
        '''
⚠️ Alerte sécurité - $_appName

Zone dangereuse signalée :
📍 $location
🚨 Type: $zoneType
📝 Nom: $zoneName

Restez vigilant dans cette zone !

Téléchargez $_appName pour être alerté des zones à risque :
${_getStoreUrl()}

#AlertContact #Sécurité #Alerte
''';

    await Share.share(message, subject: 'Alerte zone dangereuse - $_appName');
  }

  /// Partage une invitation à rejoindre un réseau de sécurité
  static Future<void> shareInvitation({
    required BuildContext context,
    required String inviterName,
    required String invitationLink,
  }) async {
    // Vérifier si c'est un lien localhost (environnement de développement)
    final isLocalhost = invitationLink.contains('localhost') || 
                       invitationLink.contains('127.0.0.1') || 
                       invitationLink.contains('10.0.2.2');
    
    final message = isLocalhost ? '''
🔗 Invitation AlertContact (Version Développement)

Vous êtes invité(e) à rejoindre mon réseau de sécurité AlertContact.

📱 Valide jusqu'au ${_formatExpirationDate()}
👥 Utilisations: 1 seule utilisation

⚠️ LIEN DE DÉVELOPPEMENT LOCAL :
Ce lien ne fonctionne que sur le même réseau WiFi.

📋 Pour accepter l'invitation :
1. Copiez ce lien : $invitationLink
2. Ouvrez l'app AlertContact sur votre téléphone
3. Collez le lien dans l'app

📲 Téléchargez AlertContact :
• Android: https://play.google.com/store/apps/details?id=com.alertcontact.app
• iOS: https://apps.apple.com/app/alertcontact/id123456789
'''.trim() : '''
🔗 Invitation AlertContact

Vous êtes invité(e) à rejoindre mon réseau de sécurité AlertContact.

📱 Valide jusqu'au ${_formatExpirationDate()}
👥 Utilisations: 1 seule utilisation

👆 Cliquez sur le lien pour accepter :

$invitationLink

📲 Téléchargez AlertContact :
• Android: https://play.google.com/store/apps/details?id=com.alertcontact.app
• iOS: https://apps.apple.com/app/alertcontact/id123456789
'''.trim();

    await Share.share(
      message,
      subject: '$inviterName vous invite sur $_appName',
    );
  }

  /// Formate la date d'expiration (7 jours à partir d'aujourd'hui)
  static String _formatExpirationDate() {
    final expirationDate = DateTime.now().add(const Duration(days: 7));
    final months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${expirationDate.day} ${months[expirationDate.month - 1]} ${expirationDate.year}';
  }

  /// Données de partage selon le contexte
  static ShareData _getShareData({
    required ShareContext context,
    required String appVersion,
    String? customMessage,
  }) {
    if (customMessage != null) {
      return ShareData(text: customMessage, subject: 'Découvrez $_appName');
    }

    switch (context) {
      case ShareContext.afterPositiveFeedback:
        return ShareData(
          text:
              '''
🌟 Je recommande $_appName !

Cette app de sécurité personnelle est fantastique ! Elle m'alerte des zones dangereuses et me permet de protéger mes proches en temps réel.

Interface intuitive, notifications intelligentes, vraiment utile au quotidien !

📱 Téléchargez-la :
${_getStoreUrl()}

#AlertContact #Sécurité #Recommandation
''',
          subject: 'Je recommande $_appName - App de sécurité',
        );

      case ShareContext.afterSuccessfulZoneCreation:
        return ShareData(
          text:
              '''
🛡️ Zone de sécurité créée avec $_appName !

Je viens de configurer une zone de sécurité pour protéger mes proches. Maintenant je serai alerté s'ils entrent ou sortent de cette zone.

C'est rassurant de pouvoir veiller sur sa famille comme ça !

📱 Protégez vos proches aussi :
${_getStoreUrl()}

#AlertContact #Sécurité #Famille
''',
          subject: 'Protection familiale avec $_appName',
        );

      case ShareContext.afterInvitingContact:
        return ShareData(
          text:
              '''
👥 Réseau de sécurité étendu avec $_appName !

Je viens d'inviter un proche à rejoindre mon réseau de sécurité. Plus on est nombreux, plus on est en sécurité !

L'app permet de créer un vrai réseau de protection mutuelle.

📱 Rejoignez le mouvement :
${_getStoreUrl()}

#AlertContact #Sécurité #Communauté
''',
          subject: 'Réseau de sécurité avec $_appName',
        );

      case ShareContext.fromSettings:
        return ShareData(
          text:
              '''
🛡️ $_appName - Sécurité personnelle

Application indispensable pour protéger ses proches ! Alertes zones dangereuses, géolocalisation sécurisée, notifications intelligentes.

Simple, efficace, rassurant.

📱 Téléchargez maintenant :
${_getStoreUrl()}

#AlertContact #Sécurité #Protection
''',
          subject: 'Découvrez $_appName - Sécurité personnelle',
        );

      case ShareContext.general:
      default:
        return ShareData(
          text:
              '''
🛡️ $_appName - Protégez vos proches

L'application de sécurité personnelle qui vous alerte des zones dangereuses et vous permet de surveiller vos proches en temps réel.

✅ Zones de sécurité personnalisées
✅ Alertes intelligentes
✅ Protection familiale
✅ Interface intuitive

📱 Téléchargez maintenant :
${_getStoreUrl()}

#AlertContact #Sécurité #Protection #Famille
''',
          subject: 'Découvrez $_appName - Application de sécurité',
        );
    }
  }

  /// URL du store selon la plateforme
  static String _getStoreUrl() {
    if (Platform.isIOS) {
      return _appStoreUrl;
    } else if (Platform.isAndroid) {
      return _playStoreUrl;
    } else {
      return _websiteUrl;
    }
  }

  /// Partage basique en cas d'erreur
  static Future<void> _shareBasic(BuildContext context) async {
    const message =
        '''
🛡️ $_appName - Sécurité personnelle

Protégez vos proches avec cette application de sécurité !

📱 Téléchargez : $_websiteUrl
''';

    await Share.share(message);
  }
}

/// Données de partage
class ShareData {
  final String text;
  final String subject;

  const ShareData({required this.text, required this.subject});
}
