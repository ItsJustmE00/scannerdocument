import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:scannerdocument/models/scanned_document.dart';
import 'package:sqflite/sqflite.dart';

class DocumentRepository {
  Database? _db;

  Future<void> initialize() async {
    if (_db != null) {
      return;
    }

    final appDirectory = await getApplicationDocumentsDirectory();
    final dbPath = p.join(appDirectory.path, 'scanner_offline.db');

    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE documents (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            image_paths TEXT NOT NULL,
            ocr_text TEXT NOT NULL,
            extracted_json TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> insertDocument(ScannedDocument document) async {
    final db = _requireDb();
    await db.insert(
      'documents',
      document.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ScannedDocument>> searchDocuments(String query) async {
    final db = _requireDb();
    final normalized = query.trim();

    final rows = normalized.isEmpty
        ? await db.query('documents', orderBy: 'created_at DESC')
        : await db.query(
            'documents',
            where: 'title LIKE ? OR ocr_text LIKE ? OR extracted_json LIKE ?',
            whereArgs: [
              '%$normalized%',
              '%$normalized%',
              '%$normalized%',
            ],
            orderBy: 'created_at DESC',
          );

    return rows.map(ScannedDocument.fromDbMap).toList();
  }

  Future<void> deleteDocument(String id) async {
    final db = _requireDb();
    await db.delete('documents', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Database _requireDb() {
    final db = _db;
    if (db == null) {
      throw StateError('DocumentRepository.initialize() must be called first.');
    }
    return db;
  }
}
