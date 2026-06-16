# AlertContacts V4 — Suivi d'avancement

> Version cible : **4.0.0+1** | Base : V3.1.4+40
> CDC de référence : `docs/AlertContacts_CDC_V4_1.pdf`
> Ordre d'exécution : F0 → F1 → F2 → F3 → F4 → F5 → F6 → F7 → F8 → F9 → F10 → F11 → F12

---

## ✅ Terminé

### F0 — Foundation
- `pubspec.yaml` : version `4.0.0+1`, ajout `google_fonts` (Manrope)
- `lib/theme/colors.dart` : tokens V4 complets
- `lib/theme/typography.dart` : specs CDC (titleLarge 20sp w500, micro 10sp w500, etc.)

### F1 — Splash Screen V4
- `lib/features/splash/presentation/splash_page.dart`
- Fond `#1E6868`, 3 blobs animés (CustomPainter), logo dégradé orange→pink
- Animation scale 0.8→1.0 (300ms) + tagline +150ms, durée 1.8s MAX

### F2 — Auth V4 Passwordless
- `lib/features/auth/presentation/login_page.dart` : Apple + Google + Magic Link
- `lib/features/auth/presentation/magic_link_sent_page.dart` : countdown 30s + deep link mail
- `lib/features/auth/providers/auth_notifier.dart` : suppression password/register/reset
- Routes `/register`, `/email-verification`, `/forgot-password` supprimées
- Route `/auth/magic-link-sent` ajoutée

### F3 — Onboarding V4
- `lib/features/onboarding/presentation/personalization_page.dart` : 4 cards 2×2 grid, pre-auth
- `lib/features/onboarding/presentation/onboarding_slides_page.dart` : 3 slides placeholder + dots
- `lib/features/onboarding/presentation/onboarding_invitation_page.dart` : navigation → appShell
- `lib/router/app_router.dart` : cascade V4 (perso → auth → slides → invitation → appShell)
- `lib/core/services/prefs_service.dart` : ajout flag `isOnboardingSlidesSeen`
- **Backend** : alias `POST /api/auth/onboarding/complete` → `UserOnboardingController@complete`

### F4 — App Shell V4
- `lib/features/app_shell/presentation/app_shell.dart` : 3 tabs (Carte / Proches / Alertes)
  - Suppression drawer `NavbarDrawer`, `AppBar`, banner vérification email
  - `print()` → `log()` (dart:developer)
- `lib/features/app_shell/providers/navigation_provider.dart` : index 0-2, méthodes V4

### F5 — Carte V4
- `lib/features/home_map/presentation/home_page.dart`
  - Header overlay glass (BackdropFilter blur) : ⊞ calques gauche | connectivity dot + N connectés centre | avatar droite
  - Connectivity status : vert (wifi/mobile) / orange (instable) / rouge (none)
  - Empty state card flottante (bas) : "Tes proches apparaîtront ici" + CTA inviter
  - Recenter FAB (bas-droite) remplace les anciens FABs de création
  - Suppression : FilterChips, SearchBar, FABs création zones/dangers
  - Safe zones : cercles dashed (AppColors.success)

### F6 — Proches V4
**Flutter**
- `lib/features/proches/presentation/proches_tab.dart` : réécriture complète V4
  - Header "N CONNECTÉS · N EN ATTENTE", 4 états contact (actif/pause/offline/attente)
  - Cards avec dot statut + chevron + FAB "+"
  - Tap card → `ContactBottomSheet`
- `lib/features/proches/presentation/contact_bottom_sheet.dart` : créé
  - Actions contextuelles selon état (voir carte / renvoyer invitation / permissions / retirer)
- `lib/features/proches/presentation/permissions_modal.dart` : créé
  - 4 toggles (Position / Batterie / Zones / Vitesse) + bouton Enregistrer

**Backend (Laravel)**
- `database/migrations/2026_06_12_000001_add_v4_permissions_to_relationships_table.php`
  - 4 colonnes booléennes : `share_position`, `share_battery`, `share_zone_events`, `share_speed`
- `RelationshipController@updatePermissions` : méthode ajoutée
- Route `PUT /api/contacts/{relationship}/permissions` : ajoutée

### F7 — Zones Panel V4
**Flutter**
- `lib/features/zones/presentation/zones_panel.dart` : overlay slide-in depuis gauche
  - Liste zones + empty state + bouton dashed "Créer une zone"
- `lib/features/zones/presentation/zone_creation_wizard.dart` : wizard 3 étapes
  - Étape 1 : carte interactive + tap = centre
  - Étape 2 : slider rayon 50–500m + cercle en temps réel
  - Étape 3 : nom + icône (6 choix) + CTA coloré
