import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final int? matchIndex;
  final int? matchLength;

  const NoteEditorScreen({super.key, this.note, this.matchIndex, this.matchLength});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final FocusNode _contentFocusNode = FocusNode();
  final UndoHistoryController _undoController = UndoHistoryController();
  ScrollController? _scrollController;
  bool _isInit = false;
  bool _hasChanges = false;
  bool _isPopping = false;

  bool get _hasUnsavedChanges {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final originalTitle = widget.note?.title ?? '';
    final originalContent = widget.note?.content ?? '';
    return title != originalTitle || content != originalContent;
  }

  void _onTextChanged() {
    final hasChanges = _hasUnsavedChanges;
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');

    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);

    if (widget.matchIndex == null || widget.matchLength == null) {
      _scrollController = ScrollController();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _contentFocusNode.requestFocus();
        _contentController.selection = TextSelection(
          baseOffset: widget.matchIndex!,
          extentOffset: widget.matchIndex! + widget.matchLength!,
        );
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit && _scrollController == null && widget.matchIndex != null) {
      _isInit = true;
      final text = _contentController.text.substring(0, widget.matchIndex!);
      
      final baseStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
        fontSize: 16,
        height: 1.6,
      ) ?? const TextStyle(fontSize: 16, height: 1.6);

      final textSpan = TextSpan(
        text: text,
        style: baseStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
      );
      
      textPainter.layout(maxWidth: MediaQuery.of(context).size.width - 40);
      final yOffset = textPainter.size.height;
      final targetOffset = (yOffset - 30) < 0 ? 0.0 : (yOffset - 30);
      
      _scrollController = ScrollController(initialScrollOffset: targetOffset);
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTextChanged);
    _contentController.removeListener(_onTextChanged);
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    _undoController.dispose();
    _scrollController?.dispose();
    super.dispose();
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final text = _contentController.text.trim();
    if (text.isEmpty && title.isEmpty && widget.note == null) {
      _isPopping = true;
      Navigator.pop(context);
      return;
    }

    final provider = context.read<NotesProvider>();
    if (widget.note != null && text.isEmpty && title.isEmpty) {
      provider.deleteNote(widget.note!.id!);
    } else {
      if (widget.note == null) {
        provider.addNote(title.isEmpty ? null : title, text);
      } else {
        provider.editNote(widget.note!, title.isEmpty ? null : title, text);
      }

      final isDark = Theme.of(context).brightness == Brightness.dark;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text(
                'Note saved',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
          backgroundColor: isDark ? const Color(0xFF43A047) : const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          duration: const Duration(seconds: 2),
          elevation: 4,
        ),
      );
    }
    _isPopping = true;
    Navigator.pop(context, true);
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges || _isPopping) return true;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A3D) : const Color(0xFFF5F6FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.save_as_rounded,
                  size: 28,
                  color: isDark ? const Color(0xFF7986CB) : const Color(0xFF5C6BC0),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Unsaved Changes',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You have unsaved changes. What would you like to do before leaving?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(context, true), // Discard
                      child: const Text('Discard', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF7986CB) : const Color(0xFF5C6BC0),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context, false);
                        _saveNote();
                      },
                      child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(context, false), // Cancel
                child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      ),
    );

    if (result == true) {
      _isPopping = true;
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF12121C) : const Color(0xFFF5F6FF),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          widget.note == null ? 'Add Note' : 'Edit Note',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          ValueListenableBuilder<UndoHistoryValue>(
            valueListenable: _undoController,
            builder: (context, value, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.undo_rounded,
                      color: value.canUndo ? (isDark ? Colors.white70 : Colors.black54) : (isDark ? Colors.white24 : Colors.black26),
                    ),
                    onPressed: value.canUndo ? () => _undoController.undo() : null,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.redo_rounded,
                      color: value.canRedo ? (isDark ? Colors.white70 : Colors.black54) : (isDark ? Colors.white24 : Colors.black26),
                    ),
                    onPressed: value.canRedo ? () => _undoController.redo() : null,
                  ),
                ],
              );
            },
          ),
          TextButton.icon(
            onPressed: _saveNote,
            icon: Icon(Icons.check_rounded, color: isDark ? const Color(0xFF7986CB) : const Color(0xFF5C6BC0)),
            label: Text(
              'Save',
              style: TextStyle(
                color: isDark ? const Color(0xFF7986CB) : const Color(0xFF5C6BC0),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  hintText: 'Title',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white30 : Colors.black38,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  undoController: _undoController,
                  scrollController: _scrollController,
                  focusNode: _contentFocusNode,
                  autofocus: widget.note == null && widget.matchIndex == null,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    color: isDark ? Colors.white.withAlpha(230) : Colors.black87,
                    fontSize: 15,
                    height: 1.6,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Start writing your note here...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white30 : Colors.black38,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
