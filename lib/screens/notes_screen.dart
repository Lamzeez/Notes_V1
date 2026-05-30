import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/note_card.dart';
import 'search_screen.dart';
import 'note_editor_screen.dart';
import 'recently_deleted_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final ScrollController _scrollController = ScrollController();

  // Track which note is currently highlighted (from search navigation)
  int? _highlightedNoteId;
  Timer? _highlightTimer;

  // Map from note id -> GlobalKey for scroll-to
  final Map<int, GlobalKey> _noteKeys = {};
  final Set<int> _selectedNoteIds = {};
  final List<int> _deletingNoteIds = [];

  @override
  void dispose() {
    _scrollController.dispose();
    _highlightTimer?.cancel();
    super.dispose();
  }

  Future<void> _openSearch() async {
    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );

    if (result != null && mounted) {
      _scrollToNote(result);
    }
  }

  void _scrollToNote(int noteId) {
    final provider = context.read<NotesProvider>();
    final index = provider.indexOfNoteId(noteId);
    if (index == -1) return;

    // Highlight the note
    setState(() => _highlightedNoteId = noteId);
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _highlightedNoteId = null);
    });

    // Scroll to the note's key
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _noteKeys[noteId];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.5, // Position note at center of viewport
        );
      }
    });
  }

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

  void _confirmBatchDelete() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final count = _selectedNoteIds.length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete $count Note${count > 1 ? 's' : ''}?',
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
            onPressed: () async {
              Navigator.pop(ctx);
              final idsToDelete = _selectedNoteIds.toList();
              setState(() {
                _deletingNoteIds.addAll(idsToDelete);
                _selectedNoteIds.clear();
              });
              await Future.delayed(const Duration(milliseconds: 300));
              if (mounted) {
                context.read<NotesProvider>().deleteNotes(idsToDelete);
                setState(() {
                  _deletingNoteIds.removeWhere((id) => idsToDelete.contains(id));
                });
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  AppBar _buildSelectionAppBar(bool isDark, NotesProvider provider) {
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
        if (_selectedNoteIds.length == 1)
          IconButton(
            icon: Icon(Icons.edit_rounded, color: isDark ? Colors.white70 : Colors.black87),
            onPressed: () {
              final note = provider.notes.firstWhere((n) => n.id == _selectedNoteIds.first);
              _clearSelection();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
              );
            },
          ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE57373)),
          onPressed: _confirmBatchDelete,
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
    final notes = notesProvider.notes;

    // Ensure keys exist for all notes
    for (final note in notes) {
      _noteKeys.putIfAbsent(note.id!, () => GlobalKey());
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF12121C) : const Color(0xFFF5F6FF),
      appBar: _selectedNoteIds.isNotEmpty
          ? _buildSelectionAppBar(isDark, notesProvider)
          : AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/Notes_V1_logoo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Notes V1',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          // Notes count badge
          if (notes.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withAlpha(20)
                    : const Color(0xFF5C6BC0).withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${notes.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : const Color(0xFF5C6BC0),
                ),
              ),
            ),
          // Search
          IconButton(
            icon: Icon(
              Icons.search_rounded,
              color: isDark ? Colors.white70 : const Color(0xFF3F4280),
            ),
            tooltip: 'Search notes',
            onPressed: notes.isEmpty ? null : _openSearch,
          ),
          // Recently Deleted
          IconButton(
            icon: Icon(
              Icons.auto_delete_outlined,
              color: isDark ? Colors.white70 : const Color(0xFF3F4280),
            ),
            tooltip: 'Recently Deleted',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecentlyDeletedScreen()),
              );
            },
          ),
          // Theme toggle
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                key: ValueKey(isDark),
                color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF5C6BC0),
              ),
            ),
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () => context.read<ThemeProvider>().toggle(),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10),
          ),
        ),
      ),
      body: notesProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notes.isEmpty
              ? _buildEmptyState(isDark)
              : Align(
                  alignment: Alignment.topCenter,
                  child: ListView.builder(
                    reverse: true,
                    shrinkWrap: true,
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    final isDeleting = _deletingNoteIds.contains(note.id);
                    return KeyedSubtree(
                      key: _noteKeys[note.id!],
                      child: AnimatedNoteItem(
                        isDeleting: isDeleting,
                        child: NoteCard(
                          note: note,
                          isHighlighted: _highlightedNoteId == note.id,
                          isSelected: _selectedNoteIds.contains(note.id),
                          onTap: () {
                            if (_selectedNoteIds.isNotEmpty) {
                              _toggleSelection(note.id!);
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
                              );
                            }
                          },
                          onLongPress: () {
                            if (_selectedNoteIds.isEmpty) {
                              _toggleSelection(note.id!);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NoteEditorScreen()),
        ),
        backgroundColor: const Color(0xFF5C6BC0),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.edit_note_rounded,
            size: 64,
            color: isDark
                ? Colors.white.withAlpha(40)
                : Colors.black.withAlpha(30),
          ),
          const SizedBox(height: 16),
          Text(
            'No notes yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first note',
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

class AnimatedNoteItem extends StatefulWidget {
  final bool isDeleting;
  final Widget child;

  const AnimatedNoteItem({super.key, required this.isDeleting, required this.child});

  @override
  State<AnimatedNoteItem> createState() => _AnimatedNoteItemState();
}

class _AnimatedNoteItemState extends State<AnimatedNoteItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void didUpdateWidget(AnimatedNoteItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDeleting && !oldWidget.isDeleting) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
        child: widget.child,
      ),
    );
  }
}
