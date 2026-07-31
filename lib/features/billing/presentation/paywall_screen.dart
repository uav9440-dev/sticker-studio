import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sticker_studio_ai/app/theme/app_theme.dart';
import 'package:sticker_studio_ai/features/billing/entitlement_service.dart';

/// Paywall: shown when the 3-day trial ends (or from settings).
/// One-time lifetime purchase — the price string comes live from Google
/// Play, so changing the price in Play Console needs no app update.
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ent = ref.watch(entitlementProvider);
    final product = ent.products.isEmpty ? null : ent.products.first;

    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.workspace_premium,
                size: 72, color: StudioTokens.gold),
            const SizedBox(height: 16),
            Text(
              'النسخة الكاملة',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              ent.isPro
                  ? 'أنت مشترك — كل الميزات مفتوحة، شكرًا لدعمك ✨'
                  : ent.inTrial
                      ? 'تجربتك المجانية تنتهي خلال ${ent.trialRemaining.inHours} ساعة'
                      : 'انتهت التجربة المجانية (3 أيام)',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            const _Benefit('تصدير غير محدود لواتساب بدون علامة مائية'),
            const _Benefit('كل التأثيرات الذهبية والنيون والحركات'),
            const _Benefit('المساعد الذكي والقوالب كاملة'),
            const _Benefit('دفعة واحدة — ملكك مدى الحياة، بدون اشتراكات'),
            const Spacer(),
            if (!ent.isPro) ...[
              FilledButton(
                onPressed: product == null
                    ? null
                    : () => ref.read(entitlementProvider.notifier).buyPro(),
                child: Text(
                  product == null
                      ? 'المتجر غير متاح حاليًا'
                      : 'شراء النسخة الكاملة — ${product.price}',
                ),
              ),
              TextButton(
                onPressed: () =>
                    ref.read(entitlementProvider.notifier).restore(),
                child: const Text('استعادة مشترياتي'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: StudioTokens.oasis, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
