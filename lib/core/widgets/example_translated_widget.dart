import 'package:flutter/material.dart';
import 'package:alertcontacts/core/utils/l10n_helper.dart';

/// Exemple d'utilisation des traductions dans un widget
class ExampleTranslatedWidget extends StatelessWidget {
  const ExampleTranslatedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.appTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.welcome,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () {}, child: Text(context.l10n.login)),
            const SizedBox(height: 8),
            TextButton(onPressed: () {}, child: Text(context.l10n.register)),
            const SizedBox(height: 16),
            Text(
              context.l10n.email,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.password,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: Text(context.l10n.save),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: Text(context.l10n.cancel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
