# AlertContacts - Parcours utilisateur actuel

Version observee : Flutter `4.2.1+50` et backend Laravel associe  
Date : 02/09/2026  
Statut : document de reference UX mis a jour

## Conclusion

AlertContacts s'organise aujourd'hui autour de quatre parcours principaux :

1. l'utilisateur installe l'app, comprend la proposition de valeur, se connecte et autorise les permissions au bon moment ;
2. il utilise la carte pour voir sa position, ses proches, les zones, les alertes et les trajets ;
3. il ajoute des proches AlertContacts, cree des zones de securite, recoit des alertes et peut signaler des incidents communautaires ;
4. il peut desormais ajouter un traceur GPS physique dans un onglet dedie, independamment des proches AlertContacts.

Le modele produit actuel est freemium : le gratuit donne acces a l'usage de base, tandis que Premium debloque les usages avances comme plusieurs proches/zones, le mode invisible, certaines capacites de trajet et le suivi actif des traceurs GPS.

## 1. Premier lancement

### 1.1 Splash screen

Quand l'utilisateur ouvre AlertContacts, il arrive d'abord sur le splash screen.

Objectif UX :

- installer l'identite visuelle de l'application ;
- eviter un lancement brutal sur un formulaire ou une demande de permission ;
- laisser le temps aux services de base de s'initialiser.

Apres cette etape, l'app redirige l'utilisateur selon son etat :

- nouvel utilisateur : onboarding ;
- utilisateur deja connecte et onboarding termine : application principale ;
- version trop ancienne : ecran de mise a jour forcee si le backend l'exige.

### 1.2 Verification de version

L'application interroge l'etat applicatif cote backend. Si une version minimale est imposee pour Android ou iOS, l'utilisateur peut etre dirige vers une page de mise a jour forcee.

Ce parcours protege l'application contre les anciennes versions incompatibles avec les API actuelles.

## 2. Onboarding

### 2.1 Personnalisation initiale

Avant de demander a l'utilisateur de se connecter, l'application presente un parcours de personnalisation.

But :

- comprendre le contexte d'usage ;
- eviter de commencer par une demande de compte trop froide ;
- preparer l'utilisateur a l'utilite concrete de l'app.

L'utilisateur indique le type d'usage qui correspond a sa situation, par exemple proteger des proches, etre rassure pendant ses deplacements ou utiliser l'app en famille.

### 2.2 Slides d'introduction

L'utilisateur voit ensuite des ecrans explicatifs courts autour de la securite, des proches, des zones et des alertes.

Le message principal est :

- AlertContacts aide a etre informe ;
- les proches doivent etre ajoutes volontairement ;
- les zones permettent de recevoir des alertes d'entree et de sortie ;
- les signalements communautaires permettent d'etre prevenu d'un risque local.

### 2.3 Connexion

L'utilisateur arrive ensuite sur l'ecran d'authentification.

Methodes prevues dans l'app :

- connexion Apple ;
- connexion Google ;
- connexion par magic link email.

Apres authentification Firebase, l'app envoie le token Firebase au backend Laravel. Le backend cree ou retrouve l'utilisateur et renvoie un token Bearer utilise pour les appels API proteges.

### 2.4 Invitation d'un proche pendant l'onboarding

Apres connexion, l'utilisateur peut etre invite a ajouter un proche.

Ce parcours peut etre passe. L'objectif est de ne pas bloquer l'utilisateur si celui-ci veut d'abord decouvrir l'application.

## 3. Permissions

AlertContacts demande les permissions en contexte, pas toutes au premier lancement.

### 3.1 Permission de localisation

La localisation est demandee quand elle devient utile, notamment sur la carte.

Avant la popup systeme, l'app affiche une explication pour dire pourquoi la position est necessaire.

Si l'utilisateur refuse :

- l'app reste utilisable ;
- une interface explique comment continuer ;
- un lien vers les reglages peut etre propose si la permission est refusee durablement.

### 3.2 Localisation en arriere-plan

La localisation en arriere-plan sert aux fonctions de suivi et de detection de zones quand l'app n'est pas ouverte.

L'app doit expliquer clairement ce point, car c'est une permission sensible.

### 3.3 Notifications

Les notifications sont demandees pour permettre :

- les alertes d'entree et sortie de zone ;
- les alertes communautaires importantes ;
- les notifications liees aux invitations ;
- les alertes relatives aux proches ou aux traceurs.

## 4. Application principale

