/// Flexible Polyline — format d'encodage de géométrie propre à HERE.
///
/// Portage du décodeur de référence `heremaps/flexible-polyline`.
/// CDC V4.1 §14.1 point 4 : aucune implémentation Dart officielle n'étant
/// publiée, on porte l'algorithme, qui est court et stable.
///
/// Le format encode des deltas en base64url avec un facteur de précision
/// variable, plus une troisième dimension optionnelle — ignorée ici,
/// AlertContacts routant en 2D.
library;

/// Un point géographique décodé, en degrés décimaux.
class PolylinePoint {
  const PolylinePoint(this.lat, this.lng);

  final double lat;
  final double lng;

  @override
  String toString() => 'PolylinePoint($lat, $lng)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolylinePoint && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);
}

class FlexiblePolyline {
  FlexiblePolyline._();

  static const int _version = 1;

  static const String _encodingTable =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

  static Map<String, int>? _decodingTable;

  static Map<String, int> get _table {
    return _decodingTable ??= {
      for (var i = 0; i < _encodingTable.length; i++) _encodingTable[i]: i,
    };
  }

  /// Décode une polyligne HERE.
  ///
  /// Lève [FormatException] si la chaîne est corrompue ou tronquée : une
  /// polyligne illisible ne doit jamais se transformer en tracé silencieusement
  /// faux sur la carte.
  static List<PolylinePoint> decode(String encoded) {
    if (encoded.isEmpty) return const [];

    final values = _decodeUnsignedValues(encoded);

    if (values.length < 2) {
      throw const FormatException('flexible polyline : en-tête absent.');
    }

    final version = values[0];
    if (version != _version) {
      throw FormatException('flexible polyline : version $version non supportée.');
    }

    final header = values[1];
    final precision = header & 15;
    final thirdDim = (header >> 4) & 7;

    final factor = _pow10(precision);
    final stride = thirdDim != 0 ? 3 : 2;

    var lastLat = 0;
    var lastLng = 0;
    final points = <PolylinePoint>[];

    for (var i = 2; i + stride <= values.length; i += stride) {
      lastLat += _toSigned(values[i]);
      lastLng += _toSigned(values[i + 1]);

      points.add(PolylinePoint(lastLat / factor, lastLng / factor));
    }

    return points;
  }

  /// Encode une liste de points. Utile pour les tests et le cache local.
  static String encode(List<PolylinePoint> points, {int precision = 7}) {
    if (points.isEmpty) return '';

    if (precision < 0 || precision > 15) {
      throw ArgumentError.value(precision, 'precision', 'doit être entre 0 et 15');
    }

    final buffer = StringBuffer()
      ..write(_encodeUnsigned(_version))
      ..write(_encodeUnsigned(precision));

    final factor = _pow10(precision);
    var lastLat = 0;
    var lastLng = 0;

    for (final point in points) {
      final lat = (point.lat * factor).round();
      final lng = (point.lng * factor).round();

      buffer
        ..write(_encodeSigned(lat - lastLat))
        ..write(_encodeSigned(lng - lastLng));

      lastLat = lat;
      lastLng = lng;
    }

    return buffer.toString();
  }

  static List<int> _decodeUnsignedValues(String encoded) {
    final values = <int>[];
    var result = 0;
    var shift = 0;

    for (var i = 0; i < encoded.length; i++) {
      final char = encoded[i];
      final value = _table[char];

      if (value == null) {
        throw FormatException('flexible polyline : caractère invalide « $char ».');
      }

      result |= (value & 0x1F) << shift;

      if ((value & 0x20) == 0) {
        values.add(result);
        result = 0;
        shift = 0;
      } else {
        shift += 5;
      }
    }

    if (shift > 0) {
      throw const FormatException('flexible polyline : chaîne tronquée.');
    }

    return values;
  }

  /// Zigzag → entier signé : le bit de poids faible porte le signe.
  static int _toSigned(int value) {
    var result = value;
    if (result & 1 == 1) result = ~result;
    return result >> 1;
  }

  static String _encodeSigned(int value) {
    final unsigned = value < 0 ? ~(value << 1) : (value << 1);
    return _encodeUnsigned(unsigned);
  }

  static String _encodeUnsigned(int value) {
    final buffer = StringBuffer();
    var remaining = value;

    while (remaining > 0x1F) {
      buffer.write(_encodingTable[(remaining & 0x1F) | 0x20]);
      remaining >>= 5;
    }

    buffer.write(_encodingTable[remaining]);
    return buffer.toString();
  }

  static double _pow10(int exponent) {
    var result = 1.0;
    for (var i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }
}
