import 'package:flutter/material.dart';

class CategoryCard extends StatefulWidget {
  final String category;
  final VoidCallback onTap;
  final VoidCallback? onReload;
  final VoidCallback? onDelete;
  final int? articleCount;
  final bool isLoading;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    this.onReload,
    this.onDelete,
    this.articleCount,
    this.isLoading = false,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _actionsVisible = false;

  static const _actionsWidth = 120.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0;
    _controller.value -= delta / _actionsWidth;
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_controller.value > 0.4) {
      _controller.forward();
      setState(() => _actionsVisible = true);
    } else {
      _controller.reverse();
      setState(() => _actionsVisible = false);
    }
  }

  void _closeActions() {
    _controller.reverse();
    setState(() => _actionsVisible = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 76,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                // Action buttons behind the card — only visible during swipe
                if (_controller.value > 0)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    width: _actionsWidth,
                    child: Row(
                      children: [
                        Expanded(
                          child: Material(
                            color: Colors.blue,
                            child: InkWell(
                              onTap: () {
                                _closeActions();
                                widget.onReload?.call();
                              },
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.refresh, color: Colors.white, size: 22),
                                  SizedBox(height: 2),
                                  Text('Reload',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Material(
                            color: colorScheme.error,
                            child: InkWell(
                              onTap: () {
                                _closeActions();
                                widget.onDelete?.call();
                              },
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.delete_outline,
                                      color: Colors.white, size: 22),
                                  SizedBox(height: 2),
                                  Text('Xóa',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Foreground card that slides left
                Transform.translate(
                  offset: Offset(-_actionsWidth * _controller.value, 0),
                  child: child,
                ),
              ],
            );
          },
          child: Semantics(
            label: 'Danh mục ${_formatCategory(widget.category)}',
            button: true,
            hint: widget.onDelete != null ? 'Nhấn giữ để xem tùy chọn' : null,
            child: GestureDetector(
            onHorizontalDragUpdate: _handleDragUpdate,
            onHorizontalDragEnd: _handleDragEnd,
            onLongPress: widget.onDelete != null || widget.onReload != null
                ? () => _showActionsMenu()
                : null,
            onTap: () {
              if (_actionsVisible) {
                _closeActions();
              } else {
                widget.onTap();
              }
            },
            child: SizedBox(
              width: double.infinity,
              child: Container(
                margin: EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF00DCFF).withValues(alpha: 0.15),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        _iconForCategory(widget.category),
                        size: 32,
                        color: const Color(0xFF00DCFF),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatCategory(widget.category),
                              style:
                                  Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            _buildSubtitle(context),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }

  void _showActionsMenu() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.onReload != null)
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Tải lại'),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onReload!();
                },
              ),
            if (widget.onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Xóa', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onDelete!();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    if (widget.isLoading) {
      return Row(
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Color(0xFF00DCFF),
            ),
          ),
          const SizedBox(width: 6),
          Semantics(
            liveRegion: true,
            child: Text(
              'Đang tải...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
            ),
          ),
        ],
      );
    }

    final count = widget.articleCount;
    final text = count != null ? '$count bài viết' : 'Chưa tải';
    final color = count != null && count > 0
        ? Colors.white.withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.6);

    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'cong-nghe':
        return Icons.computer;
      case 'kinh-doanh':
        return Icons.business;
      case 'chung-khoan':
        return Icons.show_chart;
      default:
        return Icons.article;
    }
  }

  String _formatCategory(String category) {
    return category.split('-').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}
