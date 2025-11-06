// lib/features/alertes/services/consent_service.dart
import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de gestion du consentement explicite pour le partage de localisation
/// UC-N01: Système de consentement explicite
class ConsentService {
  static final ConsentService _instance = ConsentService._internal();
  factory ConsentService() => _instance;
  ConsentService._internal();

  static const String _keyGlobalConsent = 'global_location_sharing_consent';
  static const String _keyContactConsents = 'contact_location_sharing_consents';
  static const String _keyConsentHistory = 'consent_history';
  static const String _keyDataProcessingConsent = 'data_processing_consent';
  static const String _keyAnalyticsConsent = 'analytics_consent';
  static const String _keyConsentVersion = 'consent_version';

  static const int _currentConsentVersion = 1;

  /// Vérifier si le consentement global est accordé
  Future<bool> hasGlobalLocationSharingConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyGlobalConsent) ?? false;
    } catch (e) {
      log('ConsentService: Error checking global consent: $e');
      return false;
    }
  }

  /// Accorder ou révoquer le consentement global
  Future<void> setGlobalLocationSharingConsent(bool granted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyGlobalConsent, granted);
      
      // Enregistrer dans l'historique
      await _recordConsentChange(
        type: ConsentType.globalLocationSharing,
        granted: granted,
        reason: granted ? 'User granted global consent' : 'User revoked global consent',
      );

      // Si le consentement global est révoqué, révoquer tous les consentements individuels
      if (!granted) {
        await _revokeAllContactConsents();
      }

      log('ConsentService: Global location sharing consent set to $granted');
    } catch (e) {
      log('ConsentService: Error setting global consent: $e');
    }
  }

  /// Vérifier le consentement pour un contact spécifique
  Future<bool> hasContactLocationSharingConsent(String contactId) async {
    try {
      // Vérifier d'abord le consentement global
      if (!await hasGlobalLocationSharingConsent()) {
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final consentsJson = prefs.getString(_keyContactConsents);
      
      if (consentsJson == null) return false;

      final consents = Map<String, dynamic>.from(jsonDecode(consentsJson));
      final contactConsent = consents[contactId] as Map<String, dynamic>?;
      
      if (contactConsent == null) return false;

      return contactConsent['granted'] as bool? ?? false;
    } catch (e) {
      log('ConsentService: Error checking contact consent: $e');
      return false;
    }
  }

  /// Accorder ou révoquer le consentement pour un contact spécifique
  Future<void> setContactLocationSharingConsent({
    required String contactId,
    required String contactName,
    required bool granted,
    String? reason,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Charger les consentements existants
      final consentsJson = prefs.getString(_keyContactConsents);
      final consents = consentsJson != null 
          ? Map<String, dynamic>.from(jsonDecode(consentsJson))
          : <String, dynamic>{};

      // Mettre à jour le consentement pour ce contact
      consents[contactId] = {
        'granted': granted,
        'contactName': contactName,
        'timestamp': DateTime.now().toIso8601String(),
        'reason': reason ?? (granted ? 'User granted consent' : 'User revoked consent'),
      };

      // Sauvegarder
      await prefs.setString(_keyContactConsents, jsonEncode(consents));

      // Enregistrer dans l'historique
      await _recordConsentChange(
        type: ConsentType.contactLocationSharing,
        granted: granted,
        contactId: contactId,
        contactName: contactName,
        reason: reason,
      );

      log('ConsentService: Contact consent for $contactName set to $granted');
    } catch (e) {
      log('ConsentService: Error setting contact consent: $e');
    }
  }

  /// Obtenir la liste des contacts avec consentement accordé
  Future<List<ContactConsent>> getContactsWithConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final consentsJson = prefs.getString(_keyContactConsents);
      
      if (consentsJson == null) return [];

      final consents = Map<String, dynamic>.from(jsonDecode(consentsJson));
      final result = <ContactConsent>[];

      for (final entry in consents.entries) {
        final contactData = entry.value as Map<String, dynamic>;
        if (contactData['granted'] as bool? ?? false) {
          result.add(ContactConsent(
            contactId: entry.key,
            contactName: contactData['contactName'] as String,
            grantedAt: DateTime.parse(contactData['timestamp'] as String),
            reason: contactData['reason'] as String?,
          ));
        }
      }

      return result;
    } catch (e) {
      log('ConsentService: Error getting contacts with consent: $e');
      return [];
    }
  }

  /// Révoquer tous les consentements de contacts
  Future<void> _revokeAllContactConsents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyContactConsents);
      
      await _recordConsentChange(
        type: ConsentType.allContactsRevoked,
        granted: false,
        reason: 'Global consent revoked - all contact consents removed',
      );

      log('ConsentService: All contact consents revoked');
    } catch (e) {
      log('ConsentService: Error revoking all contact consents: $e');
    }
  }

  /// Vérifier le consentement pour le traitement des données
  Future<bool> hasDataProcessingConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyDataProcessingConsent) ?? false;
    } catch (e) {
      log('ConsentService: Error checking data processing consent: $e');
      return false;
    }
  }

  /// Accorder ou révoquer le consentement pour le traitement des données
  Future<void> setDataProcessingConsent(bool granted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDataProcessingConsent, granted);
      
      await _recordConsentChange(
        type: ConsentType.dataProcessing,
        granted: granted,
        reason: granted ? 'User granted data processing consent' : 'User revoked data processing consent',
      );

      log('ConsentService: Data processing consent set to $granted');
    } catch (e) {
      log('ConsentService: Error setting data processing consent: $e');
    }
  }

  /// Vérifier le consentement pour l'analytics
  Future<bool> hasAnalyticsConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyAnalyticsConsent) ?? false;
    } catch (e) {
      log('ConsentService: Error checking analytics consent: $e');
      return false;
    }
  }

  /// Accorder ou révoquer le consentement pour l'analytics
  Future<void> setAnalyticsConsent(bool granted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAnalyticsConsent, granted);
      
      await _recordConsentChange(
        type: ConsentType.analytics,
        granted: granted,
        reason: granted ? 'User granted analytics consent' : 'User revoked analytics consent',
      );

      log('ConsentService: Analytics consent set to $granted');
    } catch (e) {
      log('ConsentService: Error setting analytics consent: $e');
    }
  }

  /// Enregistrer un changement de consentement dans l'historique
  Future<void> _recordConsentChange({
    required ConsentType type,
    required bool granted,
    String? contactId,
    String? contactName,
    String? reason,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_keyConsentHistory);
      
      final history = historyJson != null 
          ? List<Map<String, dynamic>>.from(jsonDecode(historyJson))
          : <Map<String, dynamic>>[];

      final entry = {
        'type': type.name,
        'granted': granted,
        'timestamp': DateTime.now().toIso8601String(),
        'reason': reason,
        'contactId': contactId,
        'contactName': contactName,
        'version': _currentConsentVersion,
      };

      history.add(entry);

      // Garder seulement les 100 dernières entrées
      if (history.length > 100) {
        history.removeRange(0, history.length - 100);
      }

      await prefs.setString(_keyConsentHistory, jsonEncode(history));
    } catch (e) {
      log('ConsentService: Error recording consent change: $e');
    }
  }

  /// Obtenir l'historique des consentements
  Future<List<ConsentHistoryEntry>> getConsentHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_keyConsentHistory);
      
      if (historyJson == null) return [];

      final history = List<Map<String, dynamic>>.from(jsonDecode(historyJson));
      
      return history.map((entry) => ConsentHistoryEntry(
        type: ConsentType.values.firstWhere(
          (t) => t.name == entry['type'],
          orElse: () => ConsentType.unknown,
        ),
        granted: entry['granted'] as bool,
        timestamp: DateTime.parse(entry['timestamp'] as String),
        reason: entry['reason'] as String?,
        contactId: entry['contactId'] as String?,
        contactName: entry['contactName'] as String?,
        version: entry['version'] as int? ?? 1,
      )).toList();
    } catch (e) {
      log('ConsentService: Error getting consent history: $e');
      return [];
    }
  }

  /// Obtenir un rapport complet des consentements
  Future<ConsentReport> getConsentReport() async {
    return ConsentReport(
      globalLocationSharing: await hasGlobalLocationSharingConsent(),
      dataProcessing: await hasDataProcessingConsent(),
      analytics: await hasAnalyticsConsent(),
      contactsWithConsent: await getContactsWithConsent(),
      consentHistory: await getConsentHistory(),
      version: _currentConsentVersion,
    );
  }

  /// Exporter les données de consentement (RGPD)
  Future<Map<String, dynamic>> exportConsentData() async {
    final report = await getConsentReport();
    
    return {
      'globalLocationSharing': report.globalLocationSharing,
      'dataProcessing': report.dataProcessing,
      'analytics': report.analytics,
      'contactsWithConsent': report.contactsWithConsent.map((c) => c.toJson()).toList(),
      'consentHistory': report.consentHistory.map((h) => h.toJson()).toList(),
      'version': report.version,
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Supprimer toutes les données de consentement
  Future<void> deleteAllConsentData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyGlobalConsent);
      await prefs.remove(_keyContactConsents);
      await prefs.remove(_keyConsentHistory);
      await prefs.remove(_keyDataProcessingConsent);
      await prefs.remove(_keyAnalyticsConsent);
      await prefs.remove(_keyConsentVersion);

      log('ConsentService: All consent data deleted');
    } catch (e) {
      log('ConsentService: Error deleting consent data: $e');
    }
  }

  /// Vérifier si une mise à jour du consentement est nécessaire
  Future<bool> isConsentUpdateRequired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedVersion = prefs.getInt(_keyConsentVersion) ?? 0;
      return storedVersion < _currentConsentVersion;
    } catch (e) {
      log('ConsentService: Error checking consent version: $e');
      return false;
    }
  }

  /// Marquer la version du consentement comme à jour
  Future<void> markConsentVersionUpdated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyConsentVersion, _currentConsentVersion);
    } catch (e) {
      log('ConsentService: Error updating consent version: $e');
    }
  }
}

