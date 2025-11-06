# Guide de Test - Deep Links d'Invitation

## 🎯 Objectif
Tester le flux complet d'invitation avec deep links pour un utilisateur non authentifié.

## 🔧 Prérequis
- Application AlertContact installée sur un appareil Android
- ADB installé et configuré
- Appareil Android connecté ou émulateur en cours d'exécution

## 📋 Scénarios de Test

### Scénario 1: Utilisateur non authentifié reçoit un lien d'invitation

#### Étapes:
1. **Préparation**
   - S'assurer que l'utilisateur n'est pas connecté dans l'app
   - Fermer l'application si elle est ouverte

2. **Envoi du deep link**
   ```bash
   ./test_deep_link.sh
   ```
   Ou manuellement:
   ```bash
   adb shell am start -W -a android.intent.action.VIEW \
     -d "alertcontact://invitation?t=test_token_123&pin=1234" \
     com.alertcontacts.alertcontacts
   ```

3. **Vérifications attendues**
   - ✅ L'application s'ouvre
   - ✅ L'utilisateur est redirigé vers la page de connexion
   - ✅ Le token d'invitation est stocké localement (avec timestamp)
   - ✅ Aucune erreur dans les logs

4. **Connexion utilisateur**
   - Se connecter avec des identifiants valides
   - Ou créer un nouveau compte

5. **Vérifications post-connexion**
   - ✅ Après connexion réussie, redirection automatique vers `/invitations/accept?t=test_token_123&pin=1234`
   - ✅ Le token et PIN sont présents dans l'URL
   - ✅ Le token stocké est supprimé après utilisation

### Scénario 2: Gestion de l'expiration des tokens

#### Test d'expiration (30 minutes)
1. **Simulation d'expiration**
   - Modifier temporairement le TTL dans `PendingDeepLinkService` à 1 seconde
   - Envoyer un deep link
   - Attendre 2 secondes
   - Se connecter

2. **Vérifications**
   - ✅ Le token expiré n'est pas utilisé
   - ✅ Redirection vers la page d'accueil normale
   - ✅ Aucune erreur dans les logs

### Scénario 3: Annulation du processus d'authentification

#### Test de nettoyage des tokens
1. **Envoi du deep link**
   - Envoyer un deep link d'invitation
   - Vérifier que l'app s'ouvre sur la page de connexion

2. **Navigation entre pages d'auth**
   - Cliquer sur "Créer un compte" → vérifier que le token est supprimé
   - Ou cliquer sur "Mot de passe oublié" puis "Retour" → vérifier que le token est supprimé

3. **Vérifications**
   - ✅ Le token est supprimé lors de la navigation
   - ✅ Pas de redirection automatique après connexion ultérieure

## 🔍 Logs à surveiller

### Logs Flutter (dans la console de développement)
```
[log] Initialisation du DeepLinkService
[log] Deep link reçu via MethodChannel: alertcontact://invitation?t=...
[log] Traitement invitation avec token: ...
[log] Utilisateur non authentifié, mémorisation du token et redirection vers auth
[log] Token d'invitation mémorisé, redirection vers login
[log] Vérification des deep links en attente
[log] Deep link en attente trouvé: ...
[log] Rejeu du deep link: /invitations/accept?t=...&pin=...
```

### Logs Android (via ADB)
```bash
adb logcat | grep -E "(AlertContact|DeepLink|Invitation)"
```

## 🐛 Problèmes courants et solutions

### Problème: L'application ne s'ouvre pas avec le deep link
**Solution**: Vérifier que le scheme `alertcontact://` est bien configuré dans `android/app/src/main/AndroidManifest.xml`

### Problème: Le token n'est pas stocké
**Solution**: Vérifier les permissions de stockage et les logs d'erreur dans `PendingDeepLinkService`

### Problème: Pas de redirection après connexion
**Solution**: Vérifier que `replayPendingDeepLink` est bien appelé dans `_handleAuthStateChange`

## ✅ Critères de succès

Le test est réussi si:
- [x] Deep link ouvre l'application
- [x] Token stocké avec timestamp
- [x] Redirection vers page de connexion
- [x] Après connexion, redirection automatique vers page d'invitation
- [x] Token supprimé après utilisation
- [x] Gestion correcte de l'expiration (30 min)
- [x] Nettoyage lors de l'annulation d'auth
- [x] Aucune erreur dans les logs

## 🔄 Tests de régression

Après modifications du code, relancer tous les scénarios pour s'assurer qu'aucune régression n'a été introduite.