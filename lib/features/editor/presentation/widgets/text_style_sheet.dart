import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sticker_studio_ai/features/editor/application/editor_controller.dart';
import 'package:sticker_studio_ai/features/editor/domain/models/layer.dart';
import 'package:sticker_studio_ai/features/effects/domain/effect.dart';
import 'package:sticker_studio_ai/features/text/fonts/font_catalog.dart';
import 'package:sticker_studio_ai/l10n/app_localizations.dart';

/// Text styling sheet: font, spacing, fills (gold/neon/gradient…),
/// curved-text mode, and quick effect toggles. Every slider writes through
/// the controller so undo/redo covers styling too.
class TextStyleSheet extends ConsumerWidget {
  const TextStyleSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final layer = ref.watch(editorControllerProvider).selected;
    final controller = ref.read(editorControllerProvider.notifier);
    if (layer is! TextLayer) return const SizedBox.shrink();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          // Font picker — horizontally scrolling chips previewing each face.
          Text(l10n.fontFamily,
              style: Theme.of(context).textTheme.titleMedium),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final font in FontCatalog.featured)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(font.sample,
                          style: TextStyle(fontFamily: font.family)),
                      selected: layer.fontFamily == font.family,
                      onSelected: (_) => controller.updateSelectedText(
                          (t) => t.copyWith(fontFamily: font.family)),
                    ),
                  ),
              ],
            ),
          ),
          _LabeledSlider(
            label: l10n.letterSpacing,
            value: layer.letterSpacing,
            min: -4,
            max: 24,
            onChanged: (v) => controller
                .updateSelectedText((t) => t.copyWith(letterSpacing: v)),
          ),
          _LabeledSlider(
            label: l10n.lineSpacing,
            value: layer.lineHeight,
            min: 0.8,
            max: 2.4,
            onChanged: (v) =>
                controller.updateSelectedText((t) => t.copyWith(lineHeight: v)),
          ),
          const SizedBox(height: 8),
          // Fill presets: solid, gradient, gold, silver, chrome, neon, glass.
          SegmentedButton<TextFill>(
            segments: [
              const ButtonSegment(
                  value: TextFill.solid, icon: Icon(Icons.circle)),
              ButtonSegment(
                  value: TextFill.gradient, label: Text(l10n.gradient)),
              ButtonSegment(value: TextFill.gold, label: Text(l10n.gold)),
              ButtonSegment(value: TextFill.neon, label: Text(l10n.neon)),
            ],
            selected: {layer.fill},
            onSelectionChanged: (s) => controller
                .updateSelectedText((t) => t.copyWith(fill: s.first)),
          ),
          const SizedBox(height: 16),
          // Curved text.
          SwitchListTile(
            title: Text(l10n.curvedText),
            value: layer.pathMode != TextPathMode.none,
            onChanged: (on) => controller.updateSelectedText((t) => t.copyWith(
                pathMode: on ? TextPathMode.arcUp : TextPathMode.none)),
          ),
          // Quick effects — each toggle adds/removes a stack entry.
          Wrap(
            spacing: 8,
            children: [
              for (final (label, type) in [
                (l10n.shadow, EffectType.shadow),
                (l10n.glow, EffectType.glow),
                (l10n.outline, EffectType.outline),
              ])
                FilterChip(
                  label: Text(label),
                  selected: layer.effects.any((e) => e.type == type),
                  onSelected: (on) => on
                      ? controller.setEffect(LayerEffect(type: type))
                      : controller.removeEffect(type),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 110, child: Text(label)),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
