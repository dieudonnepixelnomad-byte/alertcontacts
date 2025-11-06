# Guide d'utilisation des Services de Notifications Géolocalisées

## Vue d'ensemble

Le système de notifications géolocalisées d'AlertContact est composé de plusieurs services orchestrés par le `GeolocationNotificationIntegrationService`. Ce guide explique comment utiliser et configurer ces services.

## Architecture des Services

### Service Principal : GeolocationNotificationIntegrationService

Le service d'intégration orchestre tous les autres services :

```dart
final service = GeolocationNotificationIntegrationService();
await service.initialize();
```

### Services Orchestrés

1. **ProximityDetectionService** - Détection de proximité avec les zones
2. **CriticalAlertService** - Gestion des alertes critiques
3. **ForegroundModeService** - Mode premier plan pour la surveillance continue
4. **NotificationCooldownService** - Gestion des délais entre notifications
5. **VoiceAlertService** - Alertes vocales

## Configuration Initiale

### 1. Initialisation du Service

```dart
import 'package:alertcontacts/features/alertes/services/geolocation_notification_integration_service.dart';

final service = GeolocationNotificationIntegrationService();

// Vérifier le statut
if (service.status == ServiceStatus.uninitialized) {
  await service.initialize();
}

// Vérifier que le service est prêt
if (service.isReady) {
  print('Service prêt à utiliser');
}
```

### 2. Configuration des Zones

```dart
import 'package:alertcontacts/core/models/danger_zone.dart';
import 'package:alertcontacts/core/models/safe_zone.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Zones de danger
final dangerZones = [
  DangerZone(
    id: 'danger_1',
    name: 'Zone dangereuse',
    description: 'Zone signalée comme dangereuse',
    center: const LatLng(48.8566, 2.3522),
    radiusMeters: 100,
    severity: DangerSeverity.high,
    confirmations: 5,
    lastReportAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
];

// Zones de sécurité
final safeZones = [
  SafeZone(
    id: 'safe_1',
    name: 'Maison',
    iconKey: 'home',
    center: const LatLng(48.8566, 2.3522),
    radiusMeters: 50,
    address: '123 Rue de la Paix, Paris',
    memberIds: ['user_1', 'user_2'],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
];

// Configurer les zones
await service.configureDangerZones(dangerZones);
await service.configureSafeZones(safeZones);
```

## Surveillance de Localisation

### Démarrer la Surveillance

```dart
// Démarrer la surveillance en mode premier plan
await service.startLocationMonitoring(foregroundMode: true);

// Ou en mode arrière-plan
await service.startLocationMonitoring(foregroundMode: false);
```

### Arrêter la Surveillance

```dart
await service.stopLocationMonitoring();
```

## Analyse de Proximité

### Analyse Manuelle

```dart
import 'package:alertcontacts/features/alertes/services/proximity_detection_service.dart';

final userLocation = const LatLng(48.8566, 2.3522);
final analysis = service.analyzeProximity(userLocation, dangerZones);

if (analysis.hasImmediateDanger) {
  print('Danger immédiat détecté !');
}

if (analysis.hasCriticalProximity) {
  print('Proximité critique avec une zone dangereuse');
}

// Obtenir les détails
for (final proximity in analysis.proximities) {
  print('Zone: ${proximity.zone.name}');
  print('Distance: ${proximity.distanceMeters}m');
  print('Niveau: ${proximity.level}');
}
```

### Résumé de Proximité

```dart
final summary = service.getProximitySummary();
print('Zones dangereuses proches: ${summary.nearbyDangerZones}');
print('Zones de sécurité actives: ${summary.activeSafeZones}');
print('Niveau de risque global: ${summary.overallRiskLevel}');
```

## Gestion des Alertes

### Alertes Automatiques

Le service gère automatiquement les alertes basées sur la proximité :

```dart
// Les alertes sont envoyées automatiquement quand :
// - L'utilisateur entre dans une zone dangereuse
// - L'utilisateur s'approche d'une zone dangereuse
// - L'utilisateur sort d'une zone de sécurité
```

### Alertes Manuelles

```dart
// Envoyer une alerte de test
await service.testCriticalAlert();

// Gérer manuellement une détection de zone dangereuse
await service.handleDangerZoneDetection(
  dangerZones.first,
  const LatLng(48.8566, 2.3522),
);
```

## Configuration des Notifications

### Seuil de Proximité

```dart
// Définir le seuil de proximité (en mètres)
service.setProximityThreshold(150.0);
```

### Vérification des Capacités

```dart
// Vérifier si on peut envoyer des notifications
final canSend = await service.canSendNotification();
if (!canSend) {
  print('Notifications désactivées ou en mode silencieux');
}
```

