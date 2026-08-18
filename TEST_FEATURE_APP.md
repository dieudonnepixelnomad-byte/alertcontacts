# TEST_FEATURE_APP — Plan de test manuel AlertContacts V4.1

> Référence : `CLAUDE.md`, `AlertContacts_CDC_V4_1.pdf`, `docs/AlertContacts_CDC_V4.1_Addendum_Trajets.md`
> Objectif : valider que **toutes les features gratuites fonctionnent** et que **toutes les features payantes sont bloquées**.

---

## 1. Préalables

### 1.1 Environnement

| Élément | Valeur |
|---|---|
| App mobile | Flutter — build debug sur device réel (le GPS et FCM ne sont pas fiables en émulateur) |
| Backend | Laravel — `alertcontacts-admin` |
| Comptes nécessaires | **2 minimum** (A = testeur principal, B = proche). 3 comptes pour tester la limite de proches. |

### 1.2 Changer de tier — il n'existe aucun parcours d'achat

⚠️ **Point central de cette campagne de test.** La `PaywallPage` n'a **aucun bouton d'achat câblé** : elle affiche les arguments, un lien « Voir la comparaison des plans », et se ferme. Le webhook RevenueCat existe côté backend mais aucun flux d'achat client ne l'appelle.

**Conséquence : on ne peut pas devenir abonné depuis l'app.** C'est le comportement attendu à ce stade — le test consiste à vérifier que le blocage est propre, pas à acheter.

Pour vérifier le comportement **payant** (section 9), le seul moyen est de forcer le tier en base :

```sql
-- Passer en payant
UPDATE users SET tier = 'solo' WHERE email = 'testeur@example.com';
-- Revenir en gratuit (à faire après chaque test payant)
UPDATE users SET tier = 'free' WHERE email = 'testeur@example.com';
```

⚠️ Après changement en base, **se déconnecter / reconnecter** dans l'app : le `tier` n'est transmis qu'à l'authentification (voir anomalie A-03).

### 1.3 Légende

| Symbole | Sens |
|---|---|
| ✅ | Doit fonctionner |
| 🔒 | Doit être bloqué (paywall ou erreur explicite) |
| ⚠️ | Anomalie connue avant test — voir section 10 |
| N/A | Non implémenté (V2 ou non développé) — ne pas tester |

---

## 1.4 Protocole détaillé — Tests nécessitant 2 comptes (téléphone + émulateur)

> Setup réel utilisé pour cette campagne : **A = téléphone physique** (build debug, GPS/FCM fiables), **B = émulateur Android** (AVD). Tous les tests des sections 4, 5, 6, 9 qui impliquent un « proche » se font avec ce duo. Cette section donne la procédure **exacte**, commande par commande.

### 1.4.1 Créer l'émulateur (une seule fois)

1. Android Studio → Device Manager → Create Device.
2. Choisir un profil (ex. Pixel 7).
3. **Image système : impérativement une image avec Google Play Store** (icône ▶️ à côté du nom, ex. `Tiramisu API 33 (Google Play)`) — sans ça, **FCM ne fonctionnera pas** et les tests de notifications (5.5, 5.6, 5.7, 6.12, 9.6) échoueront systématiquement pour de mauvaises raisons.
4. Lancer l'AVD, se connecter au Play Store avec un compte Google de test (pas obligatoire pour l'app elle-même, mais nécessaire pour que Play Services s'initialise correctement).
5. Installer le build debug : `flutter run -d emulator-5554` (ou `flutter install` si déjà buildé), pendant que le téléphone tourne en parallèle sur `flutter run -d <id-telephone>`. Pour lister les devices : `flutter devices`.
6. Sur l'émulateur, faire l'onboarding complet avec le compte **B**. Sur le téléphone, avec le compte **A**.

### 1.4.2 Simuler la position GPS sur l'émulateur

L'émulateur n'a pas de GPS réel — on **injecte** une position via ADB ou l'UI Extended Controls.

**Méthode ADB (rapide, scriptable) :**
```bash
adb -s emulator-5554 emu geo fix <longitude> <latitude>
# Exemple — Tour Eiffel, Paris
adb -s emulator-5554 emu geo fix 2.2945 48.8584
```
⚠️ L'ordre est **longitude puis latitude** (inverse de l'usage courant).

**Méthode UI (visuelle) :** dans la fenêtre de l'émulateur, cliquer sur `⋮` (Extended Controls) → **Location** → saisir lat/lng ou cliquer sur la carte → **Send**.

