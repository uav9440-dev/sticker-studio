import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sticker_studio_ai/features/ai/ai_assistant_service.dart';
import 'package:sticker_studio_ai/features/billing/entitlement_service.dart';
import 'package:sticker_studio_ai/features/editor/application/editor_controller.dart';
import 'package:sticker_studio_ai/l10n/app_localizations.dart';

final aiDesignServiceProvider =
    Provider<AiDesignService>((_) => const LocalDesignEngine());

/// AI assistant: type a prompt in Arabic or English, get a complete design
/// opened in the editor. Runs fully offline via the local design engine;
/// a remote LLM backend can be bound over the same provider later.
class AiScreen extends ConsumerStatefulWidget {
  const AiScreen({super.key});

  @override
  ConsumerState<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends ConsumerState<AiScreen> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeAi)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: l10n.aiPromptHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _generate,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(l10n.aiGenerate),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final example in const [
                  'صباح الخير ذهبي فاخر',
                  'جمعة مباركة',
                  'ملصق قيمنق نيون',
                  'رمضان كريم',
                  'أحبك',
                ])
                  ActionChip(
                    label: Text(example),
                    onPressed: () => _controller.text = example,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generate() async {
    if (_controller.text.trim().isEmpty) return;
    if (!ref.read(entitlementProvider).isActive) {
      context.go('/paywall');
      return;
    }
    setState(() => _busy = true);
    final project = await ref
        .read(aiDesignServiceProvider)
        .designFromPrompt(_controller.text);
    if (!mounted) return;
    setState(() => _busy = false);
    ref.read(editorControllerProvider.notifier).loadProject(project);
    context.push('/editor');
  }
}
