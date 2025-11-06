// lib/features/feedback/presentation/feedback_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/feedback_provider.dart';
import '../../../core/services/share_service.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  String _selectedCategory = 'feature';

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    final feedbackProvider = context.read<FeedbackProvider>();

    try {
      await feedbackProvider.submitFeedback(
        category: _selectedCategory,
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Merci pour votre retour ! Nous l\'avons bien reçu.'),
            backgroundColor: Colors.green,
          ),
        );

        // Réinitialiser le formulaire
        _formKey.currentState!.reset();
        _subjectController.clear();
        _messageController.clear();
        setState(() {
          _selectedCategory = 'feature';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi : ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Critiques & Suggestions'),
        backgroundColor: const Color(0xFF006970),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/app-shell');
            }
          },
        ),
      ),
      body: Consumer<FeedbackProvider>(
        builder: (context, feedbackProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Introduction
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.feedback,
                                color: const Color(0xFF006970),
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Votre avis compte !',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF006970),
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Aidez-nous à améliorer AlertContact en partageant vos suggestions, '
                            'en signalant des bugs ou en nous faisant part de votre expérience.',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Catégorie
                  Text(
                    'Type de retour',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'feature',
                        child: Text('💡 Demande de fonctionnalité'),
                      ),
                      DropdownMenuItem(
                        value: 'bug',
                        child: Text('🐛 Signalement de bug'),
                      ),
                      DropdownMenuItem(
                        value: 'compliment',
                        child: Text('👏 Compliment'),
                      ),
                      DropdownMenuItem(
                        value: 'complaint',
                        child: Text('😞 Plainte'),
                      ),
                      DropdownMenuItem(value: 'other', child: Text('📝 Autre')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  // Sujet
                  Text(
                    'Sujet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Résumez votre retour en quelques mots',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez saisir un sujet';
                      }
                      if (value.trim().length < 5) {
                        return 'Le sujet doit contenir au moins 5 caractères';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Message
                  Text(
                    'Message détaillé',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _messageController,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText:
                          'Décrivez votre retour en détail...\n\n'
                          'Pour un bug, précisez :\n'
                          '• Les étapes pour le reproduire\n'
                          '• Le comportement attendu\n'
                          '• Votre appareil et version d\'OS',
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez saisir un message';
                      }
                      if (value.trim().length < 20) {
                        return 'Le message doit contenir au moins 20 caractères';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Informations sur la confidentialité
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Vos retours sont anonymes et utilisés uniquement pour améliorer l\'application.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.blue.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bouton d'envoi
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: feedbackProvider.isLoading
                          ? null
                          : _submitFeedback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006970),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: feedbackProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Envoyer le retour',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
