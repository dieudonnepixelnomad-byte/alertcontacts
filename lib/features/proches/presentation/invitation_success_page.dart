import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../router/app_router.dart';
import '../../../theme/colors.dart';
import '../../../core/services/app_review_service.dart';

class InvitationSuccessPage extends StatefulWidget {
  final String inviterName;
  final String myInitials;

  const InvitationSuccessPage({
    super.key,
    required this.inviterName,
    required this.myInitials,
  });

  @override
  State<InvitationSuccessPage> createState() => _InvitationSuccessPageState();
}

class _InvitationSuccessPageState extends State<InvitationSuccessPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final eligible = await AppReviewService().registerSuccessfulValueEvent();
      if (!eligible || !mounted) return;
      final choice = await AppReviewService().showPrompt(context);
      if (choice == AppReviewPromptChoice.feedback && mounted) {
        context.push('/feedback');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final inviterInitial = widget.inviterName.isNotEmpty
        ? widget.inviterName[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.success,
                  size: 52,
                ),
              ),
              const SizedBox(height: 28),

              Text(
                '${widget.inviterName} a rejoint !',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Text(
                'Vous pouvez maintenant vous voir\nsur la carte. Voilà : tu n\'es plus seul.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black.withValues(alpha: 0.55),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Deux avatars superposés
              SizedBox(
                height: 72,
                width: 116,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.orange,
                          child: Text(
                            inviterInitial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            widget.myInitials.isNotEmpty
                                ? widget.myInitials[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go(AppRoutes.appShell),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Voir ${widget.inviterName} sur la carte →',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              TextButton(
                onPressed: () => context.go(AppRoutes.appShell),
                child: Text(
                  'Plus tard',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
