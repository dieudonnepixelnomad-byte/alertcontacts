# Guide de Test Manuel pour la Production - AlertContact

## Vue d'ensemble

Ce guide détaille les procédures de test manuel à effectuer avant et après le déploiement en production pour s'assurer du bon fonctionnement de l'application AlertContact.

## 🔧 Prérequis

### Environnement de test
- Appareil physique (Android/iOS) avec GPS activé
- Connexion internet stable
- Permissions de localisation accordées
- Notifications activées
- Version de production de l'app installée

### Outils nécessaires
- Logs de debug activés (via Paramètres > Logs de Debug)
- Accès aux métriques de performance
- Compte de test configuré

## 📋 Procédures de Test

### 1. Test d'Authentification

#### 1.1 Connexion utilisateur
- [ ] Ouvrir l'application
- [ ] Vérifier l'affichage du splash screen
- [ ] Tester la connexion avec email/mot de passe
- [ ] Tester la connexion avec Google (si disponible)
- [ ] Vérifier la redirection vers l'écran principal

**Critères de succès :**
- Connexion réussie en moins de 5 secondes
- Aucune erreur dans les logs
- Interface utilisateur responsive

#### 1.2 Gestion des erreurs
- [ ] Tester avec des identifiants incorrects
- [ ] Tester sans connexion internet
- [ ] Vérifier les messages d'erreur appropriés

### 2. Test de Géolocalisation

#### 2.1 Permissions et initialisation
- [ ] Vérifier la demande de permission de localisation
- [ ] Tester le refus puis l'acceptation des permissions
- [ ] Vérifier l'initialisation du service de géolocalisation

**Logs à vérifier :**
```
[GEOLOCATION] Service de géolocalisation initialisé avec succès
[GEOFENCING] Service de géofencing initialisé avec succès
```

#### 2.2 Surveillance en temps réel
- [ ] Activer la surveillance des zones
- [ ] Vérifier la mise à jour de position toutes les 10 mètres
- [ ] Contrôler la précision GPS (< 10 mètres)

**Logs à surveiller :**
```
[GEOLOCATION] Position mise à jour: lat, lng
[GEOFENCING] Surveillance géofencing active avec X zones
```

### 3. Test des Zones de Danger

#### 3.1 Détection de proximité
- [ ] Créer une zone de danger de test
- [ ] Se déplacer vers la zone (simulation ou déplacement réel)
- [ ] Vérifier la détection à 100m (alerte normale)
- [ ] Vérifier la détection à 50m (alerte critique)

**Critères de succès :**
- Alerte normale déclenchée à ≤ 100m
- Alerte critique déclenchée à ≤ 50m
- Cooldown de 15 minutes respecté

#### 3.2 Notifications
- [ ] Vérifier l'affichage de la notification push
- [ ] Tester la vibration (si activée)
- [ ] Vérifier le contenu du message
- [ ] Tester en mode discret

**Logs attendus :**
```
[GEOFENCING] Alerte critique déclenchée
[NOTIFICATIONS] Notification envoyée avec succès
```

### 4. Test des Zones de Sécurité

#### 4.1 Configuration des zones
- [ ] Créer une zone de sécurité
- [ ] Ajouter un proche à la zone
- [ ] Configurer les horaires actifs
- [ ] Tester l'entrée/sortie de zone

#### 4.2 Notifications aux proches
- [ ] Vérifier l'envoi de notification à l'entrée
- [ ] Vérifier l'envoi de notification à la sortie
- [ ] Tester les horaires de désactivation

### 5. Test de Performance

#### 5.1 Consommation batterie
- [ ] Surveiller la consommation sur 1 heure
- [ ] Vérifier l'optimisation en arrière-plan
- [ ] Tester avec écran éteint

**Critères acceptables :**
- Consommation < 5% par heure en surveillance active
- Pas de drain excessif en arrière-plan

#### 5.2 Utilisation mémoire
- [ ] Surveiller l'utilisation RAM
- [ ] Vérifier l'absence de fuites mémoire
- [ ] Tester la stabilité sur 24h

#### 5.3 Réseau
- [ ] Tester avec connexion 4G/5G
- [ ] Tester avec WiFi
- [ ] Vérifier la gestion des déconnexions

### 6. Test des Notifications

#### 6.1 Configuration
- [ ] Tester tous les types de notifications
- [ ] Vérifier les paramètres de volume/vibration
- [ ] Tester le mode heures calmes

#### 6.2 Fiabilité
- [ ] Vérifier la réception à 100%
- [ ] Tester les notifications critiques
- [ ] Vérifier les cooldowns

### 7. Test de Stabilité

#### 7.1 Test de stress
- [ ] Laisser l'app tourner 24h en continu
- [ ] Simuler de nombreux changements de position
- [ ] Tester avec de multiples zones actives

#### 7.2 Récupération d'erreurs
- [ ] Tester la récupération après crash
- [ ] Vérifier la reprise après redémarrage
- [ ] Tester la gestion des erreurs réseau

## 🚨 Procédures d'Urgence

### En cas de problème critique

1. **Arrêt immédiat de la surveillance**
   ```
   Paramètres > État des services > Arrêter tous les services
   ```

2. **Collecte des logs**
   ```
   Paramètres > Logs de Debug > Exporter les logs
   ```

3. **Signalement**
   - Capturer les logs d'erreur
   - Noter les conditions de reproduction
   - Documenter l'impact utilisateur

## 📊 Métriques de Succès

### Performances minimales requises
- **Temps de démarrage :** < 3 secondes
- **Précision GPS :** < 10 mètres
- **Délai de notification :** < 5 secondes
- **Consommation batterie :** < 5%/heure
- **Taux de succès notifications :** > 95%

### Indicateurs de qualité
- **Stabilité :** 0 crash sur 24h
- **Fiabilité :** 100% des alertes déclenchées
- **Performance :** Temps de réponse < 1 seconde

## 🔍 Analyse des Logs

### Logs critiques à surveiller

#### Géolocalisation
```
[GEOLOCATION] Position mise à jour
[GEOFENCING] Vérification proximité zone
[GEOFENCING] Alerte déclenchée
```

#### Notifications
```
[NOTIFICATIONS] Service initialisé
[NOTIFICATIONS] Notification envoyée
[ALERT] Alerte critique/normale déclenchée
```

#### Erreurs
```
[ERROR] Toute ligne contenant ERROR
[WARNING] Alertes de performance
```

### Filtrage des logs
- Utiliser les filtres par niveau (ERROR, WARNING, INFO)
- Filtrer par tag (GEOLOCATION, GEOFENCING, NOTIFICATIONS)
- Exporter les logs pour analyse approfondie

## 📝 Rapport de Test

### Template de rapport
```
Date: [DATE]
Version: [VERSION]
Testeur: [NOM]
Appareil: [MODÈLE/OS]

Tests réussis: X/Y
Tests échoués: [LISTE]
Problèmes critiques: [DESCRIPTION]
Recommandations: [ACTIONS]

Logs joints: [OUI/NON]
```

### Critères de validation
- [ ] Tous les tests de base passent
- [ ] Aucun problème critique détecté
- [ ] Performance dans les seuils acceptables
- [ ] Logs propres sans erreurs majeures

## 🔄 Tests de Régression

Après chaque mise à jour :
1. Exécuter les tests de base (sections 1-3)
2. Vérifier les nouvelles fonctionnalités
3. Contrôler la non-régression des fonctionnalités existantes
4. Valider les métriques de performance

---

**Note :** Ce guide doit être mis à jour à chaque nouvelle fonctionnalité ou modification majeure de l'application.