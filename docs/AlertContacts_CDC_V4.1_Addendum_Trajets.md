# ALERTCONTACTS — Cahier des Charges V4.1

## Addendum : Module Trajets & Refonte du modèle géométrique des alertes

| | |
|---|---|
| **Document** | Addendum au Cahier des Charges Technique V4.0 |
| **Version** | 4.1 |
| **Date** | Août 2026 |
| **Statut** | Proposition — à valider par le client |
| **Stack** | Flutter · Laravel · Firebase · MySQL · **HERE Routing API v8** |
| **Périmètre** | Nouveau module « Trajets » + refonte du modèle de données des alertes communautaires |
| **Remplace** | §7 (partiellement), §10.1, §11.2.5, §16 du CDC V4.0 |
| **Confidentiel** | Oui |

---

## Comment lire ce document

Ce document ne remplace pas le CDC V4.0. Il s'y ajoute et en corrige certaines parties.

### Convention de référencement

⚠️ **Attention, la numérotation du présent document et celle du V4.0 se recoupent.** Pour lever toute ambiguïté :

| Notation | Signifie |
|---|---|
| **§7.2.1 V4.0** ou **§7.2.1** suivi d'une mention du V4.0 | Section du **Cahier des Charges V4.0** |
| **§4.9** cité seul dans une phrase du présent document | Section **du présent addendum**, sauf mention contraire explicite |

En cas de doute, les sections du V4.0 citées dans ce document sont exclusivement les suivantes : §1.1, §1.2, §5.1, §5.2, §6.1.1, §6.3.1, §6.3.2, §7.1, §7.2.1, §7.2.2, §7.2.3, §7.3, §7.3.1, §9.1, §10.1, §10.3, §11.2, §11.2.5, §11.3.1, §11.4, §12, §12.1, §12.4, §13.5, §14.1, §14.2, §16. Toute autre référence renvoie au présent addendum.

### Marqueurs

- Les sections marquées **⚠️ REMPLACE** annulent la spécification correspondante du V4.0.
- Les sections marquées **➕ AJOUTE** sont nouvelles.
- Les points marqués **❓ À VÉRIFIER** n'ont pas été confirmés et doivent l'être avant tout engagement de développement. Ils sont regroupés au chapitre 14 du présent document.

---

# 1. RÉSUMÉ EXÉCUTIF

## 1.1 Ce qui est demandé

Le client souhaite ajouter au module « Alertes communautaires » une fonctionnalité de **calcul d'itinéraire avec contournement des zones de danger** :

> L'utilisateur saisit un point de départ et un point d'arrivée. L'application trace l'itinéraire. Si le trajet passe à proximité d'une alerte communautaire, l'utilisateur en est averti **avant de partir**, et peut demander un itinéraire alternatif qui contourne la zone.

## 1.2 Ce que ce document propose

L'analyse de cette demande a révélé que **le modèle de données des alertes du CDC V4.0 ne permet pas de l'implémenter correctement**. La feature demandée est réalisable, mais elle exige une refonte préalable de la géométrie des alertes.

Ce document couvre donc deux chantiers liés :

| Chantier | Nature | Priorité |
|---|---|---|
| **A** — Refonte du modèle géométrique des alertes | Correction de conception | **Bloquant** — prérequis de B |
| **B** — Nouveau module Trajets & contournement | Nouvelle feature | Dépend de A |

## 1.3 Les trois changements structurants

1. **Découplage des rayons.** Un rayon unique servait à trois usages incompatibles (notifier, afficher, éviter). Il est scindé en trois valeurs indépendantes.
2. **Géométries typées.** Une alerte n'est plus systématiquement un cercle. Elle est un *corridor* (tronçon de rue) ou un *polygone* (surface), selon la nature du danger et non selon sa gravité.
3. **Séparation signalement / incident.** Plusieurs signalements du même événement fusionnent en un incident unique. La confiance et la position en découlent.

## 1.4 Valeur produit attendue

