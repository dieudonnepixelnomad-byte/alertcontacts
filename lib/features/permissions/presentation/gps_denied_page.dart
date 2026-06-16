import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../theme/colors.dart';

class GpsDeniedPage extends StatelessWidget {
  final VoidCallback? onContinueWithout;

  const GpsDeniedPage({super.key, this.onContinueWithout});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_off_outlined, size: 36, color: AppColors.danger),
              ),
              const SizedBox(height: 20),
              Text('GPS refusé', style: tt.titleLarge),
              const SizedBox(height: 8),
              Text(
                'AlertContacts a besoin de ta position pour te protéger et protéger tes proches.',
                style: tt.bodyMedium?.copyWith(color: AppColors.gray400),
              ),
              const SizedBox(height: 28),
              _Step(number: 1, text: 'Ouvre les Réglages de ton téléphone'),
              const SizedBox(height: 12),
              _Step(number: 2, text: 'Va dans "Confidentialité" → "Services de localisation"'),
              const SizedBox(height: 12),
              _Step(number: 3, text: 'Trouve AlertContacts et sélectionne "En cours d\'utilisation"'),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => openAppSettings(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Ouvrir les réglages',
                    style: tt.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onContinueWithout ?? () => Navigator.pop(context),
                  child: Text(
                    'Continuer sans GPS',
                    style: tt.bodyMedium?.copyWith(color: AppColors.gray400),
                  ),
                ),
              ),
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
    final tt = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28, height: 28,
          decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
          child: Center(
            child: Text(
              '$number',
              style: tt.bodySmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: tt.bodyMedium)),
      ],
    );
  }
}
