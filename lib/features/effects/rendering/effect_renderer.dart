import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:sticker_studio_ai/features/editor/domain/models/layer.dart';
import 'package:sticker_studio_ai/features/effects/domain/effect.dart';

/// Paints a single layer with its effect stack onto a Canvas in 512x512
/// sticker space. This class is used by BOTH the live editor (via
/// CustomPainter) and the exporter (via PictureRecorder → raster frames),
/// which guarantees what you preview is exactly what WhatsApp receives.
class EffectRenderer {
  const EffectRenderer();

  void paintLayer(
    Canvas canvas,
    Layer layer, {
    required Duration clock,
    ui.Image? imageCache,
  }) {
    if (!layer.visible || layer.opacity == 0) return;

    canvas.save();
    _applyTransform(canvas, layer);

    switch (layer) {
      case TextLayer():
        _paintText(canvas, layer, clock);
      case ImageLayer():
        if (imageCache != null) _paintImage(canvas, layer, imageCache, clock);
    }
    canvas.restore();
  }

  void _applyTransform(Canvas canvas, Layer layer) {
    final t = layer.transform;
    canvas.translate(t.position.dx, t.position.dy);
    canvas.rotate(t.rotation);
    canvas.scale(
      t.scale * (t.flipX ? -1 : 1),
      t.scale * (t.flipY ? -1 : 1),
    );
  }

  // -- Text -----------------------------------------------------------------

  void _paintText(Canvas canvas, TextLayer layer, Duration clock) {
    final painter = _layoutText(layer);
    final size = Size(painter.width, painter.height);
    final origin = Offset(-size.width / 2, -size.height / 2);

    // Behind-layer effects (shadows, glows) — painted first, blurred.
    for (final fx in layer.effects.where((e) => e.enabled)) {
      switch (fx.type) {
        case EffectType.shadow:
          _paintTextCopy(canvas, layer,
              offset: origin +
                  Offset(math.cos(fx.angle), math.sin(fx.angle)) *
                      (fx.radius * 40),
              color: fx.color.withOpacity(fx.intensity),
              blurSigma: fx.radius * 12);
        case EffectType.glow || EffectType.outerGlow:
          final pulse = fx.type == EffectType.glow && layer.animation != null
              ? 0.75 + 0.25 * math.sin(clock.inMilliseconds / 300)
              : 1.0;
          _paintTextCopy(canvas, layer,
              offset: origin,
              color: fx.color.withOpacity(fx.intensity * pulse),
              blurSigma: 4 + fx.radius * 24);
        case EffectType.outline:
          _paintTextCopy(canvas, layer,
              offset: origin,
              color: fx.color,
              stroke: 1 + fx.radius * 14);
        default:
          break; // shader/particle effects handled below or by overlays
      }
    }

    // Main fill (solid / gradient / metallic presets).
    final fillPainter = _layoutText(layer, shader: _fillShader(layer, size));
    _withPathMode(canvas, layer, size, () {
      fillPainter.paint(canvas, origin);
    });

    // Bevel highlight: light-from-above inner edge, cheap approximation.
    final bevel = layer.effects
        .where((e) => e.enabled && e.type == EffectType.bevel)
        .firstOrNull;
    if (bevel != null) {
      _paintTextCopy(canvas, layer,
          offset: origin - Offset(0, bevel.radius * 4),
          color: Colors.white.withOpacity(0.35 * bevel.intensity),
          blurSigma: 1.5);
    }
  }

  TextPainter _layoutText(TextLayer layer, {Shader? shader}) {
    final style = TextStyle(
      fontFamily: layer.fontFamily,
      fontSize: layer.fontSize,
      fontWeight: FontWeight.values[
          ((layer.fontWeight / 100).round() - 1).clamp(0, 8)],
      letterSpacing: layer.letterSpacing,
      height: layer.lineHeight,
      color: shader == null ? layer.color : null,
      foreground: shader == null ? null : (Paint()..shader = shader),
    );
    return TextPainter(
      text: TextSpan(text: layer.text, style: style),
      textAlign: TextAlign.center,
      textDirection:
          layer.textDirectionRtl ? TextDirection.rtl : TextDirection.ltr,
    )..layout();
  }

