# CLAUDE.md — AlertContacts V4

## Identité du projet

**AlertContacts** — Application mobile de sécurité familiale & tranquillité d'esprit.
Tagline : _"la sérénité en toutes circonstances"_
Version en cours : **V4.0** — Refonte complète UX/UI & Backend
CDC de référence : `AlertContacts_CDC_V4_1.pdf`

---

## Stack technique

| Couche     | Technologie                                           |
| ---------- | ----------------------------------------------------- |
| Mobile     | Flutter (iOS + Android)                               |
| Backend    | Laravel 11 + MySQL 8                                  |
| Temps réel | Firebase Realtime Database                            |
| Auth       | Firebase Auth (Magic Link, Google OAuth, Apple OAuth) |
| Push       | Firebase Cloud Messaging (FCM) via Laravel            |
| Paiement   | Stripe (Europe) + PayDunya (Afrique)                  |
| Cache      | Redis                                                 |
| Queue      | Laravel Queue (jobs asynchrones)                      |

---

## Architecture — Règle fondamentale

```
Flutter ←→ Firebase Realtime DB   (positions GPS temps réel)
Flutter ←→ Firebase Auth          (authentification)
Flutter ←→ Laravel API            (logique métier, zones, proches, alertes, abonnements)
```

**Laravel ne lit JAMAIS Firebase directement.**
**Flutter est le seul pont entre Firebase et Laravel.**

- Firebase = source de vérité pour l'affichage temps réel
- Laravel = source de vérité pour la logique métier

---

## Structure du projet Flutter

```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── router.dart
├── core/
│   ├── constants/
│   │   ├── colors.dart          # Design system couleurs
│   │   ├── typography.dart      # Design system typo
│   │   └── api_endpoints.dart   # Tous les endpoints Laravel
│   ├── services/
│   │   ├── auth_service.dart    # Firebase Auth + Laravel token
│   │   ├── location_service.dart
│   │   ├── notification_service.dart
│   │   └── api_service.dart     # HTTP client Laravel
│   ├── models/
│   │   ├── user.dart
│   │   ├── contact.dart
│   │   ├── zone.dart
│   │   └── alert.dart
│   └── utils/
├── features/
│   ├── onboarding/
│   │   ├── splash/
│   │   ├── personalization/
│   │   ├── auth/
│   │   └── invitation/
│   ├── map/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── controllers/
│   ├── contacts/
│   ├── alerts/
│   ├── zones/
│   ├── paywall/
│   └── settings/
└── shared/
    ├── widgets/
    └── extensions/
```

---

## Design System — Couleurs

```dart
// Toujours utiliser ces tokens, jamais de valeurs hardcodées
static const Color primary      = Color(0xFF1E6868); // CTA, accents, onglet actif
static const Color primaryLight = Color(0xFFE1F5EE); // Backgrounds tinted
static const Color orange       = Color(0xFFFF8C3C); // Logo gradient start
static const Color pink         = Color(0xFFFF5C7A); // Logo gradient end
static const Color success      = Color(0xFF22C55E); // En zone, connexion active
static const Color warning      = Color(0xFFF59E0B); // Connexion instable
static const Color danger       = Color(0xFFEF4444); // Hors ligne, alertes élevées
static const Color gravityLow   = Color(0xFFEAB308); // Alerte faible
static const Color gravityMid   = Color(0xFFF97316); // Alerte moyenne
static const Color gravityHigh  = Color(0xFFEF4444); // Alerte élevée
```

---

## Design System — Typographie

```dart
// Tailles et poids définis — ne pas improviser
// titleLarge  : 20sp / w500
// titleMedium : 18sp / w500
// titleSmall  : 17sp / w500
// bodyLarge   : 15sp / w400  (CTA, textes importants)
// bodyMedium  : 14sp / w400  (contenu principal)
// bodySmall   : 13sp / w400  (labels, descriptions)
// caption     : 11sp / w400  (timestamps, métadonnées)
// micro       : 10sp / w500  (labels tab bar)
```

---

## Design System — Composants

- **Touch targets** : minimum 44×44pt iOS / 48×48dp Android — sans exception
- **Border radius cards** : 12-14dp
- **Border radius boutons** : 10-12dp
- **Border radius pills/chips** : 20dp (arrondi complet)
- **Bottom tab bar** : 54dp de hauteur
- **Bottom sheets** : handle 32×3dp centré, border-radius 20dp en haut
- **CTA primaire** : pleine largeur, padding vertical 13dp, background primary
- **CTA destructif** : toujours en dernier dans un écran, background danger light, texte rouge

