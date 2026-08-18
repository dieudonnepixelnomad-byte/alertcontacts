# Mise en production Premium Android

1. Dans Google Play Console, créez les abonnements `premium_monthly` (4,99 EUR/mois) et `premium_annual` (49,99 EUR/an), chacun avec une offre d'essai de 14 jours.
2. Publiez une version de `com.alertcontacts.alertcontacts` sur le canal de test interne, puis ajoutez les comptes de licence Google Play.
3. Dans RevenueCat, créez l'application Android, connectez les credentials Google Play, puis créez l'entitlement `premium`.
4. Créez l'offering courant `default` et associez ses packages aux produits `premium_monthly` et `premium_annual`.
5. Copiez la clé publique Android RevenueCat dans `REVENUECAT_ANDROID_API_KEY` du fichier Flutter `.env`.
6. Dans le backend, définissez `REVENUECAT_WEBHOOK_SECRET` et les deux IDs produits. Configurez RevenueCat pour appeler `POST https://<domaine-api>/api/webhooks/revenuecat` avec ce secret dans l'en-tête `Authorization`.
7. Exécutez les migrations Laravel avant toute vente : elles convertissent les anciens tiers `solo` et `famille` en `premium` et ajoutent l'idempotence des webhooks.

Ne placez jamais une clé secrète RevenueCat, un compte de service Google Play ou le secret de webhook dans l'application Flutter.
