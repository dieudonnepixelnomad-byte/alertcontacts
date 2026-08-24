# Mises à jour obligatoires

La protection combine Firebase Remote Config (blocage préventif au démarrage)
et le backend Laravel (autorité sur les API).

## Publication normale

1. Augmenter `version` dans `pubspec.yaml`, par exemple `4.1.2+50`.
2. Publier l'AAB dans Google Play et attendre sa disponibilité.
3. Mettre à jour Firebase Remote Config :
   - `min_app_version_android=4.1.2` seulement si cette version doit devenir obligatoire ;
   - `android_store_url` avec la fiche Play Store.

## Blocage serveur

Après que la version qui envoie `X-App-Build` est largement distribuée,
configurer le backend :

```env
MINIMUM_ANDROID_BUILD=50
ANDROID_STORE_URL=https://play.google.com/store/apps/details?id=com.alertcontacts.alertcontacts
```

Puis vider le cache de configuration Laravel :

```bash
php artisan config:clear
php artisan config:cache
```

Le backend répond alors `426 UPDATE_REQUIRED` aux builds Android inférieurs à
50. Ne pas augmenter ce seuil avant que la version 50 soit disponible sur Play
Store, sinon les utilisateurs bloqués ne pourront pas installer la mise à jour.

Les builds `0` désactivent le contrôle afin de permettre le déploiement initial.
L'In-App Update immédiat ne fonctionne que pour une application installée depuis
Google Play ; les autres cas utilisent l'écran bloquant et le lien Store.
