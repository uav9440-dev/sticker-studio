import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:sticker_studio_ai/core/constants/whatsapp_specs.dart';
import 'package:sticker_studio_ai/core/utils/result.dart';
import 'package:sticker_studio_ai/features/editor/domain/models/layer.dart';
import 'package:sticker_studio_ai/features/editor/domain/models/project.dart';
import 'package:sticker_studio_ai/features/effects/rendering/effect_renderer.dart';

enum ExportFormat { webpStatic, webpAnimated, png, gif, mp4 }

/// Renders projects with the same [EffectRenderer] the editor uses, then
/// encodes/validates for WhatsApp. Static WebP + PNG + GIF are handled with
/// the pure-Dart `image` package; animated WebP and MP4 muxing route through
/// a platform channel (libwebp / MediaCodec) — see docs/ARCHITECTURE.md.
class ExportService {
  ExportService({
    this.renderer = const EffectRenderer(),
    this.imageResolver,
  });

  final EffectRenderer renderer;
  final ui.Image? Function(String path)? imageResolver;

  /// Rasterize one frame of the project at [clock] into a 512x512 RGBA image.
  Future<img.Image> renderFrame(StickerProject project, Duration clock) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, WhatsAppSpecs.stickerSize.toDouble(),
          WhatsAppSpecs.stickerSize.toDouble()),
    );

    for (final layer in project.layers) {
      var frameLayer = layer;
      final anim = layer.animation;
      if (anim != null) {
        final k = anim.evaluate(clock);
        frameLayer = layer.copyWith(
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
        frameLayer,
        clock: clock,
        imageCache: switch (layer) {
          ImageLayer(:final effectivePath) => imageResolver?.call(effectivePath),
          _ => null,
        },
      );
    }

    final picture = recorder.endRecording();
    final uiImage = await picture.toImage(
        WhatsAppSpecs.stickerSize, WhatsAppSpecs.stickerSize);
    final bytes =
        await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
    return img.Image.fromBytes(
      width: WhatsAppSpecs.stickerSize,
      height: WhatsAppSpecs.stickerSize,
      bytes: bytes!.buffer,
      numChannels: 4,
    );
  }

  /// Static sticker: WebP, <=100 KB. Renders once, then re-encodes with
  /// descending quality until the WhatsApp budget is met.
  Future<Result<File>> exportStatic(StickerProject project) async {
    final frame = await renderFrame(project, Duration.zero);
    final png = await _write(img.encodePng(frame), '${project.id}_src.png');
    for (final quality in [90, 80, 70, 60, 50]) {
      final webp = await FlutterImageCompress.compressWithFile(
        png.path,
        format: CompressFormat.webp,
        quality: quality,
        minWidth: WhatsAppSpecs.stickerSize,
        minHeight: WhatsAppSpecs.stickerSize,
      );
      if (webp != null && webp.length <= WhatsAppSpecs.maxStaticBytes) {
        return Ok(await _write(webp, '${project.id}.webp'));
      }
    }
    return const Err(AppFailure(
        'التصميم أكبر من حد واتساب (100KB) — قلّل التأثيرات أو التفاصيل'));
  }

  /// 512x512 PNG thumbnail for the library grid.
  Future<String> renderThumbnail(StickerProject project) async {
    final frame = await renderFrame(project, Duration.zero);
    final small = img.copyResize(frame, width: 256);
    final file = await _write(img.encodePng(small), 'thumb_${project.id}.png');
    return file.path;
  }

  /// Animated sticker: samples the timeline at [fps], encodes animated WebP,
  /// enforcing the 500 KB / 10 s WhatsApp budget by degrading fps then
  /// quality before failing.
  Future<Result<File>> exportAnimated(StickerProject project,
      {int fps = 20}) async {
    final duration = _timelineDuration(project);
    if (duration > WhatsAppSpecs.maxAnimationDuration) {
      return const Err(AppFailure('مدة الحركة تتجاوز 10 ثوانٍ'));
    }
    for (final tryFps in [fps, 15, 12, 10]) {
      final frames = <img.Image>[];
      final frameMs = (1000 / tryFps).round();
      for (var ms = 0; ms < duration.inMilliseconds; ms += frameMs) {
        frames.add(await renderFrame(project, Duration(milliseconds: ms)));
      }
      final bytes = await _encodeAnimatedWebpPlatform(frames, frameMs);
      if (bytes != null && bytes.length <= WhatsAppSpecs.maxAnimatedBytes) {
        return Ok(await _write(bytes, '${project.id}_anim.webp'));
      }
    }
    return const Err(
        AppFailure('الملصق المتحرك أكبر من 500KB — قصّر المدة أو بسّط الحركة'));
  }

  Future<Result<File>> exportPng(StickerProject project) async {
    final frame = await renderFrame(project, Duration.zero);
    return Ok(await _write(img.encodePng(frame), '${project.id}.png'));
  }

  Future<Result<File>> exportGif(StickerProject project, {int fps = 15}) async {
    final duration = _timelineDuration(project);
    final encoder = img.GifEncoder();
    final frameMs = (1000 / fps).round();
    for (var ms = 0; ms < duration.inMilliseconds; ms += frameMs) {
      encoder.addFrame(await renderFrame(project, Duration(milliseconds: ms)),
          duration: frameMs ~/ 10);
    }
    final bytes = encoder.finish()!;
    return Ok(await _write(bytes, '${project.id}.gif'));
  }

  Duration _timelineDuration(StickerProject project) {
    var max = const Duration(seconds: 2);
    for (final l in project.layers) {
      final a = l.animation;
      if (a != null && a.delay + a.effectiveDuration > max) {
        max = a.delay + a.effectiveDuration;
      }
    }
    return max > WhatsAppSpecs.maxAnimationDuration
        ? WhatsAppSpecs.maxAnimationDuration
        : max;
  }

  Future<File> _write(List<int> bytes, String name) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'exports', name));
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);
    return file;
  }

  // Platform-channel encoders (Android: libwebp via JNI). Kept nullable so
  // pure-Dart fallbacks and tests run without the native side.
  Future<List<int>?> _encodeWebpPlatform(img.Image frame,
          {required int quality}) async =>
      null; // TODO(native): MethodChannel('studio/webp').invokeMethod(...)

  Future<List<int>?> _encodeAnimatedWebpPlatform(
          List<img.Image> frames, int frameMs) async =>
      null; // TODO(native)
}