**Important** : après un `geo fix`, l'app ne se met pas toujours à jour instantanément (le `geolocator`/`background_fetch` écoute les changements de position, pas un simple mock statique). Pour forcer une lecture immédiate :
- Mettre l'app **au premier plan** sur l'émulateur juste après le `geo fix` (la carte redemande la position à l'ouverture).
- Ou envoyer 2-3 positions à quelques secondes d'intervalle pour simuler un mouvement réel et déclencher les listeners.

**Simuler un trajet (entrée/sortie de zone) :** enchaîner plusieurs `geo fix` avec un léger décalage pour simuler une approche progressive, puis une position franchement à l'intérieur du rayon de la zone, puis une position à l'extérieur :
```bash
adb -s emulator-5554 emu geo fix 2.2950 48.8580   # approche
sleep 5
adb -s emulator-5554 emu geo fix 2.2945 48.8584   # dans la zone (si zone centrée ici, rayon ≥ 50m)
sleep 15
adb -s emulator-5554 emu geo fix 2.3050 48.8650   # hors zone (~1km plus loin)
```

### 1.4.3 Transmettre le lien d'invitation entre A et B

Trois options, de la plus simple à la plus fiable :

1. **Copier/coller manuel** : sur A, générer le lien (Proches → Ajouter), le partager par un canal externe (mail, Slack, note) accessible depuis le navigateur de l'émulateur, puis l'ouvrir depuis B.
2. **ADB intent direct** (le plus rapide, évite tout copier/coller) — récupérer le token/URL généré sur A, puis :
   ```bash
   adb -s emulator-5554 shell am start -a android.intent.action.VIEW -d "https://alertcontacts.app/invite/<TOKEN>"
   ```
   (adapter le scheme au deep link réel configuré dans `AndroidManifest.xml` — vérifier avec `grep -r "android:scheme" android/app/src/main/AndroidManifest.xml` si besoin).
3. **QR code** : si l'écran d'invitation propose un QR code, l'afficher sur le moniteur et le scanner via la caméra virtuelle de l'émulateur (Extended Controls → Camera).

### 1.4.4 Vérifier que les notifications push arrivent bien sur l'émulateur

- Condition préalable : image AVD avec Google Play (§1.4.1) + permission notifications accordée dans l'app sur B.
- Pour confirmer que le token FCM est bien enregistré côté device B, regarder les logs au lancement : `flutter logs -d emulator-5554` et chercher la ligne d'enregistrement du token (`FcmService`).
- Si un push attendu n'arrive jamais sur B : vérifier d'abord que ce n'est pas un problème d'émulateur (Play Services) avant de considérer que c'est un bug applicatif — tester en parallèle sur le téléphone A pour comparer.

### 1.4.5 Procédure détaillée par groupe de tests

**Groupe Proches (§4 — tests 4.1 à 4.11)**

| Étape | Action | Device |
|---|---|---|
| 1 | Proches → Ajouter → générer l'invitation (test 4.1) | A |
| 2 | Transmettre le lien via §1.4.3 | A → B |
| 3 | Ouvrir le lien, accepter (test 4.2) | B |
| 4 | Retourner sur la carte : vérifier A visible chez B, mais B **grisé** chez A avec CTA « Invite B pour le voir aussi » (test 4.3) | A |
| 5 | Sur B, inviter A en retour (nouveau lien, transmettre à nouveau) | B → A |
| 6 | A accepte (test 4.4) : vérifier que A et B se voient désormais **tous les deux normalement** (plus grisés) | A + B |
| 7 | Pour tester le refus (test 4.5) : répéter 1-3 avec un 3ᵉ compte C, mais refuser depuis B au lieu d'accepter → vérifier notification de refus reçue par A | A + C |
| 8 | Couper le réseau/wifi de l'émulateur (Extended Controls → Cellular → basculer en mode avion, ou couper le wifi hôte de l'AVD) : vérifier sur A que l'avatar de B passe **grisé** avec dernière position connue + timestamp (test 4.7) | A + B |
| 9 | Limite à 2 proches (test 4.8/4.9) : répéter l'invitation avec un 3ᵉ compte C depuis A → doit être bloqué par un paywall côté A, et l'acceptation côté C doit renvoyer 403 `SUBSCRIPTION_LIMIT_REACHED` sans créer la relation | A + C |
| 10 | Suppression (4.10/4.11) : sur A, supprimer B → vérifier que B ne voit plus A non plus (bidirectionnel) → réinviter B, vérifier que ça repasse | A + B |

**Groupe Zones (§5 — tests 5.4 à 5.8)**

| Étape | Action | Device |
|---|---|---|
| 1 | Sur A, créer une zone centrée sur des coordonnées connues, ex. `48.8584, 2.2945` (Tour Eiffel), rayon 100m | A |
| 2 | Assigner B à la zone → vérifier que seul B (proche déjà accepté) apparaît dans la liste d'assignation (test 5.4) | A |
| 3 | Vérifier que B reçoit une notification d'assignation (test 5.5) — cf §1.4.4 si rien n'arrive | B |
| 4 | Placer B loin de la zone : `adb -s emulator-5554 emu geo fix 2.3200 48.8700` | B |
| 5 | Déplacer B progressivement vers l'intérieur de la zone (cf §1.4.2, séquence de `geo fix`) jusqu'à une position dans le rayon, ex. `2.2945 48.8584` | B |
| 6 | Vérifier sur A la réception du push « ✅ [B] est arrivé(e) » (test 5.6) | A |
| 7 | Rester dans la zone : envoyer 2-3 `geo fix` avec de très légères variations (± 0.0001°) autour du centre → vérifier qu'**une seule** notification d'entrée est reçue, pas de doublon (test 5.8) | B → A |
| 8 | Envoyer un `geo fix` clairement hors du rayon (> 500m du centre) → vérifier la notification « 🚪 [B] a quitté [Zone] » (test 5.7) | B → A |

