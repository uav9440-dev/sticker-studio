import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sticker_studio_ai/features/editor/application/editor_controller.dart';
import 'package:sticker_studio_ai/features/editor/domain/models/project.dart';
import 'package:sticker_studio_ai/features/library/library_repository.dart';
import 'package:sticker_studio_ai/l10n/app_localizations.dart';

final librarySearchProvider = StateProvider<String>((_) => '');

final libraryResultsProvider =
    FutureProvider<List<StickerProject>>((ref) async {
  final repo = await ref.watch(libraryRepositoryProvider.future);
  return repo.search(query: ref.watch(librarySearchProvider));
});

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final results = ref.watch(libraryResultsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeLibrary)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              hintText: l10n.searchHint,
              leading: const Icon(Icons.search),
              onChanged: (q) =>
                  ref.read(librarySearchProvider.notifier).state = q,
            ),
          ),
          Expanded(
            child: results.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (projects) => projects.isEmpty
                  ? Center(child: Text(l10n.emptyLibrary))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemCount: projects.length,
                      itemBuilder: (context, i) {
                        final project = projects[i];
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              ref
                                  .read(editorControllerProvider.notifier)
                                  .loadProject(project);
                              context.go('/editor');
                            },
                            child: GridTile(
                              footer: GridTileBar(
                                backgroundColor: Colors.black45,
                                title: Text(project.title),
                                trailing: project.favorite
                                    ? const Icon(Icons.star, size: 18)
                                    : null,
                              ),
                              child: project.thumbnailPath == null
                                  ? const Icon(Icons.image_outlined, size: 48)
                                  : Image.file(File(project.thumbnailPath!),
                                      fit: BoxFit.cover),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
