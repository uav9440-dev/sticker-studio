import 'dart:ui';

/// Full catalog of layer effects the studio supports. Effects are grouped by
/// how they are rendered:
///  * paint effects   — implemented with Canvas paints/MaskFilters (fast path)
///  * shader effects  — fragment shaders (chrome, holographic, fire, ice…)
///  * particle effects — emitters composited above the layer (sparkles, snow…)
enum EffectType {
  // Paint effects
  glow,
  shadow,
  innerShadow,
  outerGlow,
  blur,
  outline,
  bevel,
  emboss,
  gradientOverlay,
  patternOverlay,
  noise,
  vintage,
  reflection,
  motionBlur,
  // Shader effects
  holographic,
  glass,
  chrome,
  gold,
  silver,
  rainbow,
  rgbShift,
  fire,
  ice,
  smoke,
  lightSweep,
  lensFlare,
  // Particle effects
  sparkles,
  stars,
  snow,
  rain,
  lightning,
  particles,
  confetti,
  magicDust,
}

enum EffectCategory { paint, shader, particle }

extension EffectTypeX on EffectType {
  EffectCategory get category => switch (this) {
        EffectType.holographic ||
        EffectType.glass ||
        EffectType.chrome ||
        EffectType.gold ||
        EffectType.silver ||
        EffectType.rainbow ||
        EffectType.rgbShift ||
        EffectType.fire ||
        EffectType.ice ||
        EffectType.smoke ||
        EffectType.lightSweep ||
        EffectType.lensFlare =>
          EffectCategory.shader,
        EffectType.sparkles ||
        EffectType.stars ||
        EffectType.snow ||
        EffectType.rain ||
        EffectType.lightning ||
        EffectType.particles ||
        EffectType.confetti ||
        EffectType.magicDust =>
          EffectCategory.particle,
        _ => EffectCategory.paint,
      };
}

/// One entry in a layer's effect stack. All numeric parameters are normalized
/// 0..1 where possible so effect UIs are uniform sliders.
class LayerEffect {
  const LayerEffect({
    required this.type,
    this.enabled = true,
    this.intensity = 0.5,
    this.radius = 0.2,
    this.angle = 0.785398, // 45° for shadows/bevels
    this.color = const Color(0xFF000000),
    this.secondaryColor,
    this.speed = 0.5, // for animated shader/particle effects
  });

  final EffectType type;
  final bool enabled;
  final double intensity;
  final double radius;
  final double angle;
  final Color color;
  final Color? secondaryColor;
  final double speed;

  LayerEffect copyWith({
    bool? enabled,
    double? intensity,
    double? radius,
    double? angle,
    Color? color,
    Color? secondaryColor,
    double? speed,
  }) =>
      LayerEffect(
        type: type,
        enabled: enabled ?? this.enabled,
        intensity: intensity ?? this.intensity,
        radius: radius ?? this.radius,
        angle: angle ?? this.angle,
        color: color ?? this.color,
        secondaryColor: secondaryColor ?? this.secondaryColor,
        speed: speed ?? this.speed,
      );

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'enabled': enabled,
        'intensity': intensity,
        'radius': radius,
        'angle': angle,
        'color': color.value,
        'secondaryColor': secondaryColor?.value,
        'speed': speed,
      };

  factory LayerEffect.fromJson(Map<String, dynamic> j) => LayerEffect(
        type: EffectType.values.byName(j['type'] as String),
        enabled: j['enabled'] as bool,
        intensity: (j['intensity'] as num).toDouble(),
        radius: (j['radius'] as num).toDouble(),
        angle: (j['angle'] as num).toDouble(),
        color: Color(j['color'] as int),
        secondaryColor: j['secondaryColor'] == null
            ? null
            : Color(j['secondaryColor'] as int),
        speed: (j['speed'] as num?)?.toDouble() ?? 0.5,
      );
}
