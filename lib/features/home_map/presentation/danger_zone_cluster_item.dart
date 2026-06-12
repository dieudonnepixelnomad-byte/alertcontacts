import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import '../../../core/models/danger_zone.dart';

class DangerZoneClusterItem {
  final DangerZone zone;

  const DangerZoneClusterItem(this.zone);

  gmaps.LatLng get location => gmaps.LatLng(zone.center.lat, zone.center.lng);
}