### Règle Thumb Zone

| Zone                 | Position   | Éléments autorisés                |
| -------------------- | ---------- | --------------------------------- |
| Verte (facile)       | Bottom 40% | CTA principaux, navigation, FAB   |
| Orange (atteignable) | Middle 40% | Contenu principal, listes         |
| Rouge (difficile)    | Top 20%    | Actions secondaires, informations |

---

## Splash Screen — Spécifications exactes

```
Fond          : #1E6868
Blobs         : orange (#FF8C3C 35%), vert (#32D282 28%), teal clair (15%)
Logo          : dégradé #FF8C3C → #FF5C7A + drop shadow
Nom app       : "ALERTCONTACTS" — sans-serif w500 — blanc — letter-spacing 0.06em
Tagline       : "la sérénité en toutes circonstances" — blanc 60% opacité
Loader        : barre fine 100px — 50% opacité blanche — slide-in
Animation     : logo fade-in + scale 0.8→1.0 (300ms ease-out) · tagline fade +150ms
Durée totale  : 1.8 secondes MAX
Navigation    : automatique vers écran personnalisation
```

---

## Onboarding — Règles UX (non négociables)

| Règle                        | Application                                                 |
| ---------------------------- | ----------------------------------------------------------- |
| R1 — Valeur en < 60s         | Question perso immédiate après splash                       |
| R2 — Inscription différée    | Login arrive APRÈS la question perso                        |
| R3 — Permissions en contexte | Aucune permission dans l'onboarding — in-context uniquement |
| R4 — Progressive disclosure  | Slides supprimées — flux 4 étapes max                       |
| R6 — Personnalisation        | 1 seule question : "Tu protèges qui ?" — 4 choix            |
| R7 — Empty states            | Carte avec card flottante guidante — jamais d'écran blanc   |
| R8 — Renforcement positif    | Animation après invitation envoyée                          |

**Slides onboarding** : screenshots réels de l'app uniquement — pas d'illustrations abstraites (obsolètes en 2026).

---

## Authentification — Passwordless

Ordre strict des méthodes affichées :

1. **Sign in with Apple** (obligatoire si Google OAuth présent — règle Apple)
2. **Sign in with Google**
3. **Magic Link email** (option secondaire)

**Magic Link** : valable 1h — renvoi possible après 30s countdown — bouton "Ouvrir mon application mail" via deep link natif.

**Flux auth Flutter → Laravel** :

```
Firebase Auth → ID Token → POST /api/auth/firebase → Laravel Token (Bearer)
```

---

## Géolocalisation — Stack V1 (gratuite)

```yaml
packages:
  geolocator: # Récupération position GPS
  background_fetch: # Tâche périodique arrière-plan
  firebase_database: # Publication position temps réel
  flutter_local_notifications: # Notifications locales zone
  shared_preferences: # Cache zones en local
```

### Logique d'update adaptatif

| État utilisateur                  | Firebase    | Laravel API |
| --------------------------------- | ----------- | ----------- |
| App premier plan — carte ouverte  | 10 secondes | 5 minutes   |
| Background — en mouvement         | 5 minutes   | 5 minutes   |
| Background — immobile > 10min     | 15 minutes  | 15 minutes  |
| Alerte communautaire active < 1km | 5 minutes   | 60 secondes |
| Mode invisible activé             | ARRÊT TOTAL | ARRÊT TOTAL |

**Important** : Flutter lit `next_update_interval` dans chaque réponse de `POST /api/location` et ajuste `background_fetch` dynamiquement.

---

## Endpoints API Laravel

### Auth

```
POST /api/auth/firebase   # Échange Firebase ID token → Laravel token
POST /api/auth/logout
GET  /api/me
PUT  /api/me
```

### Géolocalisation

```
POST /api/location         # Position actuelle → déclenche zones + alertes
POST /api/location/pause   # Mode invisible { duration: minutes }
POST /api/location/resume
```

Réponse de `POST /api/location` :

```json
{ "status": "ok", "alerts_nearby": true, "next_update_interval": 60 }
```

### Proches & Invitations

