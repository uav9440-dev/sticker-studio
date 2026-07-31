import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design language: "المرسم الليلي" (The Night Atelier).
///
/// The identity is built for the product's own subject — gold-leaf Arabic
/// lettering on a jeweler's dark velvet. The signature element is a single
/// warm metallic gold used *only* for creation actions (new design, export,
/// AI generate); everything else stays quiet ink and bone so user artwork
/// is always the brightest thing on screen.
abstract final class StudioTokens {
  // Palette — 6 named values.
  static const obsidian = Color(0xFF12100E); // app background (dark)
  static const velvet = Color(0xFF1C1915); // elevated surfaces (dark)
  static const bone = Color(0xFFF5F1E8); // light background
  static const ink = Color(0xFF262119); // primary text on light
  static const gold = Color(0xFFC9A24B); // signature accent — creation only
  static const oasis = Color(0xFF2E6E5E); // secondary accent (success, links)

  static const radiusCard = 20.0;
  static const radiusSheet = 28.0;
}

class AppTheme {
  /// [dynamic_] is the Material You scheme from the device wallpaper.
  /// When the user enables Dynamic Colors we harmonize our gold into it
  /// instead of discarding the brand.
  static ThemeData dark([ColorScheme? dynamic_]) => _build(
        Brightness.dark,
        dynamic_ ??
            ColorScheme.fromSeed(
              seedColor: StudioTokens.gold,
              brightness: Brightness.dark,
              surface: StudioTokens.obsidian,
            ),
      );

  static ThemeData light([ColorScheme? dynamic_]) => _build(
        Brightness.light,
        dynamic_ ??
            ColorScheme.fromSeed(
              seedColor: StudioTokens.gold,
              brightness: Brightness.light,
              surface: StudioTokens.bone,
            ),
      );

  static ThemeData _build(Brightness brightness, ColorScheme scheme) {
    final harmonized = scheme.copyWith(
      primary: StudioTokens.gold.harmonizeWith(scheme.primary),
      secondary: StudioTokens.oasis.harmonizeWith(scheme.secondary),
    );
    final dark = brightness == Brightness.dark;

    // Type roles: Marhey (display, characterful Arabic) used with restraint
    // for screen titles; Cairo (body) carries the UI in both scripts;
    // IBM Plex Sans Arabic (utility) for numeric fields and captions.
    final body = GoogleFonts.cairoTextTheme(
      dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );
    final text = body.copyWith(
      displaySmall: GoogleFonts.marhey(
        textStyle: body.displaySmall,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: GoogleFonts.marhey(
        textStyle: body.headlineMedium,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: GoogleFonts.ibmPlexSansArabic(textStyle: body.labelSmall),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: harmonized,
      scaffoldBackgroundColor:
          dark ? StudioTokens.obsidian : StudioTokens.bone,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      cardTheme: CardThemeData(
        elevation: 0,
        color: dark ? StudioTokens.velvet : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StudioTokens.radiusCard),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(StudioTokens.radiusSheet),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: harmonized.primary,
          foregroundColor: dark ? StudioTokens.obsidian : Colors.white,
          minimumSize: const Size(64, 52),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
      ),
      sliderTheme: const SliderThemeData(
        year2023: false, // Material 3 expressive slider
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
    );
  }
}
