import 'package:flutter/material.dart';
import '../models/note.dart';

/// Builds a [TextSpan] that highlights all occurrences of [query] within [text].
TextSpan buildHighlightedText({
  required String text,
  required String query,
  required TextStyle normalStyle,
  required TextStyle highlightStyle,
}) {
  if (query.isEmpty) {
    return TextSpan(text: text, style: normalStyle);
  }

  final lowerText = text.toLowerCase();
  final lowerQuery = query.toLowerCase();
  final spans = <TextSpan>[];
  int start = 0;

  while (true) {
    final index = lowerText.indexOf(lowerQuery, start);
    if (index == -1) {
      spans.add(TextSpan(text: text.substring(start), style: normalStyle));
      break;
    }
    if (index > start) {
      spans.add(TextSpan(text: text.substring(start, index), style: normalStyle));
    }
    spans.add(TextSpan(
      text: text.substring(index, index + query.length),
      style: highlightStyle,
    ));
    start = index + query.length;
  }

  return TextSpan(children: spans);
}

class NoteCard extends StatefulWidget {
  final Note note;
  final String highlightQuery;
  final bool isHighlighted; // Glow highlight after scroll-to
  final bool isSelected; // Selection mode for batch delete
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const NoteCard({
    super.key,
    required this.note,
    this.highlightQuery = '',
    this.isHighlighted = false,
    this.isSelected = false,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} · $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseStyle = theme.textTheme.bodyMedium!.copyWith(
      height: 1.6,
      color: isDark ? Colors.white.withAlpha(220) : Colors.black87,
    );

    final highlightStyle = baseStyle.copyWith(
      backgroundColor: isDark
          ? const Color(0xFF7986CB).withAlpha(100)
          : const Color(0xFF5C6BC0).withAlpha(60),
      color: isDark ? Colors.white : Colors.black,
      fontWeight: FontWeight.w600,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: widget.isSelected
            ? (isDark
                ? const Color(0xFF3F4280).withAlpha(120)
                : const Color(0xFFE8EBFF))
            : widget.isHighlighted
                ? (isDark
                    ? const Color(0xFF3F4280).withAlpha(160)
                    : const Color(0xFFE8EBFF))
                : (isDark
                    ? const Color(0xFF1E1E2E)
                    : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isSelected 
              ? (isDark ? const Color(0xFF7986CB) : const Color(0xFF5C6BC0))
              : widget.isHighlighted
                  ? (isDark ? const Color(0xFF7986CB) : const Color(0xFF5C6BC0))
                  : (isDark
                      ? Colors.white.withAlpha(15)
                      : Colors.black.withAlpha(12)),
          width: widget.isSelected ? 2.5 : (widget.isHighlighted ? 1.5 : 1),
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isHighlighted
                ? (isDark
                    ? const Color(0xFF5C6BC0).withAlpha(60)
                    : const Color(0xFF9FA8DA).withAlpha(80))
                : Colors.black.withAlpha(isDark ? 25 : 12),
            blurRadius: widget.isHighlighted ? 16 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onHighlightChanged: (isHighlighted) {
            if (isHighlighted) {
              _scaleController.forward();
            } else {
              _scaleController.reverse();
            }
          },
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timestamp row
                    Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 12,
                    color: isDark
                        ? Colors.white.withAlpha(100)
                        : Colors.black38,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(widget.note.createdAt),
                    style: theme.textTheme.labelSmall!.copyWith(
                      color: isDark ? Colors.white.withAlpha(100) : Colors.black38,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (widget.note.updatedAt != widget.note.createdAt) ...[
                    const SizedBox(width: 8),
                    Text(
                      '(edited)',
                      style: theme.textTheme.labelSmall!.copyWith(
                        color: isDark
                            ? Colors.white.withAlpha(70)
                            : Colors.black26,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              if (widget.note.title != null && widget.note.title!.trim().isNotEmpty) ...[
                Text(
                  widget.note.title!,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
              ],
              // Note content with optional highlight
              RichText(
                maxLines: 7,
                overflow: TextOverflow.ellipsis,
                text: buildHighlightedText(
                  text: widget.note.content,
                  query: widget.highlightQuery,
                  normalStyle: baseStyle,
                  highlightStyle: highlightStyle,
                ),
              ),
            ],
          ),
        ),
        if (widget.isSelected)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF7986CB) : const Color(0xFF5C6BC0),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 24,
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