**Groupe Alertes communautaires (§6 — tests 6.5 à 6.8, 6.12)**

| Étape | Action | Device |
|---|---|---|
| 1 | Positionner A et B à proximité l'un de l'autre via `geo fix` sur B (même zone géographique que A) | A + B |
| 2 | Sur B, créer une alerte gravité élevée (FAB → type → gravité → confirmer position) | B |
| 3 | Vérifier sur A la réception du push « 🔴 Danger signalé à [X] m » (test 6.12) — délai possible de quelques secondes | A |
| 4 | Sur A, ouvrir l'incident → « Je le vois aussi » → vérifier l'incrément du compteur de confirmations (test 6.6) | A |
| 5 | Test doublon (6.5) : depuis A, tenter de signaler un incident compatible à < 150m de celui créé par B → vérifier le message « Un incident similaire est déjà signalé ici. Confirmer ? » | A |
| 6 | Sur A, résoudre l'incident (« C'est terminé ») → vérifier l'incrément de `clear_count` (test 6.7) | A |
| 7 | Sur B, signaler l'incident créé par A comme abus (test 6.8) | B |

**Test 9.6 — Surveillance pendant le trajet (nécessite tier payant sur A)**

| Étape | Action | Device |
|---|---|---|
| 1 | Passer A en `tier = 'solo'` en base (§1.2), se déconnecter/reconnecter | A |
| 2 | Sur A, démarrer un trajet vers une destination éloignée | A |
| 3 | Pendant que le trajet est actif sur A, sur B créer une alerte communautaire **devant** le trajet en cours (position sur le tracé, via `geo fix`) | B |
| 4 | Vérifier que A reçoit un push de surveillance de trajet (test 9.13.e, tier payant) | A |
| 5 | Repasser A en `tier = 'free'`, se reconnecter, répéter 2-3 → vérifier qu'**aucun** push n'arrive cette fois (test 9.6) | A + B |

**Test 2.9 — Célébration après acceptation d'invitation**

- Se déclenche naturellement à l'étape 3 du groupe Proches ci-dessus (acceptation sur B) : observer l'animation de renforcement positif sur l'écran d'acceptation de B juste après le tap.

### 1.4.6 Pièges fréquents à ne pas confondre avec un vrai bug

| Symptôme | Cause probable | Pas un bug si… |
|---|---|---|
| Aucun push ne parvient à l'émulateur | Image AVD sans Google Play Store | Recréer l'AVD avec une image « Google Play » (§1.4.1) |
| La position de B ne bouge pas dans l'app malgré `geo fix` | App en arrière-plan, listener pas déclenché | Remettre l'app au premier plan ou envoyer 2-3 `geo fix` successifs (§1.4.2) |
| Entrée de zone détectée en double | `geo fix` envoyés trop vite, l'app lit une position « limite » plusieurs fois avant stabilisation | Espacer les `geo fix` d'au moins 3-5 secondes |
| Notification en retard de plusieurs dizaines de secondes | Queue Laravel + fréquence d'update adaptative (cf. tableau géoloc CLAUDE.md) — normal en usage réel | Comparer au timing attendu selon l'état (foreground/background) avant de considérer que c'est un bug |

---

## 2. Onboarding & Authentification — tier Gratuit

| # | Test | Étapes | Résultat attendu | Statut | OK ? |
|---|---|---|---|---|---|
| 2.1 | Splash | Lancer l'app | Fond `#1E6868`, logo dégradé, tagline, durée ≤ 1,8 s, navigation auto | ✅ | ✅ |
| 2.2 | Personnalisation | Après splash | Question « Tu protèges qui ? » — 4 choix — **avant** toute demande de login | ✅ | ✅ |
| 2.3 | Aucune permission en onboarding | Parcourir tout l'onboarding | **Aucune** demande GPS/notif pendant l'onboarding (R3) | ✅ | ✅ |
| 2.4 | Ordre des méthodes d'auth | Écran login | Apple **en premier**, puis Google, puis Magic Link | ✅ | ☐ |
| 2.5 | Login Google | Se connecter via Google | Retour dans l'app, token Bearer stocké | ✅ | ☐ |
| 2.6 | Login Apple (iOS) | Se connecter via Apple | Idem | ✅ | ☐ |
| 2.7 | Magic Link | Saisir email, recevoir le lien | Lien valable 1 h, renvoi possible après 30 s | ✅ | ✅ |
| 2.8 | Invitation en onboarding | Étape invitation | Peut être **passée** (skip autorisé) | ✅ | ✅ |
| 2.9 | Célébration Aha | Après acceptation d'une invitation | Animation de renforcement positif (R8) | ✅ | ✅ |
| 2.10 | Reprise d'onboarding | Tuer l'app en cours d'onboarding, relancer | Reprend où on s'était arrêté | ✅ | ✅ |