### Statistiques de Cooldown

```dart
final stats = service.getCooldownStats();
print('Notifications bloquées: ${stats.blockedNotifications}');
print('Dernière notification: ${stats.lastNotificationTime}');
```

## Gestion du Cycle de Vie

### États du Service

```dart
enum ServiceStatus {
  uninitialized,  // Non initialisé
  initializing,   // En cours d'initialisation
  ready,          // Prêt à utiliser
  error,          // Erreur
  disposed        // Libéré
}

// Vérifier l'état
switch (service.status) {
  case ServiceStatus.ready:
    // Service prêt
    break;
  case ServiceStatus.error:
    // Gérer l'erreur
    break;
  // ...
}
```

### Nettoyage

```dart
// Libérer les ressources
await service.dispose();
```

## Exemples d'Utilisation

### Cas d'Usage 1 : Surveillance Familiale

```dart
class FamilySafetyService {
  final _service = GeolocationNotificationIntegrationService();
  
  Future<void> setupFamilySafety() async {
    await _service.initialize();
    
    // Configurer les zones de sécurité (maison, école)
    final safeZones = [
      SafeZone(
        id: 'home',
        name: 'Maison',
        iconKey: 'home',
        center: homeLocation,
        radiusMeters: 100,
        memberIds: familyMemberIds,
      ),
      SafeZone(
        id: 'school',
        name: 'École',
        iconKey: 'school',
        center: schoolLocation,
        radiusMeters: 50,
        memberIds: [childId],
      ),
    ];
    
    await _service.configureSafeZones(safeZones);
    await _service.startLocationMonitoring(foregroundMode: true);
  }
}
```

### Cas d'Usage 2 : Sécurité Personnelle

```dart
class PersonalSafetyService {
  final _service = GeolocationNotificationIntegrationService();
  
  Future<void> setupPersonalSafety() async {
    await _service.initialize();
    
    // Configurer les zones dangereuses connues
    final dangerZones = await loadDangerZonesFromAPI();
    await _service.configureDangerZones(dangerZones);
    
    // Surveillance en arrière-plan
    await _service.startLocationMonitoring(foregroundMode: false);
    
    // Seuil de proximité plus sensible
    _service.setProximityThreshold(200.0);
  }
}
```

## Bonnes Pratiques

### 1. Gestion des Permissions

```dart
// Vérifier les permissions avant d'initialiser
final hasLocationPermission = await checkLocationPermission();
final hasNotificationPermission = await checkNotificationPermission();

if (hasLocationPermission && hasNotificationPermission) {
  await service.initialize();
}
```

### 2. Gestion des Erreurs

```dart
try {
  await service.initialize();
} catch (e) {
  // Gérer les erreurs d'initialisation
  print('Erreur d\'initialisation: $e');
  // Fallback ou retry
}
```

### 3. Optimisation de la Batterie

```dart
// Utiliser le mode arrière-plan quand possible
await service.startLocationMonitoring(foregroundMode: false);

// Ajuster le seuil de proximité selon le contexte
if (isInUrbanArea) {
  service.setProximityThreshold(100.0);
} else {
  service.setProximityThreshold(500.0);
}
```

### 4. Tests et Validation

```dart
// Tester les alertes en développement
if (kDebugMode) {
  await service.testCriticalAlert();
}

// Vérifier régulièrement le statut
Timer.periodic(const Duration(minutes: 5), (timer) {
  if (service.status != ServiceStatus.ready) {
    // Réinitialiser si nécessaire
    service.initialize();
  }
});
```

## Dépannage

### Problèmes Courants

1. **Service non initialisé**
   ```dart
   if (service.status == ServiceStatus.uninitialized) {
     await service.initialize();
   }
   ```

2. **Notifications non reçues**
   ```dart
   final canSend = await service.canSendNotification();
   if (!canSend) {
     // Vérifier les permissions et paramètres
   }
   ```

3. **Consommation de batterie élevée**
   ```dart
   // Passer en mode arrière-plan
   await service.startLocationMonitoring(foregroundMode: false);
   ```

### Logs et Débogage

Le service utilise `dart:developer` pour les logs. Activez les logs en mode debug :

```dart
import 'dart:developer';

// Les logs apparaîtront dans la console avec le préfixe du service
```

## API Reference

Voir les fichiers de service individuels pour la documentation complète des API :

- `GeolocationNotificationIntegrationService` - Service principal
- `ProximityDetectionService` - Détection de proximité
- `CriticalAlertService` - Alertes critiques
- `ForegroundModeService` - Mode premier plan
- `NotificationCooldownService` - Gestion des cooldowns
- `VoiceAlertService` - Alertes vocales