- `lib/features/home_map/presentation/home_page.dart` : bouton ⊞ wired → `ZonesPanel` (slide-in gauche)

**Backend (Laravel)**
- `app/Http/Controllers/Api/ZoneController.php` : créé
  - `index`, `store`, `update`, `destroy` sur modèle `SafeZone`
  - `status` : statut en-zone par proche (Haversine)
- Routes `apiResource zones` + `GET /api/zones/{zone}/status` : ajoutées

### F8 — Alertes V4
**Flutter**
- `lib/features/alertes/presentation/alertes_page.dart` : réécriture complète
  - Tabs filtre horizontal (Tout / Proches / Zones / Communauté)
  - Groupement par date (Aujourd'hui / Hier)
  - Badges non-lus + "Tout lire"
  - FAB rouge → `AlertCreationFlow`
- `lib/features/alertes/presentation/alert_creation_flow.dart` : créé
  - Étape 1 : gravité (3 niveaux) + type (6 types grille 2 colonnes)
  - Étape 2 : description + anonymat + visibilité
  - CTA couleur = gravité (friction intentionnelle)
- `lib/features/alertes/presentation/alert_detail_page.dart` : créé
  - Badge gravité + confirmations progress bar + boutons Confirmer/Pas vu/Signaler

**Backend (Laravel)**
- `database/migrations/2026_06_12_000002_add_v4_fields_to_danger_zones_table.php`
  - Colonnes : `visibility ENUM(public/contacts_only)`, `is_anonymous BOOLEAN`
- `app/Http/Controllers/Api/AlertController.php` : créé
  - `nearby` : filtrage Haversine + visibility par contacts
  - `store` : création alerte avec config gravité auto (rayon/durée)
  - `confirm`, `deny`, `report`
- Routes V4 alertes ajoutées

### F9 — Mode Invisible (Premium)
**Flutter**
- `lib/features/home_map/presentation/invisible_mode_sheet.dart` : créé
  - Options : 1h / 4h / Jusqu'à réactivation
  - État actif : badge + CTA "Reprendre"
  - `InvisibleModeBanner` : widget orange overlay sur la carte
- `lib/features/home_map/presentation/home_page.dart` wired :
  - Long-press sur carte → ouvre `InvisibleModeSheet`
  - Banner orange si mode actif (avec countdown heure)

**Backend (Laravel)**
- `database/migrations/2026_06_12_000003_add_invisible_mode_to_users_table.php`
  - Colonnes : `location_paused BOOLEAN`, `invisible_until TIMESTAMP NULL`
- `LocationController@pause` + `LocationController@resume` : méthodes ajoutées
- Routes `POST /api/location/pause` + `POST /api/location/resume` : ajoutées

### F10 — Paywall V4
**Flutter**
- `lib/features/paywall/presentation/paywall_page.dart` : créé
  - Toggle mensuel/annuel (annuel par défaut)
  - 3 cards tiers : Gratuit / Solo / Famille
  - Badge "Essai 7 jours" (annuel uniquement)
  - Badges économies (42% Solo / 44% Famille)
  - CTAs différenciés selon cycle
- `lib/core/services/paywall_trigger_service.dart` : créé
  - `checkContactLimit()`, `checkZoneLimit()`, `shouldShowProactive()`

**Backend (Laravel)**
- `database/migrations/2026_06_12_000004_create_subscriptions_table.php`
- `app/Http/Controllers/Api/SubscriptionController.php` : créé
  - `index`, `store`, `familyInvite`, `familyRemove`
- `app/Http/Middleware/CheckSubscriptionTier.php` : créé
- Routes `/api/subscriptions` + routes famille ajoutées

### F11 — Settings V4
**Flutter**
- `lib/features/settings/presentation/settings_page.dart` : réécriture complète
  - Header avatar + nom + email (depuis AuthNotifier)
  - Section Confidentialité : Mode invisible, Paramètres partage
  - Section App : Notifications, Langue, CGU, Politique
  - Section Compte : Abonnement (badge tier) → PaywallPage, Export données, Déconnexion
  - Danger zone : Supprimer compte (rouge, confirmation)

### F12 — Edge Cases
**Flutter**
- `lib/shared/widgets/offline_banner.dart` : banner rouge non-bloquant
  - Texte cache + timestamp + bouton Réessayer
- `lib/shared/widgets/low_battery_banner.dart` : banner amber batterie faible
  - "🔋 Batterie de [Prénom] faible · X%" + CTAs Écrire/Appeler (SMS/tel: natif)
- `lib/features/permissions/presentation/gps_denied_page.dart` : page GPS refusé
  - 3 étapes numérotées + CTA "Ouvrir les réglages" + "Continuer sans GPS"

---

## ✅ Backend F3 — Alias onboarding
- Route `POST /api/auth/onboarding/complete` → `UserOnboardingController@complete` ajoutée

---

## Résultat `dart analyze` par feature

| Feature | Issues |
|---|---|
| F0 Foundation | ✅ 0 |
| F1 Splash | ✅ 0 |
| F2 Auth | ✅ 0 |
| F3 Onboarding | ✅ 0 |
| F4 App Shell | ✅ 0 |
| F5 Carte | ✅ 0 |
| F6 Proches V4 | ✅ 0 |
| F7 Zones Panel V4 | ✅ 0 |
| F8 Alertes V4 | ✅ 0 |
| F9 Mode Invisible | ✅ 0 |
| F10 Paywall | ✅ 0 |
| F11 Settings | ✅ 0 |
| F12 Edge Cases | ✅ 0 |

---

## ✅ V4.1 — Intégrations (terminé)

### Adapty — Monétisation
- `lib/core/config/adapty_config.dart` : clé SDK + placement IDs + product IDs
- `lib/core/services/adapty_service.dart` : activate, identifyUser, isPremium, getProducts, makePurchase, restorePurchases
- `lib/main.dart` : `AdaptyService.instance.activate()` après Firebase init
- `lib/core/services/paywall_trigger_service.dart` : `isPremium()` branché sur Adapty
- `lib/features/paywall/presentation/paywall_page.dart` : prix réels Adapty, achats vrais, restauration, loader overlay

### Alertes communautaires — API réelle
- `lib/core/models/community_alert.dart` : modèle complet (gravity, type, visibility, confirmations)
- `lib/core/services/api_alerts_service.dart` : getNearbyAlerts, createAlert, confirm/deny/report
- `lib/features/alertes/providers/alert_provider.dart` : fetchNearbyAlerts, markRead, markAllRead
- `lib/features/alertes/presentation/alertes_page.dart` : consomme AlertProvider, OfflineBanner, pull-to-refresh

### Paywall — Triggers opérationnels
- `lib/features/proches/presentation/proches_tab.dart` : vérification paywall avant invitation (contact_limit)
- `lib/features/zones/presentation/zone_creation_wizard.dart` : vérification paywall + appel API réel createZone
- `lib/core/services/api_zones_service.dart` : `createZone()` ajouté
- `lib/core/repositories/zones_repository.dart` : `createZone()` ajouté
- `lib/features/zones/providers/zones_notifier.dart` : `createZone()` ajouté

### Mode invisible — API branché
- `lib/core/services/api_location_service.dart` : pauseLocation, resumeLocation
- `lib/features/home_map/presentation/home_page.dart` : onActivate/onResume → POST /api/location/pause|resume

### Edge cases — Banners intégrés
- `lib/features/home_map/presentation/home_page.dart` : OfflineBanner dans Stack
- `lib/features/alertes/presentation/alertes_page.dart` : OfflineBanner dans CustomScrollView
- `lib/features/proches/presentation/proches_tab.dart` : LowBatteryBanner pour contacts < 20%
- `lib/core/models/contact_relation.dart` : champ `batteryLevel` ajouté

### Observabilité
- `lib/core/services/analytics_service.dart` : tous les events spec CLAUDE.md ajoutés
  (Aha moments, contacts, zones, alertes communautaires, monétisation, géoloc, engagement)
- `lib/core/services/crashlytics_service.dart` : CrashlyticsService créé (spec CLAUDE.md)

---

## Résultat `dart analyze` — V4.1

| Scope | Issues |
|---|---|
| Nouveaux fichiers V4.1 | ✅ 0 erreurs |
| Global projet | ⚠️ warnings/infos préexistants uniquement |

---

## Prochaines étapes — V4.2

| Priorité | Tâche |
|---|---|
| P1 | Configurer Adapty Dashboard (clé SDK, produits, placements, access level `premium`) |
| P1 | Middleware `tier:solo,famille` activé sur `POST /api/alerts` côté Laravel |
| P2 | `AdaptyService.identifyUser()` appelé après login Firebase dans `AuthNotifier` |
| P2 | `AdaptyService.logoutUser()` appelé lors du logout |
| P2 | `AnalyticsService.logPaywallDisplayed()` appelé dans `PaywallPage.initState` |
| P3 | `CrashlyticsService` utilisé à la place des appels directs dans `AnalyticsService` |
| P3 | Traces Performance : `contacts_initial_load`, `zone_creation`, `nearby_alerts_load` |
| P3 | FCM → stockage local des events zone/contact pour `AlertesPage` |
