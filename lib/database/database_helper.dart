import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'notes_v1.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE notes ADD COLUMN title TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE notes ADD COLUMN is_deleted INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE notes ADD COLUMN deleted_at INTEGER');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        is_deleted INTEGER DEFAULT 0,
        deleted_at INTEGER
      )
    ''');
  }

  // Insert a new note
  Future<Note> insertNote(String? title, String content) async {
    final db = await database;
    final now = DateTime.now();
    final note = Note(
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
    );
    final id = await db.insert('notes', note.toMap());
    return note.copyWith(id: id);
  }

  Future<List<Note>> getAllNotes() async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: 'is_deleted = 0',
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Note.fromMap(m)).toList();
  }

  Future<List<Note>> searchNotes(String query) async {
    if (query.trim().isEmpty) return [];
    final db = await database;
    final maps = await db.query(
      'notes',
      where: '(content LIKE ? OR title LIKE ?) AND is_deleted = 0',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Note.fromMap(m)).toList();
  }

  // Update a note
  Future<void> updateNote(Note note) async {
    final db = await database;
    final updated = note.copyWith(updatedAt: DateTime.now());
    await db.update(
      'notes',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  // Soft delete a note
  Future<void> deleteNote(int id) async {
    final db = await database;
    await db.update(
      'notes',
      {
        'is_deleted': 1,
        'deleted_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Soft batch delete notes
  Future<void> deleteNotes(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.update(
      'notes',
      {
        'is_deleted': 1,
        'deleted_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  // Restore a note
  Future<void> restoreNote(int id) async {
    final db = await database;
    await db.update(
      'notes',
      {'is_deleted': 0, 'deleted_at': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Restore multiple notes
  Future<void> restoreNotes(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.update(
      'notes',
      {'is_deleted': 0, 'deleted_at': null},
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  // Permanently delete a note
  Future<void> permanentlyDeleteNote(int id) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // Permanently delete multiple notes
  Future<void> permanentlyDeleteNotes(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.delete('notes', where: 'id IN ($placeholders)', whereArgs: ids);
  }

  // Get all deleted notes
  Future<List<Note>> getDeletedNotes() async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: 'is_deleted = 1',
      orderBy: 'deleted_at DESC',
    );
    return maps.map((m) => Note.fromMap(m)).toList();
  }

  // Clean up notes older than 30 days
  Future<void> cleanUpOldDeletedNotes() async {
    final db = await database;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch;
    await db.delete(
      'notes',
      where: 'is_deleted = 1 AND deleted_at < ?',
      whereArgs: [thirtyDaysAgo],
    );
  }
}
