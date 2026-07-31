import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sticker_studio_ai/features/editor/application/editor_controller.dart';
import 'package:sticker_studio_ai/features/editor/domain/models/project.dart';
import 'package:sticker_studio_ai/features/templates/data/starter_templates.dart';
import 'package:sticker_studio_ai/l10n/app_localizations.dart';

/// Template gallery. Tapping a template clones it into the editor —
/// every template stays fully editable.
class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeTemplates)),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        itemCount: starterTemplates.length,
        itemBuilder: (context, i) {
          final tpl = starterTemplates[i];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                final StickerProject project = tpl.open();
                ref
                    .read(editorControllerProvider.notifier)
                    .loadProject(project);
                context.push('/editor');
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome, size: 36),
                    const SizedBox(height: 12),
                    Text(
                      isArabic ? tpl.titleAr : tpl.titleEn,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
