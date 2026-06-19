class Article {
  final String id;
  final String title;
  final String source;
  final String audioUrl;
  final String articleUrl;
  final String category;
  final DateTime publishedAt;
  final DateTime cachedAt;

  const Article({
    required this.id,
    required this.title,
    required this.source,
    required this.audioUrl,
    required this.articleUrl,
    required this.category,
    required this.publishedAt,
    required this.cachedAt,
  });

  static const createTableSQL = '''
    CREATE TABLE IF NOT EXISTS articles (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      source TEXT NOT NULL,
      audioUrl TEXT NOT NULL,
      articleUrl TEXT NOT NULL,
      category TEXT NOT NULL,
      publishedAt INTEGER NOT NULL,
      cachedAt INTEGER NOT NULL
    )
  ''';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'source': source,
      'audioUrl': audioUrl,
      'articleUrl': articleUrl,
      'category': category,
      'publishedAt': publishedAt.millisecondsSinceEpoch,
      'cachedAt': cachedAt.millisecondsSinceEpoch,
    };
  }

  factory Article.fromMap(Map<String, dynamic> map) {
    return Article(
      id: map['id'] as String,
      title: map['title'] as String,
      source: map['source'] as String,
      audioUrl: map['audioUrl'] as String,
      articleUrl: map['articleUrl'] as String,
      category: map['category'] as String,
      publishedAt:
          DateTime.fromMillisecondsSinceEpoch(map['publishedAt'] as int),
      cachedAt: DateTime.fromMillisecondsSinceEpoch(map['cachedAt'] as int),
    );
  }

  Article copyWith({
    String? id,
    String? title,
    String? source,
    String? audioUrl,
    String? articleUrl,
    String? category,
    DateTime? publishedAt,
    DateTime? cachedAt,
  }) {
    return Article(
      id: id ?? this.id,
      title: title ?? this.title,
      source: source ?? this.source,
      audioUrl: audioUrl ?? this.audioUrl,
      articleUrl: articleUrl ?? this.articleUrl,
      category: category ?? this.category,
      publishedAt: publishedAt ?? this.publishedAt,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Article && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
