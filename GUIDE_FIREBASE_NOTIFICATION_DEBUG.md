# 🔥 Guide de Diagnostic - Notifications Firebase

## 🚨 Problème Identifié

**Symptômes :**
- ✅ Alerte vocale et vibration fonctionnent (côté mobile)
- ❌ Notification push ne s'affiche pas
- ❌ Erreur backend : `cURL error 28: Connection timed out after 10001 milliseconds for https://oauth2.googleapis.com/token`

## 🔍 Diagnostic

### 1. **Problème de Connectivité OAuth Firebase**

Le backend Laravel n'arrive pas à obtenir un token d'accès Firebase à cause d'un timeout de connexion vers `oauth2.googleapis.com`.

### 2. **Logs d'Erreur**
```
[2025-10-11 21:12:46] local.ERROR: Exception lors de l'obtention du token d'accès Firebase 
{"message":"cURL error 28: Connection timed out after 10001 milliseconds"}
```

## 🛠️ Solutions

### **Solution 1 : Augmenter le Timeout cURL**

Dans `FirebaseNotificationService.php`, ligne ~368 :

```php
// Avant (timeout par défaut)
$response = Http::post('https://oauth2.googleapis.com/token', [
    'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
    'assertion' => $jwt,
]);

// Après (timeout augmenté)
$response = Http::timeout(30) // 30 secondes au lieu de 10
    ->retry(3, 1000) // 3 tentatives avec 1s d'attente
    ->post('https://oauth2.googleapis.com/token', [
        'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion' => $jwt,
    ]);
```

### **Solution 2 : Vérifier la Connectivité Réseau**

Tester la connectivité depuis le serveur backend :

```bash
# Test de connectivité
curl -I https://oauth2.googleapis.com/token

# Test avec timeout
curl --max-time 30 -I https://oauth2.googleapis.com/token
```

### **Solution 3 : Configuration Proxy/Firewall**

Si le serveur est derrière un proxy ou firewall :

```php
// Dans FirebaseNotificationService.php
$response = Http::withOptions([
    'proxy' => 'http://proxy.example.com:8080', // Si proxy nécessaire
    'verify' => false, // Uniquement en dev si problème SSL
])->timeout(30)->post('https://oauth2.googleapis.com/token', $data);
```

### **Solution 4 : Mise en Cache du Token**

Implémenter un cache pour éviter les appels répétés :

```php
// Dans FirebaseNotificationService.php
private function getAccessToken(): string
{
    $cacheKey = 'firebase_access_token';
    
    // Vérifier le cache
    if (Cache::has($cacheKey)) {
        return Cache::get($cacheKey);
    }
    
    // Obtenir un nouveau token avec retry
    $token = $this->fetchNewAccessToken();
    
    // Mettre en cache pour 50 minutes (expire dans 1h)
    Cache::put($cacheKey, $token, now()->addMinutes(50));
    
    return $token;
}
```

### **Solution 5 : Logs Détaillés**

Ajouter des logs pour diagnostiquer :

```php
// Dans getAccessToken()
Log::info('Tentative d\'obtention du token Firebase', [
    'timestamp' => now(),
    'jwt_length' => strlen($jwt),
]);

try {
    $response = Http::timeout(30)->post('https://oauth2.googleapis.com/token', $data);
    Log::info('Token Firebase obtenu avec succès');
} catch (\Exception $e) {
    Log::error('Échec obtention token Firebase', [
        'error' => $e->getMessage(),
        'code' => $e->getCode(),
        'url' => 'https://oauth2.googleapis.com/token',
    ]);
    throw $e;
}
```

## 🧪 Tests

### **1. Test depuis l'App Mobile**

1. Ouvrir l'application
2. Aller dans **Paramètres → Debug FCM**
3. Cliquer sur "Récupérer Token FCM"
4. Copier le token
5. Tester l'envoi depuis le backend

### **2. Test Backend Direct**

```bash
# Test de connectivité
curl -v https://oauth2.googleapis.com/token

# Test avec les mêmes paramètres que Laravel
curl -X POST https://oauth2.googleapis.com/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=YOUR_JWT"
```

### **3. Test de Notification Manuelle**

Utiliser l'API Firebase directement :

```bash
curl -X POST https://fcm.googleapis.com/v1/projects/alertcontacts/messages:send \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "DEVICE_FCM_TOKEN",
      "notification": {
        "title": "Test",
        "body": "Test notification"
      }
    }
  }'
```

## 📋 Checklist de Résolution

- [ ] Augmenter le timeout cURL à 30 secondes
- [ ] Ajouter un système de retry (3 tentatives)
- [ ] Tester la connectivité réseau du serveur
- [ ] Vérifier les credentials Firebase
- [ ] Implémenter la mise en cache du token
- [ ] Ajouter des logs détaillés
- [ ] Tester depuis la page debug mobile
- [ ] Vérifier les paramètres proxy/firewall

## 🎯 Résultat Attendu

Après application des solutions :
- ✅ Token Firebase obtenu sans timeout
- ✅ Notifications push reçues sur mobile
- ✅ Logs sans erreur de connexion
- ✅ Performance améliorée (cache)

---

**Note :** Le problème est côté backend (timeout réseau), pas côté mobile. L'infrastructure FCM mobile fonctionne correctement.