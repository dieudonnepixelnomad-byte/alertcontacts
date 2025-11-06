# Guide d'Intégration des Fonctionnalités Premium

Ce guide explique comment utiliser le système de vérification d'abonnement pro implémenté dans AlertContact.

## 🎯 Fonctionnalités Premium Disponibles

### 1. Zones illimitées & sur mesure (`PremiumFeature.unlimitedZones`)
- **Gratuit** : 1 zone de sécurité maximum
- **Premium** : Zones illimitées
- **Usage** : Protection de tous les lieux importants (maison, école, travail, trajets)

### 2. Surveillance multi-proches (`PremiumFeature.multiContacts`)
- **Gratuit** : 1 proche maximum par zone
- **Premium** : Proches illimités par zone
- **Usage** : Gestion centralisée de plusieurs contacts et de leurs zones

### 3. Historique & rapports détaillés (`PremiumFeature.detailedHistory`)
- **Gratuit** : Pas d'accès à l'historique détaillé
- **Premium** : Accès complet à l'historique et aux statistiques
- **Usage** : Consultation des alertes passées, mouvements et statistiques de sécurité

## 🔧 Utilisation dans le Code

### 1. Import des dépendances

```dart
import 'package:alertcontacts/core/enums/premium_features.dart';
import 'package:alertcontacts/core/utils/premium_access_guard.dart';
import 'package:alertcontacts/core/providers/subscription_provider.dart';
```

### 2. Vérification d'accès avec garde automatique

```dart
// Exemple : Création d'une nouvelle zone de sécurité
Future<void> _createNewSafeZone() async {
  final canCreate = await PremiumAccessGuard.canCreateSafeZone(
    context,
    currentZoneCount, // Nombre actuel de zones
    onAccessGranted: () {
      // L'utilisateur peut créer une nouvelle zone
      _proceedWithZoneCreation();
    },
    showPaywall: true, // Affiche automatiquement le paywall si refusé
  );
  
  if (!canCreate) {
    // L'accès a été refusé et le paywall a été affiché
    return;
  }
}

// Exemple : Ajout d'un proche à une zone
Future<void> _addContactToZone() async {
  final canAdd = await PremiumAccessGuard.canAddContactToZone(
    context,
    currentContactCount, // Nombre actuel de proches dans la zone
    onAccessGranted: () {
      // L'utilisateur peut ajouter un proche
      _proceedWithContactAddition();
    },
  );
}

// Exemple : Accès à l'historique
Future<void> _viewHistory() async {
  final hasAccess = await PremiumAccessGuard.canAccessHistory(
    context,
    onAccessGranted: () {
      // L'utilisateur peut consulter l'historique
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => HistoryPage(),
      ));
    },
  );
}
```

### 3. Vérification d'accès manuelle

```dart
// Utilisation du provider directement
final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);

// Vérifier l'accès à une fonctionnalité spécifique
final hasUnlimitedZones = await subscriptionProvider.hasFeatureAccess(
  PremiumFeature.unlimitedZones
);

// Vérifier si l'utilisateur est premium
final isPro = await subscriptionProvider.hasProAccess();

// Obtenir les limites actuelles
final limits = await subscriptionProvider.getUserLimits();
print('Zones max: ${limits['maxSafeZones']}');
print('Proches max par zone: ${limits['maxContactsPerZone']}');
print('Accès historique: ${limits['hasHistoryAccess']}');
```

### 4. Utilisation avec garde personnalisée

```dart
// Vérification avec callback personnalisé
final hasAccess = await PremiumAccessGuard.checkAccess(
  context,
  PremiumFeature.detailedHistory,
  onAccessGranted: () {
    // Action à effectuer si l'accès est accordé
    _showDetailedReport();
  },
  showPaywall: false, // Ne pas afficher le paywall automatiquement
  customMessage: 'Cette fonctionnalité nécessite Premium',
);
```

### 5. Affichage des limites dans l'UI