```
GET    /api/contacts
POST   /api/invitations
POST   /api/invitations/accept
POST   /api/invitations/reject          # Auth non requise — token suffit
DELETE /api/contacts/{id}               # Bidirectionnel
PUT    /api/contacts/{id}/permissions
```

### Zones

```
GET    /api/zones
POST   /api/zones                       # { name, lat, lng, radius, icon, color, contact_ids }
PUT    /api/zones/{id}
DELETE /api/zones/{id}
GET    /api/zones/{id}/status
```

### Alertes communautaires

```
GET  /api/alerts/nearby
POST /api/alerts                        # Premium uniquement
POST /api/alerts/{id}/confirm
POST /api/alerts/{id}/deny
POST /api/alerts/{id}/report
```

### Abonnements

```
GET    /api/subscriptions
POST   /api/subscriptions               # Stripe ou PayDunya
POST   /api/subscriptions/family/invite
DELETE /api/subscriptions/family/{id}
```

### Versionning

```
GET /api/app/version   # { current_version, min_version, force_update, message }
```

---

## Monétisation — 3 tiers Freemium

| Feature                | Gratuit       | Solo               | Famille            |
| ---------------------- | ------------- | ------------------ | ------------------ |
| Proches                | 2 max         | Illimités          | Illimités          |
| Zones                  | 1 max         | Illimitées         | Illimitées         |
| Historique alertes     | 24h           | 30 jours           | 30 jours           |
| Alertes communautaires | Lecture seule | Création + lecture | Création + lecture |
| Alerte privée proches  | ❌            | ✅                 | ✅                 |
| Rapports de trajet     | ❌            | ✅                 | ✅                 |
| Mode invisible         | ❌            | ✅                 | ✅                 |
| Membres du foyer       | —             | 1                  | Jusqu'à 6          |

**Prix** :

