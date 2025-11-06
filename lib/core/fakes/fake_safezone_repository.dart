// lib/core/fakes/fake_safezone_repository.dart
import 'dart:math';
import '../models/safe_zone.dart';

class FakeSafeZoneRepository {
  final _items = <SafeZone>[];

  Future<SafeZone> create(SafeZone zone) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final id =
        'sz_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}';
    final created = SafeZone(
      id: id,
      name: zone.name,
      iconKey: zone.iconKey,
      center: zone.center,
      radiusMeters: zone.radiusMeters,
      address: zone.address,
      memberIds: zone.memberIds,
    );
    _items.add(created);
    return created;
  }

  Future<List<SafeZone>> list() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_items);
  }
}
