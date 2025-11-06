#!/bin/bash

# Script pour naviguer vers la page de test FCM
echo "🧪 Navigation vers la page de test FCM..."

# Ouvrir l'application (si elle n'est pas déjà ouverte)
adb shell am start -n com.alertcontacts.alertcontacts/com.alertcontacts.alertcontacts.MainActivity

# Attendre un peu
sleep 2

# Simuler une navigation vers la page de test FCM
# Note: Ceci nécessiterait une deep link ou une navigation programmatique
echo "✅ Application ouverte. Naviguez manuellement vers /debug/fcm-test dans l'app"
echo "Ou utilisez les boutons de test dans l'interface"