import 'package:flutter/material.dart';

import 'package:news_playlist/models/article.dart';

class ArticleTile extends StatelessWidget {
  final Article article;
  final VoidCallback? onTap;

  const ArticleTile({
    super.key,
    required this.article,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.audiotrack, color: Color(0xFF00DCFF)),
      title: Text(
        article.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        '${article.source} • ${_formatDate(article.publishedAt)}',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
      ),
      onTap: onTap,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
