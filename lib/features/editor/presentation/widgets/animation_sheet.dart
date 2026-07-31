import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sticker_studio_ai/features/animation/domain/animation_spec.dart';
import 'package:sticker_studio_ai/features/editor/application/editor_controller.dart';

/// Animation Studio: pick a preset (grouped Entrance / Continuous / Exit),
/// tune duration, speed and loop. The canvas previews live because presets
/// write straight to the layer and the ticker is already running.
class AnimationSheet extends ConsumerWidget {
  const AnimationSheet({super.key});

  static const _labels = <AnimPreset, String>{
    AnimPreset.fadeIn: 'ظهور تدريجي',
    AnimPreset.scaleIn: 'تكبير',
    AnimPreset.pop: 'قفزة',
    AnimPreset.bounceIn: 'ارتداد',
    AnimPreset.slideIn: 'انزلاق',
    AnimPreset.rotateIn: 'دوران دخول',
    AnimPreset.elasticIn: 'مرن',
    AnimPreset.zoomIn: 'زوم',
    AnimPreset.fadeOut: 'اختفاء',
    AnimPreset.shrink: 'انكماش',
    AnimPreset.explode: 'انفجار',
    AnimPreset.pulse: 'نبض',
    AnimPreset.float: 'طفو',
    AnimPreset.shake: 'اهتزاز',
    AnimPreset.wiggle: 'تمايل',
    AnimPreset.spin: 'دوران',
    AnimPreset.glowPulse: 'توهج نابض',
    AnimPreset.colorShift: 'تغير لون',
    AnimPreset.rainbowCycle: 'قوس قزح',
    AnimPreset.breathing: 'تنفس',
    AnimPreset.sparkleLoop: 'لمعان',
    AnimPreset.floatingParticles: 'جزيئات',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layer = ref.watch(editorControllerProvider).selected;
    final controller = ref.read(editorControllerProvider.notifier);
    if (layer == null) return const SizedBox.shrink();
    final spec = layer.animation;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          for (final group in AnimGroup.values) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                switch (group) {
                  AnimGroup.entrance => 'الدخول',
                  AnimGroup.continuous => 'مستمر',
                  AnimGroup.exit => 'الخروج',
                },
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in AnimPreset.values
                    .where((p) => p.group == group))
                  ChoiceChip(
                    label: Text(_labels[preset] ?? preset.name),
                    selected: spec?.preset == preset,
                    onSelected: (on) => controller.setAnimation(
                      on
                          ? AnimationSpec(
                              preset: preset,
                              loop: group == AnimGroup.continuous,
                              duration: spec?.duration ??
                                  const Duration(milliseconds: 1200),
                              speed: spec?.speed ?? 1,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          ],
          if (spec != null) ...[
            const Divider(height: 32),
            Row(children: [
              const SizedBox(width: 90, child: Text('المدة')),
              Expanded(
                child: Slider(
                  value: spec.duration.inMilliseconds.toDouble(),
                  min: 300,
                  max: 5000,
                  divisions: 47,
                  label: '${(spec.duration.inMilliseconds / 1000).toStringAsFixed(1)} ث',
                  onChanged: (v) => controller.setAnimation(spec.copyWith(
                      duration: Duration(milliseconds: v.round()))),
                ),
              ),
            ]),
            Row(children: [
              const SizedBox(width: 90, child: Text('السرعة')),
              Expanded(
                child: Slider(
                  value: spec.speed,
                  min: 0.25,
                  max: 3,
                  divisions: 11,
                  label: '×${spec.speed.toStringAsFixed(2)}',
                  onChanged: (v) =>
                      controller.setAnimation(spec.copyWith(speed: v)),
                ),
              ),
            ]),
            SwitchListTile(
              title: const Text('تكرار'),
              value: spec.loop,
              onChanged: (v) =>
                  controller.setAnimation(spec.copyWith(loop: v)),
            ),
          ],
        ],
      ),
    );
  }
}
