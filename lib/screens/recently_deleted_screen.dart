import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/note_card.dart';

class RecentlyDeletedScreen extends StatefulWidget {
  const RecentlyDeletedScreen({super.key});

  @override
  State<RecentlyDeletedScreen> createState() => _RecentlyDeletedScreenState();
}

class _RecentlyDeletedScreenState extends State<RecentlyDeletedScreen> {
  final Set<int> _selectedNoteIds = {};

  void _toggleSelection(int noteId) {
    setState(() {
      if (_selectedNoteIds.contains(noteId)) {
        _selectedNoteIds.remove(noteId);
      } else {
        _selectedNoteIds.add(noteId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedNoteIds.clear();
    });
  }

  void _restoreSelectedNotes() {
    if (_selectedNoteIds.isEmpty) return;
    final provider = context.read<NotesProvider>();
    provider.restoreNotes(_selectedNoteIds.toList());
    _clearSelection();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notes restored successfully')),
    );
  }

  void _confirmBatchPermanentDelete() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final count = _selectedNoteIds.length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Permanently delete $count Note${count > 1 ? 's' : ''}?',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This action cannot be undone.',
          style: TextStyle(
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE57373),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<NotesProvider>().permanentlyDeleteNotes(_selectedNoteIds.toList());
              _clearSelection();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showActions(BuildContext context, Note note) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.restore_rounded,
                  color: isDark ? const Color(0xFF7986CB) : const Color(0xFF3F51B5),
                ),
                title: Text(
                  'Restore Note',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<NotesProvider>().restoreNote(note.id!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Note restored')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_forever_rounded,
                  color: Color(0xFFE57373),
                ),
                title: const Text(
                  'Delete Permanently',
                  style: TextStyle(
                    color: Color(0xFFE57373),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _selectedNoteIds.add(note.id!);
                  _confirmBatchPermanentDelete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildSelectionAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : Colors.black87),
        onPressed: _clearSelection,
      ),
      title: Text(
        '${_selectedNoteIds.length} selected',
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.restore_rounded, color: isDark ? const Color(0xFF7986CB) : const Color(0xFF3F51B5)),
          onPressed: _restoreSelectedNotes,
          tooltip: 'Restore selected',
        ),
        IconButton(
          icon: const Icon(Icons.delete_forever_rounded, color: Color(0xFFE57373)),
          onPressed: _confirmBatchPermanentDelete,
          tooltip: 'Delete permanently',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final notesProvider = context.watch<NotesProvider>();
    final isDark = themeProvider.isDark;
    final deletedNotes = notesProvider.deletedNotes;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF12121C) : const Color(0xFFF5F6FF),
      appBar: _selectedNoteIds.isNotEmpty
          ? _buildSelectionAppBar(isDark)
          : AppBar(
              backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Recently Deleted',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  letterSpacing: -0.3,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  height: 1,
                  color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10),
                ),
              ),
            ),
      body: deletedNotes.isEmpty
          ? _buildEmptyState(isDark)
          : ListView.builder(
              padding: const EdgeInsets.only(top: 12, bottom: 20),
              itemCount: deletedNotes.length,
              itemBuilder: (context, index) {
                final note = deletedNotes[index];
                final deletedAt = note.deletedAt ?? DateTime.now();
                final daysPassed = DateTime.now().difference(deletedAt).inDays;
                final daysLeft = (30 - daysPassed).clamp(0, 30);

                return Column(
                  children: [
                    NoteCard(
                      note: note,
                      isSelected: _selectedNoteIds.contains(note.id),
                      onTap: () {
                        if (_selectedNoteIds.isNotEmpty) {
                          _toggleSelection(note.id!);
                        } else {
                          _showActions(context, note);
                        }
                      },
                      onLongPress: () {
                        if (_selectedNoteIds.isEmpty) {
                          _toggleSelection(note.id!);
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0, top: 0.0),
                      child: Text(
                        '$daysLeft days left',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delete_outline_rounded,
            size: 64,
            color: isDark
                ? Colors.white.withAlpha(40)
                : Colors.black.withAlpha(30),
          ),
          const SizedBox(height: 16),
          Text(
            'No deleted notes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Items here will be permanently deleted after 30 days',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ),
        ],
      ),
    );
  }
}