- Solo : 4,99€/mois — 34,99€/an (42% d'économie) — essai 7 jours (annuel uniquement)
- Famille : 8,99€/mois — 59,99€/an (44% d'économie) — essai 7 jours (annuel uniquement)

**Règle paywall absolue** : Le paywall ne s'affiche JAMAIS avant qu'un Aha Moment ait été vécu. Un utilisateur sans proche connecté ne voit pas de paywall.

**Déclencheurs paywall** :

1. Hit de limite (3ème proche ou 2ème zone) → modal bloquant immédiat
2. Card proactive J7 si 2 proches actifs → non bloquant
3. Paramètres → section "Mon abonnement"

---

## Bidirectionnalité — Règles

```
A invite B → B accepte :
  - A voit B ✅
  - B voit A grisé ❌ + CTA "Invite A pour le voir aussi"

B invite A en retour → A accepte :
  - Les deux se voient mutuellement ✅

B refuse retour :
  - A continue de voir B
  - B voit A grisé indéfiniment
```

---

## Offline — Règle absolue

**AlertContacts ne bloque JAMAIS l'utilisateur, même sans connexion.**

| Scénario           | Comportement                                                            |
| ------------------ | ----------------------------------------------------------------------- |
| Hors ligne complet | Carte grisée + banner rouge non-bloquant + dernières positions en cache |
| Proche hors ligne  | Avatar grisé + dernière position + timestamp                            |
| Connexion instable | Banner noir rétractable + données en cache                              |

Jamais d'écran bloquant pour connexion perdue.

---

## Navigation

```
Bottom Tab Bar (3 onglets uniquement) :
  ├── Carte       (défaut au lancement)
  ├── Proches
  └── Alertes     (badge compteur)

Hors tab bar :
  ├── Zones       (icône calque ⊞ haut gauche de la Carte)
  └── Paramètres  (avatar tapable haut droite de la Carte)
```

---

## Alertes communautaires — Niveaux de gravité

| Niveau | Couleur    | Durée  | Rayon |
| ------ | ---------- | ------ | ----- |
| Faible | #EAB308 🟡 | 30 min | 200m  |
| Moyen  | #F97316 🟠 | 1h     | 500m  |
| Élevé  | #EF4444 🔴 | 2h     | 1km   |

Le CTA de soumission change de couleur selon la gravité. C'est une friction intentionnelle.

---

## Notifications push — Templates

| Type                   | Titre                                    | Body                                             |
| ---------------------- | ---------------------------------------- | ------------------------------------------------ |
| Entrée zone            | "✅ [Prénom] est arrivé(e)"              | "[Zone] — il y a X min"                          |
| Sortie zone            | "🚪 [Prénom] a quitté [Zone]"            | "Détecté il y a X min"                           |
| Invitation reçue       | "👋 [Prénom] t'invite sur AlertContacts" | "Rejoins-le pour voir vos positions mutuelles"   |
| Invitation acceptée    | "🎉 [Prénom] a rejoint AlertContacts !"  | "Vous pouvez maintenant vous voir sur la carte"  |
| Alerte élevée          | "🔴 Danger signalé à [distance]m"        | "[Type] — [Lieu] — [X] confirmations"            |
| Alerte moyenne         | "🟠 Incident signalé à [distance]m"      | "[Type] — [Lieu]"                                |
| Mode invisible proche  | "👻 [Prénom] a mis sa position en pause" | "Sa position n'est plus partagée temporairement" |
| Batterie faible proche | "🔋 Batterie faible — [Prénom]"          | "[X]% — Position bientôt indisponible"           |

**Règles wording** : toujours langage naturel — jamais de jargon technique ("Léa est arrivée à l'école", pas "Entrée zone détectée").

---

---

## Analytics, Monitoring, Performance & Stabilité

### Outils retenus

| Outil                           | Rôle                                              | Package Flutter          |
| ------------------------------- | ------------------------------------------------- | ------------------------ |
| Firebase Crashlytics            | Crash reporting temps réel + erreurs non-fatales  | `firebase_crashlytics`   |
| Firebase Analytics (GA4)        | Événements utilisateur, funnels, rétention        | `firebase_analytics`     |
| Firebase Performance Monitoring | Traces réseau, temps de rendu, latences API       | `firebase_performance`   |
| Firebase Remote Config          | Feature flags, A/B testing, paramètres dynamiques | `firebase_remote_config` |

**Pas de Sentry, pas de New Relic.** AlertContacts est déjà 100% Firebase — rester dans l'écosystème évite un SDK supplémentaire, unifie le dashboard, et reste dans le free tier tant que la base utilisateur est petite.

---

### pubspec.yaml — dépendances à ajouter

```yaml
dependencies:
  firebase_crashlytics: ^4.x.x # Toujours vérifier la dernière version sur pub.dev
  firebase_analytics: ^11.x.x
  firebase_performance: ^0.10.x
  firebase_remote_config: ^5.x.x
```

---

### Initialisation — main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Crashlytics — intercepte toutes les erreurs Flutter non catchées
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Intercepte les erreurs Dart hors du contexte Flutter (isolates, async)
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(const AlertContactsApp());
}
```

---

### CrashlyticsService — centraliser, ne jamais appeler Crashlytics directement

```dart
// core/services/crashlytics_service.dart
class CrashlyticsService {

  // Identifier l'utilisateur dans les rapports — jamais de PII (email, nom)
  // Utiliser uniquement l'ID Firebase Auth
  Future<void> setUser(String userId) async {
    await FirebaseCrashlytics.instance.setUserIdentifier(userId);
  }

  // Erreur fatale (crash réel)
  Future<void> recordFatal(dynamic error, StackTrace stack) async {
    await FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  }

  // Erreur non-fatale (à surveiller mais n'a pas crashé l'app)
  Future<void> recordNonFatal(dynamic error, StackTrace stack, {String? reason}) async {
    await FirebaseCrashlytics.instance.recordError(
      error, stack,
      fatal: false,
      reason: reason,
    );
  }

  // Log contextuel — envoyé avec le prochain rapport de crash
  void log(String message) {
    FirebaseCrashlytics.instance.log(message);
  }

  // Clé personnalisée — enrichit le rapport pour le debug
  // Exemples : tier utilisateur, état connexion, dernière action
  void setKey(String key, dynamic value) {
    FirebaseCrashlytics.instance.setCustomKey(key, value.toString());
  }
}
```

**Clés personnalisées à toujours setter avant une opération critique :**

```dart
crashlyticsService.setKey('user_tier', 'solo');          // gratuit | solo | famille
crashlyticsService.setKey('location_enabled', 'true');
crashlyticsService.setKey('last_screen', 'map');
crashlyticsService.setKey('contacts_count', '3');
crashlyticsService.setKey('connection_status', 'online'); // online | offline | unstable
```

---

### AnalyticsService — événements à tracker

```dart
// core/services/analytics_service.dart
class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Tracking automatique des écrans — à appeler dans chaque page/route
  Future<void> logScreen(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // Événements custom
  Future<void> logEvent(String name, {Map<String, dynamic>? params}) async {
    await _analytics.logEvent(name: name, parameters: params);
  }

  // Tier utilisateur — propriété persistante sur l'utilisateur
  Future<void> setUserTier(String tier) async {
    await _analytics.setUserProperty(name: 'subscription_tier', value: tier);
  }
}
```

#### Événements obligatoires à implémenter (funnels critiques)

```dart
// --- ONBOARDING ---
analytics.logEvent('onboarding_personalization_completed', params: {'profile': 'children'});
analytics.logEvent('onboarding_auth_completed', params: {'method': 'google'}); // google | apple | magic_link
analytics.logEvent('onboarding_invitation_sent');
analytics.logEvent('onboarding_invitation_skipped');
analytics.logEvent('onboarding_completed'); // arrivée sur l'App Shell

// --- AHA MOMENTS ---
analytics.logEvent('aha_1_contact_accepted');   // Premier proche connecté
analytics.logEvent('aha_2_contact_on_map');     // Premier proche vu sur la carte
analytics.logEvent('aha_3_zone_alert_received'); // Première vraie alerte reçue

// --- PROCHES ---
analytics.logEvent('contact_invited');
analytics.logEvent('contact_invitation_accepted');
analytics.logEvent('contact_removed');

// --- ZONES ---
analytics.logEvent('zone_created', params: {'icon': 'school', 'radius': 150});
analytics.logEvent('zone_entry_detected');
analytics.logEvent('zone_exit_detected');

// --- ALERTES COMMUNAUTAIRES ---
analytics.logEvent('community_alert_viewed', params: {'gravity': 'high'});
analytics.logEvent('community_alert_created', params: {'gravity': 'medium', 'type': 'accident'});
analytics.logEvent('community_alert_confirmed');

// --- MONETISATION (les plus importants) ---
analytics.logEvent('paywall_displayed', params: {'trigger': 'contact_limit'}); // contact_limit | zone_limit | proactive | settings
analytics.logEvent('paywall_dismissed');
analytics.logEvent('subscription_trial_started', params: {'tier': 'solo', 'billing': 'annual'});
analytics.logEvent('subscription_purchased', params: {'tier': 'family', 'billing': 'monthly'});
analytics.logEvent('subscription_cancelled', params: {'tier': 'solo'});

// --- GÉOLOCALISATION ---
analytics.logEvent('location_permission_granted');
analytics.logEvent('location_permission_denied');
analytics.logEvent('invisible_mode_activated', params: {'duration': '60'}); // en minutes

// --- ENGAGEMENT ---
analytics.logEvent('notification_opened', params: {'type': 'zone_entry'});
analytics.logEvent('app_opened_from_background');
```

**Règle de nommage** : `snake_case` — verbe + objet — jamais d'espaces — max 40 caractères.

---

### PerformanceService — traces à instrumenter

```dart
// core/services/performance_service.dart
class PerformanceService {
  final FirebasePerformance _performance = FirebasePerformance.instance;

  // Trace manuelle pour une opération custom
  Future<T> trace<T>(String traceName, Future<T> Function() operation) async {
    final trace = await _performance.newTrace(traceName);
    await trace.start();
    try {
      final result = await operation();
      trace.putAttribute('success', 'true');
      return result;
    } catch (e) {
      trace.putAttribute('success', 'false');
      trace.putAttribute('error', e.runtimeType.toString());
      rethrow;
    } finally {
      await trace.stop();
    }
  }
}
```

#### Traces à instrumenter obligatoirement

```dart
// Temps de chargement des positions des proches au démarrage
await performanceService.trace('contacts_initial_load', () => _loadContacts());

// Temps de création d'une zone (Haversine + write DB)
await performanceService.trace('zone_creation', () => _createZone(data));

// Temps de résolution d'un deep link d'invitation
await performanceService.trace('invitation_deeplink_resolve', () => _resolveInvitation(token));

// Temps de chargement des alertes communautaires à proximité
await performanceService.trace('nearby_alerts_load', () => _loadNearbyAlerts());
```

**Firebase Performance instrumente automatiquement** tous les appels HTTP via Dio/http sans configuration supplémentaire — les appels à `POST /api/location`, `GET /api/contacts`, etc. sont tracés automatiquement.

---

### RemoteConfigService — feature flags et paramètres dynamiques

```dart
// core/services/remote_config_service.dart
class RemoteConfigService {
  final FirebaseRemoteConfig _config = FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    await _config.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1), // 12h en prod, 0 en dev
    ));
    await _config.setDefaults(_defaults);
    await _config.fetchAndActivate();
  }

  // Valeurs par défaut — app fonctionnelle même sans connexion Remote Config
  static const Map<String, dynamic> _defaults = {
    'paywall_enabled': true,
    'community_alerts_enabled': true,
    'invisible_mode_duration_options': '60,240,0',  // 0 = manuel
    'min_app_version': '1.0.0',
    'location_update_interval_foreground': 10,       // secondes
    'location_update_interval_background': 300,      // secondes
    'free_tier_contacts_limit': 2,
    'free_tier_zones_limit': 1,
    'trial_duration_days': 7,
    'onboarding_skip_allowed': true,
  };

  bool get paywallEnabled => _config.getBool('paywall_enabled');
  bool get communityAlertsEnabled => _config.getBool('community_alerts_enabled');
  int get freeTierContactsLimit => _config.getInt('free_tier_contacts_limit');
  int get freeTierZonesLimit => _config.getInt('free_tier_zones_limit');
  int get locationIntervalForeground => _config.getInt('location_update_interval_foreground');
  int get trialDurationDays => _config.getInt('trial_duration_days');
}
```

**Usages Remote Config dans AlertContacts :**

| Paramètre                    | Utilité concrète                                                 |
| ---------------------------- | ---------------------------------------------------------------- |
| `paywall_enabled`            | Désactiver le paywall pour un test ou une promo sans déploiement |
| `free_tier_contacts_limit`   | Ajuster la limite gratuite (2 → 3) pour booster l'acquisition    |
| `location_update_interval_*` | Ajuster les fréquences selon les coûts Firebase Realtime DB      |
| `community_alerts_enabled`   | Kill switch en cas d'abus à grande échelle                       |
| `trial_duration_days`        | Tester 14 jours vs 7 jours en A/B testing                        |
| `min_app_version`            | Forcer les mises à jour critiques (complément du mécanisme V4)   |

---

### Règles absolues — RGPD & Vie privée

```
❌ Ne JAMAIS logger dans Crashlytics :
   - Email, nom, numéro de téléphone
   - Coordonnées GPS précises
   - Contenu des messages d'invitation personnalisés
   - Token Firebase Auth

