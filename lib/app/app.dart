import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sticker_studio_ai/app/router.dart';
import 'package:sticker_studio_ai/app/theme/app_theme.dart';
import 'package:sticker_studio_ai/l10n/app_localizations.dart';

final localeProvider = StateProvider<Locale>((_) => const Locale('ar'));
final themeModeProvider = StateProvider<ThemeMode>((_) => ThemeMode.system);
final dynamicColorProvider = StateProvider<bool>((_) => true);

class StickerStudioApp extends ConsumerStatefulWidget {
  const StickerStudioApp({super.key, required this.showWelcome});
  final bool showWelcome;

  @override
  ConsumerState<StickerStudioApp> createState() => _StickerStudioAppState();
}

class _StickerStudioAppState extends ConsumerState<StickerStudioApp> {
  // نُنشئ الموجّه مرة واحدة حتى لا يفقد التنقل حالته عند تغيير اللغة/الثيم.
  late final GoRouter _router =
      createRouter(showWelcome: widget.showWelcome);

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final mode = ref.watch(themeModeProvider);
    final useDynamic = ref.watch(dynamicColorProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) => MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        routerConfig: _router,
        themeMode: mode,
        theme: AppTheme.light(useDynamic ? lightDynamic : null),
        darkTheme: AppTheme.dark(useDynamic ? darkDynamic : null),
        locale: locale,
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