Une fois connecte, l'utilisateur arrive dans l'application principale.

La navigation actuelle contient quatre onglets :

- Carte ;
- Proches ;
- Alertes ;
- Traceurs.

Les zones ne sont pas un onglet separe dans la barre du bas : elles sont accessibles depuis la carte via le bouton de calques.

## 5. Onglet Carte

### 5.1 Vue generale

La carte est l'ecran central de l'application.

Elle affiche :

- la position de l'utilisateur ;
- les proches visibles ;
- les zones de securite ;
- les alertes ou zones de danger ;
- les trajets et avertissements de trajet lorsque le module Trajets est utilise.

### 5.2 Header de carte

En haut de la carte, l'utilisateur voit :

- un bouton de calques pour ouvrir le panneau des zones ;
- un indicateur de connectivite ;
- le nombre de proches connectes ;
- l'avatar utilisateur donnant acces aux parametres.

### 5.3 Position de l'utilisateur

La position est recuperee via le service de localisation du telephone.

Quand l'app est au premier plan, la precision demandee est elevee et les mises a jour sont frequentes. En arriere-plan, l'app utilise un mecanisme de batch et de background fetch pour continuer a envoyer les positions selon les contraintes du systeme.

La position est envoyee :

- a Firebase Realtime Database pour l'affichage temps reel par les proches autorises ;
- au backend Laravel pour conserver les positions et declencher les traitements geographiques.

### 5.4 Proches sur la carte

Les proches apparaissent sur la carte s'ils ont une relation acceptee et si le partage permet de voir leur position.

Etats possibles :

- actif : position recente visible ;
- hors ligne : derniere position connue affichee avec un etat grise ;
- partage non reciproque : l'utilisateur sait que le proche existe mais ne peut pas voir sa position ;
- position en pause : le proche a active le mode invisible.

### 5.5 Etats degradés

La carte gere plusieurs situations non ideales :

- absence de connexion ;
- precision GPS faible ;
- proche avec batterie faible ;
- localisation indisponible ;
- donnees recuperees depuis le cache.

L'objectif est de ne pas afficher un ecran vide ou bloquant quand une donnee temporaire manque.

## 6. Panneau Zones

### 6.1 Acces

Depuis la carte, l'utilisateur ouvre le panneau des zones via le bouton de calques.

### 6.2 Creation de zone

Le parcours de creation se fait sous forme de wizard.

L'utilisateur :

1. choisit ou confirme la position de la zone sur la carte ;
2. definit le rayon ;
3. donne un nom a la zone et choisit une icone.

Les zones circulaires sont le parcours principal actuel. Le backend sait stocker aussi des geometries polygonales, mais le parcours utilisateur actuel est centre sur le cercle.

### 6.3 Gestion des zones

L'utilisateur peut :

- consulter ses zones ;
- modifier une zone ;
- supprimer une zone ;
- voir une zone sur la carte ;
- affecter des proches acceptes a une zone ;
- recevoir des notifications d'entree ou de sortie.

### 6.4 Limite gratuite

En mode gratuit, l'utilisateur peut creer 1 zone de securite.

Au-dela, l'application presente le paywall Premium et le serveur doit refuser l'action si l'utilisateur n'a pas les droits.

## 7. Onglet Proches

### 7.1 Vue liste

L'onglet Proches liste les relations de l'utilisateur.

Il distingue :

- les proches connectes ;
- les invitations en attente ;
- les proches hors ligne ;
- les proches dont la position n'est pas visible ;
- les proches dont la position est en pause.

### 7.2 Ajouter un proche

L'utilisateur appuie sur le bouton d'ajout.

Le parcours genere une invitation partageable. Le proche invite ouvre le lien, se connecte si necessaire, puis accepte ou refuse l'invitation.

Quand l'invitation est acceptee, une relation est creee.

### 7.3 Relation bidirectionnelle

La relation est geree dans les deux sens.

Cela signifie qu'un utilisateur peut avoir ajoute un proche, mais ne pas encore voir sa position si le proche n'a pas active ou accepte le partage attendu.

UX attendue :

- ne pas faire croire que la position est disponible si elle ne l'est pas ;
- expliquer clairement quand une invitation retour ou une permission manque ;
- afficher un etat grise ou non visible au lieu d'une fausse position.

### 7.4 Fiche proche

En ouvrant un proche, l'utilisateur accede a une fiche ou une bottom sheet.

Actions possibles selon l'etat :

