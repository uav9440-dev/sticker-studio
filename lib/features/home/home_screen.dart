import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sticker_studio_ai/app/app.dart';
import 'package:sticker_studio_ai/app/theme/app_theme.dart';
import 'package:sticker_studio_ai/features/billing/entitlement_service.dart';
import 'package:sticker_studio_ai/l10n/app_localizations.dart';

/// Home: one gold action (new design), then quiet doors to templates,
/// library, and the AI assistant. The user's own recent work is the hero —
/// the app's chrome stays out of the way.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final ent = ref.watch(entitlementProvider);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(l10n.appTitle,
                      style: Theme.of(context).textTheme.displaySmall),
                ),
                // تبديل اللغة فورًا: عربي ⇄ English (يقلب الاتجاه RTL/LTR أيضًا)
                TextButton.icon(
                  icon: const Icon(Icons.translate),
                  label: Text(isArabic ? 'English' : 'العربية'),
                  onPressed: () => ref.read(localeProvider.notifier).state =
                      Locale(isArabic ? 'en' : 'ar'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/editor'),
              icon: const Icon(Icons.add),
              label: Text(l10n.homeCreate),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Door(
                    icon: Icons.grid_view_rounded,
                    label: l10n.homeTemplates,
                    onTap: () => context.go('/templates'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Door(
                    icon: Icons.folder_outlined,
                    label: l10n.homeLibrary,
                    onTap: () => context.go('/library'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!ent.isPro && !ent.loading)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.workspace_premium,
                      color: StudioTokens.gold),
                  title: Text(ent.inTrial
                      ? 'تجربة مجانية — متبقٍ ${ent.trialRemaining.inHours} ساعة'
                      : 'انتهت التجربة — افتح النسخة الكاملة'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => context.go('/paywall'),
                ),
              ),
            if (!ent.isPro && !ent.loading) const SizedBox(height: 12),
            _Door(
              icon: Icons.auto_awesome,
              label: l10n.homeAi,
              accent: true,
              onTap: () => context.go('/ai'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Door extends StatelessWidget {
  const _Door({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(StudioTokens.radiusCard),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon,
                  color: accent ? StudioTokens.gold : null, size: 28),
              const SizedBox(width: 12),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
