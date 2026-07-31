import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// SQLite bootstrap. Schema kept intentionally small: project documents are
/// stored as JSON blobs (the layer model owns its own serialization), while
/// query-relevant fields (title, folder, favorite, updated) are columns so
/// search/sort stay indexed and fast.
class AppDatabase {
  AppDatabase._(this.db);
  final Database db;

  static Future<AppDatabase> open() async {
    final path = p.join(await getDatabasesPath(), 'sticker_studio.db');
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE projects(
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            folder TEXT,
            favorite INTEGER NOT NULL DEFAULT 0,
            tags TEXT NOT NULL DEFAULT '',
            document TEXT NOT NULL,
            thumbnail TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_projects_updated ON projects(updated_at DESC)');
        await db.execute(
            'CREATE INDEX idx_projects_folder ON projects(folder)');
      },
    );
    return AppDatabase._(db);
  }
}
