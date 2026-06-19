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
      leading: const Icon(Icons.audiotrack),
      title: Text(
        article.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${article.source} • ${_formatDate(article.publishedAt)}',
      ),
      onTap: onTap,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
