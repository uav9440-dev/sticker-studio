import 'dart:ui';

import 'package:uuid/uuid.dart';

import 'package:sticker_studio_ai/features/animation/domain/animation_spec.dart';
import 'package:sticker_studio_ai/features/editor/domain/models/layer.dart';
import 'package:sticker_studio_ai/features/editor/domain/models/project.dart';
import 'package:sticker_studio_ai/features/effects/domain/effect.dart';

/// AI design assistant. Architecture is two-tier:
///  1. [LocalDesignEngine] — an offline rule engine that maps prompt intents
///     (occasion, mood, palette keywords in Arabic/English) to a complete
///     design: typography, fills, effects, animation. Instant, free, private.
///  2. [RemoteDesignBackend] — optional LLM/image backend for free-form
///     prompts and AI image generation, injected behind the same interface
///     so the app works fully offline and upgrades gracefully.
abstract interface class AiDesignService {
  Future<StickerProject> designFromPrompt(String prompt);
}

class LocalDesignEngine implements AiDesignService {
  const LocalDesignEngine();
  static const _uuid = Uuid();

  @override
  Future<StickerProject> designFromPrompt(String prompt) async {
    final p = prompt.toLowerCase();
    final occasion = _occasion(p);
    final luxury = _hasAny(p, ['فاخر', 'ذهبي', 'luxury', 'gold', 'golden']);
    final neon = _hasAny(p, ['نيون', 'neon', 'rgb', 'gaming', 'قيمنق']);

    final layer = TextLayer(
      id: _uuid.v4(),
      transform: const LayerTransform(),
      text: occasion.text,
      fontFamily: luxury ? 'Aref Ruqaa' : (neon ? 'Bebas Neue' : 'Cairo'),
      fontSize: 72,
      fill: luxury
          ? TextFill.gold
          : neon
              ? TextFill.neon
              : TextFill.gradient,
      color: neon ? const Color(0xFF00E5FF) : occasion.accent,
      gradientColors: [occasion.accent, occasion.accentB],
      effects: [
        if (luxury)
          const LayerEffect(
              type: EffectType.shadow, intensity: 0.6, radius: 0.25),
        if (luxury)
          const LayerEffect(
              type: EffectType.sparkles, intensity: 0.5, speed: 0.4),
        if (neon)
          LayerEffect(
              type: EffectType.glow,
              intensity: 0.9,
              radius: 0.5,
              color: const Color(0xFF00E5FF)),
      ],
      animation: AnimationSpec(
        preset: luxury ? AnimPreset.glowPulse : AnimPreset.pop,
        duration: const Duration(milliseconds: 1400),
      ),
    );

    return StickerProject(
      id: _uuid.v4(),
      title: occasion.text,
      layers: [layer],
      createdAt: DateTime.now(),
    );
  }

  _Occasion _occasion(String p) {
    if (_hasAny(p, ['صباح', 'morning'])) {
      return const _Occasion(
          'صباح الخير', Color(0xFFC9A24B), Color(0xFFFFE9A8));
    }
    if (_hasAny(p, ['مساء', 'evening'])) {
      return const _Occasion(
          'مساء الخير', Color(0xFF5C6BC0), Color(0xFF9FA8DA));
    }
    if (_hasAny(p, ['جمعة', 'friday'])) {
      return const _Occasion(
          'جمعة مباركة', Color(0xFF2E6E5E), Color(0xFFC9A24B));
    }
    if (_hasAny(p, ['رمضان', 'ramadan'])) {
      return const _Occasion(
          'رمضان كريم', Color(0xFF4527A0), Color(0xFFC9A24B));
    }
    if (_hasAny(p, ['عيد', 'eid'])) {
      return const _Occasion(
          'عيد مبارك', Color(0xFFC9A24B), Color(0xFF2E6E5E));
    }
    if (_hasAny(p, ['حب', 'love'])) {
      return const _Occasion('أحبك', Color(0xFFE53935), Color(0xFFFF8A80));
    }
    if (_hasAny(p, ['مبروك', 'congrat'])) {
      return const _Occasion(
          'ألف مبروك', Color(0xFFC9A24B), Color(0xFFE53935));
    }
    return const _Occasion('✨', Color(0xFFC9A24B), Color(0xFFFFE9A8));
  }

  bool _hasAny(String p, List<String> keys) => keys.any(p.contains);
}

class _Occasion {
  const _Occasion(this.text, this.accent, this.accentB);
  final String text;
  final Color accent;
  final Color accentB;
}

/// Contract for a remote backend (LLM design generation, text-to-image,
/// server-side background removal). Implementations live in data/ and are
/// swapped via Riverpod override — the rest of the app never knows.
abstract interface class RemoteDesignBackend {
  Future<StickerProject?> generateDesign(String prompt);
  Future<String?> generateImage(String prompt); // returns local file path
  Future<String?> removeBackground(String imagePath);
  Future<String?> enhanceImage(String imagePath);
}
