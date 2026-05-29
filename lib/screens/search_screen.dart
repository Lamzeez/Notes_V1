import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/note_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<Note> _results = [];
  bool _isSearching = false;
  String _lastQuery = '';
  Timer? _debounce;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    // Auto-focus the search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query == _lastQuery) return;
    _lastQuery = query;

    _debounce?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      _animController.reverse();
      return;
    }

    setState(() => _isSearching = true);

    _debounce = Timer(const Duration(milliseconds: 150), () async {
      final provider = context.read<NotesProvider>();
      final results = await provider.searchNotes(query.trim());
      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
        });
        if (results.isNotEmpty) {
          _animController.forward();
        } else {
          _animController.reverse();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;
    final query = _searchController.text;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF12121C) : const Color(0xFFF5F6FF),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white70 : const Color(0xFF3F4280),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Search your notes...',
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            border: InputBorder.none,
          ),
          textInputAction: TextInputAction.search,
        ),
        actions: [
          if (query.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: isDark ? Colors.white54 : Colors.black38,
              ),
              onPressed: () {
                _searchController.clear();
                _focusNode.requestFocus();
              },
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
      body: _buildBody(isDark, query),
    );
  }

  Widget _buildBody(bool isDark, String query) {
    if (query.trim().isEmpty) {
      return _buildEmptySearchState(isDark);
    }

    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Color(0xFF5C6BC0)),
          strokeWidth: 2,
        ),
      );
    }

    if (_results.isEmpty && query.trim().isNotEmpty) {
      return _buildNoResultsState(isDark, query);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Result count header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${_results.length} ',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? const Color(0xFF7986CB) : const Color(0xFF5C6BC0),
                  ),
                ),
                TextSpan(
                  text: _results.length == 1 ? 'result for ' : 'results for ',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
                TextSpan(
                  text: '"${_searchController.text}"',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Results list
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final note = _results[index];
                return NoteCard(
                  note: note,
                  highlightQuery: _searchController.text,
                  onTap: () => Navigator.pop(context, note.id),
                  onLongPress: () {},
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySearchState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_rounded,
            size: 64,
            color: isDark ? Colors.white.withAlpha(30) : Colors.black.withAlpha(20),
          ),
          const SizedBox(height: 16),
          Text(
            'Search your notes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type anything to find matching notes',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(bool isDark, String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.find_in_page_rounded,
            size: 64,
            color: isDark ? Colors.white.withAlpha(30) : Colors.black.withAlpha(20),
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No notes match "$query"',
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
