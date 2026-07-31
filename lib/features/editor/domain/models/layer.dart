import 'dart:ui';

import 'package:sticker_studio_ai/features/animation/domain/animation_spec.dart';
import 'package:sticker_studio_ai/features/effects/domain/effect.dart';

/// Every element on the canvas is a [Layer]. Layers are immutable: edits
/// produce new instances, which makes undo/redo and thumbnail diffing trivial.
sealed class Layer {
  const Layer({
    required this.id,
    required this.transform,
    this.opacity = 1.0,
    this.locked = false,
    this.visible = true,
    this.effects = const [],
    this.animation,
    this.name = '',
  });

  final String id;
  final LayerTransform transform;
  final double opacity;
  final bool locked;
  final bool visible;

  /// Ordered effect stack (glow, shadow, bevel, gradient overlay, …).
  final List<LayerEffect> effects;

  /// Optional animation applied to this layer at export/preview time.
  final AnimationSpec? animation;
  final String name;

  Layer copyWith({
    LayerTransform? transform,
    double? opacity,
    bool? locked,
    bool? visible,
    List<LayerEffect>? effects,
    AnimationSpec? animation,
    bool clearAnimation = false,
    String? name,
  });

  Map<String, dynamic> toJson();

  static Layer fromJson(Map<String, dynamic> json) => switch (json['type']) {
        'text' => TextLayer.fromJson(json),
        'image' => ImageLayer.fromJson(json),
        _ => throw ArgumentError('Unknown layer type ${json['type']}'),
      };
}

/// Position/scale/rotation/flip in canvas coordinates (512x512 space).
class LayerTransform {
  const LayerTransform({
    this.position = const Offset(256, 256),
    this.scale = 1.0,
    this.rotation = 0.0, // radians
    this.flipX = false,
    this.flipY = false,
  });

  final Offset position;
  final double scale;
  final double rotation;
  final bool flipX;
  final bool flipY;

  LayerTransform copyWith({
    Offset? position,
    double? scale,
    double? rotation,
    bool? flipX,
    bool? flipY,
  }) =>
      LayerTransform(
        position: position ?? this.position,
        scale: scale ?? this.scale,
        rotation: rotation ?? this.rotation,
        flipX: flipX ?? this.flipX,
        flipY: flipY ?? this.flipY,
      );

  Map<String, dynamic> toJson() => {
        'x': position.dx,
        'y': position.dy,
        'scale': scale,
        'rotation': rotation,
        'flipX': flipX,
        'flipY': flipY,
      };

  factory LayerTransform.fromJson(Map<String, dynamic> j) => LayerTransform(
        position: Offset((j['x'] as num).toDouble(), (j['y'] as num).toDouble()),
        scale: (j['scale'] as num).toDouble(),
        rotation: (j['rotation'] as num).toDouble(),
        flipX: j['flipX'] as bool? ?? false,
        flipY: j['flipY'] as bool? ?? false,
      );
}

// ---------------------------------------------------------------------------
// Text layer
// ---------------------------------------------------------------------------

enum TextFill { solid, gradient, gold, silver, chrome, neon, glass }

enum TextPathMode { none, arcUp, arcDown, circle, wave }

class TextLayer extends Layer {
  const TextLayer({
    required super.id,
    required super.transform,
    required this.text,
    this.fontFamily = 'Cairo',
    this.fontSize = 64,
    this.fontWeight = 700,
    this.letterSpacing = 0,
    this.lineHeight = 1.2,
    this.fill = TextFill.solid,
    this.color = const Color(0xFFFFFFFF),
    this.gradientColors = const [],
    this.pathMode = TextPathMode.none,
    this.pathCurvature = 0.5, // 0..1 — how tight the arc/wave is
    this.textDirectionRtl = true,
    super.opacity,
    super.locked,
    super.visible,
    super.effects,
    super.animation,
    super.name,
  });

  final String text;
  final String fontFamily;
  final double fontSize;
  final int fontWeight;
  final double letterSpacing;
  final double lineHeight;
  final TextFill fill;
  final Color color;
  final List<Color> gradientColors;
  final TextPathMode pathMode;
  final double pathCurvature;
  final bool textDirectionRtl;

  @override
  TextLayer copyWith({
    LayerTransform? transform,
    double? opacity,
    bool? locked,
    bool? visible,
    List<LayerEffect>? effects,
    AnimationSpec? animation,
    bool clearAnimation = false,
    String? name,
    String? text,
    String? fontFamily,
    double? fontSize,
    int? fontWeight,
    double? letterSpacing,
    double? lineHeight,
    TextFill? fill,
    Color? color,
    List<Color>? gradientColors,
    TextPathMode? pathMode,
    double? pathCurvature,
    bool? textDirectionRtl,
  }) =>
      TextLayer(
        id: id,
        transform: transform ?? this.transform,
        opacity: opacity ?? this.opacity,
        locked: locked ?? this.locked,
        visible: visible ?? this.visible,
        effects: effects ?? this.effects,
        animation: clearAnimation ? null : (animation ?? this.animation),
        name: name ?? this.name,
        text: text ?? this.text,
        fontFamily: fontFamily ?? this.fontFamily,
        fontSize: fontSize ?? this.fontSize,
        fontWeight: fontWeight ?? this.fontWeight,
        letterSpacing: letterSpacing ?? this.letterSpacing,
        lineHeight: lineHeight ?? this.lineHeight,
        fill: fill ?? this.fill,
        color: color ?? this.color,
        gradientColors: gradientColors ?? this.gradientColors,
        pathMode: pathMode ?? this.pathMode,
        pathCurvature: pathCurvature ?? this.pathCurvature,
        textDirectionRtl: textDirectionRtl ?? this.textDirectionRtl,
      );

