import 'package:flutter/material.dart';

class ResumeCard extends StatelessWidget {
  final String category;
  final int articleIndex;
  final VoidCallback onTap;

  const ResumeCard({
    super.key,
    required this.category,
    required this.articleIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Tiếp tục nghe ${_formatCategory(category)}, bài ${articleIndex + 1}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 76,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00DCFF).withValues(alpha: 0.15),
                const Color(0xFF00DCFF).withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF00DCFF).withValues(alpha: 0.3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.play_circle_outline,
                  size: 32,
                  color: Color(0xFF00DCFF),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Tiếp tục nghe',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatCategory(category)} • Bài ${articleIndex + 1}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                      ),
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
    );
  }

  String _formatCategory(String category) {
    return category.split('-').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}
