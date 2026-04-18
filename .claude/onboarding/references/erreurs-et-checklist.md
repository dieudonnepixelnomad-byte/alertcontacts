# Erreurs Classiques, Checklist et Plan 30 Jours

## Les 10 erreurs à éviter absolument

### ❌ Erreur #1 — Le mur d'inscription

Demander une inscription complète avant de montrer quoi que ce soit.
**Solution** : Montrer la valeur d'abord. Proposer l'inscription quand l'utilisateur a quelque chose à perdre.

### ❌ Erreur #2 — Le tutoriel imposé de 10 écrans

Un onboarding de 10 écrans de texte avec flèches partout → perte garantie de 60% des utilisateurs.
**La règle des 3** : Si l'onboarding nécessite plus de 3 étapes pour être expliqué, c'est l'**interface** qui est le problème, pas l'utilisateur.

### ❌ Erreur #3 — Demander toutes les permissions dès le début

"Cette app veut accéder à vos contacts, localisation, photos et microphone" → refus systématique.
**Solution** : Permissions demandées au moment contextuel précis, avec explication du bénéfice avant.

### ❌ Erreur #4 — Une app vide sans données d'exemple

Montrer une app vide → l'utilisateur doit imaginer comment elle pourrait être utile.
**Solution** : Pré-remplir avec des données d'exemple pertinentes et réalistes.

### ❌ Erreur #5 — Ignorer les utilisateurs qui reviennent

Un utilisateur qui reprend l'onboarding 3 jours plus tard ne doit pas repartir de zéro.
**Solution** : Reconnaître la progression, aider à reprendre là où il s'était arrêté.

### ❌ Erreur #6 — Ne pas célébrer les premiers succès

Premier succès → passage silencieux à l'écran suivant = magie gâchée.
**Solution** : Animer, célébrer, féliciter. Un pic émotionnel positif ancre le souvenir positif de l'app.

### ❌ Erreur #7 — Un onboarding identique sur iOS et Android

Les conventions d'interaction sont différentes sur les deux plateformes.
**Solution** : Adapter l'onboarding aux conventions de chaque OS.

### ❌ Erreur #8 — Ne jamais tester son propre onboarding

Observer quelqu'un ouvrir l'app pour la première fois sans rien lui expliquer. Observer ses hésitations, erreurs, questions.
C'est l'exercice le plus précieux possible — et la plupart des équipes ne le font jamais.

### ❌ Erreur #9 — Optimiser trop tôt

Vouloir A/B tester avant d'avoir suffisamment de données.
**Solution** : Attendre au moins 500 utilisateurs ayant traversé le flow avant de commencer à tester.

### ❌ Erreur #10 — Considérer l'onboarding comme un projet fini

L'onboarding n'est **jamais "terminé"**. Les comportements des utilisateurs évoluent, l'app évolue, l'onboarding doit évoluer avec.

---

## La checklist finale avant lancement

Avant de lancer ou relancer l'onboarding, valider ces points :

- [ ] Mon premier écran montre la valeur en moins de 5 secondes
- [ ] Je propose une façon d'utiliser l'app sans créer de compte (ou je diffère l'inscription)
- [ ] J'ai un social login comme option principale
- [ ] Mon onboarding conduit vers un Quick Win en moins de 3 minutes
- [ ] Je ne demande aucune permission sans explication contextuelle
- [ ] J'ai identifié et documenté mon Aha Moment avec des données
- [ ] Je mesure le taux de complétion et le drop rate à chaque étape
- [ ] J'ai observé au moins 5 utilisateurs en test qualitatif
- [ ] Je célèbre le premier succès de l'utilisateur
- [ ] J'ai planifié un prochain A/B test

---

## Plan d'action 30 jours

### Vue d'ensemble

| Période   | Focus              |
| --------- | ------------------ |
| J1 - J7   | Audit & Diagnostic |
| J8 - J14  | Design & Décisions |
| J15 - J21 | Implémentation     |
| J22 - J30 | Test & Mesure      |

---

### Semaine 1 — Audit & Diagnostic

- **J1** : Cartographier l'onboarding actuel (chaque écran, chaque action requise)
- **J2** : Mesurer les métriques de base (taux de complétion, rétention J1/J7/J30)
- **J3-4** : Observer 5 utilisateurs en test qualitatif
- **J5** : Identifier le Aha Moment avec les données de rétention
- **J6-7** : Lister les 3 plus grosses frictions

### Semaine 2 — Design & Décisions

- **J8-9** : Définir la stratégie d'onboarding (quel pattern ? inscription différée ?)
- **J10-11** : Redesigner le premier écran. Tester 3 variantes.
- **J12** : Simplifier le flow d'inscription (social login, max 3 champs)
- **J13-14** : Concevoir le Quick Win (premier succès en moins de 2 minutes)

### Semaine 3 — Implémentation

- **J15-18** : Implémenter les 3 changements les plus impactants
- **J19** : Configurer le tracking précis sur chaque étape
- **J20-21** : Nouveau test qualitatif avec la nouvelle version

### Semaine 4 — Test & Mesure

- **J22-25** : Lancer un premier A/B test sur l'élément le plus impactant
- **J26-28** : Analyser les premières données (rétention J1, J7)
- **J29-30** : Documenter les apprentissages et planifier la suite

---

## Social Login — guide rapide

Proposer "Continuer avec Google" ou "Continuer avec Apple" :

- Réduit le temps d'inscription de **80%**
- Élimine la friction de création de mot de passe

**Règle d'or** : Le social login doit être l'option la **plus visible**, pas une option parmi d'autres.

**Inscription différée** : Ne pas demander de compte pour accéder aux fonctionnalités de base. Permettre une utilisation partielle, puis proposer l'inscription au moment de friction naturelle (sauvegarder, partager, synchroniser).