  @override
  Map<String, dynamic> toJson() => {
        'type': 'text',
        'id': id,
        'transform': transform.toJson(),
        'opacity': opacity,
        'locked': locked,
        'visible': visible,
        'effects': effects.map((e) => e.toJson()).toList(),
        'animation': animation?.toJson(),
        'name': name,
        'text': text,
        'fontFamily': fontFamily,
        'fontSize': fontSize,
        'fontWeight': fontWeight,
        'letterSpacing': letterSpacing,
        'lineHeight': lineHeight,
        'fill': fill.name,
        'color': color.value,
        'gradientColors': gradientColors.map((c) => c.value).toList(),
        'pathMode': pathMode.name,
        'pathCurvature': pathCurvature,
        'rtl': textDirectionRtl,
      };

  factory TextLayer.fromJson(Map<String, dynamic> j) => TextLayer(
        id: j['id'] as String,
        transform:
            LayerTransform.fromJson(j['transform'] as Map<String, dynamic>),
        opacity: (j['opacity'] as num).toDouble(),
        locked: j['locked'] as bool,
        visible: j['visible'] as bool,
        effects: (j['effects'] as List)
            .map((e) => LayerEffect.fromJson(e as Map<String, dynamic>))
            .toList(),
        animation: j['animation'] == null
            ? null
            : AnimationSpec.fromJson(j['animation'] as Map<String, dynamic>),
        name: j['name'] as String? ?? '',
        text: j['text'] as String,
        fontFamily: j['fontFamily'] as String,
        fontSize: (j['fontSize'] as num).toDouble(),
        fontWeight: j['fontWeight'] as int,
        letterSpacing: (j['letterSpacing'] as num).toDouble(),
        lineHeight: (j['lineHeight'] as num).toDouble(),
        fill: TextFill.values.byName(j['fill'] as String),
        color: Color(j['color'] as int),
        gradientColors:
            (j['gradientColors'] as List).map((v) => Color(v as int)).toList(),
        pathMode: TextPathMode.values.byName(j['pathMode'] as String),
        pathCurvature: (j['pathCurvature'] as num).toDouble(),
        textDirectionRtl: j['rtl'] as bool? ?? true,
      );
}

// ---------------------------------------------------------------------------
// Image layer
// ---------------------------------------------------------------------------

class ImageLayer extends Layer {
  const ImageLayer({
    required super.id,
    required super.transform,
    required this.sourcePath,
    this.processedPath,
    this.cropRect,
    super.opacity,
    super.locked,
    super.visible,
    super.effects,
    super.animation,
    super.name,
  });

  /// Original file the user imported (PNG/JPG/WEBP).
  final String sourcePath;

  /// Cached path after background removal / enhancement, if applied.
  final String? processedPath;

  /// Normalized crop rect (0..1 in source image space).
  final Rect? cropRect;

  String get effectivePath => processedPath ?? sourcePath;

  @override
  ImageLayer copyWith({
    LayerTransform? transform,
    double? opacity,
    bool? locked,
    bool? visible,
    List<LayerEffect>? effects,
    AnimationSpec? animation,
    bool clearAnimation = false,
    String? name,
    String? sourcePath,
    String? processedPath,
    bool clearProcessed = false,
    Rect? cropRect,
  }) =>
      ImageLayer(
        id: id,
        transform: transform ?? this.transform,
        opacity: opacity ?? this.opacity,
        locked: locked ?? this.locked,
        visible: visible ?? this.visible,
        effects: effects ?? this.effects,
        animation: clearAnimation ? null : (animation ?? this.animation),
        name: name ?? this.name,
        sourcePath: sourcePath ?? this.sourcePath,
        processedPath:
            clearProcessed ? null : (processedPath ?? this.processedPath),
        cropRect: cropRect ?? this.cropRect,
      );

  @override
  Map<String, dynamic> toJson() => {
        'type': 'image',
        'id': id,
        'transform': transform.toJson(),
        'opacity': opacity,
        'locked': locked,
        'visible': visible,
        'effects': effects.map((e) => e.toJson()).toList(),
        'animation': animation?.toJson(),
        'name': name,
        'sourcePath': sourcePath,
        'processedPath': processedPath,
        'crop': cropRect == null
            ? null
            : [cropRect!.left, cropRect!.top, cropRect!.right, cropRect!.bottom],
      };

  factory ImageLayer.fromJson(Map<String, dynamic> j) => ImageLayer(
        id: j['id'] as String,
        transform:
            LayerTransform.fromJson(j['transform'] as Map<String, dynamic>),
        opacity: (j['opacity'] as num).toDouble(),
        locked: j['locked'] as bool,
        visible: j['visible'] as bool,
        effects: (j['effects'] as List)
            .map((e) => LayerEffect.fromJson(e as Map<String, dynamic>))
            .toList(),
        animation: j['animation'] == null
            ? null
            : AnimationSpec.fromJson(j['animation'] as Map<String, dynamic>),
        name: j['name'] as String? ?? '',
        sourcePath: j['sourcePath'] as String,
        processedPath: j['processedPath'] as String?,
        cropRect: j['crop'] == null
            ? null
            : Rect.fromLTRB(
                (j['crop'][0] as num).toDouble(),
                (j['crop'][1] as num).toDouble(),
                (j['crop'][2] as num).toDouble(),
                (j['crop'][3] as num).toDouble(),
              ),
      );
}
