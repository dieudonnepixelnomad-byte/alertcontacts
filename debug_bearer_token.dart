import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:alertcontacts/core/services/prefs_service.dart';
import 'package:alertcontacts/core/config/api_config.dart';

/// Script de débogage pour vérifier la présence du bearerToken
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  log('🔍 DEBUG: DÉBUT du débogage bearerToken');
  
  try {
    final prefsService = PrefsService();
    
    log('🔍 DEBUG: Récupération du bearerToken...');
    final bearerToken = await prefsService.getBearerToken();
    
    if (bearerToken != null) {
      log('✅ DEBUG: bearerToken trouvé: ${bearerToken.substring(0, 10)}...');
      log('✅ DEBUG: Longueur du token: ${bearerToken.length}');
    } else {
      log('❌ DEBUG: bearerToken est null');
    }
    
    log('🔍 DEBUG: baseUrl: ${ApiConfig.baseUrlSync}');
    
    log('🔍 DEBUG: Test terminé');
    
  } catch (e) {
    log('❌ DEBUG: Erreur lors du débogage: $e');
  }
}