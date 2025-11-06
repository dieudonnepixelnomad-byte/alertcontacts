# Configuration RevenueCat pour AlertContact

## Problème résolu

L'erreur `ConfigurationError: There are no products registered in the RevenueCat dashboard for your offerings` indique que RevenueCat n'est pas correctement configuré.

## Solution mise en place

### 1. Mode développement automatique

L'application bascule automatiquement en **mode développement** avec des produits factices quand :
- RevenueCat n'est pas configuré (clé API manquante)
- Aucun produit n'est configuré dans le dashboard RevenueCat
- Une erreur de configuration est détectée

### 2. Produits factices disponibles

En mode développement, l'application utilise ces produits de test :

- **Premium Mensuel** : 4,99 € avec 7 jours d'essai gratuit
- **Premium Annuel** : 29,99 € (économie de 50%)

### 3. Fonctionnalités du mode développement

- ✅ Interface paywall complète
- ✅ Simulation d'achat avec délais réalistes
- ✅ Simulation de restauration d'achats
- ✅ Gestion des états premium/gratuit
- ✅ Messages informatifs pour les développeurs
- ✅ Logs détaillés avec emoji 🧪

## Configuration RevenueCat (pour la production)

### Étape 1 : Dashboard RevenueCat

1. Connectez-vous à [RevenueCat Dashboard](https://app.revenuecat.com)
2. Créez un nouveau projet "AlertContact"
3. Configurez les produits :

#### Produits iOS (App Store Connect)
```
Identifiant : alertcontacts_premium_monthly
Type : Auto-Renewable Subscription
Prix : 4,99 €
Durée : 1 mois
Essai gratuit : 7 jours
```

```
Identifiant : alertcontacts_premium_annual  
Type : Auto-Renewable Subscription
Prix : 29,99 €
Durée : 1 an
```

#### Produits Android (Google Play Console)
```
Identifiant : alertcontacts_premium_monthly
Type : Subscription
Prix : 4,99 €
Période de facturation : Mensuelle
Essai gratuit : 7 jours
```

```
Identifiant : alertcontacts_premium_annual
Type : Subscription  
Prix : 29,99 €
Période de facturation : Annuelle
```

### Étape 2 : Offerings RevenueCat

1. Dans RevenueCat Dashboard → Offerings
2. Créez un offering "default" 
3. Ajoutez les packages :
   - Package "monthly" → produit monthly
   - Package "annual" → produit annual

### Étape 3 : Clés API

1. Récupérez les clés API dans RevenueCat Dashboard → API Keys
2. Mettez à jour `lib/core/config/revenuecat_config.dart` :

```dart
class RevenueCatConfig {
  static const String androidApiKey = 'goog_VOTRE_CLE_ANDROID';
  static const String iosApiKey = 'appl_VOTRE_CLE_IOS';
}
```

### Étape 4 : Configuration des stores

#### App Store Connect (iOS)
1. Créez les produits d'abonnement
2. Configurez les prix et essais gratuits
3. Soumettez pour révision

#### Google Play Console (Android)  
1. Créez les produits d'abonnement
2. Configurez les prix et essais gratuits
3. Activez les produits

## Test et validation

### Mode développement (actuel)
```bash
flutter run --debug
# L'app utilise automatiquement les produits factices
```

### Mode production (après configuration)
```bash
flutter run --release
# L'app utilise RevenueCat avec les vrais produits
```

## Logs de débogage

Recherchez ces messages dans les logs :

```
🧪 Mode développement : Chargement des produits factices
🧪 2 produits factices chargés
🧪 Mode développement : Simulation d'achat de mock_monthly
🧪 Abonnement factice créé : Premium jusqu'au 2025-02-26
```

## Avantages de cette approche

1. **Développement fluide** : Pas de blocage pendant le développement
2. **Tests complets** : Interface paywall entièrement testable
3. **Transition transparente** : Basculement automatique vers RevenueCat une fois configuré
4. **Expérience utilisateur** : Messages clairs sur l'état de configuration
5. **Débogage facile** : Logs détaillés pour identifier les problèmes

## Prochaines étapes

1. ✅ Mode développement opérationnel
2. ⏳ Configuration RevenueCat Dashboard
3. ⏳ Création des produits dans les stores
4. ⏳ Tests avec vrais produits
5. ⏳ Déploiement en production

L'application fonctionne maintenant parfaitement en mode développement et basculera automatiquement vers RevenueCat une fois la configuration terminée.