✅ Toujours utiliser :
   - L'UID Firebase Auth (anonyme) comme identifiant Crashlytics
   - Des valeurs agrégées ou catégorisées (tier, état, compteur)
   - Des noms d'écran, pas des données affichées à l'écran
```

---

### Priorité de traitement des crashs

AlertContacts est une app de **sécurité**. Un crash pendant une alerte ou une détection de zone a un impact direct sur la tranquillité d'esprit de l'utilisateur. Appliquer cette priorité strictement :

| Priorité          | Écran / Fonctionnalité                            | Raison                 |
| ----------------- | ------------------------------------------------- | ---------------------- |
| P0 — Fix immédiat | Détection de zone + notification push             | Raison d'être de l'app |
| P0 — Fix immédiat | Réception et affichage d'une alerte communautaire | Sécurité physique      |
| P1 — Fix sous 24h | Auth + onboarding                                 | Bloque l'acquisition   |
| P1 — Fix sous 24h | Carte principale                                  | Valeur core immédiate  |
| P2 — Fix sous 72h | Paywall + abonnement                              | Impact revenus         |
| P3 — Planifié     | Paramètres, profil, historique alertes            | Secondaire             |

---

### Alertes à configurer dans la Firebase Console

Configurer ces alertes dans **Crashlytics > Alertes** dès le lancement :

- Crash rate > **1%** sur les 24 dernières heures → notification immédiate
- Nouveau crash type impactant > **10 utilisateurs** → notification immédiate
- Régression crash post-déploiement → notification automatique

---

### Dashboard de suivi — métriques clés à surveiller

**Stabilité (hebdomadaire)**

- Crash-free users rate → objectif > 99,5%
- ANR rate Android → objectif < 0,5%
- Top 5 crashes par nombre d'utilisateurs affectés

**Performance (hebdomadaire)**

- Temps médian `contacts_initial_load` → objectif < 800ms
- Temps médian `POST /api/location` → objectif < 300ms
- Temps médian `nearby_alerts_load` → objectif < 500ms

**Analytics — Funnels critiques (hebdomadaire)**

- Funnel onboarding : `app_open` → `onboarding_completed` → taux de completion
- Funnel Aha #1 : `onboarding_invitation_sent` → `aha_1_contact_accepted`
- Funnel monétisation : `paywall_displayed` → `subscription_trial_started` → `subscription_purchased`

**Rétention (mensuel)**

- Day 1 / Day 7 / Day 30 retention dans Firebase Analytics
- Corrélation entre `aha_1_contact_accepted` et rétention J7

## Backend Laravel — Bonnes pratiques

```php
// Rate limiting
// Max 1 requête POST /api/location par minute par utilisateur