---

## 3. Permissions — in-context

| # | Test | Étapes | Résultat attendu | Statut | OK ? |
|---|---|---|---|---|---|
| 3.1 | Permission GPS en contexte | Ouvrir la carte pour la 1ʳᵉ fois | Écran d'explication **avant** la popup système | ✅ | ✅ |
| 3.2 | Refus GPS non bloquant | Refuser la permission | L'app reste utilisable, message non bloquant | ✅ | ☐ |
| 3.3 | Permission notifications | Au moment pertinent (1ʳᵉ zone / 1ᵉʳ proche) | Écran d'explication puis popup | ✅ | ✅ |
| 3.4 | Réglage a posteriori | Paramètres → permissions | Lien vers les réglages système | ✅ | ✅ |

---

## 4. Proches — limite Gratuit : 2 max

> Limite appliquée **côté client** (`PaywallTriggerService.freeContactsLimit = 2`) **et côté serveur** (`InvitationController`, `config('alertcontacts.free_tier.contacts_limit')`).

| # | Test | Étapes | Résultat attendu | Statut | OK ? |
|---|---|---|---|---|---|
| 4.1 | Inviter un proche | Proches → Ajouter → envoyer l'invitation | Lien/deep link généré et partageable | ✅ | ✅ |
| 4.2 | Accepter une invitation | Sur le compte B, ouvrir le lien | Relation créée, B apparaît chez A | ✅ | ✅ |
| 4.3 | Bidirectionnalité | Après 4.2, regarder la carte de B | A apparaît **grisé** chez B + CTA « Invite A pour le voir aussi » | ✅ | ✅ |
| 4.4 | Invitation retour | B invite A, A accepte | Les deux se voient mutuellement | ✅ | ✅ |
| 4.5 | Refus d'invitation | Refuser depuis le lien | Refus enregistré, notification à l'inviteur | ✅ | ☐ |
| 4.6 | Voir un proche sur la carte | Carte avec 1 proche actif | Avatar positionné + fraîcheur de la position | ✅ | ✅ |
| 4.7 | Proche hors ligne | Couper le réseau chez B | Avatar **grisé** + dernière position + timestamp | ✅ | ✅ |
| 4.8 | **Limite atteinte (2 proches)** | Avoir 2 proches acceptés, tenter d'en inviter un 3ᵉ | **Paywall bloquant** `trigger: contact_limit` | 🔒 | ✅ |
| 4.9 | **Limite côté serveur** | Avec 2 proches, faire accepter une 3ᵉ invitation par un compte C | Réponse **403 `SUBSCRIPTION_LIMIT_REACHED`** — la relation n'est PAS créée | 🔒 | ✅ |
| 4.10 | Supprimer un proche | Proches → détail → supprimer | Suppression **bidirectionnelle** | ✅ | ✅ |
| 4.11 | Après suppression | Supprimer 1 proche (retour à 1), réinviter | L'invitation repasse (limite libérée) | ✅ | ✅ |
| 4.12 | Permissions de partage | Proches → détail → permissions | Modification du niveau de partage persistée | ✅ | ✅ |

---

## 5. Zones de sécurité — limite Gratuit : 1 max

> Limite client (`freeZonesLimit = 1`) **et serveur** (`SafeZonesController::store`).

| # | Test | Étapes | Résultat attendu | Statut | OK ? |
|---|---|---|---|---|---|
| 5.1 | Créer la 1ʳᵉ zone | Carte → icône calque ⊞ → créer | Zone circulaire créée (rayon 50–500 m) | ✅ | ✅ |
| 5.2 | Icône & couleur | Wizard de création | Choix d'icône et de couleur pris en compte | ✅ | ✅ |
| 5.3 | Recherche d'adresse | Étape localisation | Autocomplétion fonctionnelle | ✅ | ✅ |
| 5.4 | Assigner un proche | Zone → assigner des contacts | Seuls les proches **acceptés** sont proposés | ✅ | ✅ |
| 5.5 | Notification d'assignation | Assigner un proche à une zone | Le proche reçoit une notification | ✅ | ✅ |
| 5.6 | Détection d'entrée | Entrer physiquement dans la zone | Push « ✅ [Prénom] est arrivé(e) » — **langage naturel** | ✅ | ✅ |
| 5.7 | Détection de sortie | Sortir de la zone | Push « 🚪 [Prénom] a quitté [Zone] » | ✅ | ✅ |
| 5.8 | Pas de doublon de notif | Rester dans la zone, bouger un peu | **Une seule** notification d'entrée (table `user_zone_states`) | ✅ | ✅ |
| 5.9 | Modifier une zone | Zone → éditer nom/rayon | Modification persistée | ✅ | ✅ |
| 5.10 | Supprimer une zone | Zone → supprimer | Zone + assignations supprimées | ✅ | ✅ |
| 5.11 | **Limite atteinte (1 zone)** | Avec 1 zone, tenter d'en créer une 2ᵉ | **Paywall bloquant** `trigger: zone_limit` | 🔒 | ✅ |
| 5.12 | **Limite côté serveur** | Avec 1 zone, appeler `POST /api/safe-zones` directement (Postman + token) | **403 `SUBSCRIPTION_LIMIT_REACHED`** — zone non créée | 🔒 | ✅ |
| 5.13 | Paramètres de notification | Zone → réglages notif entrée/sortie | Toggles persistés | ✅ | ☐ |

