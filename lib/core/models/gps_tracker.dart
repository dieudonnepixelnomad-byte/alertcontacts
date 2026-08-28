class GpsTracker {
  final int id;
  final String name;
  final String status;
  final int? batteryLevel;
  final DateTime? lastPositionAt;
  final DateTime? lastSeenAt;

  const GpsTracker({required this.id, required this.name, required this.status, this.batteryLevel, this.lastPositionAt, this.lastSeenAt});

  factory GpsTracker.fromJson(Map<String, dynamic> json) => GpsTracker(
    id: json['id'] as int,
    name: json['name'] as String,
    status: json['status'] as String? ?? 'draft',
    batteryLevel: (json['battery_level'] as num?)?.toInt(),
    lastPositionAt: json['last_position_at'] == null ? null : DateTime.tryParse(json['last_position_at'] as String),
    lastSeenAt: json['last_seen_at'] == null ? null : DateTime.tryParse(json['last_seen_at'] as String),
  );
}

class TrackerCapabilities {
  const TrackerCapabilities({
    required this.isPremium,
    required this.trackerLimit,
    required this.locationIntervalHours,
    required this.realtimeLocation,
    required this.locationHistory,
    required this.safeZones,
    required this.zoneAlerts,
  });

  final bool isPremium;
  final int? trackerLimit;
  final int? locationIntervalHours;
  final bool realtimeLocation;
  final bool locationHistory;
  final bool safeZones;
  final bool zoneAlerts;

  factory TrackerCapabilities.fromJson(Map<String, dynamic> json) {
    return TrackerCapabilities(
      isPremium: json['is_premium'] as bool? ?? false,
      trackerLimit: (json['tracker_limit'] as num?)?.toInt(),
      locationIntervalHours:
          (json['location_interval_hours'] as num?)?.toInt(),
      realtimeLocation: json['realtime_location'] as bool? ?? false,
      locationHistory: json['location_history'] as bool? ?? false,
      safeZones: json['safe_zones'] as bool? ?? false,
      zoneAlerts: json['zone_alerts'] as bool? ?? false,
    );
  }
}

class GpsTrackerList {
  const GpsTrackerList({required this.trackers, required this.capabilities});

  final List<GpsTracker> trackers;
  final TrackerCapabilities capabilities;
}
