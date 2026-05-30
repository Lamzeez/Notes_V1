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
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _contentKey = GlobalKey();

  RenderEditable? _findRenderEditable(RenderObject? root) {
    if (root is RenderEditable) return root;
    if (root == null) return null;
    RenderEditable? result;
    root.visitChildren((child) {
      result ??= _findRenderEditable(child);
    });
    return result;
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');

    if (widget.matchIndex != null && widget.matchLength != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _contentFocusNode.requestFocus();
        _contentController.selection = TextSelection(
          baseOffset: widget.matchIndex!,
          extentOffset: widget.matchIndex! + widget.matchLength!,
        );

        // Wait for keyboard and native auto-scroll to finish,
        // then query the precise pixel location from the native rendering engine.
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted || !_scrollController.hasClients) return;
          
          final root = _contentKey.currentContext?.findRenderObject();
          final renderEditable = _findRenderEditable(root);
          
          if (renderEditable != null) {
            final endpoints = renderEditable.getEndpointsForSelection(
              TextSelection.collapsed(offset: widget.matchIndex!)
            );
            
            if (endpoints.isNotEmpty) {
              final yOffset = endpoints.first.point.dy;
              final targetOffset = (yOffset - 30) < 0 ? 0.0 : (yOffset - 30);
              
              final maxScroll = _scrollController.position.maxScrollExtent;
              _scrollController.animateTo(
                targetOffset.clamp(0.0, maxScroll),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
              );
            }
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final text = _contentController.text.trim();
    if (text.isEmpty && title.isEmpty && widget.note == null) {
      Navigator.pop(context);
      return;
    }

    final provider = context.read<NotesProvider>();
    if (widget.note == null) {
      provider.addNote(title.isEmpty ? null : title, text);
    } else {
      if (text.isEmpty && title.isEmpty) {
        provider.deleteNote(widget.note!.id!);
      } else {
        provider.editNote(widget.note!, title.isEmpty ? null : title, text);
      }
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF12121C) : const Color(0xFFF5F6FF),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
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
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  hintText: 'Title',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white30 : Colors.black38,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  key: _contentKey,
                  controller: _contentController,
                  scrollController: _scrollController,
                  focusNode: _contentFocusNode,
                  autofocus: widget.note == null && widget.matchIndex == null,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    color: isDark ? Colors.white.withAlpha(230) : Colors.black87,
                    fontSize: 16,
                    height: 1.6,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Start writing your note here...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white30 : Colors.black38,
                      fontSize: 16,
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
    );
  }
}
