import 'dart:math' as math;
import 'dart:ui';

/// Animation presets, grouped as in the Animation Studio UI.
enum AnimPreset {
  // Entrance
  fadeIn,
  scaleIn,
  pop,
  bounceIn,
  slideIn,
  rotateIn,
  elasticIn,
  zoomIn,
  // Exit
  fadeOut,
  shrink,
  explode,
  // Continuous (looping)
  pulse,
  float,
  shake,
  wiggle,
  spin,
  glowPulse,
  colorShift,
  rainbowCycle,
  breathing,
  sparkleLoop,
  floatingParticles,
}

enum AnimGroup { entrance, exit, continuous }

extension AnimPresetX on AnimPreset {
  AnimGroup get group => switch (this) {
        AnimPreset.fadeOut ||
        AnimPreset.shrink ||
        AnimPreset.explode =>
          AnimGroup.exit,
        AnimPreset.fadeIn ||
        AnimPreset.scaleIn ||
        AnimPreset.pop ||
        AnimPreset.bounceIn ||
        AnimPreset.slideIn ||
        AnimPreset.rotateIn ||
        AnimPreset.elasticIn ||
        AnimPreset.zoomIn =>
          AnimGroup.entrance,
        _ => AnimGroup.continuous,
      };
}

/// A keyframe: layer transform deltas at normalized time [t] (0..1).
class Keyframe {
  const Keyframe({
    required this.t,
    this.dx = 0,
    this.dy = 0,
    this.scale = 1,
    this.rotation = 0,
    this.opacity = 1,
  });

  final double t;
  final double dx;
  final double dy;
  final double scale;
  final double rotation;
  final double opacity;

  static Keyframe lerp(Keyframe a, Keyframe b, double t) {
    final u = ((t - a.t) / (b.t - a.t)).clamp(0.0, 1.0);
    double l(double x, double y) => x + (y - x) * u;
    return Keyframe(
      t: t,
      dx: l(a.dx, b.dx),
      dy: l(a.dy, b.dy),
      scale: l(a.scale, b.scale),
      rotation: l(a.rotation, b.rotation),
      opacity: l(a.opacity, b.opacity),
    );
  }

  Map<String, dynamic> toJson() =>
      {'t': t, 'dx': dx, 'dy': dy, 's': scale, 'r': rotation, 'o': opacity};

  factory Keyframe.fromJson(Map<String, dynamic> j) => Keyframe(
        t: (j['t'] as num).toDouble(),
        dx: (j['dx'] as num).toDouble(),
        dy: (j['dy'] as num).toDouble(),
        scale: (j['s'] as num).toDouble(),
        rotation: (j['r'] as num).toDouble(),
        opacity: (j['o'] as num).toDouble(),
      );
}

/// Animation attached to a layer. Either a [preset] (which expands to
/// keyframes at evaluation time) or explicit user [keyframes] from the
/// timeline editor. Both share duration/speed/looping controls.
class AnimationSpec {
  const AnimationSpec({
    this.preset,
    this.keyframes = const [],
    this.duration = const Duration(milliseconds: 1200),
    this.speed = 1.0,
    this.loop = true,
    this.delay = Duration.zero,
  }) : assert(preset != null || keyframes.length >= 2,
            'Provide a preset or at least two keyframes');

  final AnimPreset? preset;
  final List<Keyframe> keyframes;
  final Duration duration;
  final double speed;
  final bool loop;
  final Duration delay;

  Duration get effectiveDuration =>
      Duration(microseconds: (duration.inMicroseconds / speed).round());

  /// Evaluate the animation at absolute time [time], returning the transform
  /// delta to compose onto the layer. Used by both live preview and the
  /// frame-by-frame animated-WebP exporter, so preview == export.
  Keyframe evaluate(Duration time) {
    final d = effectiveDuration.inMicroseconds;
    if (d == 0) return const Keyframe(t: 0);
    var t = (time - delay).inMicroseconds / d;
    if (t < 0) return const Keyframe(t: 0, opacity: _startsHidden ? 0 : 1);
    t = loop ? t % 1.0 : t.clamp(0.0, 1.0);
    final frames = preset != null ? _presetFrames(preset!) : keyframes;
    for (var i = 0; i < frames.length - 1; i++) {
      if (t >= frames[i].t && t <= frames[i + 1].t) {
        return Keyframe.lerp(frames[i], frames[i + 1], t);
      }
    }
    return frames.last;
  }

  bool get _startsHidden =>
      preset?.group == AnimGroup.entrance || keyframes.firstOrNull?.opacity == 0;

