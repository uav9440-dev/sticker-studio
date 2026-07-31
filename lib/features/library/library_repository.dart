import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'package:sticker_studio_ai/core/db/app_database.dart';
import 'package:sticker_studio_ai/features/editor/domain/models/project.dart';

final appDatabaseProvider =
    FutureProvider<AppDatabase>((_) => AppDatabase.open());

final libraryRepositoryProvider = FutureProvider<LibraryRepository>(
    (ref) async => LibraryRepository((await ref.watch(appDatabaseProvider.future)).db));

/// Projects, folders, favorites, tags, search. Cloud backup syncs this table
/// (documents are self-contained JSON, so sync is a row merge by updated_at).
class LibraryRepository {
  LibraryRepository(this._db);
  final Database _db;

  Future<void> save(StickerProject project) async {
    await _db.insert(
      'projects',
      {
        'id': project.id,
        'title': project.title,
        'folder': project.folder,
        'favorite': project.favorite ? 1 : 0,
        'tags': project.tags.join(','),
        'document': project.encode(),
        'thumbnail': project.thumbnailPath,
        'created_at':
            (project.createdAt ?? DateTime.now()).millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<StickerProject>> search({
    String query = '',
    String? folder,
    bool favoritesOnly = false,
  }) async {
    final where = <String>[];
    final args = <Object>[];
    if (query.isNotEmpty) {
      where.add('(title LIKE ? OR tags LIKE ?)');
      args.addAll(['%$query%', '%$query%']);
    }
    if (folder != null) {
      where.add('folder = ?');
      args.add(folder);
    }
    if (favoritesOnly) where.add('favorite = 1');

    final rows = await _db.query(
      'projects',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args,
      orderBy: 'updated_at DESC',
    );
    return rows
        .map((r) => StickerProject.decode(
              r['document'] as String,
              folder: r['folder'] as String?,
              favorite: (r['favorite'] as int) == 1,
              tags: (r['tags'] as String)
                  .split(',')
                  .where((t) => t.isNotEmpty)
                  .toList(),
              createdAt: DateTime.fromMillisecondsSinceEpoch(
                  r['created_at'] as int),
              updatedAt: DateTime.fromMillisecondsSinceEpoch(
                  r['updated_at'] as int),
              thumbnailPath: r['thumbnail'] as String?,
            ))
        .toList();
  }

  Future<void> delete(String id) =>
      _db.delete('projects', where: 'id = ?', whereArgs: [id]);

  Future<List<String>> folders() async {
    final rows = await _db.rawQuery(
        'SELECT DISTINCT folder FROM projects WHERE folder IS NOT NULL');
    return rows.map((r) => r['folder'] as String).toList();
  }
}
