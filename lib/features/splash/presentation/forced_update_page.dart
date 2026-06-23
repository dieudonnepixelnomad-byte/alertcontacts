import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ForcedUpdatePage extends StatelessWidget {
  final String storeUrl;

  const ForcedUpdatePage({super.key, required this.storeUrl});

  Future<void> _launchStore() async {
    if (storeUrl.isEmpty) return;
    final uri = Uri.parse(storeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E6868),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Icône
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 32),

                // Titre
                const Text(
                  'Mise à jour requise',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  'Cette version d\'AlertContacts n\'est plus supportée.\nMets à jour pour continuer à protéger tes proches.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.70),
                    height: 1.5,
                  ),
                ),

                const Spacer(flex: 2),

                // CTA
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _launchStore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1E6868),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Mettre à jour maintenant',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
