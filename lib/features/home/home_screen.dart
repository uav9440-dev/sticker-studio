import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sticker_studio_ai/app/app.dart';
import 'package:sticker_studio_ai/app/theme/app_theme.dart';
import 'package:sticker_studio_ai/core/widgets/bounce.dart';
import 'package:sticker_studio_ai/features/billing/entitlement_service.dart';
import 'package:sticker_studio_ai/l10n/app_localizations.dart';

/// الرئيسية بحلّة أرتب: ترويسة ذهبية ترحيبية، زر إنشاء كبير،
/// وبطاقات مرتبة بحركة ارتداد عند الضغط.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final ent = ref.watch(entitlementProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            // ترويسة ذهبية
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    StudioTokens.gold.withOpacity(0.22),
                    Colors.transparent,
                  ],
                ),
                border: Border.all(
                    color: StudioTokens.gold.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.appTitle,
                            style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 4),
                        Text(
                          isArabic
                              ? 'صمّم ملصقات تُبهر أصدقاءك ✨'
                              : 'Design stickers that wow ✨',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Bounce(
                    onTap: () => ref.read(localeProvider.notifier).state =
                        Locale(isArabic ? 'en' : 'ar'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.translate, size: 18),
                          const SizedBox(width: 6),
                          Text(isArabic ? 'EN' : 'ع'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // زر الإنشاء الرئيسي
            Bounce(
              onTap: () => context.push('/editor'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFC9A24B), Color(0xFFE8CB7E)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: StudioTokens.gold.withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_circle_outline,
                        color: StudioTokens.obsidian),
                    const SizedBox(width: 8),
                    Text(
                      l10n.homeCreate,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: StudioTokens.obsidian,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // شريط التجربة/الشراء
            if (!ent.isPro && !ent.loading) ...[
              Bounce(
                onTap: () => context.push('/paywall'),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.workspace_premium,
                        color: StudioTokens.gold),
                    title: Text(ent.inTrial
                        ? 'تجربة مجانية — متبقٍ ${ent.trialRemaining.inHours} ساعة'
                        : 'انتهت التجربة — افتح النسخة الكاملة'),
                    trailing: const Icon(Icons.chevron_left),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // بطاقات الأقسام
            Row(
              children: [
                Expanded(
                  child: _Door(
                    icon: Icons.grid_view_rounded,
                    label: l10n.homeTemplates,
                    onTap: () => context.push('/templates'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Door(
                    icon: Icons.folder_outlined,
                    label: l10n.homeLibrary,
                    onTap: () => context.push('/library'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Door(
              icon: Icons.auto_awesome,
              label: l10n.homeAi,
              subtitle: l10n.aiPromptHint,
              onTap: () => context.push('/ai'),
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
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Bounce(
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: StudioTokens.gold.withOpacity(0.15),
                ),
                child: Icon(icon, color: StudioTokens.gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.titleMedium),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left),
            ],
          ),
        ),
      ),
    );
  }
}