- voir le proche sur la carte ;
- renvoyer une invitation ;
- activer le partage ;
- modifier les permissions ;
- retirer le proche.

### 7.5 Permissions de partage

Les permissions prevues sont :

- partager la position ;
- partager le niveau de batterie ;
- partager les evenements de zone ;
- partager la vitesse.

Ces permissions doivent rester comprehensibles : l'utilisateur doit savoir ce qu'il donne comme information a l'autre personne.

### 7.6 Limite gratuite

En mode gratuit, l'utilisateur peut avoir 1 proche.

L'ajout d'un proche supplementaire declenche le paywall Premium.

## 8. Onglet Alertes

### 8.1 Vue principale

L'onglet Alertes regroupe plusieurs types d'evenements :

- alertes communautaires ;
- alertes de zone ;
- alertes relatives aux proches.

L'utilisateur peut filtrer par :

- Tout ;
- Proches ;
- Zones ;
- Communaute.

Les alertes sont groupees par date et peuvent etre marquees comme lues.

### 8.2 Creation d'une alerte communautaire

L'utilisateur peut creer une alerte communautaire depuis le bouton d'ajout.

Le parcours demande :

- le type d'incident ;
- la gravite ;
- une description si necessaire ;
- la position.

La creation d'alertes communautaires est disponible en gratuit, car le module a besoin de contribution pour devenir utile.

### 8.3 Consultation d'un incident

Depuis une alerte communautaire, l'utilisateur peut ouvrir le detail.

Actions possibles :

- confirmer qu'il voit aussi l'incident ;
- indiquer que l'incident est termine ;
- signaler un abus.

### 8.4 Doublons et confiance

Quand un signalement ressemble a un incident deja existant, l'app peut traiter cela comme une confirmation plutot que comme une nouvelle alerte separee.

Le but UX est de garder la carte lisible et d'augmenter la confiance dans l'incident.

## 9. Module Trajets

### 9.1 Point d'entree

Le module Trajets est accessible depuis la carte via une barre de recherche du type "Ou vas-tu ?".

### 9.2 Recherche d'itineraire

L'utilisateur choisit :

- un point de depart, par defaut sa position actuelle si disponible ;
- une destination ;
- un mode de transport.

Il peut inverser depart et destination.

### 9.3 Apercu du trajet

L'app calcule le trajet cote backend.

Elle peut afficher :

- le trace ;
- la duree ;
- la distance ;
- l'heure estimee d'arrivee ;
- des alternatives ;
- des alertes si un incident actif affecte le trajet.

### 9.4 Incident sur le trajet

Si un incident est detecte sur le trajet, l'utilisateur est averti avant de partir.

Il peut :

- continuer avec le trajet propose ;
- demander un contournement ;
- selectionner une alternative si elle existe.

Le wording doit rester prudent : l'app ne doit pas promettre un trajet "sur" ou "securise".

### 9.5 Contournement et Premium

Le contournement d'un incident de gravite elevee reste gratuit et illimite.

Pour les incidents faibles ou moyens, le gratuit dispose d'un quota mensuel. Au-dela, le paywall Premium peut etre affiche.

### 9.6 Trajet actif

Un trajet peut passer par plusieurs statuts :

- cree ;
- selectionne ;
- actif ;
- termine ;
- annule.

La surveillance pendant le trajet est reservee aux utilisateurs Premium selon la configuration backend.

## 10. Onglet Traceurs

### 10.1 Role du module

Le module Traceurs est une nouvelle feature independante du module Proches.

Il sert au cas ou la personne a suivre ne porte pas de telephone avec AlertContacts, mais possede un traceur GPS physique.

Un traceur n'est donc pas un "proche" AlertContacts. C'est un equipement rattache au compte de l'utilisateur.

### 10.2 Ajouter un traceur

Depuis l'onglet Traceurs, l'utilisateur peut ajouter un traceur.

Champs actuels :

- nom du traceur ;
- fournisseur, facultatif ;
- identifiant materiel, facultatif dans l'interface, mais requis pour l'activation ;
- modele, prevu cote API.

L'identifiant materiel peut etre un IMEI, un numero de serie ou un identifiant propre au fabricant.

### 10.3 Liste des traceurs

La liste affiche :

- le nom du traceur ;
- le statut ;
- la fraicheur de la derniere position ;
- le niveau de batterie si disponible.

Statuts possibles :

- draft : traceur ajoute mais pas encore active ;
- active : suivi actif ;
- suspended : suivi suspendu ;
- offline : traceur hors ligne.

