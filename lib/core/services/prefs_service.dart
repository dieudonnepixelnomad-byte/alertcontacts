import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class PrefsService {
  static const _keyOnboardingDone = 'onboarding_done';
  static const _keyBearerToken = 'bearer_token';
  static const _keyUserProfile = 'user_profile';
  static const _keyInitialSetupDone = 'initial_setup_done';
  static const _keyUserSetupDone = 'user_setup_done';

  Future<void> setOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingDone, true);
  }

  Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingDone) ?? false;
  }

  Future<void> setBearerToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBearerToken, token);
  }

  Future<String?> getBearerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBearerToken);
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
}
