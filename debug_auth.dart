import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== DEBUG AUTHENTIFICATION ===');
  
  // Vérifier le token stocké
  final prefs = await SharedPreferences.getInstance();
  final bearerToken = prefs.getString('bearer_token');
  final userProfile = prefs.getString('user_profile');
  
  print('Token Bearer stocké: ${bearerToken != null ? "OUI (${bearerToken.length} caractères)" : "NON"}');
  print('Profil utilisateur stocké: ${userProfile != null ? "OUI" : "NON"}');
  
  if (bearerToken != null) {
    print('Token: ${bearerToken.substring(0, 20)}...');
    
    // Tester le token avec l'API
    print('\n=== TEST API AVEC TOKEN ===');
    
    try {
      final response = await http.get(
        Uri.parse('https://mobile.alertcontacts.net/api/user'),
        headers: {
          'Authorization': 'Bearer $bearerToken',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );
      
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        print('✅ Token valide - utilisateur authentifié');
      } else if (response.statusCode == 401) {
        print('❌ Token invalide ou expiré');
      } else {
        print('⚠️ Erreur inattendue');
      }
    } catch (e) {
      print('❌ Erreur lors du test API: $e');
    }
    
    // Tester l'endpoint de suppression de compte
    print('\n=== TEST ENDPOINT SUPPRESSION ===');
    
    try {
      final response = await http.delete(
        Uri.parse('https://mobile.alertcontacts.net/api/user/account'),
        headers: {
          'Authorization': 'Bearer $bearerToken',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );
      
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        print('✅ Endpoint de suppression accessible');
      } else if (response.statusCode == 401) {
        print('❌ Non autorisé pour la suppression');
      } else {
        print('⚠️ Erreur inattendue pour la suppression');
      }
    } catch (e) {
      print('❌ Erreur lors du test de suppression: $e');
    }
  }
  
  if (userProfile != null) {
    print('\n=== PROFIL UTILISATEUR ===');
    try {
      final profileMap = jsonDecode(userProfile) as Map<String, dynamic>;
      print('ID: ${profileMap['id']}');
      print('Email: ${profileMap['email']}');
      print('Nom: ${profileMap['name']}');
    } catch (e) {
      print('Erreur lors du décodage du profil: $e');
    }
  }
  
  print('\n=== FIN DEBUG ===');
  exit(0);
}