  static List<Keyframe> _presetFrames(AnimPreset p) => switch (p) {
        AnimPreset.fadeIn => const [
            Keyframe(t: 0, opacity: 0),
            Keyframe(t: 1),
          ],
        AnimPreset.scaleIn => const [
            Keyframe(t: 0, scale: 0.2, opacity: 0),
            Keyframe(t: 1),
          ],
        AnimPreset.pop => const [
            Keyframe(t: 0, scale: 0, opacity: 0),
            Keyframe(t: 0.7, scale: 1.15),
            Keyframe(t: 1),
          ],
        AnimPreset.bounceIn => const [
            Keyframe(t: 0, dy: -220, opacity: 0),
            Keyframe(t: 0.55, dy: 0),
            Keyframe(t: 0.72, dy: -34),
            Keyframe(t: 0.86, dy: 0),
            Keyframe(t: 0.94, dy: -10),
            Keyframe(t: 1),
          ],
        AnimPreset.slideIn => const [
            Keyframe(t: 0, dx: -300, opacity: 0),
            Keyframe(t: 1),
          ],
        AnimPreset.rotateIn => const [
            Keyframe(t: 0, rotation: -math.pi, scale: 0.4, opacity: 0),
            Keyframe(t: 1),
          ],
        AnimPreset.elasticIn => const [
            Keyframe(t: 0, scale: 0),
            Keyframe(t: 0.5, scale: 1.25),
            Keyframe(t: 0.7, scale: 0.92),
            Keyframe(t: 0.85, scale: 1.06),
            Keyframe(t: 1),
          ],
        AnimPreset.zoomIn => const [
            Keyframe(t: 0, scale: 3, opacity: 0),
            Keyframe(t: 1),
          ],
        AnimPreset.fadeOut => const [
            Keyframe(t: 0),
            Keyframe(t: 1, opacity: 0),
          ],
        AnimPreset.shrink => const [
            Keyframe(t: 0),
            Keyframe(t: 1, scale: 0, opacity: 0),
          ],
        AnimPreset.explode => const [
            Keyframe(t: 0),
            Keyframe(t: 0.3, scale: 1.3),
            Keyframe(t: 1, scale: 2.4, opacity: 0),
          ],
        AnimPreset.pulse || AnimPreset.breathing => const [
            Keyframe(t: 0),
            Keyframe(t: 0.5, scale: 1.08),
            Keyframe(t: 1),
          ],
        AnimPreset.float => const [
            Keyframe(t: 0),
            Keyframe(t: 0.5, dy: -18),
            Keyframe(t: 1),
          ],
        AnimPreset.shake => const [
            Keyframe(t: 0),
            Keyframe(t: 0.2, dx: -12),
            Keyframe(t: 0.4, dx: 12),
            Keyframe(t: 0.6, dx: -8),
            Keyframe(t: 0.8, dx: 8),
            Keyframe(t: 1),
          ],
        AnimPreset.wiggle => const [
            Keyframe(t: 0),
            Keyframe(t: 0.25, rotation: -0.12),
            Keyframe(t: 0.75, rotation: 0.12),
            Keyframe(t: 1),
          ],
        AnimPreset.spin => const [
            Keyframe(t: 0),
            Keyframe(t: 1, rotation: 2 * math.pi),
          ],
        // Shader-driven presets keep the transform static; the effect
        // renderer reads the animation clock for glow/color cycling.
        AnimPreset.glowPulse ||
        AnimPreset.colorShift ||
        AnimPreset.rainbowCycle ||
        AnimPreset.sparkleLoop ||
        AnimPreset.floatingParticles =>
          const [Keyframe(t: 0), Keyframe(t: 1)],
      };

  AnimationSpec copyWith({
    AnimPreset? preset,
    List<Keyframe>? keyframes,
    Duration? duration,
    double? speed,
    bool? loop,
    Duration? delay,
  }) =>
      AnimationSpec(
        preset: preset ?? this.preset,
        keyframes: keyframes ?? this.keyframes,
        duration: duration ?? this.duration,
        speed: speed ?? this.speed,
        loop: loop ?? this.loop,
        delay: delay ?? this.delay,
      );

  Map<String, dynamic> toJson() => {
        'preset': preset?.name,
        'keyframes': keyframes.map((k) => k.toJson()).toList(),
        'durationMs': duration.inMilliseconds,
        'speed': speed,
        'loop': loop,
        'delayMs': delay.inMilliseconds,
      };

  factory AnimationSpec.fromJson(Map<String, dynamic> j) => AnimationSpec(
        preset: j['preset'] == null
            ? null
            : AnimPreset.values.byName(j['preset'] as String),
        keyframes: (j['keyframes'] as List)
            .map((k) => Keyframe.fromJson(k as Map<String, dynamic>))
            .toList(),
        duration: Duration(milliseconds: j['durationMs'] as int),
        speed: (j['speed'] as num).toDouble(),
        loop: j['loop'] as bool,
        delay: Duration(milliseconds: j['delayMs'] as int? ?? 0),
      );
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
