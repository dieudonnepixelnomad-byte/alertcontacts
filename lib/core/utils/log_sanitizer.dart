/// Utilitaire générique pour masquer les données sensibles (RGPD) dans les logs.
class LogSanitizer {
  // Liste des clés sensibles (insensible à la casse)
  static const _sensitiveKeys = [
    'password',
    'token',
    'api_key',
    'secret',
    'email',
    'card',
    'credit_card',
    'ssn',
    'phone',
    'authorization',
  ];

  /// Nettoie une Map de données en masquant les valeurs sensibles.
  static Map<String, dynamic> sanitize(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};

    data.forEach((key, value) {
      final lowerKey = key.toLowerCase();

      if (_sensitiveKeys.any((sensitive) => lowerKey.contains(sensitive))) {
        sanitized[key] = _maskValue(value);
      } else if (value is Map) {
        sanitized[key] = sanitize(Map<String, dynamic>.from(value));
      } else if (value is List) {
        sanitized[key] = value.map((item) {
          if (item is Map) {
            return sanitize(Map<String, dynamic>.from(item));
          }
          return item;
        }).toList();
      } else {
        sanitized[key] = value;
      }
    });

    return sanitized;
  }

  static String _maskValue(dynamic value) {
    if (value == null) return 'null';
    final strVal = value.toString();
    if (strVal.isEmpty) return '*****';

    if (strVal.length <= 4) return '****';

    // Masquage intelligent: garde le premier et dernier caractère
    return '${strVal[0]}***${strVal[strVal.length - 1]}';
  }
}
