import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// Le titre de l'application
  ///
  /// In fr, this message translates to:
  /// **'AlertContact'**
  String get appTitle;

  /// Message de bienvenue
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue'**
  String get welcome;

  /// Message de bienvenue
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous ou inscrivez-vous et nous commencerons.'**
  String get signInOrRegister;

  /// Bouton de connexion
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get login;

  /// Bouton de déconnexion
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get logout;

  /// Label pour le champ email
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get email;

  /// Label pour le champ mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// Label pour confirmer le mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get confirmPassword;

  /// Lien pour récupérer le mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get forgotPassword;

  /// Bouton d'inscription
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get register;

  /// Lien pour s'inscrire
  ///
  /// In fr, this message translates to:
  /// **'Pas encore membre ?'**
  String get notAMember;

  /// Bouton pour continuer avec Google
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get continueWithGoogle;

  /// Bouton pour créer un compte
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get createAccount;

  /// Message pour les termes et conditions
  ///
  /// In fr, this message translates to:
  /// **'Veuillez accepter les termes et conditions'**
  String get pleaseAcceptTerms;

  /// Message pour créer un compte
  ///
  /// In fr, this message translates to:
  /// **'Créer votre compte'**
  String get createYourAccount;

  /// Message pour l'inscription
  ///
  /// In fr, this message translates to:
  /// **'Inscrivez-vous pour commencer.'**
  String get registerSubtitle;

  /// Message pour le mot de passe requis
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe est requis'**
  String get passwordRequired;

  /// Message pour l'email requis
  ///
  /// In fr, this message translates to:
  /// **'L\'email est requis'**
  String get emailRequired;

  /// Message pour l'email invalide
  ///
  /// In fr, this message translates to:
  /// **'L\'email est invalide'**
  String get emailInvalid;

  /// Message pour le mot de passe minimum
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins 6 caractères'**
  String get passwordMinLength;

  /// Message pour les mots de passe non correspondants
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get passwordMatch;

  /// Message pour la force du mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins 1 majuscule, 1 chiffre et 1 caractère spécial'**
  String get passwordStrength;

  /// Message pour le caractère spécial
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins 1 caractère spécial'**
  String get passwordSpecialChar;

  /// Message pour la majuscule
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins 1 majuscule'**
  String get passwordCapitalLetter;

  /// Message pour le chiffre
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins 1 chiffre'**
  String get passwordNumber;

  /// Message pour l'email invalide
  ///
  /// In fr, this message translates to:
  /// **'L\'email est invalide'**
  String get invalidEmail;

  /// Label pour le nom complet
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get fullName;

  /// Message pour le nom requis
  ///
  /// In fr, this message translates to:
  /// **'Le nom est requis'**
  String get nameRequired;

  /// Message pour le nom trop court
  ///
  /// In fr, this message translates to:
  /// **'Le nom doit contenir au moins 2 caractères'**
  String get nameTooShort;

  /// Message pour le mot de passe trop court
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins 6 caractères'**
  String get passwordTooShort;

  /// Message pour le mot de passe de confirmation requis
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe de confirmation est requis'**
  String get confirmPasswordRequired;

  /// Message pour les mots de passe non correspondants
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get passwordsDoNotMatch;

  /// Message pour le mot de passe trop court
  ///
  /// In fr, this message translates to:
  /// **'Min 6 caractères'**
  String get passwordHintShort;

  /// Message pour le lien pour se connecter
  ///
  /// In fr, this message translates to:
  /// **'Vous avez déjà un compte ?'**
  String get alreadyHaveAccount;

  /// Message pour le lien pour accepter les termes et conditions
  ///
  /// In fr, this message translates to:
  /// **'Je accepte les'**
  String get iAgreeWith;

  /// Message pour le lien pour les termes et conditions
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation'**
  String get termsOfUse;

  /// Message pour le lien pour la politique de confidentialité
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get privacyPolicy;

  /// Message pour le lien pour les termes et conditions
  ///
  /// In fr, this message translates to:
  /// **'et'**
  String get and;

  /// Onglet accueil
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get home;

  /// Onglet carte
  ///
  /// In fr, this message translates to:
  /// **'Carte'**
  String get map;

  /// Onglet zones de danger
  ///
  /// In fr, this message translates to:
  /// **'Zones de danger'**
  String get dangerZones;

  /// Onglet zones de sécurité
  ///
  /// In fr, this message translates to:
  /// **'Zones de sécurité'**
  String get safeZones;

  /// Onglet contacts
  ///
  /// In fr, this message translates to:
  /// **'Contacts'**
  String get contacts;

  /// Onglet alertes
  ///
  /// In fr, this message translates to:
  /// **'Alertes'**
  String get alerts;

  /// Onglet paramètres
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// Onglet profil
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// Bouton pour ajouter un contact
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un contact'**
  String get addContact;

  /// Bouton pour créer une zone de danger
  ///
  /// In fr, this message translates to:
  /// **'Créer une zone de danger'**
  String get createDangerZone;

  /// Bouton pour créer une zone de sécurité
  ///
  /// In fr, this message translates to:
  /// **'Créer une zone de sécurité'**
  String get createSafeZone;

  /// Bouton pour envoyer une alerte
  ///
  /// In fr, this message translates to:
  /// **'Envoyer une alerte'**
  String get sendAlert;

  /// Bouton d'annulation
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// Bouton d'enregistrement
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// Bouton de suppression
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// Bouton de modification
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// Placeholder pour la recherche
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get search;

  /// Message de chargement
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loading;

  /// Message d'erreur générique
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get error;

  /// Message de succès
  ///
  /// In fr, this message translates to:
  /// **'Succès'**
  String get success;

  /// Message quand il n'y a pas de données
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée disponible'**
  String get noData;

  /// Bouton pour réessayer
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// Message pour les permissions requises
  ///
  /// In fr, this message translates to:
  /// **'Permission requise'**
  String get permissionRequired;

  /// Message pour la permission de localisation
  ///
  /// In fr, this message translates to:
  /// **'Permission de localisation'**
  String get locationPermission;

  /// Message pour la permission de notification
  ///
  /// In fr, this message translates to:
  /// **'Permission de notification'**
  String get notificationPermission;

  /// Message pour la permission d'accès au téléphone
  ///
  /// In fr, this message translates to:
  /// **'Permission d\'accès au téléphone'**
  String get phonePermission;

  /// Bouton pour autoriser
  ///
  /// In fr, this message translates to:
  /// **'Autoriser'**
  String get allow;

  /// Bouton pour refuser
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get deny;

  /// Bouton pour aller aux paramètres
  ///
  /// In fr, this message translates to:
  /// **'Aller aux paramètres'**
  String get goToSettings;

  /// Titre du premier slide d'onboarding
  ///
  /// In fr, this message translates to:
  /// **'Votre sécurité. Votre sérénité.'**
  String get onBoardingSlide_title_1;

  /// Corps du premier slide d'onboarding
  ///
  /// In fr, this message translates to:
  /// **'Anticipez les risques autour de vous et veillez sur ceux qui comptent — simplement, sans stress.'**
  String get onBoardingSlide_body_1;

  /// Titre du deuxième slide d'onboarding
  ///
  /// In fr, this message translates to:
  /// **'Évitez les zones à risques'**
  String get onBoardingSlide_title_2;

  /// Corps du deuxième slide d'onboarding
  ///
  /// In fr, this message translates to:
  /// **'Alerte instantanée quand vous approchez d\'un lieu signalé (vol, agression, accident).'**
  String get onBoardingSlide_body_2;

  /// Titre du troisième slide d'onboarding
  ///
  /// In fr, this message translates to:
  /// **'Créez des périmètres sûrs'**
  String get onBoardingSlide_title_3;

  /// Corps du troisième slide d'onboarding
  ///
  /// In fr, this message translates to:
  /// **'Maison, école, trajet… Recevez une notification si un proche sort de la zone.'**
  String get onBoardingSlide_body_3;

  /// Titre du quatrième slide d'onboarding
  ///
  /// In fr, this message translates to:
  /// **'Vos proches, vos règles'**
  String get onBoardingSlide_title_4;

  /// Corps du quatrième slide d'onboarding
  ///
  /// In fr, this message translates to:
  /// **'Devenir \"proches\" ne veut pas dire être suivi : vous décidez, personne d\'autre.'**
  String get onBoardingSlide_body_4;

  /// Bouton pour commencer l'onboarding
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get onBoardingStart;

  /// Bouton suivant dans l'onboarding
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get onBoardingNext;

  /// Bouton pour passer l'onboarding
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get onBoardingSkip;

  /// Titre de la page de vérification d'email
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre email'**
  String get emailVerificationTitle;

  /// Description de la page de vérification d'email
  ///
  /// In fr, this message translates to:
  /// **'Nous avons envoyé un lien de vérification à votre adresse email. Cliquez sur le lien pour activer votre compte.'**
  String get emailVerificationDescription;

  /// Message de vérification automatique
  ///
  /// In fr, this message translates to:
  /// **'Vérification automatique en cours...'**
  String get emailVerificationAutoCheck;

  /// Bouton pour renvoyer l'email de vérification
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer l\'email'**
  String get resendEmail;

  /// Compte à rebours pour renvoyer l'email
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer dans {seconds}s'**
  String resendEmailIn(int seconds);

  /// Bouton pour vérifier maintenant
  ///
  /// In fr, this message translates to:
  /// **'Vérifier maintenant'**
  String get checkNow;

  /// Message d'aide pour l'email non trouvé
  ///
  /// In fr, this message translates to:
  /// **'Vous ne trouvez pas l\'email ?'**
  String get emailNotFound;

  /// No description provided for @emailVerificationResend.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer l\'email'**
  String get emailVerificationResend;

  /// No description provided for @emailVerificationResendCooldown.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer dans {seconds}s'**
  String emailVerificationResendCooldown(int seconds);

  /// No description provided for @emailVerificationCheckNow.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier maintenant'**
  String get emailVerificationCheckNow;

  /// No description provided for @emailVerificationNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne trouvez pas l\'email ?'**
  String get emailVerificationNotFound;

  /// Conseils de dépannage pour l'email
  ///
  /// In fr, this message translates to:
  /// **'• Vérifiez votre dossier spam\n• Assurez-vous que l\'adresse email est correcte\n• L\'email peut prendre quelques minutes à arriver'**
  String get emailTroubleshootingTips;

  /// Titre de la page de mot de passe oublié
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié'**
  String get forgotPasswordTitle;

  /// Description de la page de mot de passe oublié
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre adresse email pour recevoir un lien de réinitialisation de mot de passe.'**
  String get forgotPasswordDescription;

  /// Message confirmant l'envoi de l'email de réinitialisation
  ///
  /// In fr, this message translates to:
  /// **'Un email de réinitialisation a été envoyé à votre adresse. Vérifiez votre boîte de réception et suivez les instructions.'**
  String get forgotPasswordEmailSent;

  /// Titre après envoi du lien de réinitialisation
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre email'**
  String get checkEmailTitle;

  /// Description après envoi du lien de réinitialisation
  ///
  /// In fr, this message translates to:
  /// **'Nous avons envoyé un lien de réinitialisation à votre adresse email.'**
  String get checkEmailDescription;

  /// Bouton pour envoyer le lien de réinitialisation
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le lien'**
  String get sendResetLink;

  /// Bouton pour renvoyer l'email de réinitialisation
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer l\'email'**
  String get resendResetEmail;

  /// Lien pour retourner à la connexion
  ///
  /// In fr, this message translates to:
  /// **'Retour à la connexion'**
  String get backToLogin;

  /// Message de succès d'envoi d'email de réinitialisation
  ///
  /// In fr, this message translates to:
  /// **'Email de réinitialisation envoyé avec succès'**
  String get resetEmailSentSuccess;

  /// Message d'erreur lors de l'envoi d'email de réinitialisation
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue'**
  String get resetEmailError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