// Détection de zone — Haversine
public function containsPoint(float $lat, float $lng): bool {
    $R = 6371000;
    $φ1 = deg2rad($this->lat);
    $φ2 = deg2rad($lat);
    $Δφ = deg2rad($lat - $this->lat);
    $Δλ = deg2rad($lng - $this->lng);
    $a = sin($Δφ/2)**2 + cos($φ1)*cos($φ2)*sin($Δλ/2)**2;
    $distance = $R * 2 * atan2(sqrt($a), sqrt(1-$a));
    return $distance <= $this->radius;
}
```

| Règle             | Description                                                        |
| ----------------- | ------------------------------------------------------------------ |
| Rate limiting     | Max 1 req/min sur `POST /api/location` par user                    |
| Index géospatiaux | SPATIAL INDEX sur lat/lng des tables zones et community_alerts     |
| Queue obligatoire | Toutes les notifications FCM → Queue Laravel — jamais synchrone    |
| Cache Redis       | Zones en cache Redis TTL 5min — évite MySQL à chaque position      |
| Logs position     | Ne logger QUE les changements d'état de zone — pas chaque position |

---

## Table critique — user_zone_states

Évite les notifications dupliquées à chaque update de position.

```sql
user_id     FK
zone_id     FK
state       ENUM('inside', 'outside')
entered_at  TIMESTAMP
exited_at   TIMESTAMP
updated_at  TIMESTAMP
```

---

## Marché & Positionnement

- **Marché prioritaire** : France + Europe francophone
- **Marché secondaire** : Afrique francophone (Cameroun, Côte d'Ivoire, Sénégal)
- **Concurrents** : Life360, Google Family Sharing, Find My (Apple)
- **Différenciation** : alertes communautaires + alerte privée proches uniquement + marché francophone

---

## Les 3 Aha Moments — Guider toutes les décisions UX

| Moment | Description                                                                   | Timing   |
| ------ | ----------------------------------------------------------------------------- | -------- |
| Aha #1 | "Quelqu'un me protège — je protège quelqu'un" — relation de confiance établie | J0       |
| Aha #2 | "Je vois où est mon proche en temps réel sur la carte"                        | J0 ou J1 |
| Aha #3 | "Je reçois une vraie alerte. Mon proche est arrivé à l'école."                | J1 à J7  |

**Aha #1 est la cible prioritaire de l'onboarding** — atteignable dès J0.
Toute décision UX/produit doit se demander : _"Est-ce que ça aide à atteindre un Aha Moment plus vite ?"_

---

## Décisions V4 figées — Ne pas remettre en question

| Décision            | Choix                                               |
| ------------------- | --------------------------------------------------- |
| Auth                | Passwordless — Magic Link + OAuth uniquement        |
| Navigation          | 3 tabs uniquement                                   |
| Onboarding slides   | Screenshots réels — pas d'illustrations             |
| Sandbox interactive | Supprimée définitivement                            |
| Geofencing          | Stack gratuite V1 — migration payante après revenus |
| Zones               | Circulaire uniquement V1 — polygonal en V2          |
| Offline             | Jamais bloquant — cache avec timestamp              |
| Bidirectionnalité   | Invitation retour requise pour voir mutuellement    |
| Paywall             | Après Aha Moment vécu — jamais avant                |

NB: Toujours repondre en Francais
