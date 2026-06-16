import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class LocationPermissionOverlay extends StatelessWidget {
  final bool isPermanentlyDenied;
  final VoidCallback onOpenSettings;
  final VoidCallback onContinueWithout;

  const LocationPermissionOverlay({
    super.key,
    required this.isPermanentlyDenied,
    required this.onOpenSettings,
    required this.onContinueWithout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_off_rounded,
                  color: AppColors.danger,
                  size: 38,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'La localisation est désactivée',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sans accès à ta position, tes proches ne peuvent pas voir où tu es. Tu peux toujours voir leurs positions à toi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              // Steps section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '3 ÉTAPES POUR ACTIVER',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Step(
                      number: 1,
                      text: 'Ouvre les Paramètres ${isPermanentlyDenied ? 'Android' : 'de ton téléphone'}',
                    ),
                    const SizedBox(height: 10),
                    const _Step(
                      number: 2,
                      text: 'Apps → AlertContacts → Autorisations',
                    ),
                    const SizedBox(height: 10),
                    const _Step(
                      number: 3,
                      text: 'Position → Autoriser tout le temps',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Pourquoi tout le temps ?'),
                      content: const Text(
                        'Pour détecter les arrivées de zone quand l\'app est en arrière-plan, AlertContacts a besoin d\'accéder à ta position même quand l\'app n\'est pas ouverte.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Compris'),
                        ),
                      ],
                    ),
                  );
                },
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    children: [
                      const TextSpan(text: '+ Pourquoi tout le temps ? '),
                      TextSpan(
                        text: 'Pour détecter les arrivées de zone quand l\'app est en arrière-plan.',
                        style: const TextStyle(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 1),
              // CTA
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onOpenSettings,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text(
                    'Ouvrir les paramètres',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: onContinueWithout,
                child: const Text(
                  'Continuer sans localisation',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String text;
  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
