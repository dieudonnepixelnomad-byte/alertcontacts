# Prompt — Audit Firebase Analytics Tracking · AlertContacts V4

Colle ce prompt directement dans Claude Code à la racine du projet Flutter.

---

## CONTEXTE

Tu travailles sur **AlertContacts V4**, une app Flutter de sécurité familiale.
Stack : Flutter · Firebase Analytics · Firebase Auth · Firebase Realtime Database · Laravel 11 (backend).

L'app est **live en production** avec 100 téléchargements et 0 revenu.
L'objectif de cette mission est d'auditer le tracking Firebase Analytics existant pour identifier pourquoi les utilisateurs n'atteignent pas les Aha Moments et ne convertissent pas.

**Règle architecture :** Flutter est le seul pont entre Firebase et Laravel. Laravel ne lit jamais Firebase directement.

---

## MISSION

Effectue un audit complet du tracking Firebase Analytics dans le code Flutter.
**Ne modifie rien pour l'instant.** Analyse uniquement et produit un rapport.

---

## ÉTAPE 1 — Exploration de la structure

Explore la structure du projet Flutter et identifie :
- Le fichier de configuration Firebase (`google-services.json`, `firebase_options.dart`)
- Le(s) fichier(s) où `FirebaseAnalytics` est initialisé
- Tous les fichiers qui appellent `logEvent()` ou utilisent `FirebaseAnalytics`
- Le fichier `pubspec.yaml` pour vérifier la présence de `firebase_analytics`

---

## ÉTAPE 2 — Audit des événements critiques

Vérifie si les événements suivants sont bien loggés dans le code.
Pour chaque événement, indique : ✅ Présent | ❌ Manquant | ⚠️ Présent mais mal placé

### Funnel Onboarding
| Événement attendu | Paramètres attendus | Où il doit être loggé |
|---|---|---|
| `onboarding_started` | aucun | Après le splash screen |
| `profile_selected` | `profile_type: string` (enfants/parents/conjoint/moi) | Après sélection sur l'écran "Tu protèges qui ?" |
| `auth_started` | `method: string` (google/apple/magic_link) | Tap sur un bouton d'auth |
| `auth_completed` | `method: string`, `is_new_user: bool` | Après connexion réussie Firebase |
| `invitation_screen_viewed` | aucun | Affichage de l'écran invitation proche |
| `invitation_sent` | `method: string` (share_sheet/qr_code) | Après confirmation du share sheet |
| `onboarding_skipped` | `step: string` | Tap sur "Pas maintenant" |
| `app_shell_reached` | aucun | Premier affichage de la carte principale |

### Aha Moments
| Événement attendu | Paramètres attendus | Où il doit être loggé |
|---|---|---|
| `aha_moment_1` | aucun | Quand un proche accepte l'invitation (notification reçue ou GET /api/contacts retourne >= 1 proche actif) |
| `aha_moment_2` | aucun | Quand la position d'un proche s'affiche sur la carte pour la première fois |
| `aha_moment_3` | aucun | Quand l'utilisateur reçoit sa première notification d'entrée/sortie de zone |

### Engagement & Rétention
| Événement attendu | Paramètres attendus | Où il doit être loggé |
|---|---|---|
| `zone_created` | `radius: int`, `has_contacts: bool` | Après POST /api/zones réussi |
| `alert_created` | `gravity: string`, `type: string`, `visibility: string` | Après POST /api/alerts réussi |
| `alert_confirmed` | aucun | Tap sur "Je confirme" |
| `invisible_mode_activated` | `duration_minutes: int` | Après activation mode invisible |
| `contact_invited` | `profile_type: string` | Chaque invitation envoyée (hors onboarding) |

### Monétisation
| Événement attendu | Paramètres attendus | Où il doit être loggé |
|---|---|---|
| `paywall_shown` | `trigger: string` (limit_hit/proactive_card/settings) | Affichage du paywall |
| `paywall_dismissed` | `trigger: string` | Fermeture sans action |
| `subscription_started` | `tier: string`, `billing: string` (monthly/annual) | Après POST /api/subscriptions réussi |
| `free_trial_started` | `tier: string` | Début d'essai gratuit |

---

## ÉTAPE 3 — Vérification de la configuration de base

Vérifie les points suivants et signale tout problème :

1. **Initialisation** : `FirebaseAnalytics.instance` est-il bien initialisé avant le premier `logEvent()` ?
2. **User Properties** : Les propriétés utilisateur suivantes sont-elles définies après connexion ?
   - `user_tier` (free/solo/famille)
   - `profile_type` (enfants/parents/conjoint/moi)
   - `has_active_contact` (true/false)
3. **Screen tracking** : `setCurrentScreen()` ou `logScreenView()` est-il appelé sur les écrans principaux (Carte, Proches, Alertes, Paramètres, Paywall) ?
4. **Paramètres des événements** : Les noms d'événements respectent-ils la limite de 40 caractères Firebase ? Les paramètres respectent-ils la limite de 25 caractères ?

---

## ÉTAPE 4 — Rapport de sortie

Produis un rapport structuré en markdown avec exactement ces sections :

```
## Résumé exécutif
[2-3 phrases sur l'état global du tracking]

## Score de couverture
Événements présents : X/Y
Événements manquants : X/Y
Événements mal placés : X/Y

## Événements manquants critiques
[Liste des événements absents classés par priorité : CRITIQUE / IMPORTANT / NICE TO HAVE]
[CRITIQUE = bloque l'analyse du funnel]
[IMPORTANT = bloque l'analyse de la rétention]
[NICE TO HAVE = enrichit l'analyse mais pas bloquant]

## Problèmes de configuration
[Problèmes d'initialisation, user properties, screen tracking]

## Plan de correction priorisé
[Liste ordonnée des fichiers à modifier avec ce qu'il faut ajouter — sans code pour l'instant]

## Estimation du travail de correction
[Nombre de fichiers à modifier, complexité estimée]
```

---

## CONTRAINTES

- Ne modifie aucun fichier pendant cet audit
- Si tu ne trouves pas de fichier Analytics, signale-le immédiatement — c'est le problème le plus grave possible
- Si le projet utilise un wrapper Analytics custom (ex: `AnalyticsService`, `TrackingService`), audite ce wrapper en priorité
- Ignore les événements automatiques Firebase (`first_open`, `session_start`, etc.) — concentre-toi uniquement sur les événements custom

---

*Prompt généré pour AlertContacts V4 — Mission diagnostic Analytics — Juin 2026*
