# Système de Traduction Multilingue

Ce projet utilise le système de localisation Flutter avec le plugin `intl` pour supporter plusieurs langues.

## Structure des fichiers

```
lib/
├── l10n/                    # Fichiers ARB (Application Resource Bundle)
│   ├── app_fr.arb          # Traductions françaises
│   └── app_en.arb          # Traductions anglaises
├── generated/l10n/         # Classes générées automatiquement
│   └── app_localizations.dart
└── core/utils/
    └── l10n_helper.dart    # Helper pour faciliter l'utilisation
```

## Configuration

### 1. Fichier de configuration (`l10n.yaml`)
```yaml
arb-dir: lib/l10n
template-arb-file: app_fr.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
output-dir: lib/generated/l10n
```

### 2. Configuration dans `pubspec.yaml`
```yaml
dependencies:
  flutter_localizations:
    sdk: flutter

flutter:
  generate: true
```

### 3. Configuration dans `app.dart`
```dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:alertcontacts/generated/l10n/app_localizations.dart';

MaterialApp.router(
  locale: const Locale('fr'), // Langue par défaut
  supportedLocales: const [
    Locale('fr', ''), // Français
    Locale('en', ''), // Anglais
  ],
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  // ...
)
```

## Utilisation

### 1. Utilisation basique avec le helper
```dart
import 'package:alertcontacts/core/utils/l10n_helper.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(context.l10n.welcome);
  }
}
```

### 2. Utilisation directe
```dart
import 'package:alertcontacts/generated/l10n/app_localizations.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Text(l10n.welcome);
  }
}
```

### 3. Utilisation dans les blocs
```dart
class MyBloc extends Bloc<MyEvent, MyState> {
  MyBloc() : super(MyInitial()) {
    on<MyEvent>((event, emit) {
      // Les traductions ne sont pas disponibles dans les blocs
      // Utilisez les événements pour passer les textes nécessaires
    });
  }
}
```

## Ajouter de nouvelles traductions

### 1. Ajouter une nouvelle clé dans `app_fr.arb`
```json
{
  "newKey": "Nouveau texte",
  "@newKey": {
    "description": "Description de la nouvelle clé"
  }
}
```

### 2. Ajouter la traduction dans `app_en.arb`
```json
{
  "newKey": "New text"
}
```

### 3. Régénérer les classes
```bash
flutter gen-l10n
```

### 4. Utiliser la nouvelle traduction
```dart
Text(context.l10n.newKey)
```

## Changer la langue dynamiquement

Pour changer la langue de l'application dynamiquement, vous pouvez utiliser un bloc ou un provider pour gérer l'état de la langue :

```dart
class LocaleBloc extends Bloc<LocaleEvent, LocaleState> {
  LocaleBloc() : super(LocaleState(locale: const Locale('fr'))) {
    on<ChangeLocaleEvent>((event, emit) {
      emit(LocaleState(locale: event.locale));
    });
  }
}
```

## Bonnes pratiques

1. **Nommage des clés** : Utilisez des noms descriptifs en camelCase
2. **Descriptions** : Ajoutez toujours une description pour chaque clé
3. **Pluriels** : Utilisez les fonctions de pluralisation d'`intl` pour les textes avec pluriels
4. **Paramètres** : Utilisez les paramètres pour les textes dynamiques
5. **Cohérence** : Gardez les mêmes clés dans tous les fichiers ARB

## Exemple avec paramètres

### Dans `app_fr.arb`
```json
{
  "welcomeUser": "Bienvenue {name}",
  "@welcomeUser": {
    "description": "Message de bienvenue avec le nom de l'utilisateur",
    "placeholders": {
      "name": {
        "type": "String"
      }
    }
  }
}
```

### Dans `app_en.arb`
```json
{
  "welcomeUser": "Welcome {name}"
}
```

### Utilisation
```dart
Text(context.l10n.welcomeUser('John'))
```
