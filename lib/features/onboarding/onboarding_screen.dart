import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sticker_studio_ai/app/theme/app_theme.dart';

/// شاشة الترحيب + الشروط والأحكام — تظهر مرة واحدة عند أول تشغيل.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _agreed = false;

  static const _terms = '''
مرحبًا بك في استوديو الملصقات ✨

باستخدامك التطبيق فأنت توافق على الشروط التالية:

١. الاستخدام: التطبيق مخصص لتصميم ملصقات شخصية. أنت مسؤول عن المحتوى الذي تصممه، ويُمنع استخدام التطبيق لإنشاء محتوى مسيء أو مخالف للأنظمة أو ينتهك حقوق الآخرين.

٢. التجربة المجانية والشراء: تحصل على تجربة مجانية كاملة لمدة ٣ أيام من أول تشغيل. بعدها تتطلب ميزات التصدير والمساعد الذكي شراء النسخة الكاملة (دفعة واحدة عبر Google Play). عمليات الشراء تُدار بواسطة جوجل ويمكن استعادتها على أي جهاز بنفس الحساب.

٣. الملكية الفكرية: التصاميم التي تنشئها ملك لك. الخطوط والقوالب المضمّنة مرخّصة للاستخدام داخل التطبيق.

٤. الخصوصية: تصاميمك تُحفظ على جهازك فقط ولا نرفع بياناتك إلى خوادمنا. عمليات الشراء تخضع لسياسة خصوصية Google Play.

٥. إخلاء المسؤولية: يُقدَّم التطبيق كما هو، ونعمل باستمرار على تحسينه، دون ضمان خلوّه التام من الأخطاء.

٦. التحديثات: قد تتغير هذه الشروط مع التحديثات المستقبلية وسيتم إشعارك داخل التطبيق.
''';

  Future<void> _accept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('terms_accepted', true);
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // شعار ترحيبي ذهبي
              Container(
                width: 84,
                height: 84,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFC9A24B), Color(0xFFFFE9A8)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: StudioTokens.gold.withOpacity(0.45),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome,
                    size: 42, color: StudioTokens.obsidian),
              ),
              const SizedBox(height: 20),
              Text(
                'أهلًا بك في استوديو الملصقات',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'صمّم ملصقات واتساب مبهرة — نصوص ذهبية، تأثيرات، وحركات، كل ذلك من جوالك.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Card(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Text('الشروط والأحكام\n$_terms',
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.7)),
                  ),
                ),
              ),
              CheckboxListTile(
                value: _agreed,
                onChanged: (v) => setState(() => _agreed = v ?? false),
                title: const Text('قرأت الشروط والأحكام وأوافق عليها'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              FilledButton.icon(
                onPressed: _agreed ? _accept : null,
                icon: const Icon(Icons.rocket_launch_outlined),
                label: const Text('ابدأ التصميم'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