---

## 6. Alertes communautaires — création GRATUITE (V4.1 §10.3a)

> ⚠️ Changement V4.1 : la création n'est **plus** réservée aux abonnés. Aucun paywall ne doit apparaître ici.

| # | Test | Étapes | Résultat attendu | Statut | OK ? |
|---|---|---|---|---|---|
| 6.1 | Lecture des alertes | Onglet Alertes | Liste des alertes à proximité | ✅ | ✅ |
| 6.2 | **Créer une alerte en Gratuit** | Alertes → FAB → parcours de signalement | **Aucun paywall.** Alerte créée en 3 taps max | ✅ | ✅ |
| 6.3 | Parcours en 3 taps | Type → gravité → confirmer position | Pas de saisie de rayon (déduit du type) | ✅ | ✅ |
| 6.4 | Couleur du CTA selon gravité | Changer la gravité dans le formulaire | Le CTA change de couleur (jaune/orange/rouge) | ✅ | ✅ |
| 6.5 | Détection de doublon | Signaler un incident à < 150 m d'un incident compatible | « Un incident similaire est déjà signalé ici. Confirmer ? » | ✅ | ✅ |
| 6.6 | Confirmer un incident | Fiche incident → « Je le vois aussi » | Compteur de signalements incrémenté | ✅ | ✅ |
| 6.7 | Résoudre un incident | Fiche incident → « C'est terminé » | Compteur `clear_count` incrémenté | ✅ | ✅ |
| 6.8 | Signaler un abus | Fiche incident → signaler | Signalement enregistré | ✅ | ☐ |
| 6.9 | Indicateur de fiabilité | Incident à 1 signalement vs 3+ | « non confirmé » vs « confirmé » | ✅ | ☐ |
| 6.10 | Wording non anxiogène | Parcourir les écrans d'alerte | Jamais « danger », « trajet dangereux », « sécurisé » (§6.7) | ✅ | ☐ |
| 6.11 | Mention de routage | Ouvrir un incident « Individu suspect » | « Cette alerte n'affecte pas le calcul d'itinéraire » | ✅ | ☐ |
| 6.12 | Push alerte à proximité | Créer une alerte élevée près du compte B | B reçoit un push « 🔴 Danger signalé à [X] m » | ✅ | ☐ |
| 6.13 | Filtres de la liste | Onglet Alertes → chips | Filtres Tout / Proches / Zones / Communauté | ✅ | ☐ |
| 6.14 | Marquer comme lu | Tapoter une alerte / « Tout lire » | Badge non-lu mis à jour | ✅ | ☐ |
| 6.15 | Rate limit signalements | Envoyer de nombreux signalements d'affilée | Plafond horaire appliqué (429) | ✅ | ☐ |

---

## 7. Historique des alertes — 24 h en Gratuit

> Fenêtre appliquée dans `AlertEventStore` (filtrage **non destructif** à la lecture).

