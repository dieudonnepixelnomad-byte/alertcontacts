# Avis Play Store

La sollicitation automatique est gérée par `AppReviewService`.

Elle ne devient possible qu'après :

- 7 jours depuis la première ouverture ;
- 3 actions métier réussies, dont une boucle de sécurité confirmée ;
- 48 heures sans erreur enregistrée ;
- 90 jours depuis la précédente demande ;
- moins de deux reports explicites (« Pas maintenant »).

Une boucle de sécurité confirmée exige une position de proche fraîche (moins de
10 minutes), suffisamment précise (100 m maximum), dans une zone qui lui est
affectée et active. Créer une zone ne compte pas. Les autres succès comptabilisés
sont le signalement communautaire d'une zone de danger et l'acceptation d'une
invitation de proche. Les valeurs de politique sont regroupées dans
`lib/core/services/app_review_service.dart`.

La demande automatique propose à tous les utilisateurs éligibles les deux mêmes
choix : donner un avis public sur Google Play ou envoyer un retour privé à
l'équipe. Le choix du retour privé ouvre `/feedback` ; il ne retire jamais
l'accès à l'avis public. Le bouton « Noter l'application » du profil est
volontaire et ouvre la fiche Store. Google Play peut ne pas afficher sa fenêtre,
notamment en raison de ses propres quotas ; ce cas ne doit pas être considéré
comme une erreur fonctionnelle.
