# CLAUDE.md — AlertContacts V3

## Contexte du projet

**AlertContacts** est une application mobile de sécurité personnelle et familiale.
- **Version** : 3.1.4+40
- **Stack** : Flutter (Dart), iOS & Android
- **Backend** : REST HTTP (Laravel), Firebase Auth, FCM, Google Maps
- **Stockage local** : Hive, SharedPreferences

L'app permet de surveiller l'entrée/sortie de proches dans des zones de sécurité, de recevoir des alertes communautaires sur des zones de danger, et de gérer un réseau de proches avec des niveaux de partage de localisation configurables.

---

## Flux de navigation principal

```
Splash → Onboarding → Auth → Permissions → User Setup → Safezone Setup → App Shell
```

- **Onboarding** : affiché uniquement au 1er lancement
- **Auth** : obligatoire (Email, Google, Apple via Firebase)
- **Permissions** : localisation précise, localisation arrière-plan, notifications, ATT (iOS)
- **Safezone Setup** : création d'au moins une zone de sécurité obligatoire avant accès à l'app

---

## Modules principaux

### Auth (F-AUTH)
Email/mot de passe, Google OAuth, Sign in with Apple, vérification email, reset mot de passe, mise à jour forcée si version obsolète.

### Proches (F-PROCHE)
3 niveaux de partage : `realtime` (GPS continu) / `alert_only` (alertes zones uniquement) / `none`.
Invitations par lien/token/QR Code, expiration 7 jours, PIN optionnel, statuts : `pending` / `accepted` / `refused` / `expired`.

### Zones de sécurité — SafeZones (F-SAFE)
Zones géographiques personnalisées (nom, icône, centre GPS, rayon en mètres). Création obligatoire d'au moins une zone au setup. Zones illimitées en premium.

### Zones de danger — DangerZones (F-DANGER)
Signalement communautaire. 14 types (agression, braquage, harcèlement, vol...), 3 niveaux de sévérité (`low` / `med` / `high`). Alertes vocales + vibration à l'approche.

### Carte (F-MAP)
Google Maps Flutter. Overlay des SafeZones, DangerZones, et positions des proches en temps réel.

### Alertes (F-ALERT / F-NOTIF)
TTS fr-FR par défaut, vibrations configurables, notifications FCM avant-plan et arrière-plan, deep links, retry sur alertes critiques non délivrées.

### Premium
`unlimited_zones` / `multi_contacts` / `detailed_history`

---

## Modèle de données clé

```
User
 └── ContactRelation → ShareLevel (realtime / alert_only / none)

SafeZone → Center (LatLng), radiusMeters, memberIds

DangerZone → DangerType (15 types), DangerSeverity (low/med/high), confirmations communautaires

Invitation → Token, PIN, expiration, maxUses, deep link

UserActivity → Action, EntityType, Metadata
```

---

## Contraintes à respecter

- Cooldown alertes : 1 alerte / zone / 24h max (géré backend)
- Permissions localisation arrière-plan : critiques, à demander avec justification explicite
- Langue : français par défaut, architecture i18n
- Une demande de permission refusée sur iOS/Android est **irréversible** — ne jamais les demander au mauvais moment

---

## Connaissances onboarding mobile

Ce projet contient un dossier de référence sur l'onboarding et les métriques d'applications mobiles.

**Emplacement** : `.claude/onboarding/`

```
.claude/onboarding/
├── SKILL.md                      ← Point d'entrée, lire en premier
├── references/
│   ├── audit-framework.md        ← Tunnel de conversion, cas pratiques (Duolingo, Notion, Airbnb...)
│   ├── patterns-et-conception.md ← Les 5 patterns qui fonctionnent, Quick Win, personnalisation
│   ├── aha-moment.md             ← Identifier et accélérer le Aha Moment
│   ├── metriques-et-tests.md     ← Benchmarks D1/D7/D30, outils analytics, méthodo A/B
│   └── erreurs-et-checklist.md  ← 10 erreurs classiques, checklist finale, plan 30 jours
```

**Quand consulter ces fichiers** :
- Toute question sur le flow d'onboarding d'AlertContacts → lire `SKILL.md` puis le fichier pertinent
- Audit du tunnel Splash→Auth→Permissions→SafezoneSetup → `audit-framework.md`
- Conception ou refonte du flow d'inscription → `patterns-et-conception.md`
- Trouver le Aha Moment d'AlertContacts → `aha-moment.md`
- Définir les métriques de rétention à tracker → `metriques-et-tests.md`
- Checklist avant mise en production → `erreurs-et-checklist.md`

### Aha Moment probable d'AlertContacts
Le vrai Aha Moment n'est probablement pas "créer une zone de sécurité". Il est probablement **la première alerte réelle reçue** : quand un proche entre ou sort d'une zone, ou quand l'app détecte une zone de danger à proximité. Tout l'onboarding doit être optimisé pour que l'utilisateur vive cette expérience le plus vite possible.

### Points de friction identifiés dans le flow actuel
Le flow `Splash → Onboarding → Auth → Permissions → User Setup → Safezone Setup → App Shell` comporte plusieurs risques majeurs :

1. **Permissions demandées trop tôt** : localisation arrière-plan et notifications avant que l'utilisateur ait compris la valeur de l'app → taux de refus élevé, irréversible sur iOS
2. **Safezone Setup obligatoire avant accès** : l'utilisateur doit créer une zone sans avoir encore compris pourquoi → friction temporelle et cognitive élevée
3. **Inscription obligatoire avant toute démonstration de valeur** : aucune démonstration avant le wall d'auth

---

## Comportement attendu de Claude sur ce projet

- Toujours raisonner dans le contexte Flutter/Dart sauf instruction contraire
- Pour toute question d'architecture onboarding ou de rétention, consulter les fichiers `.claude/onboarding/` avant de répondre
- Signaler proactivement quand une décision de design risque de créer de la friction inutile
- Les permissions `ACCESS_BACKGROUND_LOCATION` et notifications sont critiques : ne jamais suggérer de les demander sans justification contextuelle préalable
