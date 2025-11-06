# Guide - Configuration des URLs d'invitation

## Problème identifié

Les liens d'invitation générés utilisent actuellement `http://127.0.0.1:8000` (localhost), ce qui pose plusieurs problèmes :

1. **Non cliquables dans WhatsApp** : Les URLs localhost ne sont pas reconnues comme des liens valides
2. **Non accessibles depuis d'autres appareils** : Seul l'appareil de développement peut accéder à ces liens
3. **Expérience utilisateur dégradée** : Les utilisateurs doivent copier/coller manuellement

## Solution temporaire (Développement)

Le message de partage a été modifié pour :
- Détecter automatiquement les URLs localhost
- Afficher un avertissement explicite
- Donner des instructions de copie/collage
- Expliquer que c'est un environnement de développement

## Solutions pour la production

### Option 1 : Serveur de développement accessible (Recommandé)

1. **Utiliser ngrok** pour exposer le serveur local :
```bash
# Installer ngrok
brew install ngrok

# Exposer le port 8000
ngrok http 8000
```

2. **Modifier la configuration API** :
```dart
// lib/core/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'https://your-ngrok-url.ngrok.io/api';
  static const String baseUrlWithoutApi = 'https://your-ngrok-url.ngrok.io';
}
```

### Option 2 : Serveur de staging

1. **Déployer le backend Laravel** sur un serveur accessible (Heroku, DigitalOcean, etc.)

2. **Configurer les URLs** :
```dart
// lib/core/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'https://alertcontact-staging.herokuapp.com/api';
  static const String baseUrlWithoutApi = 'https://alertcontact-staging.herokuapp.com';
}
```

### Option 3 : Configuration par environnement

Créer une configuration dynamique selon l'environnement :

```dart
// lib/core/config/api_config.dart
class ApiConfig {
  static const bool isDevelopment = true; // À changer selon l'environnement
  
  static String get baseUrl => isDevelopment 
    ? 'http://127.0.0.1:8000/api'
    : 'https://api.alertcontact.com/api';
    
  static String get baseUrlWithoutApi => isDevelopment 
    ? 'http://127.0.0.1:8000'
    : 'https://api.alertcontact.com';
}
```

## Configuration backend Laravel

Assurez-vous que le backend génère les bonnes URLs d'invitation :

```php
// Dans le contrôleur d'invitation Laravel
$invitationUrl = config('app.frontend_url') . '/invitations/accept?t=' . $invitation->token;
```

Avec dans `.env` :
```env
FRONTEND_URL=https://your-domain.com
# ou pour ngrok :
FRONTEND_URL=https://your-ngrok-url.ngrok.io
```

## Test des modifications

1. Créer une invitation
2. Partager le lien via WhatsApp
3. Vérifier que le lien est cliquable
4. Tester l'acceptation de l'invitation

## Notes importantes

- Les deep links `alertcontact://` fonctionnent uniquement dans l'app
- Les URLs HTTP/HTTPS sont nécessaires pour le partage externe
- En production, utiliser HTTPS obligatoirement
- Configurer les domaines autorisés côté backend pour la sécurité