/// Types de consentement
enum ConsentType {
  globalLocationSharing,
  contactLocationSharing,
  dataProcessing,
  analytics,
  allContactsRevoked,
  unknown,
}

/// Consentement d'un contact
class ContactConsent {
  final String contactId;
  final String contactName;
  final DateTime grantedAt;
  final String? reason;

  ContactConsent({
    required this.contactId,
    required this.contactName,
    required this.grantedAt,
    this.reason,
  });

  Map<String, dynamic> toJson() => {
    'contactId': contactId,
    'contactName': contactName,
    'grantedAt': grantedAt.toIso8601String(),
    'reason': reason,
  };
}

/// Entrée d'historique de consentement
class ConsentHistoryEntry {
  final ConsentType type;
  final bool granted;
  final DateTime timestamp;
  final String? reason;
  final String? contactId;
  final String? contactName;
  final int version;

  ConsentHistoryEntry({
    required this.type,
    required this.granted,
    required this.timestamp,
    this.reason,
    this.contactId,
    this.contactName,
    required this.version,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'granted': granted,
    'timestamp': timestamp.toIso8601String(),
    'reason': reason,
    'contactId': contactId,
    'contactName': contactName,
    'version': version,
  };
}

/// Rapport complet des consentements
class ConsentReport {
  final bool globalLocationSharing;
  final bool dataProcessing;
  final bool analytics;
  final List<ContactConsent> contactsWithConsent;
  final List<ConsentHistoryEntry> consentHistory;
  final int version;

  ConsentReport({
    required this.globalLocationSharing,
    required this.dataProcessing,
    required this.analytics,
    required this.contactsWithConsent,
    required this.consentHistory,
    required this.version,
  });

  bool get hasAllRequiredConsents => globalLocationSharing && dataProcessing;
  bool get hasOptionalConsents => analytics;
  int get activeContactConsents => contactsWithConsent.length;
}