| # | Test | Étapes | Résultat attendu | Statut | OK ? |
|---|---|---|---|---|---|
| 7.1 | Événements récents visibles | Générer une entrée/sortie de zone | L'événement apparaît dans l'onglet Alertes | ✅ | ☐ |
| 7.2 | **Coupure à 24 h** | Avoir des événements de plus de 24 h (ou modifier l'horloge du device) | Les événements > 24 h **n'apparaissent plus** | ✅ | ☐ |
| 7.3 | Compteur non-lus cohérent | Idem 7.2 | Le badge ne compte **pas** les événements masqués | ✅ | ☐ |
| 7.4 | Non-destructif | Après 7.2 : passer en `solo` en base, se reconnecter | Les événements de 24 h–30 j **réapparaissent** (ils n'ont pas été supprimés) | ✅ | ☐ |
| 7.5 | Purge au-delà de 30 j | Événement de plus de 30 jours | Définitivement purgé, même en tier payant | ✅ | ☐ |

> Test automatisé associé : `test/alert_event_store_retention_test.dart` (`flutter test`).

---

## 8. Module Trajets — Gratuit

| # | Test | Étapes | Résultat attendu | Statut | OK ? |
|---|---|---|---|---|---|
| 8.1 | Barre de recherche | Onglet Carte | Barre « Où vas-tu ? » sous le header — **pas de 4ᵉ onglet** | ✅ | ✅ |
| 8.2 | Autocomplétion | Saisir 3+ caractères | Suggestions après debounce ~300 ms | ✅ | ✅ |
| 8.3 | Départ pré-rempli | Ouvrir la recherche | « Ma position », modifiable | ✅ | ✅ |
| 8.4 | Inversion départ/arrivée | Bouton ⇅ | Les deux champs s'échangent | ✅ | ✅ |
| 8.5 | Mode de transport | Segmenté 🚗 / 🚶 / 🛵 | Le mode change le calcul | ✅ | ☐ |
| 8.6 | **Calcul d'itinéraire** | Lancer un trajet | Tracé affiché en teal + durée + distance + ETA | ✅ | ✅ |
| 8.7 | **Itinéraires alternatifs** | Voir les alternatives | Jusqu'à 3, libellés « via ... » issus de `routeLabels` | ✅ | ✅ |
| 8.8 | Trajet sans incident | Trajet dans une zone sans alerte | Aucun bandeau, **1 seul appel** au moteur | ✅ | ☐ |
| 8.9 | **Avertissement avant départ** | Trajet passant près d'un incident actif | Bandeau incident + boutons « Contourner » / « Continuer » | ✅ | ☐ |
| 8.10 | **Contournement gravité Élevé** | Contourner un incident 🔴, **répéter 5+ fois** | **Jamais bloqué, illimité** — même en Gratuit (§10.3b) | ✅ | ☐ |
| 8.11 | Contournement 🟡/🟠 — quota 1 à 3 | Contourner 3 incidents faible/moyen dans le mois | Les 3 passent | ✅ | ☐ |
| 8.12 | **Quota épuisé (4ᵉ)** | Tenter un 4ᵉ contournement 🟡/🟠 | **Paywall** « Tu as utilisé tes 3 contournements de ce mois » | 🔒 | ☐ |
| 8.13 | Quota côté serveur | Appeler `POST /api/v1/routes/{id}/avoid` directement après épuisement | **403** via middleware `avoidance.quota` | 🔒 | ☐ |
| 8.14 | Badge de sécurité | Après contournement | ✅ contourne / ⚠️ partiel / 🔴 traverse | ✅ | ☐ |
| 8.15 | Tri des itinéraires | Sélecteur d'itinéraires | L'itinéraire sûr **en premier**, même s'il est plus long | ✅ | ☐ |
| 8.16 | Aucune alternative | Incident sur un axe unique | « Aucun itinéraire ne contourne cette zone » — **jamais d'écran vide** | ✅ | ☐ |
| 8.17 | Destination dans la zone | Destination à l'intérieur d'un incident | « Ta destination est dans la zone signalée » — pas de contournement proposé | ✅ | ☐ |
| 8.18 | Détour excessif | Contournement > +50 % de durée | Surcoût en minutes affiché, proposé sans être imposé | ✅ | ☐ |
| 8.19 | Incident propre à l'utilisateur | Créer une alerte puis calculer un trajet passant dessus | **Exclu** de son propre calcul (§4.10 règle 1) | ✅ | ☐ |
| 8.20 | « Individu suspect » non routé | Trajet passant sur un incident 👤 | Affiché mais **ne modifie jamais** l'itinéraire (§4.11) | ✅ | ☐ |
| 8.21 | Hors ligne | Couper le réseau, ouvrir un trajet | Dernier itinéraire en cache + horodatage — **jamais bloquant** | ✅ | ☐ |
| 8.22 | Démarrer / terminer un trajet | « Démarrer » puis terminer | Statut `active` → `completed` | ✅ | ☐ |
| 8.23 | Destinations récentes | Rouvrir la recherche | 5 dernières destinations proposées | ✅ | ☐ |
| 8.24 | Historique des trajets 24 h | Chercher l'écran d'historique | ⚠️ **Aucun écran ne l'affiche** — voir A-01 | ⚠️ | ☐ |

---

## 9. Features PAYANTES — doivent toutes être bloquées

> **Aucune ne doit être accessible en tier Gratuit.** Le test consiste à vérifier le blocage.
> Pour vérifier qu'elles fonctionnent une fois débloquées, forcer `tier = 'solo'` en base (§1.2) puis se reconnecter.

| # | Feature | Test en Gratuit | Attendu en Gratuit | Statut | OK ? |
|---|---|---|---|---|---|
| 9.1 | 3ᵉ proche | Inviter un 3ᵉ proche | Paywall (cf. 4.8 / 4.9) | 🔒 | ☐ |
| 9.2 | 2ᵉ zone | Créer une 2ᵉ zone | Paywall (cf. 5.11 / 5.12) | 🔒 | ☐ |
| 9.3 | Historique alertes 30 j | Consulter > 24 h d'historique | Coupé à 24 h (cf. 7.2) | 🔒 | ☐ |
| 9.4 | Historique trajets 30 j | Consulter l'historique des trajets | Coupé à 24 h côté API | 🔒 | ☐ |
| 9.5 | Contournement 🟡/🟠 illimité | 4ᵉ contournement du mois | Paywall (cf. 8.12) | 🔒 | ☐ |
| 9.6 | **Surveillance pendant le trajet** | Démarrer un trajet, faire créer un incident devant par le compte B | **Aucun push** en Gratuit (job filtre sur `monitoring_tiers`) | 🔒 | ☐ |
| 9.7 | **Mode invisible — carte** | Carte → appui long → mode invisible | **Paywall** `trigger: invisible_mode` | 🔒 | ☐ |
| 9.7.b | **Mode invisible — paramètres** | Paramètres → Mode invisible | **Paywall** (2ᵉ point d'entrée) | 🔒 | ☐ |
| 9.7.c | **Mode invisible — serveur** | `POST /api/location/pause` en direct (Postman + token gratuit) | **403** via `tier:solo,famille` | 🔒 | ☐ |
| 9.7.d | **Sortie toujours possible** | Passer en `solo`, activer le mode, repasser en `free`, se reconnecter, reprendre le partage | **Reprise autorisée** — `resume` n'est jamais bloqué | ✅ | ☐ |
| 9.7.e | **Pas de faux « invisible »** | Couper le réseau, tenter d'activer le mode (en tier payant) | Message d'échec — l'app **n'affiche pas** « invisible actif » | ✅ | ☐ |
| 9.8 | Alerte privée aux proches | Chercher la fonction | Non accessible en Gratuit | 🔒 | ☐ |
| 9.9 | Rapports de trajet | Chercher la fonction | Non accessible en Gratuit | 🔒 | ☐ |
| 9.10 | Trajets favoris | Chercher la fonction | N/A — prévu V2, non développé | N/A | ☐ |
| 9.11 | Membres du foyer (Famille) | Appeler `POST /api/subscriptions/family/invite` | **403** via middleware `tier:famille` | 🔒 | ☐ |
| 9.12 | **Achat d'abonnement** | Paywall → tenter de souscrire | ⚠️ **Aucun bouton d'achat câblé** — impossible de payer. Voir A-04 | ⚠️ | ☐ |

### 9.13 — Contre-test en tier payant (après `UPDATE users SET tier='solo'`)

| # | Test | Attendu | OK ? |
|---|---|---|---|
| 9.13.a | 3ᵉ, 4ᵉ proche | Acceptés sans paywall | ☐ |
| 9.13.b | 2ᵉ, 3ᵉ zone | Créées sans paywall | ☐ |
| 9.13.c | Contournements 🟡/🟠 | Illimités | ☐ |
| 9.13.d | Historique alertes | Remonte à 30 jours | ☐ |
| 9.13.e | Surveillance en trajet | Push reçu quand un incident apparaît devant | ☐ |
| 9.13.f | Retour en `free` | Les limites se réappliquent après reconnexion | ☐ |

---

## 10. Règles transverses

| # | Test | Étapes | Résultat attendu | Statut | OK ? |
|---|---|---|---|---|---|
| 10.1 | **Paywall jamais avant l'Aha Moment** | Compte neuf, **0 proche connecté** — parcourir toute l'app | **Aucun paywall ne s'affiche jamais** | ✅ | ☐ |
| 10.2 | Hors ligne complet | Couper le réseau | Carte grisée + banner rouge **non bloquant** + positions en cache | ✅ | ☐ |
| 10.3 | Connexion instable | Réseau dégradé | Banner noir rétractable, données en cache | ✅ | ☐ |
| 10.4 | Aucun écran bloquant | Toutes les situations réseau | Jamais d'écran qui empêche d'utiliser l'app | ✅ | ☐ |
| 10.5 | Navigation 3 onglets | Barre du bas | **Exactement 3** onglets : Carte / Proches / Alertes | ✅ | ☐ |
| 10.6 | Zones hors tab bar | Carte | Icône calque ⊞ en haut à gauche | ✅ | ☐ |
| 10.7 | Paramètres hors tab bar | Carte | Avatar tapable en haut à droite | ✅ | ☐ |
| 10.8 | Touch targets | Tous les écrans | Minimum 44×44 pt iOS / 48×48 dp Android | ✅ | ☐ |
| 10.9 | Empty states | Carte sans proche, Alertes vides, Zones vides | Card guidante — **jamais d'écran blanc** (R7) | ✅ | ☐ |
| 10.10 | CTA destructif en dernier | Écrans avec suppression | Toujours en bas, style danger | ✅ | ☐ |
| 10.11 | Thème / couleurs | Tous les écrans | Tokens du design system, pas de couleur hardcodée visible | ✅ | ☐ |

---

## 11. Paramètres & RGPD

| # | Test | Étapes | Résultat attendu | Statut | OK ? |
|---|---|---|---|---|---|
| 11.1 | Profil | Paramètres → profil | Nom / photo modifiables | ⚠️ Voir A-05 | ☐ |
| 11.2 | Réglages de notification | Paramètres → notifications | Toggles persistés | ✅ | ☐ |
| 11.3 | Heures silencieuses | Paramètres | `quiet_hours` pris en compte | ✅ | ☐ |
| 11.4 | Export des données (RGPD) | Paramètres → exporter | Demande acceptée, email annoncé | ✅ | ☐ |
| 11.5 | Suppression de compte (RGPD) | Paramètres → supprimer | Compte supprimé (soft delete), déconnexion | ✅ | ☐ |
| 11.6 | Consentements | Paramètres → consentements | Modifications persistées | ✅ | ☐ |
| 11.7 | Zones ignorées | Zones danger → ignorées | Liste et gestion fonctionnelles | ✅ | ☐ |
| 11.8 | Feedback | Paramètres → feedback | Envoi fonctionnel | ✅ | ☐ |
| 11.9 | Aide / À propos | Paramètres | Pages accessibles, version affichée | ✅ | ☐ |
| 11.10 | Déconnexion | Paramètres → déconnexion | Token effacé, retour au login | ✅ | ☐ |
| 11.11 | Aucune PII dans Crashlytics | Provoquer une erreur | Aucun email/nom/GPS précis dans le rapport | ✅ | ☐ |

---

## 12. Anomalies connues **avant** la campagne

> À ne pas rouvrir comme bugs : elles sont déjà identifiées. Vérifier seulement qu'elles n'ont pas empiré.

| ID | Anomalie | Impact sur les tests |
|---|---|---|
| **A-01** | **Écran d'historique des trajets absent.** `RouteProvider.loadHistory()` existe et l'API `GET /api/v1/routes/history` applique bien 24 h / 30 j, mais **aucune UI ne l'appelle**. | Test 8.24 non exécutable côté app — vérifier via API (Postman) uniquement. |
| ~~A-02~~ | ~~Mode invisible non gated.~~ **CORRIGÉ** : `POST /location/pause` porte `tier:solo,famille`, les deux points d'entrée Flutter (carte + paramètres) affichent le paywall, et une activation refusée n'affiche plus « invisible actif ». `resume` reste ouvert à tous. | Tests 9.7.a → 9.7.e à exécuter normalement. |
| **A-03** | **Le `tier` n'est rafraîchi qu'à l'authentification.** `getCurrentUser()` (`GET /me`) est défini côté Flutter mais jamais appelé. | Après tout changement de tier en base, **se déconnecter/reconnecter** obligatoirement. |
| **A-04** | **Aucun parcours d'achat.** La `PaywallPage` n'a pas de CTA d'achat câblé ; le webhook RevenueCat existe mais rien ne le déclenche côté client. | Impossible de tester un achat réel (test 9.12). Passage en payant uniquement via SQL. |
| **A-05** | **`GET /user/profile` n'existe pas** dans `routes/api.php` (seul le `PUT`). `ProfileRepository.getProfile()` appelle donc une route absente. | Le chargement du profil via `ProfileProvider.loadProfile()` échoue. Test 11.1 : tester l'édition (PUT), pas le chargement. |
| **A-06** | **Deux implémentations de zones coexistent** : `lib/features/zones/` et `lib/features/zones_securite/`. | En cas de comportement incohérent sur les zones, préciser dans le rapport quel écran a été utilisé. |
| **A-07** | **Trois sources de vérité pour les limites** : constantes `PaywallTriggerService`, `RemoteConfigService`, et `config/alertcontacts.php`. Les valeurs coïncident aujourd'hui (2 / 1). | Si une limite se comporte différemment client vs serveur, vérifier ces trois emplacements. |

---

## 13. Feuille de résultats

| Section | Total | ✅ OK | ❌ KO | ⏭️ Non testé |
|---|---|---|---|---|
| 2 — Onboarding & Auth | 10 | | | |
| 3 — Permissions | 4 | | | |
| 4 — Proches | 12 | | | |
| 5 — Zones de sécurité | 13 | | | |
| 6 — Alertes communautaires | 15 | | | |
| 7 — Historique des alertes | 5 | | | |
| 8 — Trajets | 24 | | | |
| 9 — Features payantes | 16 + 6 | | | |
| 10 — Règles transverses | 11 | | | |
| 11 — Paramètres & RGPD | 11 | | | |
| **TOTAL** | **127** | | | |

### Modèle de rapport de bug

```
[ID test]    : 8.12
Tier         : free
Device / OS  : iPhone 14 / iOS 18.2
Attendu      : Paywall « 3 contournements épuisés »
Observé      : Le contournement passe sans paywall
Reproductible: oui (3/3)
Logs / capture:
```

---

## 14. Ordre d'exécution recommandé

1. **Sections 2 → 3** sur un compte **neuf** (l'onboarding n'est jouable qu'une fois).
2. **Section 10.1** immédiatement après : vérifier l'absence de paywall **avant** tout Aha Moment. Ce test est perdu dès qu'un proche est connecté.
3. **Section 4** (proches) — nécessaire pour débloquer le reste.
4. **Sections 5 → 8** (zones, alertes, historique, trajets).
5. **Section 9** en dernier : elle implique des manipulations en base qui polluent l'état du compte.
6. **Section 11** à tout moment ; le test 11.5 (suppression de compte) **en tout dernier**.
