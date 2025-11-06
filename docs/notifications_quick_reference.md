# Référence Rapide - Services de Notifications Géolocalisées

## Démarrage Rapide

```dart
// 1. Importer le service
import 'package:alertcontacts/features/alertes/services/geolocation_notification_integration_service.dart';

// 2. Obtenir l'instance
final service = GeolocationNotificationIntegrationService();

// 3. Initialiser
await service.initialize();

// 4. Configurer les zones
await service.configureDangerZones(dangerZones);
await service.configureSafeZones(safeZones);

// 5. Démarrer la surveillance
await service.startLocationMonitoring(foregroundMode: true);
```

## API Essentielle

### Initialisation
```dart
await service.initialize();                    // Initialiser le service
service.isReady                               // Vérifier si prêt
service.status                                // État actuel
```

### Configuration
```dart
await service.configureDangerZones(zones);    // Configurer zones dangereuses
await service.configureSafeZones(zones);      // Configurer zones sécurisées
service.setProximityThreshold(150.0);        // Seuil de proximité (mètres)
```

### Surveillance
```dart
await service.startLocationMonitoring(foregroundMode: true);  // Démarrer
await service.stopLocationMonitoring();                      // Arrêter
```

### Analyse
```dart
final analysis = service.analyzeProximity(location, zones);  // Analyser proximité
final summary = service.getProximitySummary();              // Résumé global
```

### Alertes
```dart
await service.testCriticalAlert();                          // Test d'alerte
await service.handleDangerZoneDetection(zone, location);    // Alerte manuelle
await service.canSendNotification();                        // Vérifier capacité
```

### Nettoyage
```dart
await service.dispose();                     // Libérer ressources
```

## États du Service

| État | Description |
|------|-------------|
| `uninitialized` | Non initialisé |
| `initializing` | En cours d'initialisation |
| `ready` | Prêt à utiliser |
| `error` | Erreur |
| `disposed` | Libéré |

## Niveaux de Proximité

| Niveau | Description |
|--------|-------------|
| `safe` | Sécurisé, loin des zones dangereuses |
| `warning` | Avertissement, approche d'une zone |
| `critical` | Critique, très proche d'une zone |
| `inside` | À l'intérieur d'une zone dangereuse |

## Sévérité des Zones Dangereuses

| Sévérité | Description |
|----------|-------------|
| `low` | Risque faible |
| `medium` | Risque moyen |
| `high` | Risque élevé |
| `critical` | Risque critique |

## Exemples de Zones

### Zone Dangereuse
```dart
DangerZone(
  id: 'danger_1',
  name: 'Zone à risque',
  description: 'Zone signalée comme dangereuse',
  center: const LatLng(48.8566, 2.3522),
  radiusMeters: 100,
  severity: DangerSeverity.high,
  confirmations: 5,
  lastReportAt: DateTime.now(),
)
```

### Zone Sécurisée
```dart
SafeZone(
  id: 'safe_1',
  name: 'Maison',
  iconKey: 'home',
  center: const LatLng(48.8566, 2.3522),
  radiusMeters: 50,
  address: '123 Rue de la Paix',
  memberIds: ['user_1'],
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
)
```

## Gestion d'Erreurs

```dart
try {
  await service.initialize();
} catch (e) {
  print('Erreur: $e');
  // Gérer l'erreur
}

// Vérifier l'état
if (service.status == ServiceStatus.error) {
  // Réinitialiser
  await service.initialize();
}
```

## Optimisations

### Batterie
```dart
// Mode arrière-plan pour économiser la batterie
await service.startLocationMonitoring(foregroundMode: false);

// Ajuster le seuil selon le contexte
service.setProximityThreshold(isUrban ? 100.0 : 500.0);
```

### Performance
```dart
// Vérifier avant d'envoyer des notifications
if (await service.canSendNotification()) {
  // Envoyer notification
}

// Utiliser le résumé pour des vérifications rapides
final summary = service.getProximitySummary();
if (summary.hasNearbyDangers) {
  // Traiter les dangers proches
}
```

## Debugging

```dart
import 'dart:developer';

// Les logs apparaissent automatiquement en mode debug
// Préfixes des logs :
// - GeolocationNotificationIntegrationService
// - ProximityDetectionService
// - CriticalAlertService
// - etc.
```

## Tests

```dart
// Test d'intégration disponible
flutter test test/features/alertes/geolocation_notification_integration_test.dart

// Exemple d'utilisation disponible
lib/features/alertes/examples/geolocation_notification_example.dart
```

## Checklist de Mise en Production

- [ ] Permissions de localisation accordées
- [ ] Permissions de notifications accordées
- [ ] Service initialisé avec succès
- [ ] Zones configurées
- [ ] Surveillance démarrée
- [ ] Tests d'alertes effectués
- [ ] Gestion d'erreurs implémentée
- [ ] Optimisations de batterie appliquées