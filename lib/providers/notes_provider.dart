import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/note.dart';

class NotesProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Note> _notes = [];
  bool _isLoading = false;

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;

  NotesProvider() {
    loadNotes();
  }

  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();
    _notes = await _db.getAllNotes();
    _isLoading = false;
    notifyListeners();
  }

  Future<Note> addNote(String? title, String content) async {
    final note = await _db.insertNote(title, content.trim());
    _notes.insert(0, note); // Insert at top (newest first)
    notifyListeners();
    return note;
  }

  Future<void> editNote(Note note, String? newTitle, String newContent) async {
    final updated = note.copyWith(title: newTitle, content: newContent.trim());
    await _db.updateNote(updated);
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = updated;
      notifyListeners();
    }
  }

  Future<void> deleteNote(int id) async {
    await _db.deleteNote(id);
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  Future<void> deleteNotes(List<int> ids) async {
    if (ids.isEmpty) return;
    await _db.deleteNotes(ids);
    _notes.removeWhere((n) => ids.contains(n.id));
    notifyListeners();
  }

  Future<List<Note>> searchNotes(String query) async {
    if (query.trim().isEmpty) return [];
    return await _db.searchNotes(query.trim());
  }

  /// Returns the index of a note in the [_notes] list by its id.
  int indexOfNoteId(int id) {
    return _notes.indexWhere((n) => n.id == id);
  }
}