### 10.4 Mode gratuit

En gratuit, l'utilisateur peut enregistrer 1 traceur GPS.

Il peut voir la derniere position deja connue si une position existe, mais il ne beneficie pas du suivi actif.

Les fonctions suivantes sont reservees au Premium :

- activation du suivi actif ;
- reception continue des positions ;
- historique des positions ;
- association a des zones ;
- alertes d'entree et sortie de zone.

### 10.5 Mode Premium

En Premium, l'utilisateur peut activer le traceur si l'identifiant materiel est renseigne.

Quand une position arrive depuis le traceur :

- le backend verifie le secret d'ingestion ;
- retrouve le traceur par fournisseur et identifiant externe ;
- verifie que le traceur est actif ;
- verifie que le proprietaire est Premium ;
- enregistre la position ;
- met a jour la derniere position, la derniere activite et la batterie ;
- execute le geofencing des zones de securite circulaires associees.

### 10.6 Zones et alertes de traceur

Un traceur Premium peut etre associe a des zones de securite.

Pour chaque zone, on peut activer ou desactiver :

- la surveillance de la zone ;
- les notifications d'entree ;
- les notifications de sortie.

Quand le traceur entre ou sort d'une zone circulaire active, le backend cree un evenement et peut envoyer une notification push au proprietaire.

### 10.7 Expiration Premium

Si l'abonnement Premium expire, les traceurs actifs sont suspendus directement.

L'ingestion de nouvelles positions est refusee tant que l'utilisateur n'a pas recupere un acces Premium.

### 10.8 Ce qui n'est pas dans le parcours traceur

Le module Traceurs ne contient pas de bouton SOS.

Il ne garantit pas non plus l'acces aux positions Apple Find My ou Google Find Hub. Pour etre compatible avec le besoin AlertContacts, un traceur doit fournir une position exploitable par le backend, idealement via GNSS/GPS et connectivite 4G/LTE ou via une API serveur officielle.

## 11. Paywall et abonnement

### 11.1 Declencheurs du paywall

Le paywall peut apparaitre lorsque l'utilisateur essaie d'utiliser une fonction reservee au Premium.

Declencheurs actuels :

- ajout d'un proche au-dela de la limite gratuite ;
- creation d'une zone au-dela de la limite gratuite ;
- activation du mode invisible ;
- fonctions avancees des traceurs GPS ;
- contournements limites du module Trajets selon gravite et quota ;
- acces aux usages avances prevus par le modele Premium.

### 11.2 RevenueCat

L'application utilise RevenueCat cote Flutter pour :

- charger l'etat de l'abonnement ;
- afficher le paywall natif RevenueCat UI ;
- acheter ou restaurer un abonnement ;
- detecter l'entitlement Premium.

Le backend recoit les webhooks RevenueCat et met a jour le tier de l'utilisateur.

### 11.3 Regle importante

Le client mobile peut adapter l'interface, mais le serveur reste la source d'autorite.

Une action Premium ne doit pas reussir simplement parce que le client pense que l'utilisateur est Premium.

## 12. Mode invisible

### 12.1 Acces

Le mode invisible est accessible :

- depuis la carte, via l'interaction prevue ;
- depuis les parametres.

### 12.2 Activation

L'utilisateur Premium peut masquer temporairement sa position.

Durees prevues :

- 1 heure ;
- 4 heures ;
- jusqu'a reactivation manuelle.

Quand le mode est actif :

- la publication de position vers Firebase est suspendue ;
- l'etat `is_invisible` est pousse pour que les proches comprennent que la position est en pause ;
- un bandeau indique l'etat actif.

### 12.3 Reprise

La reprise du partage reste toujours possible, meme si l'utilisateur n'est plus Premium.

Cette decision evite de bloquer quelqu'un dans un etat invisible apres expiration d'abonnement.

## 13. Parametres

Depuis les parametres, l'utilisateur peut :

- voir son profil ;
- ouvrir la gestion de l'abonnement ;
- ouvrir les reglages de notifications ;
- consulter la langue affichee ;
- acceder aux conditions d'utilisation ;
- acceder a la politique de confidentialite ;
- exporter ses donnees ;
- se deconnecter ;
- supprimer son compte.

Le mode invisible est aussi accessible depuis la section Confidentialite.

## 14. Parcours hors ligne et etats d'erreur

L'application prevoit des etats non bloquants pour :

