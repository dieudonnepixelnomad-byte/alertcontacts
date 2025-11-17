import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/repositories/user_setup_repository.dart';
import '../../../core/services/prefs_service.dart';
import '../../../router/app_router.dart';
import '../providers/user_setup_provider.dart';

class UserSetupWizard extends StatelessWidget {
  const UserSetupWizard({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserSetupProvider(),
      child: const _UserSetupWizardView(),
    );
  }
}

class _UserSetupWizardView extends StatefulWidget {
  const _UserSetupWizardView();

  @override
  State<_UserSetupWizardView> createState() => _UserSetupWizardViewState();
}

class _UserSetupWizardViewState extends State<_UserSetupWizardView> {
  final PageController _pageController = PageController();
  final _firstNameController = TextEditingController(text: 'Moi');
  String _selectedAge = '18-35';
  String _selectedGender = 'prefer_not_to_say';
  String _selectedGoal = 'moi_meme';
  String _experienceLevel = 'first_time';
  bool _submitting = false;

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    final provider = context.read<UserSetupProvider>();
    final repo = UserSetupRepository();
    final prefs = PrefsService();

    setState(() => _submitting = true);

    try {
      provider.setFirstName(_firstNameController.text.trim());
      provider.setAgeRange(_selectedAge);
      provider.setGender(_selectedGender);
      provider.setPrimaryGoal(_selectedGoal);
      provider.setExperienceLevel(_experienceLevel);

      await repo.submitSetup(provider.data.toJson());
      await prefs.setUserSetupDone();

      if (!mounted) return;
      context.go(AppRoutes.appShell);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur de soumission: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _nextPage(BuildContext context) {
    final provider = context.read<UserSetupProvider>();
    provider.nextStep();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  Widget _progress(int step, {String label = ''}) {
    return Text('$label${step} / 3', style: const TextStyle(fontSize: 12));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Bienvenue !')), // sobre
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // ÉCRAN 1 — Vos informations de base
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        const Text(
                          'Bienvenue ! Faisons connaissance 👋',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ces informations permettent d’adapter la protection et l’expérience à votre profil.',
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _firstNameController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Prénom',
                            hintText: 'Votre prénom',
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedAge,
                          items: const [
                            DropdownMenuItem(value: '<18', child: Text('–18')),
                            DropdownMenuItem(
                              value: '18-35',
                              child: Text('18-35'),
                            ),
                            DropdownMenuItem(
                              value: '36-60',
                              child: Text('36-60'),
                            ),
                            DropdownMenuItem(value: '60+', child: Text('60+')),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedAge = v ?? '18-35'),
                          decoration: const InputDecoration(labelText: 'Âge'),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          children: [
                            ChoiceChip(
                              label: const Text('Femme'),
                              selected: _selectedGender == 'female',
                              onSelected: (_) =>
                                  setState(() => _selectedGender = 'female'),
                            ),
                            ChoiceChip(
                              label: const Text('Homme'),
                              selected: _selectedGender == 'male',
                              onSelected: (_) =>
                                  setState(() => _selectedGender = 'male'),
                            ),
                            ChoiceChip(
                              label: const Text('Autre'),
                              selected: _selectedGender == 'other',
                              onSelected: (_) =>
                                  setState(() => _selectedGender = 'other'),
                            ),
                            ChoiceChip(
                              label: const Text('Préfère ne pas dire'),
                              selected: _selectedGender == 'prefer_not_to_say',
                              onSelected: (_) => setState(
                                () => _selectedGender = 'prefer_not_to_say',
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _nextPage(context),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Continuer'),
                                const SizedBox(width: 12),
                                _progress(1),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ÉCRAN 2 — Objectif d’usage
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Que souhaitez-vous protéger ?',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Choisissez ce qui compte le plus pour vous — l’app se configurera automatiquement.',
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _goalButton('👧 Mes enfants', 'enfants'),
                            _goalButton('👵 Un proche âgé', 'proche_age'),
                            _goalButton(
                              '🏠 Maison / trajets',
                              'maison_trajets',
                            ),
                            _goalButton('🚶 Moi-même', 'moi_meme'),
                            _goalButton(
                              '💼 Mes collaborateurs',
                              'collaborateurs',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            setState(() => _selectedGoal = 'moi_meme');
                          },
                          child: const Text('Je ne sais pas encore'),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _nextPage(context),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Suivant'),
                                const SizedBox(width: 12),
                                _progress(2),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ÉCRAN 3 — Expérience et attentes
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Avez-vous déjà utilisé une application similaire ?',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Cela nous aide à adapter les explications pour vous.',
                        ),
                        const SizedBox(height: 24),
                        RadioListTile<String>(
                          value: 'experienced',
                          groupValue: _experienceLevel,
                          onChanged: (v) => setState(
                            () => _experienceLevel = v ?? 'experienced',
                          ),
                          title: const Text('Oui, j’en ai déjà utilisé une.'),
                        ),
                        RadioListTile<String>(
                          value: 'first_time',
                          groupValue: _experienceLevel,
                          onChanged: (v) => setState(
                            () => _experienceLevel = v ?? 'first_time',
                          ),
                          title: const Text('Non, c’est la première fois.'),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitting
                                ? null
                                : () => _submit(context),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _submitting
                                      ? 'Envoi...'
                                      : 'Terminer et découvrir AlertContacts',
                                ),
                                const SizedBox(width: 12),
                                _progress(3),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_experienceLevel == 'first_time')
                          Text(
                            'Un micro‑tutoriel guidé vous sera proposé.',
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _goalButton(String label, String value) {
    final selected = _selectedGoal == value;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => setState(() => _selectedGoal = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withOpacity(0.15)
              : theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : Colors.transparent,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
