# Patterns d'Onboarding & Conception

## Les 4 objectifs fondamentaux de l'onboarding

1. **Démontrer la valeur avant de demander quoi que ce soit** — Show, don't tell
2. **Réduire la friction au minimum absolu** — Éliminer chaque écran inutile
3. **Conduire vers le Aha Moment le plus vite possible** — Tout optimiser pour ça
4. **Créer une habitude d'usage** — L'objectif final : un utilisateur qui revient

**Erreur critique** : L'onboarding ne se termine PAS quand l'utilisateur a créé son compte. Il se termine quand l'utilisateur a **expérimenté** la valeur principale de l'app.

---

## Les 3 types d'onboarding

| Type            | Description                               | Avantages                        | Limites                         | Idéal pour                     |
| --------------- | ----------------------------------------- | -------------------------------- | ------------------------------- | ------------------------------ |
| **Bénéfice**    | Présente les bénéfices (pas les features) | Crée la motivation initiale      | Peut sembler générique          | Apps grand public, B2C         |
| **Fonctionnel** | Explique comment utiliser les features    | Réduit la courbe d'apprentissage | Peut être ennuyeux              | Apps complexes, outils pro     |
| **Progressif**  | Révèle les features au fur et à mesure    | Pas d'écrasement d'info, naturel | Peut frustrer les users avancés | Apps avec beaucoup de features |

---

## Les 5 patterns qui fonctionnent

### Pattern #1 — Valeur First, Inscription Ensuite

**Le plus contre-intuitif et le plus efficace.**

Flow :

1. Utilisateur ouvre l'app
2. Voit immédiatement une version fonctionnelle (ou démo) de l'expérience principale
3. Après avoir expérimenté la valeur → proposition de créer un compte pour "sauvegarder" ou "aller plus loin"

✅ Ce qui fonctionne :

- Utilisation des fonctions de base sans compte
- Inscription proposée au moment de motivation maximale
- Social login pour réduire la friction
- Expliquer pourquoi le compte est nécessaire

❌ Ce qui ne fonctionne pas :

- Bloquer l'app derrière un wall d'inscription
- Demander un email avant de montrer l'app
- Forcer une vérification d'email dès le départ

**Exemple Airbnb** : Toutes les annonces, photos, prix, avis consultables sans compte. L'inscription n'est requise qu'à la réservation — quand la motivation est au maximum.

---

### Pattern #2 — Le Questionnaire de Personnalisation

Poser **3 à 5 questions** pour personnaliser l'expérience. La clé : ces questions doivent sembler bénéficier à l'utilisateur, pas à vous.

Règles d'or :

- Maximum 5 questions (au-delà, le taux d'abandon explose)
- Chaque question doit être clairement liée à une meilleure expérience
- Utiliser des visuels plutôt que du texte pur quand possible
- Montrer une barre de progression
- Commencer par la question la plus engageante (souvent : l'objectif)

**Exemple Duolingo** : "Pourquoi apprenez-vous une langue ?" (voyage / culture / cerveau / famille / travail / autre) → engagement émotionnel immédiat.

---

### Pattern #3 — L'Onboarding Progressif (Progressive Disclosure)

Révéler les features au fur et à mesure que l'utilisateur en a besoin.

3 niveaux :

- **Niveau 1 — Core** : à découvrir dans les premières minutes, permettent d'atteindre le Aha Moment. **Pas plus de 3.**
- **Niveau 2 — Valeur ajoutée** : révélées dans les premiers jours, quand une habitude basique est établie
- **Niveau 3 — Avancées** : pour les power users, après plusieurs semaines d'usage

---

### Pattern #4 — Le Quick Win

Faire expérimenter un succès rapide et concret dans les premières minutes.

Critères d'un Quick Win parfait :

- Réalisable en **moins de 2 minutes**
- Génère un résultat visible et satisfaisant
- Directement lié à la valeur principale de l'app

| Application  | Quick Win                                            | Temps   |
| ------------ | ---------------------------------------------------- | ------- |
| Duolingo     | Compléter une première leçon de 5 exercices          | 3-4 min |
| Canva        | Créer et télécharger un post Instagram avec template | 2-3 min |
| Headspace    | Compléter une méditation guidée de 3 min             | 3 min   |
| Notion       | Créer sa première page avec un template              | 1-2 min |
| MyFitnessPal | Logger son premier repas et voir le bilan calorique  | 2 min   |

---

### Pattern #5 — L'Onboarding Contextuel (Tooltips & Coach Marks)

Expliquer les fonctionnalités au moment précis où l'utilisateur les rencontre.

✅ Quand utiliser les tooltips :

- Fonctionnalité non auto-explicative
- Geste inhabituel (swipe long, 3D touch, etc.)
- Première fois sur un écran clé
- Nouvelle fonctionnalité ajoutée pour les anciens utilisateurs

❌ Quand éviter :

- Éléments UI standards et évidents
- Séquence de plus de 3 tooltips d'affilée
- Sur chaque écran de l'application
- Quand ils bloquent le contenu que l'utilisateur essaie de voir

---

## Les 5 techniques de personnalisation légère

1. **Questions au début** : 3-5 questions simples → l'utilisateur perçoit que l'app est faite pour lui
2. **Templates par persona** : configurations pré-remplies adaptées au profil déclaré
3. **Exemples contextuels** : adapter les données d'exemple au contexte (dev → projets dev, marketer → projets marketing)
4. **Conseils personnalisés** : après les premières actions, proposer des conseils basés sur ce que l'utilisateur a fait (ou n'a pas fait)
5. **Notifications personnalisées** : premiers pushs liés à ce que l'utilisateur a déjà fait → "Vous avez commencé X, voici comment aller plus loin"

**Benchmark** : Les onboardings personnalisés ont des taux de complétion **50% supérieurs** aux onboardings génériques.

---

## Segmentation par profil

4 axes de segmentation :

- **Par objectif** : que veut accomplir l'utilisateur ? (question directe)
- **Par niveau d'expertise** : débutant / intermédiaire / expert ?
- **Par contexte d'usage** : personnel / professionnel / éducatif ?
- **Par persona** : démographie, industrie, rôle

---

## Optimiser les permissions système

⚠️ Une demande refusée à l'OS **ne peut pas être re-demandée**. C'est irréversible.

4 règles absolues :

1. **Jamais au premier lancement** — attendre que l'utilisateur ait expérimenté la valeur
2. **Toujours contextuel** — demander la permission au moment précis où c'est nécessaire
3. **Pré-demande systématique** — expliquer le bénéfice avant la dialog système (+30-50% d'acceptation)
4. **Offrir une alternative** — si l'utilisateur refuse, l'app reste fonctionnelle
