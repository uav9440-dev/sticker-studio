import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:sticker_studio_ai/core/utils/image_cache_service.dart';
import 'package:sticker_studio_ai/core/utils/image_tools.dart';
import 'package:sticker_studio_ai/core/utils/result.dart';
import 'package:sticker_studio_ai/features/editor/application/editor_controller.dart';
import 'package:sticker_studio_ai/features/editor/domain/models/layer.dart';
import 'package:sticker_studio_ai/features/editor/domain/models/project.dart';
import 'package:sticker_studio_ai/features/editor/presentation/canvas/sticker_canvas.dart';
import 'package:sticker_studio_ai/features/editor/presentation/widgets/animation_sheet.dart';
import 'package:sticker_studio_ai/features/editor/presentation/widgets/layer_panel.dart';
import 'package:sticker_studio_ai/features/editor/presentation/widgets/text_style_sheet.dart';
import 'package:sticker_studio_ai/features/billing/entitlement_service.dart';
import 'package:sticker_studio_ai/features/export/export_service.dart';
import 'package:sticker_studio_ai/features/library/library_repository.dart';
import 'package:sticker_studio_ai/l10n/app_localizations.dart';

final exportServiceProvider = Provider<ExportService>((ref) {
  final cache = ref.watch(imageCacheProvider);
  return ExportService(imageResolver: cache.resolve);
});

class EditorScreen extends ConsumerWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(editorControllerProvider);
    final controller = ref.read(editorControllerProvider.notifier);
    final cache = ref.watch(imageCacheProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editorTitle),
        actions: [
          IconButton(
            tooltip: l10n.undo,
            onPressed: state.canUndo ? controller.undo : null,
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: l10n.redo,
            onPressed: state.canRedo ? controller.redo : null,
            icon: const Icon(Icons.redo),
          ),
          IconButton(
            tooltip: 'حفظ في المكتبة',
            onPressed: () => _saveToLibrary(context, ref),
            icon: const Icon(Icons.save_outlined),
          ),
          FilledButton.tonalIcon(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => const _ExportSheet(),
            ),
            icon: const Icon(Icons.ios_share),
            label: Text(l10n.export),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StickerCanvas(imageResolver: cache.resolve),
      ),
      bottomNavigationBar: _ToolRail(l10n: l10n),
    );
  }

  Future<void> _saveToLibrary(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final state = ref.read(editorControllerProvider);
    final export = ref.read(exportServiceProvider);
    final repo = await ref.read(libraryRepositoryProvider.future);

    final thumb = await export.renderThumbnail(state.project);
    var project = state.project.copyWith(thumbnailPath: thumb);
    if (project.title.isEmpty) {
      final first = project.layers.whereType<TextLayer>().firstOrNull;
      project = project.copyWith(title: first?.text ?? 'تصميم جديد');
    }
    await repo.save(project);
    ref.read(editorControllerProvider.notifier).loadProject(project);
    messenger.showSnackBar(const SnackBar(content: Text('تم الحفظ ✅')));
  }
}

