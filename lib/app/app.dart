import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sticker_studio_ai/app/router.dart';
import 'package:sticker_studio_ai/app/theme/app_theme.dart';
import 'package:sticker_studio_ai/l10n/app_localizations.dart';

/// Locale + theme mode live in simple providers (persisted to
/// SharedPreferences in the settings repository).
final localeProvider = StateProvider<Locale>((_) => const Locale('ar'));
final themeModeProvider = StateProvider<ThemeMode>((_) => ThemeMode.system);
final dynamicColorProvider = StateProvider<bool>((_) => true);

class StickerStudioApp extends ConsumerWidget {
  const StickerStudioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final mode = ref.watch(themeModeProvider);
    final useDynamic = ref.watch(dynamicColorProvider);

    // Material You: harvest wallpaper scheme when available and enabled.
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) => MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        routerConfig: appRouter,
        themeMode: mode,
        theme: AppTheme.light(useDynamic ? lightDynamic : null),
        darkTheme: AppTheme.dark(useDynamic ? darkDynamic : null),
        locale: locale, // 'ar' default → full RTL layout
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
