# Métriques, Tests A/B et Optimisation

## Les métriques essentielles à tracker

### Métriques du tunnel d'onboarding

- **Taux de complétion de l'onboarding** : % d'utilisateurs qui terminent le flow complet
- **Drop rate par étape** : % d'abandon à chaque écran spécifique
- **Time-to-value** : temps entre le premier lancement et l'atteinte du Aha Moment
- **Time-to-register** : temps entre le premier lancement et la création de compte

### Métriques de rétention (les plus importantes)

- **D1** : % d'utilisateurs qui reviennent le lendemain du téléchargement
- **D7** : % qui reviennent à J7
- **D30** : % qui reviennent à J30
- **DAU/MAU ratio** : Daily Active Users / Monthly Active Users (indicateur d'habitude)

### Benchmarks secteur

| Métrique              | Mauvais | Moyen  | Bon    | Excellent |
| --------------------- | ------- | ------ | ------ | --------- |
| D1                    | < 20%   | 20-30% | 30-40% | > 40%     |
| D7                    | < 10%   | 10-20% | 20-30% | > 30%     |
| D30                   | < 3%    | 3-8%   | 8-15%  | > 15%     |
| Complétion onboarding | < 30%   | 30-50% | 50-65% | > 65%     |

---

## Les outils recommandés

| Outil                  | Force                                   | Limite                    | Prix                   | Idéal pour              |
| ---------------------- | --------------------------------------- | ------------------------- | ---------------------- | ----------------------- |
| **Mixpanel**           | Funnels avancés, segmentation puissante | Courbe d'apprentissage    | Freemium / ~25$/mois   | Apps > 100K MAU         |
| **Amplitude**          | Analyse comportementale profonde        | Complexe à configurer     | Freemium / ~50$/mois   | Équipes data-driven     |
| **Firebase Analytics** | Intégration native mobile               | Moins flexible            | Gratuit                | Petites apps, débutants |
| **PostHog**            | Open source, feature flags intégrés     | Auto-hébergement complexe | Freemium / Open Source | Startups                |
| **UXCam**              | Session recording mobile                | Pas de funnel classique   | ~49$/mois              | Analyse qualitative     |

**Recommandation débutant** : Firebase Analytics pour commencer (gratuit, intégration native), puis Mixpanel ou Amplitude quand le volume justifie l'investissement.

---

## Méthodologie de test A/B

### Étape 1 — Définir une hypothèse claire

Format : "Si nous [changement], alors [métrique] augmentera de [X]%."

Exemple : "Si nous remplaçons le formulaire d'inscription par un social login, alors le taux de complétion augmentera de 15%."

Tester **une seule variable** à la fois.

### Étape 2 — Taille d'échantillon nécessaire

Pour un test statistiquement significatif : **au moins 500 utilisateurs par variation**.
En dessous → résultats non fiables, ne pas en tirer de conclusions.

Ne pas A/B tester avant d'avoir au moins **500 utilisateurs** ayant traversé le flow.

### Étape 3 — Définir les métriques

- **Métrique principale** : celle qui valide ou invalide l'hypothèse
- **Métriques secondaires** : pour détecter les effets de bord non anticipés

### Étape 4 — Lancer et ne pas toucher

Une fois lancé, ne pas modifier le test. Attendre la signification statistique.

### Étape 5 — Analyser les résultats complets

Regarder non seulement la métrique principale, mais aussi l'impact sur la **rétention à J7 et J30**.

⚠️ Une variation qui améliore le taux de complétion mais réduit la rétention est une **fausse bonne idée**.

---

## Tests qualitatifs — indispensables

Les données quantitatives disent **QUOI**. Les tests qualitatifs disent **POURQUOI**.

### User Testing

Faire observer 5 à 8 personnes utiliser l'app pour la première fois. **Ne pas les aider.** En 5 tests, on identifie 85% des problèmes d'utilisabilité.

### Session Recording

Outils : UXCam, FullStory. Chercher les moments de blocage, les tapotements répétés sur des éléments non-cliquables.

### Enquêtes in-app

Poser 1-2 questions après le premier succès. La question la plus utile : **"Qu'est-ce qui vous a presque empêché de continuer ?"**

### Interviews utilisateurs

Parler aux utilisateurs qui ont abandonné dans les premiers jours. Ces conversations valent des mois d'analyses quantitatives.

---

## Séquence de mise en place du tracking

Pour un nouveau projet, dans l'ordre :

1. Installer Firebase Analytics (ou équivalent) dès le départ
2. Tracker chaque écran de l'onboarding comme un événement distinct
3. Créer un funnel de visualisation dès les premiers utilisateurs
4. Identifier l'étape avec le plus fort drop rate
5. Lancer des tests qualitatifs sur cette étape spécifique
6. Une fois +500 utilisateurs → commencer les A/B tests
