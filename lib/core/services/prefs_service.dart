import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class PrefsService {
  static const _keyOnboardingDone = 'onboarding_done';
  static const _keyBearerToken = 'bearer_token';
  static const _keyUserProfile = 'user_profile';
  static const _keyInitialSetupDone = 'initial_setup_done';
  static const _keyUserSetupDone = 'user_setup_done';

  // Onboarding V2 keys
  static const _keyOnboardingPhase = 'onboarding_phase';
  static const _keyAhaSandboxSeen = 'aha_sandbox_seen';
  static const _keyOnboardingPersona = 'onboarding_persona';
  static const _keyOnboardingInviteeName = 'onboarding_invitee_name';
  static const _keyOnboardingInviteDone = 'onboarding_invite_done';
  static const _keyOnboardingNotifPermAsked = 'onboarding_notif_perm_asked';
  static const _keyOnboardingZoneCreated = 'onboarding_zone_created';
  static const _keyFirstLaunchTooltipShown = 'first_launch_tooltip_shown';

  Future<void> setOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingDone, true);
  }

  Future<String?> getBearerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBearerToken);
  }

  Future<void> setBearerToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(_keyBearerToken, token);
    } else {
      await prefs.remove(_keyBearerToken);
    }
  }

  Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingDone) ?? false;
  }

  Future<void> clearBearerToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyBearerToken);
  }

  Future<void> setUserProfile(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserProfile, jsonEncode(user.toJson()));
  }

  Future<User?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString(_keyUserProfile);
    if (profileJson == null) return null;
    
    try {
      final profileMap = jsonDecode(profileJson) as Map<String, dynamic>;
      return User.fromJson(profileMap);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserProfile);
  }

  /// Marque le setup initial comme terminé (première zone de sécurité créée)
  Future<void> setInitialSetupDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyInitialSetupDone, true);
  }

  /// Vérifie si l'utilisateur a complété le setup initial
  Future<bool> isInitialSetupDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyInitialSetupDone) ?? false;
  }

  /// Efface le flag du setup initial (utile pour les tests ou reset)
  Future<void> clearInitialSetupDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyInitialSetupDone);
  }

  /// Marque le wizard d'informations utilisateur comme terminé (à la première connexion)
  Future<void> setUserSetupDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUserSetupDone, true);
  }

  /// Vérifie si l'utilisateur a complété le wizard d'informations utilisateur
  Future<bool> isUserSetupDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUserSetupDone) ?? false;
  }

  /// Efface le flag du wizard d'informations utilisateur
  Future<void> clearUserSetupDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserSetupDone);
  }

  // ── Onboarding V2 ────────────────────────────────────────────────────────

  Future<void> setOnboardingPhase(int phase) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyOnboardingPhase, phase);
  }

  Future<int> getOnboardingPhase() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyOnboardingPhase) ?? 0;
  }

  Future<void> setAhaSandboxSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAhaSandboxSeen, true);
  }

  Future<bool> isAhaSandboxSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAhaSandboxSeen) ?? false;
  }

  Future<void> setOnboardingPersona(String persona) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyOnboardingPersona, persona);
  }

  Future<String?> getOnboardingPersona() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyOnboardingPersona);
  }

  Future<void> setOnboardingInviteeName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyOnboardingInviteeName, name);
  }

  Future<String?> getOnboardingInviteeName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyOnboardingInviteeName);
  }

  Future<void> setOnboardingInviteDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingInviteDone, true);
  }

  Future<bool> isOnboardingInviteDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingInviteDone) ?? false;
  }

  Future<void> setOnboardingNotifPermAsked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingNotifPermAsked, true);
  }

  Future<bool> isOnboardingNotifPermAsked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingNotifPermAsked) ?? false;
  }

  Future<void> setOnboardingZoneCreated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingZoneCreated, true);
  }

  Future<bool> isOnboardingZoneCreated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingZoneCreated) ?? false;
  }

  Future<void> setFirstLaunchTooltipShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstLaunchTooltipShown, true);
  }

  Future<bool> isFirstLaunchTooltipShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFirstLaunchTooltipShown) ?? false;
  }

  // Onboarding V4
  static const _keyOnboardingSlidesSeen = 'onboarding_slides_seen';

  Future<void> setOnboardingSlidesSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingSlidesSeen, true);
  }

  Future<bool> isOnboardingSlidesSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingSlidesSeen) ?? false;
  }

  // Flag "utilisateur déjà authentifié" — évite le flash /auth au redémarrage
  static const _keyHasLoggedIn = 'has_logged_in';
  static const _keyFirebaseUid = 'firebase_uid';
  static const _keyBaseUrl = 'base_url';

  Future<void> setFirebaseUid(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFirebaseUid, uid);
  }

  Future<String?> getFirebaseUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFirebaseUid);
  }

  Future<void> clearFirebaseUid() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFirebaseUid);
  }

  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, url);
  }

  Future<String?> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBaseUrl);
  }

  Future<void> setHasLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasLoggedIn, value);
  }

  Future<bool> hasLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasLoggedIn) ?? false;
  }

  // Magic Link pending email (Firebase requirement: store email before sending link)
  static const _keyPendingMagicLinkEmail = 'pending_magic_link_email';

  Future<void> setPendingMagicLinkEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPendingMagicLinkEmail, email);
  }

  Future<String?> getPendingMagicLinkEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPendingMagicLinkEmail);
  }

  Future<void> clearPendingMagicLinkEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPendingMagicLinkEmail);
  }
}
