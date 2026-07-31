import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sticker_studio_ai/features/editor/application/editor_controller.dart';
import 'package:sticker_studio_ai/features/editor/domain/models/layer.dart';
import 'package:sticker_studio_ai/l10n/app_localizations.dart';

/// Reorderable layer stack: drag to reorder, toggle visibility/lock,
/// swipe actions for duplicate/delete.
class LayerPanel extends ConsumerWidget {
  const LayerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(editorControllerProvider);
    final controller = ref.read(editorControllerProvider.notifier);
    // Show top-most first, matching designer mental model.
    final layers = state.project.layers.reversed.toList();
    final count = state.project.layers.length;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(l10n.layers,
                style: Theme.of(context).textTheme.headlineMedium),
          ),
          Flexible(
            child: ReorderableListView.builder(
              shrinkWrap: true,
              itemCount: layers.length,
              onReorder: (o, n) =>
                  controller.reorderLayer(count - 1 - o, count - n),
              itemBuilder: (context, i) {
                final layer = layers[i];
                final selected = layer.id == state.selectedLayerId;
                return ListTile(
                  key: ValueKey(layer.id),
                  selected: selected,
                  leading: Icon(switch (layer) {
                    TextLayer() => Icons.text_fields,
                    ImageLayer() => Icons.image_outlined,
                  }),
                  title: Text(
                    layer.name.isEmpty ? layer.id.substring(0, 6) : layer.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => controller.select(layer.id),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(layer.visible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () {
                          controller.select(layer.id);
                          controller.updateSelected(
                              (l) => l.copyWith(visible: !l.visible));
                        },
                      ),
                      IconButton(
                        icon: Icon(layer.locked
                            ? Icons.lock_outline
                            : Icons.lock_open_outlined),
                        onPressed: () {
                          controller.select(layer.id);
                          controller.updateSelected(
                              (l) => l.copyWith(locked: !l.locked));
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