- absence de connexion ;
- API indisponible ;
- localisation refusee ;
- GPS imprecis ;
- proche hors ligne ;
- traceur sans position recue ;
- offres Premium indisponibles.

L'objectif UX est simple : l'utilisateur doit comprendre ce qui manque et pouvoir continuer quand c'est possible.

## 15. Parcours donnees et confidentialite

### 15.1 Donnees de localisation mobile

La localisation mobile suit ce flux :

1. le telephone recupere une position via Geolocator ;
2. l'app filtre les points trop imprecis ;
3. l'app publie vers Firebase RTDB si le mode invisible n'est pas actif ;
4. l'app envoie les points au backend Laravel par batch ;
5. le backend persiste les positions et declenche les traitements de zone.

### 15.2 Donnees traceur GPS

La localisation traceur suit ce flux :

1. le traceur ou l'integrateur externe obtient une position GPS ;
2. l'integrateur envoie la position a l'endpoint interne AlertContacts ;
3. Laravel authentifie l'appel via le secret d'ingestion ;
4. Laravel retrouve le traceur par fournisseur et identifiant externe ;
5. Laravel verifie le statut du traceur et l'abonnement du proprietaire ;
6. Laravel enregistre la position et declenche le geofencing si autorise.

### 15.3 Consentement

Pour les proches AlertContacts, le suivi repose sur une relation acceptee et des permissions.

Pour les traceurs GPS, le consentement doit etre gere dans le cadre contractuel et produit : le traceur ne doit pas etre presente comme un outil de surveillance cachee ou non consentie.

## 16. Points UX encore a surveiller

Les points suivants doivent etre suivis avant une communication commerciale forte :

- verifier que les prix Premium affiches dans RevenueCat et Google Play correspondent exactement aux prix communiques ;
- finaliser le detail visuel du traceur si l'interface actuelle ne montre pas encore la carte de position, l'historique, l'edition et l'affectation zone ;
- clarifier les limites gratuites dans tous les textes, car certains anciens documents mentionnaient encore 2 proches gratuits alors que le code actuel indique 1 ;
- eviter de promettre le temps reel traceur tant que le fournisseur materiel et son protocole ne sont pas confirmes ;
- verifier que les alertes communautaires et les trajets disponibles en production correspondent bien aux features presentes dans la version Google Play ;
- maintenir un langage de securite prudent : l'app rassure, informe et alerte, mais ne garantit pas la protection physique.

## 17. Synthese du parcours complet

Parcours type d'un nouvel utilisateur :

1. Il ouvre l'app et voit le splash screen.
2. Il passe par la personnalisation et les slides d'introduction.
3. Il se connecte avec Google, Apple ou magic link.
4. Il peut inviter un proche ou passer cette etape.
5. Il arrive sur la carte.
6. Il autorise la localisation quand la carte en a besoin.
7. Il voit sa position et peut inviter un proche.
8. Il cree une zone de securite.
9. Il assigne un proche a cette zone.
10. Il recoit des alertes quand un proche entre ou sort de la zone.
11. Il peut consulter ou creer des alertes communautaires.
12. Il peut chercher un trajet et etre averti si un incident affecte ce trajet.
13. Il peut ajouter un traceur GPS physique dans l'onglet Traceurs.
14. S'il veut le suivi actif du traceur, l'historique ou les alertes de zone traceur, il passe par Premium.
15. Depuis les parametres, il gere son abonnement, ses notifications, sa confidentialite, ses donnees et son compte.

## 18. Sources internes utilisees

Ce document a ete prepare a partir des fichiers et modules suivants :

- `lib/router/app_router.dart`
- `lib/features/app_shell/presentation/app_shell.dart`
- `lib/features/home_map/presentation/home_page.dart`
- `lib/features/proches/presentation/proches_tab.dart`
- `lib/features/alertes/presentation/alertes_page.dart`
- `lib/features/trajets/presentation/route_search_page.dart`
- `lib/features/traceurs/presentation/traceurs_tab.dart`
- `lib/features/settings/presentation/settings_page.dart`
- `lib/core/services/location_service.dart`
- `lib/core/services/subscription_service.dart`
- `lib/core/services/gps_tracker_service.dart`
- `routes/api.php`
- `app/Http/Controllers/Api/GpsTrackerController.php`
- `app/Http/Controllers/Api/InternalTrackerTelemetryController.php`
- `app/Services/TrackerGeofencingService.php`
- `config/alertcontacts.php`