class _ToolRail extends ConsumerWidget {
  const _ToolRail({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(editorControllerProvider.notifier);
    final selected =
        ref.watch(editorControllerProvider.select((s) => s.selected));
    final hasSelection = selected != null;
    final isImage = selected is ImageLayer;

    return SafeArea(
      child: SizedBox(
        height: 76,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            _Tool(
              icon: Icons.text_fields,
              label: l10n.addText,
              onTap: () => controller.addTextLayer('نص جديد'),
            ),
            _Tool(
              icon: Icons.image_outlined,
              label: l10n.addImage,
              onTap: () => _pickImage(context, ref),
            ),
            if (isImage)
              _Tool(
                icon: Icons.auto_fix_off_outlined,
                label: l10n.removeBackground,
                onTap: () => _removeBackground(context, ref, selected as ImageLayer),
              ),
            _Tool(
              icon: Icons.auto_fix_high,
              label: l10n.effects,
              enabled: hasSelection,
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const TextStyleSheet(),
              ),
            ),
            _Tool(
              icon: Icons.animation,
              label: l10n.animation,
              enabled: hasSelection,
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const AnimationSheet(),
              ),
            ),
            _Tool(
              icon: Icons.flip,
              label: 'قلب',
              enabled: hasSelection,
              onTap: () => controller.flipSelected(),
            ),
            _Tool(
              icon: Icons.copy_outlined,
              label: 'نسخ',
              enabled: hasSelection,
              onTap: controller.duplicateSelected,
            ),
            _Tool(
              icon: Icons.delete_outline,
              label: 'حذف',
              enabled: hasSelection,
              onTap: controller.deleteSelected,
            ),
            _Tool(
              icon: Icons.layers_outlined,
              label: l10n.layers,
              onTap: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => const LayerPanel(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, WidgetRef ref) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    await ref.read(imageCacheProvider).load(picked.path);
    ref.read(editorControllerProvider.notifier).addImageLayer(picked.path);
  }

  Future<void> _removeBackground(
      BuildContext context, WidgetRef ref, ImageLayer layer) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger
        .showSnackBar(const SnackBar(content: Text('جارٍ إزالة الخلفية…')));
    try {
      final processed =
          await ImageTools.removeSolidBackground(layer.sourcePath);
      await ref.read(imageCacheProvider).load(processed);
      ref.read(editorControllerProvider.notifier).updateSelected(
          (l) => (l as ImageLayer).copyWith(processedPath: processed));
      messenger.hideCurrentSnackBar();
    } catch (e) {
      messenger
          .showSnackBar(SnackBar(content: Text('تعذّرت إزالة الخلفية: $e')));
    }
  }
}

class _Tool extends StatelessWidget {
  const _Tool({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: enabled ? 1 : 0.35,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon),
                const SizedBox(height: 4),
                Text(label, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExportSheet extends ConsumerStatefulWidget {
  const _ExportSheet();

  @override
  ConsumerState<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends ConsumerState<_ExportSheet> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final animated = ref
        .watch(editorControllerProvider.select((s) => s.project.isAnimated));

    return SafeArea(
      child: _busy
          ? const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.sticky_note_2_outlined),
                  title: const Text('ملصق WEBP'),
                  subtitle: const Text('512×512 · متوافق مع واتساب'),
                  onTap: () => _run((s, p) => s.exportStatic(p)),
                ),
                ListTile(
                  leading: const Icon(Icons.image_outlined),
                  title: const Text('PNG'),
                  onTap: () => _run((s, p) => s.exportPng(p)),
                ),
                if (animated)
                  ListTile(
                    leading: const Icon(Icons.gif_box_outlined),
                    title: const Text('GIF متحرك'),
                    onTap: () => _run((s, p) => s.exportGif(p)),
                  ),
                ListTile(
                  leading: const Icon(Icons.send),
                  title: Text(l10n.exportToWhatsApp),
                  subtitle: const Text('تصدير WEBP ثم مشاركته'),
                  onTap: () => _run((s, p) => s.exportStatic(p)),
                ),
              ],
            ),
    );
  }

  Future<void> _run(
      Future<Result<File>> Function(ExportService, StickerProject) job) async {
    // بوابة النسخة الكاملة: التصدير متاح خلال التجربة (3 أيام) أو بعد الشراء.
    if (!ref.read(entitlementProvider).isActive) {
      Navigator.of(context).pop();
      context.go('/paywall');
      return;
    }
    setState(() => _busy = true);
    final service = ref.read(exportServiceProvider);
    final project = ref.read(editorControllerProvider).project;
    final result = await job(service, project);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Ok(:final value):
        Navigator.of(context).pop();
        await Share.shareXFiles([XFile(value.path)]);
      case Err(:final failure):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
