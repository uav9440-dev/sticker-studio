/// Hard requirements enforced by WhatsApp for sticker packs.
/// Every export path in the app validates against these before writing files.
abstract final class WhatsAppSpecs {
  /// Canvas size for all stickers (px). Both dimensions must be exactly 512.
  static const int stickerSize = 512;

  /// Static stickers must be WebP and <= 100 KB.
  static const int maxStaticBytes = 100 * 1024;

  /// Animated stickers must be animated WebP and <= 500 KB.
  static const int maxAnimatedBytes = 500 * 1024;

  /// Animated stickers: total duration <= 10s, min frame duration 8ms.
  static const Duration maxAnimationDuration = Duration(seconds: 10);
  static const Duration minFrameDuration = Duration(milliseconds: 8);

  /// Tray icon: 96x96 PNG, <= 50 KB.
  static const int trayIconSize = 96;
  static const int maxTrayBytes = 50 * 1024;

  /// A pack must contain between 3 and 30 stickers.
  static const int minPackStickers = 3;
  static const int maxPackStickers = 30;

  /// Recommended transparent margin around artwork (px) so stickers
  /// don't touch the bubble edge in chat.
  static const int safeMargin = 16;
}
