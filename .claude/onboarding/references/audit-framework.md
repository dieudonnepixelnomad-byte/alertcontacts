# Audit d'Onboarding : Framework Complet

## Le tunnel d'onboarding — taux moyens de référence

| Étape                    | Taux moyen | Levier principal                              |
| ------------------------ | ---------- | --------------------------------------------- |
| Premier lancement        | 100%       | Première impression en 3 secondes             |
| Engagement 1er écran     | ~85%       | Un bon écran peut passer de 60% à 95%         |
| Commencent l'inscription | ~60%       | Montrer la valeur AVANT = +20-30 pts          |
| Complètent l'inscription | ~40%       | Chaque champ supplémentaire = -5%             |
| Atteignent le Aha Moment | ~25%       | C'est ici que se joue la rétention long terme |
| Reviennent J7            | ~15%       | Un bon onboarding peut tripler ce chiffre     |

---

## La carte de friction (Étape 1 de l'audit)

Pour chaque écran du flow, répondre :

- Combien de temps l'utilisateur passe-t-il sur cet écran ?
- Quel % abandonne à cette étape ?
- Combien d'actions sont requises ?
- Y a-t-il des décisions à prendre ?

### Score de friction par étape (1 = faible, 5 = élevé)

- Nombre d'actions requises (1 action = 1, 5+ actions = 5)
- Complexité cognitive (évident = 1, réflexion nécessaire = 5)
- Quantité d'info demandée (aucune = 1, données sensibles = 5)
- Attente requise (instantané = 1, 30+ secondes = 5)

**Priorisation** : classer par `score friction × taux d'abandon`. Les scores les plus élevés = priorités immédiates.

**Test immédiat** : Ouvrir l'app en tant que nouvel utilisateur et compter les secondes entre le premier lancement et le premier truc utile. Si > 30 secondes → problème critique.

---

## Les 6 types de friction

| Type              | Exemples                                       | Impact     | Solution                                  |
| ----------------- | ---------------------------------------------- | ---------- | ----------------------------------------- |
| **Cognitive**     | Trop d'options, jargon, instructions complexes | Élevé      | Simplifier, guider, décider à la place    |
| **Formulaire**    | Trop de champs, captcha, confirmation email    | Très élevé | Réduire champs, social login, différer    |
| **Permission**    | Demander caméra/micro sans explication         | Élevé      | Expliquer le bénéfice avant la demande    |
| **Performance**   | Chargements lents, bugs, crashes               | Critique   | Optimiser, loading states engageants      |
| **Apprentissage** | Interface non intuitive, gestes non évidents   | Moyen      | Tests utilisateurs, onboarding progressif |
| **Temporelle**    | Setup trop long avant de voir la valeur        | Élevé      | Quick wins, progression visible           |

---

## Cas pratiques de référence

### Duolingo — Gamification au service de la rétention

**Chiffres** : 500M utilisateurs, 40% rétention J30 (vs 15% industrie)

Ce qui fonctionne :

1. Question d'objectif émotionnel en PREMIER ("Pourquoi apprenez-vous ?") → projection dans le résultat avant de commencer
2. Niveau de départ immédiat → évite la frustration du débutant imposé
3. Première leçon DANS l'onboarding → Aha Moment dans les 3 premières minutes
4. Inscription DIFFÉRÉE → commence à apprendre sans compte, inscription après la 1ère leçon
5. Streak introduit tôt → mécanisme de rétention par pression positive

### Headspace — Vendre un bénéfice invisible

**Défi** : vendre la méditation à des sceptiques

Ce qui fonctionne :

- Commencer par le **problème** (stress, anxiété, sommeil), PAS par la solution (méditation)
- Durée très courte pour le premier essai (3 min) → lève la barrière du temps
- La voix apaisante dans l'onboarding EST une démonstration en temps réel du produit
- Animations douces = expérience émotionnelle avant même de méditer

### Notion — Gérer la complexité sans overwhelm

**Défi** : une des apps les plus complexes du monde

Ce qui fonctionne :

- Segmentation dès le départ (personnel / équipe / éducation) → 3 onboardings différents
- Templates → l'utilisateur ne part jamais d'une page blanche
- Progressive disclosure → features avancées cachées jusqu'à ce que l'utilisateur soit prêt
- Tooltips contextuels → révélés uniquement au survol d'éléments nouveaux

### Airbnb — Confiance et conversion

**Défi** : vendre quelque chose intrinsèquement risqué (dormir chez des étrangers)

Mécanismes de confiance :

- Photos de qualité exceptionnelle dès le premier écran
- Avis et notes visibles AVANT de créer un compte
- Badges de vérification clairement affichés
- Politique de remboursement mentionnée tôt
- Prix transparents dès la recherche → pas de surprise en fin de parcours

### Canva — Démocratiser le design

**Défi** : non-designers qui veulent des visuels professionnels

Ce qui fonctionne :

- Premier écran : choisir un TYPE de création → ancrage immédiat dans l'objectif
- Templates → l'utilisateur n'a qu'à personnaliser, pas créer
- Premier design terminable en < 2 min → Quick Win parfait
- Partage intégré → gratification sociale immédiate

### Slack — L'onboarding en équipe

**Défi unique** : l'app n'a de valeur que si des collègues l'utilisent aussi

Ce qui fonctionne :

- Invitation collègues intégrée TRÈS TÔT → c'est une étape, pas une option
- Slackbot guide les premiers pas automatiquement
- Channels suggérées (#général, #aléatoire) → structure immédiate
- Premier message envoyé + réactions reçues = Aha Moment social
- Onboarding différent pour admins vs membres → segmentation par rôle

---

## Framework JTBD pour l'audit

Avant d'auditer, répondre à ces questions sur les utilisateurs :

1. Quel job précis essaient-ils d'accomplir ?
2. Quelle solution utilisaient-ils avant votre app ?
3. Qu'est-ce qui les a poussés à chercher une alternative ?
4. Quel est leur critère de succès ?

**Exemple Duolingo** : L'utilisateur ne veut pas "apprendre une langue". Il veut commander un repas en espagnol lors de son voyage à Barcelone dans 3 mois. L'onboarding doit être construit autour de cet objectif concret et émotionnellement chargé.
