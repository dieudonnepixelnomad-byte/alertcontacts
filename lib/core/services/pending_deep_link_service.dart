import 'package:shared_preferences/shared_preferences.dart';

/// Service pour gérer les deep links en attente pour les utilisateurs non authentifiés
class PendingDeepLinkService {
  static const String _tokenKey = 'pending_invitation_token';
  static const String _pinKey = 'pending_invitation_pin';
  static const String _timestampKey = 'pending_invitation_timestamp';
  
  /// TTL de 30 minutes en millisecondes
  static const int _ttlMilliseconds = 30 * 60 * 1000;

  /// Sauvegarde un token d'invitation en attente avec timestamp
  static Future<void> savePendingInvitationToken(String token, {String? pin}) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    await prefs.setString(_tokenKey, token);
    await prefs.setInt(_timestampKey, timestamp);
    
    if (pin != null) {
      await prefs.setString(_pinKey, pin);
    } else {
      await prefs.remove(_pinKey);
    }
  }

  /// Récupère le token d'invitation en attente s'il n'a pas expiré
  static Future<String?> getPendingInvitationToken() async {
    final prefs = await SharedPreferences.getInstance();
    
    final token = prefs.getString(_tokenKey);
    final timestamp = prefs.getInt(_timestampKey);
    
    if (token == null || timestamp == null) {
      return null;
    }
    
    // Vérifier l'expiration
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - timestamp > _ttlMilliseconds) {
      // Token expiré, on le supprime
      await clearPendingDeepLink();
      return null;
    }
    
    return token;
  }

  /// Récupère le PIN d'invitation en attente s'il n'a pas expiré
  static Future<String?> getPendingInvitationPin() async {
    final prefs = await SharedPreferences.getInstance();
    
    final pin = prefs.getString(_pinKey);
    final timestamp = prefs.getInt(_timestampKey);
    
    if (pin == null || timestamp == null) {
      return null;
    }
    
    // Vérifier l'expiration
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - timestamp > _ttlMilliseconds) {
      // Token expiré, on le supprime
      await clearPendingDeepLink();
      return null;
    }
    
    return pin;
  }

  /// Vérifie s'il y a un deep link en attente et non expiré
  static Future<bool> hasPendingDeepLink() async {
    final token = await getPendingInvitationToken();
    return token != null;
  }

  /// Supprime tous les deep links en attente
  static Future<void> clearPendingDeepLink() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_pinKey);
    await prefs.remove(_timestampKey);
  }

  /// Récupère les informations complètes du deep link en attente
  static Future<Map<String, String>?> getPendingDeepLinkData() async {
    final token = await getPendingInvitationToken();
    if (token == null) {
      return null;
    }
    
    final pin = await getPendingInvitationPin();
    
    return {
      'token': token,
      if (pin != null) 'pin': pin,
    };
  }

  /// Nettoie automatiquement les tokens expirés (à appeler au démarrage de l'app)
  static Future<void> cleanupExpiredTokens() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_timestampKey);
    
    if (timestamp != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - timestamp > _ttlMilliseconds) {
        await clearPendingDeepLink();
      }
    }
  }
}