  void _paintTextCopy(
    Canvas canvas,
    TextLayer layer, {
    required Offset offset,
    required Color color,
    double blurSigma = 0,
    double? stroke,
  }) {
    final paint = Paint()..color = color;
    if (blurSigma > 0) {
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);
    }
    if (stroke != null) {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeJoin = StrokeJoin.round;
    }
    final tp = TextPainter(
      text: TextSpan(
        text: layer.text,
        style: TextStyle(
          fontFamily: layer.fontFamily,
          fontSize: layer.fontSize,
          fontWeight: FontWeight.values[
              ((layer.fontWeight / 100).round() - 1).clamp(0, 8)],
          letterSpacing: layer.letterSpacing,
          height: layer.lineHeight,
          foreground: paint,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection:
          layer.textDirectionRtl ? TextDirection.rtl : TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  /// Metallic and gradient fills. Gold/silver/chrome are multi-stop linear
  /// gradients tuned to read as metal at sticker size; neon adds saturation
  /// with the glow effect expected on top.
  Shader? _fillShader(TextLayer layer, Size size) {
    final rect = Offset(-size.width / 2, -size.height / 2) & size;
    List<Color>? colors;
    switch (layer.fill) {
      case TextFill.solid:
        return null;
      case TextFill.gradient:
        colors = layer.gradientColors.length >= 2
            ? layer.gradientColors
            : [layer.color, layer.color.withOpacity(0.6)];
      case TextFill.gold:
        colors = const [
          Color(0xFF7A5A17),
          Color(0xFFFFE9A8),
          Color(0xFFC9A24B),
          Color(0xFFFFF6D8),
          Color(0xFF8A6A20),
        ];
      case TextFill.silver:
        colors = const [
          Color(0xFF5C5F66),
          Color(0xFFF2F4F8),
          Color(0xFFB8BCC4),
          Color(0xFFFFFFFF),
          Color(0xFF6E7178),
        ];
      case TextFill.chrome:
        colors = const [
          Color(0xFF2E3138),
          Color(0xFFEFF3F8),
          Color(0xFF9AA3AE),
          Color(0xFF1C1E24),
          Color(0xFFD7DDE5),
        ];
      case TextFill.neon:
        colors = [layer.color, Colors.white, layer.color];
      case TextFill.glass:
        colors = [
          Colors.white.withOpacity(0.85),
          Colors.white.withOpacity(0.25),
          Colors.white.withOpacity(0.6),
        ];
    }
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
    ).createShader(rect);
  }

  /// Curved text / text-on-path. For arcs we transform per-glyph; for the
  /// v1 fast path we approximate with a canvas skew for wave and rotation
  /// composition for arcs, upgraded to per-glyph layout in the text engine.
  void _withPathMode(
      Canvas canvas, TextLayer layer, Size size, VoidCallback paint) {
    switch (layer.pathMode) {
      case TextPathMode.none:
        paint();
      case TextPathMode.arcUp || TextPathMode.arcDown || TextPathMode.circle:
        _paintTextOnArc(canvas, layer);
      case TextPathMode.wave:
        canvas.save();
        canvas.skew(0, 0.12 * layer.pathCurvature);
        paint();
        canvas.restore();
    }
  }

  void _paintTextOnArc(Canvas canvas, TextLayer layer) {
    // العربية حروفها متصلة، فتقسيمها حرفًا حرفًا على القوس يكسر الاتصال.
    // الحل: نقسّم النص العربي إلى كلمات كاملة (تبقى حروف كل كلمة متصلة)
    // ونوزّع الكلمات على القوس، بينما الإنجليزية تُوزّع حرفًا حرفًا.
    final List<String> chars = layer.textDirectionRtl
        ? layer.text.split(' ').where((w) => w.isNotEmpty).toList()
        : layer.text.characters.toList();
    if (chars.isEmpty) return;
    if (layer.textDirectionRtl && chars.length == 1) {
      // كلمة واحدة: نرسمها كاملة بدون تقويس حفاظًا على شكل الحروف.
      final tp = TextPainter(
        text: TextSpan(
          text: layer.text,
          style: TextStyle(
            fontFamily: layer.fontFamily,
            fontSize: layer.fontSize,
            color: layer.color,
            fontWeight: FontWeight.values[
                ((layer.fontWeight / 100).round() - 1).clamp(0, 8)],
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      return;
    }
    final direction =
        layer.textDirectionRtl ? chars.reversed.toList() : chars;
    final radius = 90 + (1 - layer.pathCurvature) * 240;
    final sweep = layer.pathMode == TextPathMode.circle
        ? 2 * math.pi
        : math.pi * (0.4 + layer.pathCurvature * 0.6);
    final up = layer.pathMode != TextPathMode.arcDown;
    final start = -math.pi / 2 - sweep / 2;

    for (var i = 0; i < direction.length; i++) {
      final t = direction.length == 1 ? 0.5 : i / (direction.length - 1);
      final angle = start + sweep * t;
      final pos = Offset(math.cos(angle), math.sin(angle)) *
          (up ? radius : -radius);
      canvas.save();
      canvas.translate(pos.dx, pos.dy + (up ? radius * 0.4 : -radius * 0.4));
      canvas.rotate(angle + math.pi / 2 * (up ? 1 : -1));
      final glyph = TextPainter(
        text: TextSpan(
          text: direction[i],
          style: TextStyle(
            fontFamily: layer.fontFamily,
            fontSize: layer.fontSize,
            color: layer.color,
            fontWeight: FontWeight.values[
                ((layer.fontWeight / 100).round() - 1).clamp(0, 8)],
          ),
        ),
        textDirection:
            layer.textDirectionRtl ? TextDirection.rtl : TextDirection.ltr,
      )..layout();
      glyph.paint(canvas, Offset(-glyph.width / 2, -glyph.height / 2));
      canvas.restore();
    }
  }

  // -- Images ---------------------------------------------------------------

  void _paintImage(
      Canvas canvas, ImageLayer layer, ui.Image image, Duration clock) {
    final src = layer.cropRect == null
        ? Rect.fromLTWH(
            0, 0, image.width.toDouble(), image.height.toDouble())
        : Rect.fromLTRB(
            layer.cropRect!.left * image.width,
            layer.cropRect!.top * image.height,
            layer.cropRect!.right * image.width,
            layer.cropRect!.bottom * image.height,
          );
    final aspect = src.width / src.height;
    final w = 320.0;
    final dst = Rect.fromCenter(
        center: Offset.zero, width: w, height: w / aspect);

    for (final fx in layer.effects.where((e) => e.enabled)) {
      if (fx.type == EffectType.shadow) {
        canvas.drawRect(
          dst.shift(Offset(math.cos(fx.angle), math.sin(fx.angle)) *
              (fx.radius * 40)),
          Paint()
            ..color = fx.color.withOpacity(fx.intensity * 0.8)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, fx.radius * 16),
        );
      }
    }

    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..color = Colors.white.withOpacity(layer.opacity);
    final blur = layer.effects
        .where((e) => e.enabled && e.type == EffectType.blur)
        .firstOrNull;
    if (blur != null) {
      paint.imageFilter =
          ui.ImageFilter.blur(sigmaX: blur.radius * 10, sigmaY: blur.radius * 10);
    }
    canvas.drawImageRect(image, src, dst, paint);
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