Le module Alertes communautaires du V4.0 souffre d'un problème de démarrage à froid : il n'a aucune valeur tant que la densité de signalements est faible. Le module Trajets le résout partiellement en transformant un flux passif (une liste qu'on consulte rarement) en utilité active (l'app s'ouvre à chaque déplacement).

Effets attendus :

- **Boucle d'usage quotidienne** au lieu d'un usage événementiel.
- **Motivation à contribuer** : signaler devient un acte qui protège les trajets des autres.
- **Argument commercial différenciant** face à Life360 et Google Family Sharing, aucun ne proposant de routage sensible aux dangers.

---

# 2. DIAGNOSTIC — POURQUOI LE MODÈLE V4.0 NE PEUT PAS SUPPORTER CETTE FEATURE

## 2.1 Défaut n°1 — Un rayon unique pour trois usages incompatibles

Le §7.2.1 définit un « rayon de diffusion » par niveau de gravité. Ce rayon sert simultanément à :

1. **Décider qui reçoit la notification push** — logique de population
2. **Dessiner le cercle sur la carte** — logique d'affichage
3. **Définir la zone à exclure du calcul d'itinéraire** — logique de réseau routier

Ces trois besoins sont contradictoires.

- Pour la **notification**, il faut être **large** : un incendie dans mon quartier, je veux le savoir à 800 m.
- Pour le **routage**, il faut être **serré** : un incendie au 12 rue de la Paix bloque la rue de la Paix, pas la rue parallèle à 80 m.

Un nombre unique ne peut pas satisfaire les deux. Dans le V4.0, c'est le besoin « notification » qui l'emporte, ce qui rend le routage inexploitable.

## 2.2 Défaut n°2 — La gravité détermine la géométrie, et la relation est inversée

Comparaison entre le §7.2.1 et l'étendue physique réelle des incidents :

| Type (§7.2.2) | Gravité V4.0 | Rayon V4.0 | Étendue physique réelle | Verdict |
|---|---|---|---|---|
| Embouteillage | 🟡 Faible | **200 m** | **500 m à plusieurs km** | ❌ largement sous-estimé |
| Travaux | 🟡 Faible | 200 m | 50 m à 2 km selon le chantier | ❌ non modélisé |
| Colis suspect | 🟡 Faible | 200 m | périmètre de sécurité 100-300 m | ⚠️ gravité discutable |
| Accident | 🟠 Moyen | 500 m | **20 à 200 m** sur une voie | ❌ surestimé |
| Individu suspect | 🟠 Moyen | 500 m | ponctuel et mobile | ❌ non modélisable |
| Agression | 🔴 Élevé | **1 000 m** | **10 à 50 m** | ❌ surestimé (facteur 20 à 100) |
| Incendie | 🔴 Élevé | 1 000 m | 30 à 200 m | ❌ surestimé |

**Le modèle est inversé sur ses deux extrêmes.** L'embouteillage — seul incident réellement étendu de la liste — reçoit le plus petit rayon. L'agression — événement quasi ponctuel — reçoit le plus grand.

L'origine de l'erreur est compréhensible : le V4.0 a raisonné en « à quel point c'est grave » et l'a projeté sur « à quelle distance c'est pertinent ». C'est juste pour la **notification**, faux pour la **géométrie**.

Le même défaut affecte les durées de vie : *travaux → 30 minutes*, alors qu'un chantier dure des semaines.

> **Gravité, étendue et durée sont trois dimensions indépendantes. Le V4.0 les a fusionnées en une seule.**

## 2.3 Défaut n°3 — Pas de distinction entre signalement et incident

Dans le V4.0 : un utilisateur signale → une alerte est créée. Cinq personnes témoins du même incendie produisent **cinq alertes** distinctes.

Conséquences dès le premier événement marquant en usage réel :

- Carte illisible : cinq cercles superposés et décalés
- Cinq zones d'évitement envoyées au moteur de routage au lieu d'une
- Le compteur de confirmations (§7.3.1) est dilué sur cinq objets — le seuil anti-abus ne se déclenche jamais
- Impossible de distinguer trois incidents distincts de trois témoignages du même incident

Et le signal le plus précieux d'une application communautaire est perdu : **quand plusieurs personnes signalent indépendamment au même endroit dans la même minute, on obtient à la fois la confirmation et une bien meilleure estimation de la position.**

## 2.4 Défaut n°4 — Pas de résolution, seulement de l'expiration

Le V4.0 prévoit qu'une alerte **expire** après un délai fixe. Il ne prévoit pas qu'elle soit **résolue**.

Un accident dégagé en 20 minutes continuerait donc à dérouter des utilisateurs pendant 1 h 40. Chaque détour inutile érode la confiance dans la feature. Sur une application de sécurité, la confiance perdue ne revient pas.

## 2.5 Défaut n°5 — Aucune notion de précision de position

Un signalement effectué avec un fix GPS à ±8 m et un signalement à ±60 m sont traités de manière identique. La précision (`gps_accuracy`) est pourtant fournie gratuitement par le SDK de géolocalisation déjà retenu (§6.3.1).

## 2.6 Défaut n°6 — Le bouton de confirmation est un instrument trop grossier

Le §7.3.1 prévoit un bouton unique de confirmation. Confirmer quoi ? Que l'incident existe ? Qu'il est toujours en cours ? Qu'il est plus grave qu'annoncé ? Trois questions distinctes derrière un seul geste.

## 2.7 Défaut n°7 — Le paywall bloque la contribution

Le §10.1 place les alertes communautaires en « lecture seule » pour le tier Gratuit. La création est réservée aux abonnés.

C'est contre-productif : le module a un besoin critique de contributeurs pour atteindre une densité utile. Restreindre la contribution ralentit le seul mécanisme capable de remplir le module.

## 2.8 Conséquence technique directe sur le routage

Le moteur retenu (HERE Routing v8, cf. §5.2) applique **deux algorithmes différents** selon la taille de la zone à éviter :

- **Petite zone** → évitement basé sur la géométrie des segments. Précis. Évite même les segments partiellement dans la zone.
- **Grande zone** → évitement approximatif basé sur les jonctions. N'évite que les segments **entièrement** contenus dans la zone, ou dont une jonction de début/fin est à l'intérieur.

HERE situe la frontière autour de « quelques pâtés de maisons » : environ 20 000 m² (bloc de Manhattan) à 50-70 000 m² (bloc parisien).

Application aux rayons du V4.0 :

| Gravité V4.0 | Rayon | Surface du disque | Régime HERE |
|---|---|---|---|
| 🟡 Faible | 200 m | 125 600 m² | approximatif |
| 🟠 Moyen | 500 m | 785 000 m² | approximatif |
| 🔴 Élevé | 1 000 m | **3 141 000 m²** | approximatif — échelle d'un quartier |

**Les trois niveaux du V4.0 tombent dans le régime approximatif.** Sans refonte géométrique, l'évitement serait structurellement imprécis, quel que soit le soin apporté à l'implémentation.

---

# 3. DÉCISIONS CLÉS V4.1

⚠️ **REMPLACE et complète le §16 du V4.0**

| Décision | Choix V4.1 | Raison |
|---|---|---|
| Moteur de routage | **HERE Routing API v8** | Seul fournisseur combinant évitement de zones polygonales, signalement explicite des violations et SDK Flutter officiel |
| Appels au moteur | **Serveur uniquement** (Laravel) | Clé API non extractible, contrôle du volume et de la facture, changement de fournisseur sans mise à jour des stores |
| Géométrie des alertes | **Corridor ou polygone selon le type**, plus le cercle seul | Le danger est une propriété du réseau routier, pas du plan |
| Rayons | **Trois valeurs distinctes** : notification / affichage / évitement | Trois usages aux contraintes opposées |
| Gravité | Détermine **uniquement** couleur, priorité et tri | Gravité, étendue et durée sont indépendantes |
| Modèle communautaire | **Signalement ≠ Incident**, avec clustering | Carte lisible, position affinée, anti-abus opérant |
| Affichage vs routage | **Géométries différentes** pour le même incident | Le halo exprime l'incertitude, le corridor exprime la décision |
| Fin de vie d'un incident | **Résolution communautaire** en plus de l'expiration | Un incident terminé ne doit plus dérouter personne |
| Second appel de routage | **Uniquement sur action explicite** de l'utilisateur | Coût maîtrisé + signal produit mesurable |
| Surveillance en trajet | **Pilotée par la création d'alerte**, pas par polling | Zéro batterie, zéro appel externe supplémentaire |
| Contournement d'un danger vital | **Gratuit, illimité, sans condition** | On monétise le confort, jamais la survie |
| Alertes visant des personnes | **Affichées, jamais routées** | Refus d'encoder du profilage dans un algorithme de navigation |
| Création d'alerte en tier Gratuit | **Autorisée** (⚠️ modifie §10.1) | Le module a besoin de contributeurs pour exister |

---

# 4. CHANTIER A — REFONTE DU MODÈLE D'ALERTE

⚠️ **REMPLACE les §7.1, §7.2.1, §7.2.2, §7.2.3 et §7.3.1 du V4.0**

## 4.1 Découplage des trois rayons

```
incident {
  severity          : low | medium | high     → couleur, priorité, tri. RIEN d'autre.

  geometry_type     : corridor | polygon      → déterminé par le TYPE d'incident
  geometry          : [...]                   → où se situe le danger
  danger_buffer_m   : 15 .. 60                → largeur utilisée pour l'ÉVITEMENT

  notify_radius_m   : 200 .. 2000             → qui reçoit le PUSH
  display_radius_m  : dérivé                  → ce qui est DESSINÉ sur la carte

  ttl               : fonction du TYPE, pas de la gravité
}
```

Le `notify_radius_m` reste généreux : tout le quartier est prévenu de l'incendie. La géométrie d'évitement devient chirurgicale : seule la voie concernée est exclue. Les deux promesses cessent de se contredire.

## 4.2 Deux primitives géométriques

HERE Routing v8 expose trois formes : `bbox`, `polygon`, `corridor`. `bbox` n'étant qu'un polygone dégénéré, deux primitives suffisent.

### A. `corridor` — le danger est SUR une voie

Cas majoritaire : accident, incendie, agression, véhicule en panne, contrôle routier, route barrée, travaux, embouteillage.

Le danger se situe en un point d'une voie. Ce qu'il faut exclure est **un tronçon de cette voie**, pas un disque autour du point.

```
corridor:48.8698,2.3325;48.8703,2.3341;r=20
```

Polyligne suivant la rue sur 100 à 150 m, largeur 20 m. Assez large pour couvrir la chaussée, assez étroit pour ne pas capturer la rue parallèle.

### B. `polygon` — le danger couvre réellement une surface

Manifestation, inondation, émeute, coupure d'électricité, périmètre de sécurité, zone de recherche.

Le disque est ici légitime. Il est converti en polygone à 12 sommets pour l'envoi à HERE.

### C. Corridor long — le danger s'étend le long d'un axe

Embouteillage, convoi, portion d'autoroute fermée, chantier linéaire. Même primitive que A, avec davantage de points. C'est enfin une modélisation correcte de l'embouteillage, que le V4.0 traitait comme un point de 200 m.

## 4.3 Gain chiffré

| Modèle | Géométrie | Surface | Régime HERE |
|---|---|---|---|
| V4.0 — gravité Élevé | disque r = 1000 m | 3 141 000 m² | approximatif |
| V4.0 — gravité Moyen | disque r = 500 m | 785 000 m² | approximatif |
| V4.0 — gravité Faible | disque r = 200 m | 125 600 m² | approximatif |
| **V4.1 — corridor** | 120 m × 20 m | **2 400 m²** | ✅ **précis** |
| **V4.1 — polygone serré** | disque r = 80 m | 20 100 m² | ✅ précis (limite) |

**Facteur 1 300 sur la surface, et surtout changement d'algorithme.**

Ce n'est pas une optimisation marginale. Avec le modèle V4.0, l'évitement est structurellement approximatif quoi qu'on fasse. Avec le corridor, on bascule dans l'évitement basé sur la géométrie des segments, qui capture même les segments partiellement inclus.

## 4.4 Affichage ≠ routage

| | Géométrie | Justification |
|---|---|---|
| **Affichage carte** | halo circulaire, généreux, flou | Un signalement communautaire est imprécis (GPS urbain ±10 à 50 m). Un trait fin sur une seule rue prétendrait une précision que la donnée ne possède pas. Le halo communique honnêtement « quelque part par ici ». |
| **Routage** | corridor ou polygone serré | Le moteur exige une décision binaire sur des segments de route. |

Ce n'est pas une incohérence. Le halo exprime une **incertitude**, le corridor exprime une **décision**. Conséquence pratique : le cercle du design system (§12) est conservé, la validation visuelle du client reste acquise.

## 4.5 Signalement ≠ Incident

➕ **AJOUTE — changement structurel absent du V4.0**

```
        Signalement          Signalement          Signalement
     (Marie, 14h02)       (Ahmed, 14h03)       (Léa, 14h05)
             \                   |                   /
              \                  |                  /
               └────────► clustering spatio-temporel ◄────┘
                                 │
                         ┌───────▼────────┐
                         │    INCIDENT    │  ← objet publié,
                         │  position =    │     affiché et routé
                         │   centroïde    │
                         │  confiance = 3 │
                         └────────────────┘
```

### Règle de regroupement

Deux signalements fusionnent s'ils sont :

- de **même type**, ou de types compatibles (voir table §4.9)
- à moins de **150 m** l'un de l'autre
- à moins de **10 minutes** d'écart

Ces trois seuils sont configurables et devront être ajustés à l'usage réel.

### Ce que le clustering débloque

| Bénéfice | Détail |
|---|---|
| **Carte lisible** | Un incendie = un objet, quel que soit le nombre de témoins |
| **Position affinée** | Le centroïde de N signalements indépendants est significativement plus précis que chacun pris isolément. La géométrie d'évitement devient fiable *grâce à* la nature communautaire de la donnée, et non malgré elle. |
| **Anti-abus opérant** | `confiance = nombre de signalements indépendants`. Un troll isolé produit un incident à confiance 1 → affiché, jamais routé. |
| **Géométrie déduite** | À partir de 4 signalements, l'enveloppe convexe donne l'étendue réelle. Une manifestation qui progresse dessine sa propre forme, sans rien demander à l'utilisateur. |
| **Passage à l'échelle** | C'est le fonctionnement de Waze. Ce n'est pas un détail d'implémentation, c'est ce qui sépare une app de signalement d'une app de sécurité. |

> **Note importante :** le signalement spontané indépendant a plus de valeur probante que la confirmation par bouton. Confirmer suppose d'avoir vu l'alerte puis d'avoir tapé. Signaler spontanément est un acte non sollicité, bien plus difficile à falsifier en volume.

## 4.6 Construction de la géométrie — l'utilisateur ne la saisit jamais

**Contrainte absolue :** une personne signalant une agression est en état de stress. Elle ne dessinera pas de polygone. Le V4.0 a raison sur ce point et ce principe est conservé.

Le parcours de signalement reste celui du §7.2.3, en trois taps :

```
  [🔥 Incendie]  →  [gravité]  →  [confirmer position]  →  envoyé
```

Le système déduit la géométrie du type d'incident. L'utilisateur ne voit jamais la table du §4.9.

### Construction du corridor sans appel API

**Cas 1 — Le signaleur est en déplacement.** Sa trace GPS récente est déjà remontée (§6.3.2, remontée adaptative). **Les 100 derniers mètres de sa propre trace *sont* la géométrie de la voie.** Ils sont repris tels quels comme polyligne du corridor.

- Zéro appel externe, zéro coût, et géométrie exacte plutôt qu'approximée.

**Cas 2 — Le signaleur est à l'arrêt ou piéton.** Pas de trace exploitable. Repli sur un **polygone serré de 80 m de rayon** (20 100 m², à la frontière du régime précis de HERE). Soit 150 fois mieux que le disque de 1 km, sans aucune infrastructure supplémentaire.

### Phasage

| Phase | Méthode | Dépendance |
|---|---|---|
| **V1** | Polygone serré 80 m par défaut + corridor quand la trace GPS est disponible | Aucune |
| **V2** | Corridor systématique via snapping sur le réseau routier | ❓ Mécanisme de snapping HERE à identifier (§14) |

## 4.7 Cycle de vie — résoudre, pas seulement expirer

➕ **AJOUTE**

Trois mécanismes complémentaires :

### a) Résolution communautaire

Bouton **« C'est terminé »** sur la fiche incident, symétrique du bouton de confirmation existant. Deux à trois signalements de résolution font passer l'incident en statut `resolved`.

### b) Résolution passive

Si N utilisateurs traversent la zone sans rien signaler et sans ralentissement anormal, l'incident est probablement terminé. Les positions sont déjà disponibles (§6.3). La confiance est décrémentée automatiquement. Coût : nul.

### c) Prolongation automatique

Symétriquement, tout nouveau signalement rattaché à un incident actif repousse son expiration. Un incendie qui dure trois heures reste actif trois heures, sans que quiconque ait eu à choisir une durée.

> La durée de vie cesse d'être une constante décidée en réunion. Elle devient une propriété émergente de l'attention collective — sans modérateur, ce qui reste conforme à la décision « pas de modération » du §16 V4.0.

## 4.8 Confiance et précision de position

➕ **AJOUTE**

Chaque signalement porte un indice de confiance dérivé de :

| Facteur | Source | Effet |
|---|---|---|
| Précision du fix GPS | `gps_accuracy` du SDK (§6.3.1) | > 40 m → buffer élargi ; > 80 m → affichage seul |
| En mouvement / à l'arrêt | Vitesse instantanée | À l'arrêt = position plus fiable |
| Ancienneté du compte | `users.created_at` | Compte de moins de 24 h → pondération réduite |
| Historique du signaleur | Taux de signalements résolus vs rejetés | Réputation implicite, sans score public |
| Nombre de signalements indépendants | Clustering (§4.5) | **Facteur dominant** |

## 4.9 Table de référence — type d'incident → comportement

⚠️ **REMPLACE le §7.2.2 du V4.0**

| Type | Emoji | Gravité par défaut | Géométrie | Buffer | TTL par défaut | Notification | Modifie l'itinéraire |
|---|---|---|---|---|---|---|---|
| Accident | 🚗 | Moyen | corridor | 20 m | 45 min, prolongeable | 500 m | ✅ dès 1 signalement |
| Incendie | 🔥 | Élevé | corridor + polygone 80 m | 25 m | 2 h, prolongeable | 1 000 m | ✅ dès 1 signalement |
| Agression | ⚠️ | Élevé | corridor court | 20 m | 1 h | 800 m | ⚠️ à partir de 3 signalements |
| Individu suspect | 👤 | Moyen | polygone 100 m | — | 45 min | 500 m | ❌ **jamais** |
| Colis suspect | 📦 | Moyen | polygone 150 m | — | 1 h, prolongeable | 500 m | ✅ dès 2 signalements |
| Travaux | 🚧 | Faible | corridor long | 20 m | **7 jours** | 300 m | ✅ dès 2 signalements |
| Embouteillage | 🚦 | Faible | corridor long | 20 m | 30 min, auto-prolongé | 400 m | ✅ dès 2 signalements |
| Inondation | 🌊 | Élevé | polygone | — | 6 h | 1 000 m | ✅ dès 2 signalements |
| Manifestation | 📢 | Moyen | polygone (enveloppe) | — | 4 h | 800 m | ✅ dès 3 signalements |
| Autre | 🔔 | Libre | polygone 100 m | — | 1 h | 400 m | ❌ |

**Note :** cette table ajoute quatre types absents du V4.0 (Travaux distinct, Embouteillage distinct, Inondation, Manifestation) et retire le type générique « bagarre » (couvert par Agression). Elle doit vivre en base de configuration, pas en dur dans le code — elle évoluera avec l'usage réel.

## 4.10 Règles complémentaires anti-abus

1. **Une alerte créée par un utilisateur ne modifie jamais son propre itinéraire.** Protection anti-auto-manipulation, une ligne de code.
2. **Zéro confirmation et un seul signalement → affichage seul.** Le seuil de confiance conditionne l'autorité de modifier des trajets.
3. **Seuls les incidents `active` comptent.** Les TTL et la résolution font le ménage.
4. **Plafond de signalements par utilisateur et par heure.** Limite de débit contre le spam automatisé.
5. **Un incident à faible confiance qui n'est jamais reconfirmé passe en `rejected`** au bout de son TTL, et pénalise légèrement la réputation implicite de son auteur.

## 4.11 Position éthique et juridique

➕ **AJOUTE — décision produit, pas décision technique**

**Les signalements portant sur des personnes ne modifient jamais un itinéraire.**

Concerné : le type « Individu suspect ». Le type « Agression » n'influence le routage qu'à partir de trois signalements indépendants.

**Motif :** rerouter automatiquement autour d'un signalement visant une personne revient à encoder du profilage dans un algorithme de navigation. Sur un marché grand public français, cela constitue un risque réputationnel réel et probablement un sujet CNIL.

**Principe retenu :** l'information reste visible, l'utilisateur décide. L'algorithme ne prend jamais cette décision à sa place.

Cette règle doit être validée par écrit par le client avant développement.

---

# 5. CHANTIER B — NOUVEAU MODULE TRAJETS

➕ **AJOUTE — nouveau chapitre, sans équivalent dans le V4.0**

## 5.1 Périmètre V1

| | Inclus V1 | Reporté |
|---|---|---|
| Saisie départ / arrivée avec autocomplétion | ✅ | |
| Tracé de l'itinéraire sur la carte | ✅ | |
| Itinéraires alternatifs (jusqu'à 3) | ✅ | |
| Détection des incidents sur le trajet | ✅ | |
| Avertissement **avant le départ** | ✅ | |
| Recalcul avec contournement | ✅ | |
| Surveillance pendant le trajet (push si nouvel incident devant) | ✅ | |
| Historique des trajets | ✅ | |
| Trajets favoris | | V2 |
| **Guidage turn-by-turn avec voix** | | **V2 ou jamais** |
| Partage du trajet avec un proche (ETA) | | V2 |
| Routage hors ligne | | V2 |

### Pourquoi le turn-by-turn est exclu de la V1

Trois raisons, dans l'ordre d'importance :

1. **Il multiplie le périmètre par 3 à 4.** Guidage vocal, recalcul en continu, gestion des déviations, instructions de voie.
2. **Il casse la stack de géolocalisation économe retenue au §6.3.1.** `geolocator` + `background_fetch` ne tiennent pas une navigation continue ; il faut un service de premier plan et un GPS permanent.
3. **Il place AlertContacts en concurrence frontale avec Google Maps sur le terrain où Google est imbattable**, tout en détruisant l'autonomie — sur une application dont la promesse est « fonctionner en toutes circonstances » (§16).

La valeur d'AlertContacts n'est pas de guider. Elle est de **prévenir avant de partir et de veiller pendant le trajet**.

## 5.2 Choix du moteur de routage

### Matrice comparative

| Critère | Google Routes | Mapbox Directions | **HERE Routing v8** | Valhalla |
|---|---|---|---|---|
| Exclusion de zone arbitraire | ❌ aucune | ⚠️ points, BETA | ✅ **bbox + polygone + corridor** | ✅ polygones |
| Nombre de zones par requête | — | 50 points max | **250** | non spécifié |
| Signalement des violations | ❌ | ✅ `violation` | ✅ `violatedBlockedRoad` (critical) | partiel |
| Itinéraires alternatifs | ✅ | ✅ | ✅ `alternatives` + `routeLabels` | ✅ |
| SDK Flutter officiel | ❌ | ❓ à vérifier | ✅ **first-party** | ❌ REST uniquement |
| Routage hors ligne | ❌ | partiel | ✅ 190+ pays | ✅ si auto-hébergé |
| Charge d'infrastructure | nulle | nulle | **nulle** | lourde |
| Coût à l'échelle | élevé | moyen | ❓ à chiffrer | **le plus bas** |

### Pourquoi Google est éliminé

L'API Google Routes ne propose que quatre exclusions : `avoidTolls`, `avoidHighways`, `avoidFerries`, `avoidIndoor`. **Aucune exclusion géographique arbitraire.** Google précise en outre que ces contraintes ne sont qu'un biais et n'excluent pas les routes concernées.

Le contournement souvent proposé — insérer un point de passage forçant un détour — est à rejeter : le moteur ne garantit pas la route empruntée entre deux points de passage et peut retraverser la zone.

**Google reste pertinent pour l'autocomplétion d'adresses** (Places), indépendamment du choix de moteur de routage.

### Pourquoi Mapbox n'est pas retenu

`exclude=point(lon lat)` semble adapté, mais :

- La fonctionnalité est en **BETA** — inacceptable au cœur d'une promesse de sécurité
- Elle exclut des **points snappés à la route la plus proche**, pas des zones : une alerte de 1 km couvre des dizaines de segments, il faudrait deviner où poser les points
- **50 points maximum** par requête
- Les exclusions sont explicitement **« best-effort »**

Reste viable comme fournisseur de secours.

### Pourquoi Valhalla est retenu comme porte de sortie, pas comme socle V1

`exclude_polygons` est une contrainte solide et le coût marginal est quasi nul en auto-hébergement. Mais :

- L'auto-hébergement ajoute un poste d'infrastructure permanent (tuiles OSM, RAM, mises à jour, supervision) à un projet qui porte déjà Laravel + Firebase + MySQL
- En managé via Stadia Maps, le tier gratuit est réservé au développement, à l'évaluation et au non-commercial — AlertContacts est commercial, donc payant dès le premier jour
- Pas de SDK Flutter first-party
- La documentation Valhalla recommande elle-même `exclude_locations` plutôt que `exclude_polygons` pour des raisons de coût de calcul

**Bascule envisagée quand la facture HERE dépassera le coût d'un poste d'exploitation.** C'est un arbitrage de volume, pas de capacité technique.

### Ce que HERE garantit exactement — et ce qu'il ne garantit pas

**Point d'honnêteté important :** HERE peut lui aussi traverser une zone à éviter. La documentation l'indique explicitement :

> *« If the specified area and vehicle parameters are such that the only possible route is through the avoided area, the part of the route inside the avoided area may not be optimal. »*

Cas documentés où la route traverse malgré tout :
- Aucun itinéraire alternatif n'existe (pont unique, impasse)
- L'origine, la destination ou un point de passage est **à l'intérieur** de la zone

**La différence décisive** est que HERE le signale de façon explicite et machine-lisible :

```json
"notices": [{
  "title": "Violated road that is blocked, due to a traffic incident, `avoid[areas]`, or `avoid[segments]`.",
  "code": "violatedBlockedRoad",
  "severity": "critical"
}]
```

Cela permet de construire une interface honnête : « zone contournée » vs « zone traversée — aucune alternative disponible ».

## 5.3 Architecture

```
┌──────────────────── FLUTTER ─────────────────────┐
│  Barre de recherche « Où vas-tu ? »              │
│  Carte + tracé + sélecteur d'itinéraires         │
│  Bandeau d'avertissement incident                │
└──────────────────────┬───────────────────────────┘
                       │  REST — aucun appel direct à HERE
┌──────────────────────▼───────────────────────────────────────┐
│                        LARAVEL                                │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ RoutingProvider  (interface)                            │ │
│  │   ├─ HereRoutingProvider          ← V1                  │ │
│  │   └─ ValhallaRoutingProvider      ← porte de sortie     │ │
│  ├─────────────────────────────────────────────────────────┤ │
│  │ IncidentIntersectionService   ← 0 appel externe         │ │
│  │   Haversine (formule déjà spécifiée §11.3.1)            │ │
│  ├─────────────────────────────────────────────────────────┤ │
│  │ IncidentGeometryBuilder                                 │ │
│  │   cercle → n-gone · trace GPS → corridor                │ │
│  ├─────────────────────────────────────────────────────────┤ │
│  │ IncidentClusteringService     ← signalement → incident  │ │
│  ├─────────────────────────────────────────────────────────┤ │
│  │ RouteAvoidancePolicy                                    │ │
│  │   quels incidents ont le droit de modifier un trajet    │ │
│  └─────────────────────────────────────────────────────────┘ │
└────────┬─────────────────────────────────────┬───────────────┘
         │ clé API strictement serveur         │
┌────────▼────────────┐              ┌─────────▼──────────────┐
│  HERE Routing v8    │              │  MySQL  ·  Firebase    │
└─────────────────────┘              └────────────────────────┘
```

### Règle non négociable

**Flutter n'appelle jamais HERE directement.** Trois motifs :

1. Une clé API embarquée dans un APK est extractible en quelques minutes
2. Le volume d'appels, donc la facture, doit rester sous contrôle serveur
3. Un changement de fournisseur ne doit pas exiger une publication sur les stores

L'abstraction `RoutingProvider` est à écrire dès la V1. Coût estimé : deux jours. Elle rend la migration vers Valhalla indolore.

## 5.4 Flux détaillé

### Étape 1 — Saisie de la destination

Autocomplétion d'adresses. Deux options : HERE Geocoding & Search (fournisseur unique, facture unique) ou Google Places (❓ meilleure couverture des POI en Afrique francophone à vérifier sur les marchés cibles).

**Debounce de 300 ms minimum.** Sans cela, chaque frappe génère une requête facturée.

> **Appels de routage : 0**

### Étape 2 — Calcul de l'itinéraire

```bash
GET https://router.hereapi.com/v8/routes
  ?origin=48.8566,2.3522
  &destination=48.8738,2.2950
  &transportMode=car
  &return=polyline,summary,routeLabels
  &alternatives=2
  &apiKey=***
```

**`routeLabels`** génère automatiquement des libellés lisibles à partir des axes les plus structurants de chaque itinéraire — « via A86 », « via Bd Voltaire ». Chaque route reçoit au maximum deux libellés : l'axe le plus long, puis l'axe non-commun le plus long. Les libellés du sélecteur d'itinéraires sont donc fournis par l'API, sans code à écrire.

La géométrie est retournée au format **Flexible Polyline**, format d'encodage propre à HERE, open source. ❓ Vérifier la disponibilité d'un décodeur PHP (Laravel) et Dart (Flutter).

> **Appels : 1**

### Étape 3 — Détection des incidents sur le trajet

Entièrement côté Laravel. Aucun appel externe, aucun coût.

```
1. Décoder la polyligne → liste de points
2. Calculer la bbox de la polyligne + marge
   → SELECT des incidents actifs dans cette bbox (index spatial)
3. Sous-échantillonner la polyligne tous les ~50 m
4. Pour chaque incident candidat :
       d = min( Haversine(point_polyligne, géométrie_incident) )
   si d <= incident.danger_buffer_m  →  HIT
5. Appliquer RouteAvoidancePolicy (table §4.9 + règles §4.10)
6. Trier par gravité puis par distance au point de départ
```

**Optimisation :** filtrer d'abord les incidents par bbox, ne jamais tester les 4 000 points de la polyligne contre l'ensemble des incidents. Sur un trajet urbain type, le calcul s'exécute en quelques millisecondes.

> **Appels : 0**

### Étape 4 — Avertissement avant le départ

Aucun HIT → l'itinéraire s'affiche, fin du parcours. **Le cas majoritaire ne coûte qu'un seul appel.**

HIT → bandeau au-dessus de la bottom card :

```
┌────────────────────────────────────────────┐
│  🔴  Agression signalée sur ton trajet     │
│      Rue de la Paix · il y a 12 min        │
│      Signalée par 3 personnes              │
│                                             │
│   [  Contourner  ]      [  Continuer  ]    │
└────────────────────────────────────────────┘
```

### Étape 5 — Recalcul avec contournement

**Décision de conception : le second appel n'est déclenché que si l'utilisateur tape « Contourner ».**

Double bénéfice :
- Le second appel n'est facturé que quand la feature apporte réellement de la valeur
- Le taux de tap devient un **signal produit mesurable** de l'utilité de la feature

Conversion du cercle en polygone (12 sommets, erreur d'aire < 4 %) :

```
Pour k de 0 à N-1 :
  θ     = 2πk / N
  lat_k = lat + (r / 111320) × cos(θ)
  lon_k = lon + (r / (111320 × cos(lat))) × sin(θ)
```

Requête :

```bash
GET https://router.hereapi.com/v8/routes
  ?origin=...&destination=...
  &transportMode=car
  &return=polyline,summary,routeLabels,actions
  &alternatives=2
  &avoid[areas]=polygon:48.8701,2.3312;48.8698,2.3340;...
  &apiKey=***
```

Plusieurs incidents → concaténation avec `|`. Limite de 250 zones, jamais atteinte en pratique (1 à 5 sur un trajet).

Formes combinables dans un même appel :

```
avoid[areas]=polygon:52.5185,13.3416;52.5237,13.3733;52.5119,13.3780
             |bbox:13.4142,52.5845,13.4081,52.5883
             |corridor:52.5748,13.3896;52.5798,13.3977;r=100
```

Le mécanisme `!exception=` permet de retirer une sous-zone d'une zone évitée. Utile si la destination se trouve en bordure d'un incident.

**⚠️ Prévoir le POST dès la V1.** Si l'URL dépasse la longueur maximale autorisée, HERE accepte la requête en POST avec `avoid` dans le corps. Anticiper cela dans le client HTTP Laravel évite un bug tardif et difficile à diagnostiquer.

> **Appels : 1, conditionnel**

### Étape 6 — Vérification et affichage

Double filet de sécurité :

```
Pour chaque itinéraire retourné :
    (1) notices[] contient-il "violatedBlockedRoad" (severity: critical) ?
    (2) Ma propre mesure Haversine dit-elle « traverse encore » ?

    OUI à l'un des deux  →  badge « contournement partiel »
    NON aux deux         →  badge « contourne la zone »
```

Sélecteur d'itinéraires :

```
┌──────────────────────────────────────────┐
│ ✅ via A86               24 min   +7 min │
│    contourne la zone signalée            │
├──────────────────────────────────────────┤
│ ⚠️ via Bd Voltaire       17 min          │
│    traverse la zone signalée             │
└──────────────────────────────────────────┘
```

Les libellés proviennent de `routeLabels`.

## 5.5 Surveillance pendant le trajet

➕ **AJOUTE**

**Principe : l'événement déclencheur est la création d'un incident, pas l'écoulement du temps.**

Ne pas implémenter « toutes les 2 minutes, le téléphone demande s'il y a du nouveau ». Implémenter « quand un incident est créé, le serveur regarde qui roule dessus ».

```
Un incident est créé ou passe le seuil de confiance
        ↓
Laravel : SELECT les trajets status='active'
          dont la bbox recoupe l'incident
        ↓
Pour chacun : Haversine sur la portion NON ENCORE PARCOURUE
        ↓
HIT  →  push FCM
        « 🔴 Alerte sur ta route, dans 800 m. Contourner ? »
        ↓
Tap  →  recalcul depuis la position courante   [1 appel, à la demande]
```

Bénéfices :

| | |
|---|---|
| **Zéro polling** | Pas de consommation batterie supplémentaire, pas de requêtes à vide |
| **Zéro appel HERE** | Tant que personne ne tape « Contourner » |
| **Code déjà prévu** | L'endpoint de création d'alerte existe (§11.2.5). On y ajoute un job en file. |
| **Stack géoloc préservée** | Le téléphone continue sa remontée adaptative (§6.3.2), rien de plus |

Résultat : la sensation « l'application veille sur moi pendant que je roule » pour un coût marginal quasi nul. C'est exactement la promesse du §1.1 — *« une application de tranquillité d'esprit »*.

## 5.6 Cas limites

| Situation | Comportement attendu |
|---|---|
| **Destination à l'intérieur de la zone** | HERE documente que la route traversera. Ne pas proposer de contournement. Afficher : *« Ta destination est dans la zone signalée. Sois prudent à l'arrivée. »* |
| **Aucune alternative possible** | `violatedBlockedRoad` critical. Afficher : *« Aucun itinéraire ne contourne cette zone. Voici le trajet le plus court — reste vigilant. »* **Jamais d'écran vide ni d'erreur technique.** |
| **Incident expiré ou résolu en cours de trajet** | Retrait silencieux de la carte. Aucune notification : l'absence de danger n'est pas un événement. |
| **Contournement excessivement long** | Au-delà de +50 % de durée, proposer sans imposer. Afficher clairement le surcoût en minutes. |
| **Hors ligne** | §9.1 : jamais bloquant. Pas de calcul possible. Afficher le dernier itinéraire en cache avec horodatage visible. |
| **Piéton vs voiture** | `transportMode` change les incidents pertinents (un accident de la route pèse moins à pied). Paramétré dans la table §4.9. |
| **Trop d'incidents sur le trajet** | Plafonner à 20 zones, prioriser par gravité puis par proximité au point de départ. |
| **Incident créé par l'utilisateur lui-même** | Exclu de son propre calcul (§4.10 règle 1). |
| **Trajet très long (> 100 km)** | Sous-échantillonner davantage la polyligne. Ne considérer que les incidents dans un couloir de ±2 km. |

---

# 6. INTERFACE & PARCOURS

## 6.1 Intégration à la navigation

⚠️ **NE MODIFIE PAS le §5.1 — la barre d'onglets reste à 3 entrées**

Le module Trajets **n'ajoute pas de quatrième onglet**. Il s'intègre à l'onglet Carte via une barre de recherche flottante placée sous le header.

```
┌─────────────────────────────────────────┐
│  ⊞        ● 3 proches actifs        (A) │  ← header §5.2, inchangé
├─────────────────────────────────────────┤
│  ┌───────────────────────────────────┐  │
│  │  🔍  Où vas-tu ?                  │  │  ← ➕ NOUVEAU
│  └───────────────────────────────────┘  │
│                                          │
│              [  CARTE  ]                 │
│                                          │
│                                    (◎)   │  ← FAB localisation, inchangé
├─────────────────────────────────────────┤
│      Carte    │   Proches   │  Alertes   │
└─────────────────────────────────────────┘
```

**Justification :** convention établie (Google Maps, Apple Plans, Waze), aucun emplacement de navigation consommé, découvrabilité maximale. La règle de la thumb zone (§12.4) est respectée : la barre est en zone haute mais n'est qu'un point d'entrée ; toutes les actions décisionnelles restent en zone basse.

## 6.2 Écran — Recherche d'itinéraire

| Élément | Spécification |
|---|---|
| Champ Départ | Pré-rempli « Ma position ». Modifiable. |
| Champ Arrivée | Focus automatique à l'ouverture. Autocomplétion à partir de 3 caractères, debounce 300 ms. |
| Adresses récentes | 5 dernières destinations, sous les champs |
| Mode de transport | Segmenté : 🚗 Voiture · 🚶 À pied · 🛵 Deux-roues |
| Bouton d'inversion | Icône ⇅ entre les deux champs |
| État vide | « Où veux-tu aller ? » |

## 6.3 Écran — Aperçu de l'itinéraire

| Zone | Contenu |
|---|---|
| Carte | Tracé principal en teal. Alternatives en gris. Incidents affichés selon leur halo (§4.4). |
| Bandeau incident | Uniquement si HIT. Couleur selon la gravité (§12.1). |
| Bottom card | Durée · distance · heure d'arrivée estimée |
| CTA principal | « Démarrer » — zone basse, pleine largeur |

## 6.4 Bottom sheet — Sélection d'itinéraire

Ouverte au tap sur « Contourner » ou sur « Voir les alternatives ».

| Élément | Spécification |
|---|---|
| Cartes d'itinéraire | 2 à 3 maximum |
| Libellé | Issu de `routeLabels` — « via A86 » |
| Durée | Absolue + différentiel par rapport au plus rapide |
| Badge sécurité | ✅ contourne · ⚠️ contournement partiel · 🔴 traverse |
| Tri | Itinéraire sûr en premier, même s'il est plus long |
| Sélection | Tap → la carte se recentre et le tracé se met à jour |

## 6.5 Fiche incident — modifications

⚠️ **MODIFIE le §7.3 du V4.0**

Ajouts :

| Élément | Spécification |
|---|---|
| Compteur de signalements | « Signalé par N personnes » — remplace le compteur de confirmations seul |
| Bouton « C'est terminé » | ➕ NOUVEAU — symétrique du bouton de confirmation (§4.7a) |
| Indicateur de fiabilité | Discret. 1 signalement → « non confirmé ». 3+ → « confirmé ». |
| Mention de routage | Si l'incident ne modifie pas les itinéraires : « Cette alerte n'affecte pas le calcul d'itinéraire » |
| CTA « Éviter cette zone » | ➕ NOUVEAU — si un trajet est en cours ou planifié |

## 6.6 Formulaire de signalement — modifications

⚠️ **MODIFIE le §7.2.3 du V4.0**

Le parcours reste en trois taps. Modifications invisibles pour l'utilisateur :

| Élément | Changement |
|---|---|
| Liste des types | 4 types ajoutés (§4.9) |
| Choix du rayon | **Supprimé s'il existait** — le système déduit la géométrie |
| Capture de la trace GPS | ➕ Les 100 derniers mètres sont joints au signalement (§4.6) |
| Précision GPS | ➕ `gps_accuracy` joint au signalement |
| Détection de doublon | ➕ Si un incident compatible existe à moins de 150 m : « Un incident similaire est déjà signalé ici. Confirmer ? » |

Ce dernier point est important : il transforme un doublon potentiel en confirmation, ce qui renforce la confiance de l'incident au lieu de polluer la carte.

## 6.7 Règles de rédaction

⚠️ **Règles contraignantes, pas des suggestions**

| Interdit | Autorisé | Raison |
|---|---|---|
| « Itinéraire sécurisé » | « Contourne la zone signalée » | On ne peut pas garantir la sécurité |
| « Zone évitée à 100 % » | « Contourne la zone signalée » | L'évitement peut être partiel (§5.2) |
| « Danger » | « Alerte signalée » | Un signalement n'est pas un fait vérifié |
| « 3 personnes confirment » | « Signalé par 3 personnes » | Nuance entre témoignage et vérification |
| « Trajet dangereux » | « Alerte sur ton trajet » | Ne pas produire d'anxiété inutile sur une app dont la promesse est la tranquillité |

Le §1.1 pose que l'application vend de la tranquillité d'esprit. Un vocabulaire anxiogène travaille contre le positionnement.

---

# 7. MODÈLE DE DONNÉES

⚠️ **REMPLACE la structure d'alerte du V4.0**

## 7.1 Signalements

```sql
CREATE TABLE alert_reports (
  id                  BIGINT PRIMARY KEY AUTO_INCREMENT,
  incident_id         BIGINT NULL,            -- rattaché après clustering
  user_id             BIGINT NOT NULL,
  type                VARCHAR(32) NOT NULL,
  severity            ENUM('low','medium','high') NOT NULL,

  lat                 DECIMAL(10,7) NOT NULL,
  lng                 DECIMAL(10,7) NOT NULL,
  gps_accuracy_m      SMALLINT,               -- précision du fix
  gps_trace           JSON NULL,              -- 100 derniers m → corridor
  was_moving          BOOLEAN DEFAULT FALSE,
  speed_kmh           SMALLINT NULL,

  comment             TEXT NULL,
  photo_url           VARCHAR(255) NULL,
  visibility          ENUM('public','circle') DEFAULT 'public',

  created_at          TIMESTAMP,

  INDEX idx_cluster (type, created_at, lat, lng),
  INDEX idx_incident (incident_id),
  INDEX idx_user_rate (user_id, created_at),
  FOREIGN KEY (incident_id) REFERENCES incidents(id) ON DELETE SET NULL
);
```

## 7.2 Incidents

```sql
CREATE TABLE incidents (
  id                  BIGINT PRIMARY KEY AUTO_INCREMENT,
  type                VARCHAR(32) NOT NULL,
  severity            ENUM('low','medium','high') NOT NULL,  -- max des signalements

  -- Géométrie
  geometry_type       ENUM('corridor','polygon') NOT NULL,
  geometry            JSON NOT NULL,          -- polyligne ou anneau extérieur
  danger_buffer_m     SMALLINT NOT NULL,      -- ÉVITEMENT
  notify_radius_m     SMALLINT NOT NULL,      -- PUSH
  display_radius_m    SMALLINT NOT NULL,      -- CARTE

  -- Position et indexation
  centroid_lat        DECIMAL(10,7) NOT NULL,
  centroid_lng        DECIMAL(10,7) NOT NULL,
  bbox_north          DECIMAL(10,7) NOT NULL,
  bbox_south          DECIMAL(10,7) NOT NULL,
  bbox_east           DECIMAL(10,7) NOT NULL,
  bbox_west           DECIMAL(10,7) NOT NULL,

  -- Confiance
  report_count        SMALLINT DEFAULT 1,     -- = confiance
  confirm_count       SMALLINT DEFAULT 0,     -- boutons « je le vois aussi »
  clear_count         SMALLINT DEFAULT 0,     -- boutons « c'est terminé »
  confidence_score    DECIMAL(3,2),           -- calculé, 0.00 à 1.00

  -- Routage
  affects_routing     BOOLEAN DEFAULT FALSE,  -- dérivé de RouteAvoidancePolicy

  -- Cycle de vie
  status              ENUM('active','resolved','expired','rejected') DEFAULT 'active',
  expires_at          TIMESTAMP NOT NULL,
  resolved_at         TIMESTAMP NULL,
  created_at          TIMESTAMP,
  updated_at          TIMESTAMP,

  INDEX idx_active_bbox (status, expires_at, bbox_south, bbox_north, bbox_west, bbox_east),
  INDEX idx_routing (affects_routing, status, expires_at)
);
```

> **`affects_routing` est un booléen dérivé**, recalculé à chaque nouveau signalement. Toute la politique du §4.9 et du §4.10 s'y condense. Le service de routage n'exécute plus qu'un `WHERE affects_routing = TRUE AND status = 'active'`. Simple à lire, simple à auditer, modifiable sans toucher au moteur.

## 7.3 Trajets

```sql
CREATE TABLE routes (
  id                  BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id             BIGINT NOT NULL,

  origin_lat          DECIMAL(10,7) NOT NULL,
  origin_lng          DECIMAL(10,7) NOT NULL,
  origin_label        VARCHAR(255),
  destination_lat     DECIMAL(10,7) NOT NULL,
  destination_lng     DECIMAL(10,7) NOT NULL,
  destination_label   VARCHAR(255),

  transport_mode      ENUM('car','pedestrian','scooter') DEFAULT 'car',
  polyline            TEXT NOT NULL,          -- Flexible Polyline HERE
  distance_m          INT,
  duration_s          INT,

  avoidance_applied   BOOLEAN DEFAULT FALSE,
  avoidance_partial   BOOLEAN DEFAULT FALSE,  -- violatedBlockedRoad détecté
  avoided_incident_ids JSON NULL,

  bbox_north          DECIMAL(10,7),
  bbox_south          DECIMAL(10,7),
  bbox_east           DECIMAL(10,7),
  bbox_west           DECIMAL(10,7),

  status              ENUM('planned','active','completed','cancelled') DEFAULT 'planned',
  started_at          TIMESTAMP NULL,
  ended_at            TIMESTAMP NULL,
  created_at          TIMESTAMP,

  INDEX idx_active (status, user_id),
  INDEX idx_active_bbox (status, bbox_south, bbox_north, bbox_west, bbox_east)
);
```

## 7.4 Rencontres trajet × incident

```sql
CREATE TABLE route_incident_hits (
  id                  BIGINT PRIMARY KEY AUTO_INCREMENT,
  route_id            BIGINT NOT NULL,
  incident_id         BIGINT NOT NULL,
  min_distance_m      INT,
  detected_phase      ENUM('pre_departure','en_route') NOT NULL,
  user_action         ENUM('avoided','ignored','no_alternative','not_offered') NULL,
  detected_at         TIMESTAMP,
  acted_at            TIMESTAMP NULL,

  INDEX idx_route (route_id),
  INDEX idx_analytics (detected_phase, user_action, detected_at)
);
```

> **Cette table n'est pas une table technique, c'est le tableau de bord produit du module.** Voir §13.

---

# 8. API LARAVEL

➕ **AJOUTE au §11.2 du V4.0**

## 8.1 Trajets

```
POST   /api/v1/routes/preview
       { origin: {lat,lng,label}, destination: {...}, transport_mode }
       → { route_id, routes: [...], incidents_on_route: [...] }
       Coût : 1 appel HERE

POST   /api/v1/routes/{id}/avoid
       { incident_ids: [] }
       → { routes: [...], avoidance_partial, incidents_still_crossed: [] }
       Coût : 1 appel HERE          [point de gating premium — voir §10]

POST   /api/v1/routes/{id}/select
       { route_index }
       → 200

POST   /api/v1/routes/{id}/start        → status = active
POST   /api/v1/routes/{id}/end          → status = completed
POST   /api/v1/routes/{id}/cancel       → status = cancelled

GET    /api/v1/routes/history
       → 24 h en tier Gratuit · 30 jours en Solo/Famille (§10.1)

GET    /api/v1/routes/recent-destinations
       → 5 dernières destinations
```

## 8.2 Signalements et incidents

⚠️ **REMPLACE le §11.2.5 du V4.0**

```
POST   /api/v1/reports
       { type, severity, lat, lng, gps_accuracy_m, gps_trace,
         was_moving, comment?, photo?, visibility }
       → { report_id, incident_id, was_merged: bool }
       Déclenche : IncidentClusteringService puis CheckActiveRoutesJob

GET    /api/v1/incidents?bbox=...
       → incidents actifs dans la zone

GET    /api/v1/incidents/{id}
       → fiche détaillée + signalements agrégés

POST   /api/v1/incidents/{id}/confirm    → « je le vois aussi »
POST   /api/v1/incidents/{id}/clear      → « c'est terminé »       ➕ NOUVEAU
```

## 8.3 Jobs asynchrones

```
IncidentClusteringJob
    Déclencheur : création d'un signalement
    Rôle        : rattacher à un incident existant ou en créer un
                  recalculer centroïde, géométrie, confiance, affects_routing

CheckActiveRoutesAgainstIncidentJob        ➕ NOUVEAU — cœur du §5.5
    Déclencheur : incident créé ou franchissant le seuil de confiance
    Rôle        : SELECT routes actives dont la bbox recoupe l'incident
                  Haversine sur la portion non parcourue
                  push FCM aux utilisateurs concernés
    Coût externe: 0

ExpireIncidentsJob
    Déclencheur : planifié, toutes les minutes
    Rôle        : passer en 'expired' les incidents dont expires_at est dépassé

PassiveResolutionJob                        ➕ NOUVEAU — §4.7b
    Déclencheur : planifié, toutes les 5 minutes
    Rôle        : détecter les traversées sans signalement, décrémenter la confiance
```

---

# 9. NOTIFICATIONS PUSH — NOUVEAUX TEMPLATES

➕ **AJOUTE au §14.2 du V4.0**

Les règles générales du §14.1 s'appliquent.

| Déclencheur | Titre | Corps | Action |
|---|---|---|---|
| Incident détecté sur un trajet actif | 🔴 Alerte sur ta route | {type} signalé dans {distance}. Contourner ? | Ouvre le sélecteur d'itinéraires |
| Incident contourné avec succès | ✅ Itinéraire mis à jour | Tu contournes la zone. +{n} min. | Ouvre la carte |
| Aucune alternative | ⚠️ Impossible de contourner | Aucun itinéraire n'évite cette zone. Reste vigilant. | Ouvre la fiche incident |
| Incident sur le trajet résolu | ✅ Voie dégagée | L'alerte sur ta route n'est plus active. | Ouvre la carte |
| Signalement fusionné | — | *Pas de notification* | — |

**Règles spécifiques au module Trajets :**

1. **Jamais de push si l'incident est derrière l'utilisateur.** Seule la portion non parcourue est testée.
2. **Une seule notification par incident et par trajet.** Pas de rappel.
3. **Pas de push pour la disparition d'un danger**, sauf s'il avait généré une alerte pendant ce trajet (dernière ligne du tableau).
4. **Silence pendant la conduite si le mode Ne pas déranger est actif** — seule la gravité Élevé passe outre.

---

# 10. MONÉTISATION

⚠️ **REMPLACE partiellement le §10.1 du V4.0**

## 10.1 Position de principe

Facturer à quelqu'un le droit d'éviter un incendie est un risque asymétrique : gain marginal en conversion, exposition majeure en réputation, sur une application dont le positionnement est la sécurité familiale (§1.2).

> **Principe retenu : on monétise le confort et la veille continue. Jamais la survie.**

## 10.2 Grille révisée

| Feature | Gratuit | Solo | Famille |
|---|---|---|---|
| Calcul d'itinéraire | ✅ | ✅ | ✅ |
| Itinéraires alternatifs | ✅ | ✅ | ✅ |
| Incidents affichés sur le trajet | ✅ | ✅ | ✅ |
| Avertissement avant départ | ✅ | ✅ | ✅ |
| **Contournement — gravité 🔴 Élevé** | ✅ **illimité** | ✅ | ✅ |
| Contournement — gravité 🟡 🟠 | 3 / mois | ✅ illimité | ✅ illimité |
| Surveillance pendant le trajet | ❌ | ✅ | ✅ |
| Trajets favoris | ❌ | ✅ | ✅ |
| Historique des trajets | 24 h | 30 j | 30 j |
| **Création d'alertes communautaires** | ✅ ⚠️ *modifié* | ✅ | ✅ |

## 10.3 Deux modifications au §10.1 du V4.0

**a) La création d'alertes communautaires passe en tier Gratuit.**

Le V4.0 la réservait aux abonnés (« lecture seule » en Gratuit). C'est contre-productif : le module a un besoin critique de contributeurs pour atteindre une densité utile. Restreindre la contribution ralentit le seul mécanisme capable de remplir le module — et donc de rendre les tiers payants désirables.

**b) Le contournement d'un danger de gravité Élevé est gratuit et illimité.**

Bénéfice commercial associé : un argument de communication qui vaut davantage qu'un point de conversion — *« le contournement d'un danger vital est gratuit pour tout le monde, à vie. »*

## 10.4 Placement du paywall

Conforme au §10.3 du V4.0 et au UC-05 (§13.5) : le mur apparaît au pic de motivation, quand l'utilisateur voit un incident de gravité Faible ou Moyen sur son trajet et a épuisé ses 3 contournements mensuels.

```
┌────────────────────────────────────────────┐
│  🟠  Embouteillage sur ton trajet          │
│      Tu as utilisé tes 3 contournements    │
│      de ce mois.                            │
│                                             │
│   [ Passer à Solo — 4,99€ ]  [ Continuer ] │
└────────────────────────────────────────────┘
```

---

# 11. DESIGN SYSTEM — AJOUTS

➕ **AJOUTE au §12 du V4.0**

## 11.1 Couleurs

Réutilisation des couleurs de gravité existantes (§12.1). Ajouts :

| Usage | Couleur | Note |
|---|---|---|
| Tracé d'itinéraire principal | Teal (couleur primaire existante) | Cohérent avec « ma position » (§6.1.1) |
| Tracé alternatif | Gris 40 % | Non sélectionné |
| Tracé contournant | Teal + liseré vert | Différenciation du badge ✅ |
| Tracé traversant | Teal + pointillés orange | Signal d'attention sans dramatiser |
| Halo d'incident | Couleur de gravité, opacité 15 % | Le flou exprime l'incertitude (§4.4) |
| Bordure de halo | Couleur de gravité, pointillés | Cohérent avec les zones personnelles (§6.1.1) |

## 11.2 Composants nouveaux

| Composant | Règles |
|---|---|
| Barre de recherche flottante | Hauteur 48 dp, coins arrondis 24 dp, ombre portée légère, sous le header |
| Bandeau d'avertissement | Pleine largeur, au-dessus de la bottom card, couleur de gravité en fond à 10 % |
| Carte d'itinéraire | Hauteur 72 dp, badge sécurité à gauche, durée à droite |
| Badge sécurité | Pastille 24 dp — ✅ vert · ⚠️ orange · 🔴 rouge |
| Bouton « C'est terminé » | Style secondaire, jamais destructif visuellement |

## 11.3 Thumb zone

Conformément au §12.4 : la barre de recherche est en zone haute (point d'entrée, non critique). **Tous les boutons décisionnels — Contourner, Continuer, Démarrer, sélection d'itinéraire — sont en zone basse.**

---

# 12. USE CASES

➕ **AJOUTE au §13 du V4.0**

## UC-06 — Trajet sans incident (cas majoritaire)

| # | Acteur | Action | Système |
|---|---|---|---|
| 1 | Utilisateur | Tape « Où vas-tu ? » | Ouvre l'écran de recherche |
| 2 | Utilisateur | Saisit « Gare de Lyon » | Autocomplétion (debounce 300 ms) |
| 3 | Utilisateur | Sélectionne la destination | `POST /routes/preview` → **1 appel HERE** |
| 4 | Système | — | Détection d'incidents : aucun HIT (**0 appel**) |
| 5 | Système | — | Affiche le tracé + durée + distance |
| 6 | Utilisateur | Tape « Démarrer » | `POST /routes/{id}/start` |

**Coût total : 1 appel HERE.**

## UC-07 — Incident détecté avant le départ, contournement accepté

| # | Acteur | Action | Système |
|---|---|---|---|
| 1-3 | — | *identique à UC-06* | 1 appel HERE |
| 4 | Système | — | HIT : incendie, confiance 3, `affects_routing = true` |
| 5 | Système | — | Bandeau 🔴 « Incendie signalé sur ton trajet » |
| 6 | Utilisateur | Tape « Contourner » | `POST /routes/{id}/avoid` → **1 appel HERE** |
| 7 | Système | — | Vérifie `notices[]` + re-mesure Haversine |
| 8 | Système | — | Bottom sheet : « via A86, +7 min, ✅ contourne » |
| 9 | Utilisateur | Sélectionne | `route_incident_hits.user_action = 'avoided'` |

**Coût total : 2 appels HERE.**

## UC-08 — Aucune alternative disponible

| # | Acteur | Action | Système |
|---|---|---|---|
| 1-6 | — | *identique à UC-07* | 2 appels HERE |
| 7 | Système | — | `notices[].code = "violatedBlockedRoad"` (critical) |
| 8 | Système | — | *« Aucun itinéraire ne contourne cette zone. Voici le trajet le plus court — reste vigilant. »* |
| 9 | Système | — | `user_action = 'no_alternative'` |

**Point critique :** ce cas ne doit **jamais** produire d'écran vide, de spinner infini ou de message d'erreur technique.

## UC-09 — Incident apparaissant pendant le trajet

| # | Acteur | Action | Système |
|---|---|---|---|
| 1 | Utilisateur A | Roule, trajet `status = active` | — |
| 2 | Utilisateur B | Signale un accident 800 m devant A | `POST /reports` |
| 3 | Système | — | `IncidentClusteringJob` → incident créé |
| 4 | Système | — | `CheckActiveRoutesAgainstIncidentJob` (**0 appel HERE**) |
| 5 | Système | — | Haversine sur la portion non parcourue de A → HIT |
| 6 | Système | — | Push : « 🔴 Alerte sur ta route, dans 800 m » |
| 7 | Utilisateur A | Tape la notification | Ouvre le sélecteur |
| 8 | Utilisateur A | Tape « Contourner » | **1 appel HERE** depuis la position courante |

**Coût : 1 appel, et uniquement si A agit.**

## UC-10 — Signalements multiples fusionnés

| # | Acteur | Action | Système |
|---|---|---|---|
| 1 | Marie, 14h02 | Signale un incendie | Incident créé, `report_count = 1`, `affects_routing = true` (incendie, seuil 1) |
| 2 | Ahmed, 14h03 | Signale un incendie à 60 m | Fusion : `report_count = 2`, centroïde recalculé |
| 3 | Léa, 14h05 | Signale un incendie à 90 m | Fusion : `report_count = 3`, géométrie affinée |
| 4 | Système | — | **Un seul objet** sur la carte, confiance 3, position affinée |
| 5 | Système | — | `expires_at` repoussé (prolongation §4.7c) |

**Comportement V4.0 pour comparaison : 3 alertes distinctes, 3 cercles, confiance diluée à 1 chacune, 3 zones envoyées au routage.**

## UC-11 — Résolution communautaire

| # | Acteur | Action | Système |
|---|---|---|---|
| 1 | — | Accident actif depuis 25 min, TTL 45 min | — |
| 2 | Utilisateur X | Passe, voie dégagée, tape « C'est terminé » | `clear_count = 1` |
| 3 | Utilisateur Y | Idem | `clear_count = 2` |
| 4 | Système | — | Seuil atteint → `status = 'resolved'` |
| 5 | Système | — | Retrait de la carte, `affects_routing = false` |
| 6 | Système | — | Push aux utilisateurs ayant contourné : « ✅ Voie dégagée » |

**Sans ce mécanisme, l'accident continuerait à dérouter des utilisateurs pendant 20 minutes supplémentaires.**

---

# 13. MESURE DU SUCCÈS

➕ **AJOUTE**

La table `route_incident_hits` (§7.4) doit être instrumentée **dès le premier jour**. Sans ces chiffres, l'arbitrage sur l'avenir du module se fera à l'opinion.

## 13.1 Indicateurs de viabilité

| Indicateur | Calcul | Seuil d'alerte |
|---|---|---|
| **Taux de rencontre** | trajets avec ≥ 1 HIT / total trajets | **< 5 % → la feature ne sert à rien.** Retour au problème de densité du module communautaire. |
| **Taux de contournement** | `user_action = 'avoided'` / HITs proposés | < 20 % → la valeur perçue est faible ou le wording est mauvais |
| **Taux d'échec** | `user_action = 'no_alternative'` / tentatives | > 15 % → géométries trop larges, revoir les buffers du §4.9 |
| **Contournements par type** | groupé par `incidents.type` | Pilote l'ajustement de la table §4.9 |
| **Coût par utilisateur actif** | appels HERE / MAU | Pilote l'arbitrage HERE vs Valhalla |

## 13.2 Indicateurs de qualité de la donnée

| Indicateur | Calcul | Interprétation |
|---|---|---|
| Taux de fusion | signalements fusionnés / total | Élevé = densité suffisante, clustering utile |
| Confiance moyenne | moyenne de `report_count` | < 1,3 → pas assez de témoins, seuils du §4.9 à baisser |
| Taux de résolution communautaire | `resolved` / (`resolved` + `expired`) | Faible → le bouton « C'est terminé » n'est pas découvert |
| Taux de rejet | `rejected` / total | Élevé → abus ou taxonomie inadaptée |

## 13.3 Conversion

| Indicateur | Usage |
|---|---|
| Vues du paywall depuis le module Trajets | Compare l'efficacité de ce point d'entrée aux autres (§10.3 V4.0) |
| Conversion après épuisement des 3 contournements | Valide ou invalide la grille du §10.2 |

---

# 14. RISQUES ET POINTS À VÉRIFIER

## 14.1 ❓ À vérifier avant tout engagement de développement

Par ordre de priorité — le premier conditionne tous les autres.

| # | Point | Impact si négatif | Effort |
|---|---|---|---|
| **1** | **Tester `avoid[areas]` sur une vraie ville cible**, en comparant disque 1 km et corridor 120 m | Invalide tout le §4.3. C'est la mesure qui transforme ce document en fait établi. | 0,5 j |
| **2** | Tester la piste `danger_buffer_m` réduit pour rester en régime « petite zone » | Détermine les valeurs du §4.9 | 0,5 j |
| **3** | Tarification HERE officielle + volume projeté (MAU × trajets/j × 1,15) | **Seul chiffre pouvant renverser le choix de HERE** | 0,5 j |
| **4** | Décodeur Flexible Polyline disponible en PHP et en Dart | Sinon, portage de l'algorithme — court mais à budgéter | 0,5 j |
| **5** | Édition du SDK HERE Flutter (Explore vs Navigate) et licence associée | Change le coût et le périmètre possible | 0,5 j |
| **6** | Mécanisme de snapping point → géométrie de segment chez HERE | Bloque la V2 du corridor (§4.6). La V1 n'en dépend pas. | 1 j |
| **7** | Couverture des POI en Afrique francophone : HERE Search vs Google Places | Qualité de l'autocomplétion sur le marché secondaire (§1.2) | 0,5 j |

## 14.2 Risques produit

| Risque | Probabilité | Impact | Mitigation |
|---|---|---|---|
| **Densité d'alertes insuffisante** — la feature ne se déclenche presque jamais | Élevée au lancement | Élevé | Ouvrir la création d'alertes au tier Gratuit (§10.3a). Suivre le taux de rencontre (§13.1). |
| **Fausses alertes détournant le trafic** | Moyenne | Élevé | Seuils de confiance (§4.9), limite de débit, réputation implicite (§4.8) |
| **Contestation éthique du reroutage** sur signalements visant des personnes | Faible mais grave | Très élevé | Politique du §4.11, validée par écrit |
| **Facture HERE supérieure aux projections** | Moyenne | Moyen | Second appel conditionnel (§5.4 étape 5), cache, abstraction `RoutingProvider` |
| **Évitement perçu comme peu fiable** | Moyenne | Élevé | Double vérification (§5.4 étape 6) + wording contraint (§6.7) |

## 14.3 Risques techniques

| Risque | Mitigation |
|---|---|
| URL trop longue avec plusieurs zones | Prévoir le POST dès la V1 (§5.4) |
| Clustering agressif fusionnant des incidents distincts | Seuils configurables, monitoring du taux de fusion (§13.2) |
| Performance de l'intersection sur trajets longs | Sous-échantillonnage + filtre bbox + plafond de 20 zones |
| Dépendance à un fournisseur unique | Abstraction `RoutingProvider` écrite dès la V1 |

---

# 15. PLAN DE LIVRAISON

## Phase 0 — Validation (prérequis absolu)

- Points 1 à 5 du §14.1
- Validation écrite par le client de la politique éthique (§4.11) et de la grille de monétisation (§10.2)

**Aucune ligne de code de production avant la fin de cette phase.**

## Phase 1 — Refonte du modèle d'alerte (Chantier A)

| Livrable |
|---|
| Migrations `alert_reports` + `incidents` |
| `IncidentGeometryBuilder` — cercle → n-gone, trace GPS → corridor |
| `IncidentClusteringService` + job |
| `RouteAvoidancePolicy` + table de configuration (§4.9) |
| Bouton « C'est terminé » (§4.7a) + `PassiveResolutionJob` (§4.7b) |
| Migration des données existantes le cas échéant |
| Adaptation du formulaire de signalement (§6.6) et de la fiche incident (§6.5) |

> **Cette phase a une valeur autonome.** Même sans le module Trajets, elle corrige les défauts 3, 4, 5 et 6 du §2 et rend la carte utilisable en cas d'événement marquant.

## Phase 2 — Module Trajets, socle

| Livrable |
|---|
| Interface `RoutingProvider` + `HereRoutingProvider` |
| Décodeur Flexible Polyline (PHP + Dart) |
| `IncidentIntersectionService` |
| Endpoints `/routes/preview`, `/avoid`, `/start`, `/end` |
| Migrations `routes` + `route_incident_hits` |
| Écran de recherche (§6.2) + écran d'aperçu (§6.3) |
| Barre de recherche flottante (§6.1) |

## Phase 3 — Contournement et sélection

| Livrable |
|---|
| Bandeau d'avertissement (§6.3) |
| Bottom sheet de sélection (§6.4) |
| Double vérification (§5.4 étape 6) |
| Gestion complète des cas limites (§5.6) |
| Gating monétisation (§10.2) |

## Phase 4 — Surveillance en trajet

| Livrable |
|---|
| `CheckActiveRoutesAgainstIncidentJob` (§8.3) |
| Templates de push (§9) |
| Recalcul depuis la position courante |
| Historique des trajets |

## Phase 5 — Instrumentation et ajustement

| Livrable |
|---|
| Tableau de bord des indicateurs du §13 |
| Ajustement des seuils du §4.9 sur données réelles |
| Ajustement des seuils de clustering (§4.5) |

---

# 16. HORS PÉRIMÈTRE — PISTES IDENTIFIÉES, NON RETENUES POUR CETTE VERSION

Ces éléments sont documentés pour mémoire, sans engagement.

| Piste | Intérêt | Pourquoi pas maintenant |
|---|---|---|
| **Bouton SOS / alerte panique** | Absent du V4.0 alors que c'est un standard du secteur (Life360) et probablement le déclencheur d'achat le plus fort en sécurité familiale | Périmètre distinct, mérite sa propre spécification |
| Guidage turn-by-turn vocal | Complète le module Trajets | §5.1 — périmètre ×3, batterie, concurrence frontale avec Google |
| Partage de trajet avec ETA vers un proche | Relie naturellement les deux modules du produit | V2 — dépend du module Trajets stabilisé |
| Signalement d'une rue entière (corridor dessiné) | Correspond mieux à la réalité que le point | V2 — nécessite le snapping (§14.1 point 6) |
| Directionnalité des incidents (sens de circulation) | Un accident sur la voie nord ne bloque pas la voie sud | V2 — pertinent surtout sur voies rapides |
| Historique de dangerosité par zone | Alertes prédictives plutôt que réactives | Sujet éthique et juridique lourd — à traiter séparément |
| Routage hors ligne | Aligné sur « fonctionner en toutes circonstances » (§16 V4.0) | Dépend de la licence SDK HERE (§14.1 point 5) |

---

# 17. ANNEXES

## A. Formule de conversion cercle → polygone

```
Entrée : centre (lat, lng), rayon r en mètres, N sommets (N = 12 par défaut)

Pour k de 0 à N-1 :
    θ     = 2πk / N
    lat_k = lat + (r / 111320) × cos(θ)
    lon_k = lon + (r / (111320 × cos(lat_rad))) × sin(θ)

Sortie : polygon:lat_0,lon_0;lat_1,lon_1;...;lat_{N-1},lon_{N-1}
```

Erreur d'aire avec N = 12 : environ 3,4 % par défaut. Acceptable — et conservatrice, puisqu'elle sous-estime légèrement la zone évitée.

## B. Formule de Haversine

Déjà spécifiée au §11.3.1 du V4.0. Réutilisée telle quelle pour :
- L'intersection trajet × incident (§5.4 étape 3)
- La vérification post-contournement (§5.4 étape 6)
- Le clustering des signalements (§4.5)
- La détection de proximité pour les notifications (§11.4 V4.0)

## C. Exemples de requêtes HERE

**Itinéraire simple avec alternatives**

```bash
curl -gX GET 'https://router.hereapi.com/v8/routes?'\
'origin=48.8566,2.3522&'\
'destination=48.8738,2.2950&'\
'transportMode=car&'\
'return=polyline,summary,routeLabels&'\
'alternatives=2&'\
'lang=fr-fr&'\
'apiKey=YOUR_API_KEY'
```

**Avec évitement d'un polygone**

```bash
curl -gX GET 'https://router.hereapi.com/v8/routes?'\
'origin=48.8566,2.3522&'\
'destination=48.8738,2.2950&'\
'transportMode=car&'\
'return=polyline,summary,routeLabels&'\
'alternatives=2&'\
'avoid[areas]=polygon:48.8701,2.3312;48.8698,2.3340;48.8685,2.3335&'\
'apiKey=YOUR_API_KEY'
```

**Formes multiples combinées**

```
avoid[areas]=corridor:48.8698,2.3325;48.8703,2.3341;r=20
             |polygon:48.8750,2.3400;48.8760,2.3420;48.8745,2.3430
             |bbox:2.3300,48.8650,2.3350,48.8680
```

**Avec exception** — retire une sous-zone de la zone évitée

```
avoid[areas]=polygon:...!exception=corridor:48.8700,2.3330;48.8705,2.3335;r=15
```

## D. Glossaire

| Terme | Définition |
|---|---|
| **Signalement** (`report`) | Ce qu'un utilisateur envoie. Donnée brute, non publiée telle quelle. |
| **Incident** | Objet publié, affiché et routé. Agrège 1 à N signalements. |
| **Corridor** | Polyligne + rayon. Modélise un danger situé sur une voie. |
| **Buffer de danger** | Largeur utilisée pour l'exclusion au routage. À distinguer du rayon de notification. |
| **Rayon de notification** | Distance de diffusion du push. Large. |
| **Rayon d'affichage** | Rayon du halo dessiné sur la carte. Exprime l'incertitude. |
| **Confiance** | Nombre de signalements indépendants d'un incident. Conditionne `affects_routing`. |
| **HIT** | Rencontre détectée entre un trajet et un incident. |
| **Flexible Polyline** | Format d'encodage de géométrie propre à HERE. |
| **Régime petit / grand** | Deux algorithmes d'évitement HERE, avec des garanties de précision différentes. |
| **`violatedBlockedRoad`** | Code de notice HERE, sévérité `critical`, indiquant qu'une zone à éviter a été traversée. |

---

# 18. SOURCES

## Documentation technique

- HERE — [How to avoid areas in routes](https://docs.here.com/routing/docs/routing-v8-avoid-area) — formats `bbox` / `polygon` / `corridor`, exceptions, régimes petite vs grande zone, `violatedBlockedRoad`, requête POST
- HERE — [How to get alternative routes](https://docs.here.com/routing/docs/routing-v8-get-alternative-routes) — paramètres `alternatives` et `routeLabels`
- HERE — [Get started with Routing API v8](https://docs.here.com/routing/docs/routing-v8-get-started) — endpoint, `return`, `transportMode`
- HERE — [Flexible Polyline](https://github.com/heremaps/flexible-polyline) — format d'encodage, implémentations de référence
- HERE — [SDK Flutter, application de référence](https://github.com/heremaps/here-sdk-ref-app-flutter) et [exemples](https://docs.here.com/here-sdk/docs/flutter-examples)
- Google — [Specify route features to avoid](https://developers.google.com/maps/documentation/routes/route-modifiers) — limites de `avoidTolls` / `avoidHighways` / `avoidFerries` / `avoidIndoor`
- Mapbox — [Directions API](https://docs.mapbox.com/api/navigation/directions/) — `exclude=point()` en BETA, 50 points max, comportement « best-effort »
- Valhalla — [API Overview](https://valhalla.github.io/valhalla/api/) — `exclude_polygons`, `exclude_locations`
- Stadia Maps — [Getting the best routes with Valhalla](https://docs.stadiamaps.com/guides/getting-the-best-routes-with-valhalla-turn-by-turn-directions-apis/) · [Pricing](https://stadiamaps.com/pricing/) · [Service Limits](https://docs.stadiamaps.com/limits/)

## Sources tierces — à confirmer auprès du fournisseur

- Tarification HERE : [Placematic](https://placematic.com/here-location-services/here-pricing/) · [Local Eyes](https://local-eyes.nl/here-maps-api-costs-in-2024/) — **chiffres non officiels, cf. §14.1 point 3**

## Document source

- *AlertContacts — Cahier des Charges V4.0*, juin 2026 — sections référencées : §1.1, §1.2, §5.1, §5.2, §6.1, §6.3, §7.1, §7.2, §7.3, §9.1, §10.1, §10.3, §11.2, §11.3.1, §11.4, §12, §13.5, §14.1, §14.2, §16

---

*Fin de l'addendum V4.1*