```dart
// Widget pour afficher les limites actuelles
Widget build(BuildContext context) {
  return Column(
    children: [
      // Autres widgets...
      
      // Affichage des limites
      PremiumAccessGuard.buildLimitsInfo(context),
      
      // Autres widgets...
    ],
  );
}
```

## 🎨 Exemples d'Intégration UI

### 1. Bouton avec vérification d'accès

```dart
class CreateZoneButton extends StatelessWidget {
  final int currentZoneCount;
  
  const CreateZoneButton({required this.currentZoneCount});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        await PremiumAccessGuard.canCreateSafeZone(
          context,
          currentZoneCount,
          onAccessGranted: () {
            // Naviguer vers la page de création de zone
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => CreateSafeZonePage(),
            ));
          },
        );
      },
      child: Text('Créer une zone'),
    );
  }
}
```

### 2. Liste avec indicateur de limite

```dart
class SafeZonesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscription, child) {
        return FutureBuilder<Map<String, dynamic>>(
          future: subscription.getUserLimits(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return CircularProgressIndicator();
            
            final limits = snapshot.data!;
            final maxZones = limits['maxSafeZones'] as int;
            final currentCount = safeZones.length;
            
            return Column(
              children: [
                // Indicateur de limite
                if (maxZones != -1)
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: currentCount >= maxZones 
                        ? Colors.red.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$currentCount / $maxZones zones utilisées',
                      style: TextStyle(
                        color: currentCount >= maxZones 
                          ? Colors.red 
                          : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                
                // Liste des zones
                ...safeZones.map((zone) => SafeZoneTile(zone: zone)),
                
                // Bouton d'ajout avec vérification
                CreateZoneButton(currentZoneCount: currentCount),
              ],
            );
          },
        );
      },
    );
  }
}
```

### 3. Page d'historique avec protection

```dart
class HistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: PremiumAccessGuard.canAccessHistory(context, showPaywall: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: Text('Historique')),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        final hasAccess = snapshot.data!;
        
        if (!hasAccess) {
          return Scaffold(
            appBar: AppBar(title: Text('Historique')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Fonctionnalité Premium',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'L\'accès à l\'historique détaillé nécessite un abonnement Premium.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.paywall),
                    child: Text('Découvrir Premium'),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Afficher l'historique complet
        return Scaffold(
          appBar: AppBar(title: Text('Historique')),
          body: HistoryContent(),
        );
      },
    );
  }
}
```

## 🔄 Migration du Code Existant

### Avant (méthodes synchrones)
```dart
// Ancien code
final subscription = Provider.of<SubscriptionProvider>(context);
if (subscription.isPremium) {
  // Action premium
}
```

### Après (méthodes asynchrones avec garde)
```dart
// Nouveau code
final hasAccess = await PremiumAccessGuard.checkAccess(
  context,
  PremiumFeature.unlimitedZones,
  onAccessGranted: () {
    // Action premium
  },
);
```

## 🧪 Tests

### Test des fonctionnalités premium
```dart
// Test de vérification d'accès
testWidgets('Should show paywall when creating zone without premium', (tester) async {
  // Setup mock subscription provider (free user)
  
  await tester.pumpWidget(MyApp());
  
  // Tenter de créer une zone
  await tester.tap(find.byKey(Key('create_zone_button')));
  await tester.pumpAndSettle();
  
  // Vérifier que le paywall est affiché
  expect(find.text('Fonctionnalité Premium'), findsOneWidget);
});
```

## 📝 Bonnes Pratiques

1. **Toujours utiliser les gardes d'accès** avant les actions premium
2. **Gérer les erreurs** avec des fallbacks appropriés
3. **Afficher des messages clairs** à l'utilisateur
4. **Utiliser les callbacks** pour une UX fluide
5. **Tester les scénarios** gratuit et premium

## 🚀 Prochaines Étapes

1. Intégrer les gardes dans les pages existantes
2. Mettre à jour les tests unitaires
3. Ajouter des analytics pour les tentatives d'accès premium
4. Implémenter des niveaux d'abonnement plus granulaires si nécessaire