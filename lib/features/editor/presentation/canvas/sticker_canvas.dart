import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sticker_studio_ai/core/constants/whatsapp_specs.dart';
import 'package:sticker_studio_ai/features/editor/application/editor_controller.dart';
import 'package:sticker_studio_ai/features/editor/domain/models/layer.dart';
import 'package:sticker_studio_ai/features/effects/rendering/effect_renderer.dart';

/// The 512x512 sticker canvas. Wrapped in InteractiveViewer for pinch-zoom of
/// the workspace; layer gestures (drag / pinch-scale / two-finger rotate) are
/// handled inside so zooming the canvas and manipulating a layer never fight.
class StickerCanvas extends ConsumerStatefulWidget {
  const StickerCanvas({super.key, this.imageResolver});

  /// Resolves ImageLayer paths to decoded images (with an LRU cache) —
  /// injected so the canvas stays testable.
  final ui.Image? Function(String path)? imageResolver;

  @override
  ConsumerState<StickerCanvas> createState() => _StickerCanvasState();
}

class _StickerCanvasState extends ConsumerState<StickerCanvas>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Offset? _lastFocal;
  double _lastScale = 1;
  double _lastRotation = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final s = ref.read(editorControllerProvider);
      if (s.playing || s.project.isAnimated) {
        ref.read(editorControllerProvider.notifier).tick(elapsed);
      }
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorControllerProvider);
    final controller = ref.read(editorControllerProvider.notifier);

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 8,
      // Canvas pan/zoom only with no layer selected; otherwise gestures
      // belong to the layer.
      panEnabled: state.selectedLayerId == null,
      scaleEnabled: state.selectedLayerId == null,
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(builder: (context, constraints) {
            final view = constraints.biggest.width;
            final toCanvas = WhatsAppSpecs.stickerSize / view;

            return GestureDetector(
              onTapDown: (d) => _hitSelect(d.localPosition * toCanvas),
              onScaleStart: (d) {
                _lastFocal = d.localFocalPoint;
                _lastScale = 1;
                _lastRotation = 0;
              },
              onScaleUpdate: (d) {
                if (state.selectedLayerId == null) return;
                final focal = d.localFocalPoint;
                controller.moveSelected((focal - _lastFocal!) * toCanvas);
                if (d.pointerCount > 1) {
                  controller.scaleRotateSelected(
                    scaleFactor: d.scale / _lastScale,
                    rotationDelta: d.rotation - _lastRotation,
                  );
                  _lastScale = d.scale;
                  _lastRotation = d.rotation;
                }
                _lastFocal = focal;
              },
              onScaleEnd: (_) => controller.endGesture(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomPaint(
                  painter: _CheckerboardPainter(
                      dark: Theme.of(context).brightness == Brightness.dark),
                  foregroundPainter: _CanvasPainter(
                    state: state,
                    renderer: const EffectRenderer(),
                    imageResolver: widget.imageResolver,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  void _hitSelect(Offset canvasPoint) {
    final state = ref.read(editorControllerProvider);
    // Top-most layer whose bounding box contains the point.
    for (final layer in state.project.layers.reversed) {
      if (!layer.visible || layer.locked) continue;
      final half = 160 * layer.transform.scale; // generous hit box, v1
      if ((canvasPoint - layer.transform.position).distance < half) {
        ref.read(editorControllerProvider.notifier).select(layer.id);
        return;
      }
    }
    ref.read(editorControllerProvider.notifier).select(null);
  }
}

/// Paints all layers via [EffectRenderer], selection chrome, safe-area
/// margin, and live snap guides — scaled from 512-space to view space.
class _CanvasPainter extends CustomPainter {
  _CanvasPainter({
    required this.state,
    required this.renderer,
    this.imageResolver,
  });

  final EditorState state;
  final EffectRenderer renderer;
  final ui.Image? Function(String path)? imageResolver;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / WhatsAppSpecs.stickerSize;
    canvas.scale(s);

    for (final layer in state.project.layers) {
      // Compose animation delta for live preview.
      var animated = layer;
      final anim = layer.animation;
      if (anim != null) {
        final k = anim.evaluate(state.previewClock);
        animated = layer.copyWith(
          transform: layer.transform.copyWith(
            position: layer.transform.position + Offset(k.dx, k.dy),
            scale: layer.transform.scale * k.scale,
            rotation: layer.transform.rotation + k.rotation,
          ),
          opacity: layer.opacity * k.opacity,
        );
      }
      renderer.paintLayer(
        canvas,
        animated,
        clock: state.previewClock,
        imageCache: switch (layer) {
          ImageLayer(:final effectivePath) => imageResolver?.call(effectivePath),
          _ => null,
        },
      );
    }

    _paintSafeMargin(canvas);
    _paintSelection(canvas);
    _paintGuides(canvas);
  }

  void _paintSafeMargin(Canvas canvas) {
    const m = WhatsAppSpecs.safeMargin.toDouble();
    const size = WhatsAppSpecs.stickerSize.toDouble();
    canvas.drawRect(
      const Rect.fromLTRB(m, m, size - m, size - m),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x22FFFFFF),
    );
  }

  void _paintSelection(Canvas canvas) {
    final sel = state.selected;
    if (sel == null) return;
    canvas.save();
    canvas.translate(sel.transform.position.dx, sel.transform.position.dy);
    canvas.rotate(sel.transform.rotation);
    final half = 160 * sel.transform.scale;
    final rect = Rect.fromCenter(center: Offset.zero, width: half * 2, height: half * 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFC9A24B),
    );
    for (final corner in [
      rect.topLeft, rect.topRight, rect.bottomLeft, rect.bottomRight,
    ]) {
      canvas.drawCircle(corner, 7, Paint()..color = const Color(0xFFC9A24B));
    }
    canvas.restore();
  }

  void _paintGuides(Canvas canvas) {
    const size = WhatsAppSpecs.stickerSize.toDouble();
    final paint = Paint()
      ..color = const Color(0xFF2E6E5E)
      ..strokeWidth = 1.5;
    final v = state.guides.vertical;
    final h = state.guides.horizontal;
    if (v != null) canvas.drawLine(Offset(v, 0), Offset(v, size), paint);
    if (h != null) canvas.drawLine(Offset(0, h), Offset(size, h), paint);
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter old) => true;
}

/// Transparency checkerboard so users see exactly what's transparent.
class _CheckerboardPainter extends CustomPainter {
  const _CheckerboardPainter({required this.dark});
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final a = Paint()..color = dark ? const Color(0xFF23201B) : const Color(0xFFE8E4DA);
    final b = Paint()..color = dark ? const Color(0xFF1C1915) : const Color(0xFFF5F1E8);
    const cell = 14.0;
    for (var y = 0; y * cell < size.height; y++) {
      for (var x = 0; x * cell < size.width; x++) {
        canvas.drawRect(
          Rect.fromLTWH(x * cell, y * cell, cell, cell),
          (x + y).isEven ? a : b,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckerboardPainter old) => old.dark != dark;
}
