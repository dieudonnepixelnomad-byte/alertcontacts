// lib/core/fakes/fake_contacts_repository.dart
import '../models/proche.dart';

class FakeContactsRepository {
  // jeu de données fake
  final _items = <Proche>[
    const Proche(id: 'u1', name: 'Marie'),
    const Proche(id: 'u2', name: 'Paul'),
    const Proche(id: 'u3', name: 'Lucas'),
  ];

  Future<List<Proche>> listProches() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _items;
  }
}
