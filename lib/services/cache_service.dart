import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'package:news_playlist/models/article.dart';
import 'package:news_playlist/models/category_config.dart';

class CacheService {
  static const cacheTTL = Duration(hours: 6);

  late Database _db;
  bool _initialized = false;

  bool get isReady => _initialized;

  Future<void> init() async {
    if (_initialized) return;
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/news_playlist.db';
    _db = await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute(Article.createTableSQL);
        await db.execute(CategoryConfig.createTableSQL);
        await db.execute(_createPlaybackStateSQL);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(CategoryConfig.createTableSQL);
        }
        if (oldVersion < 3) {
          await db.execute(_createPlaybackStateSQL);
        }
      },
    );
    _initialized = true;
  }

  Future<void> initWithDatabase(Database db) async {
    if (_initialized) return;
    _db = db;
    await _db.execute(Article.createTableSQL);
    await _db.execute(CategoryConfig.createTableSQL);
    await _db.execute(_createPlaybackStateSQL);
    _initialized = true;
  }

  static const _createPlaybackStateSQL = '''
    CREATE TABLE IF NOT EXISTS playback_state (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      category TEXT NOT NULL,
      category_url TEXT,
      article_index INTEGER NOT NULL,
      position_ms INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''';

  // Articles
  Future<void> insertArticles(List<Article> articles) async {
    await _db.transaction((txn) async {
      for (final article in articles) {
        await txn.insert(
          'articles',
          article.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<Article>> getArticlesByCategory(String category) async {
    final cutoff = _cutoffMillis();
    final results = await _db.query(
      'articles',
      where: 'category = ? AND cachedAt > ?',
      whereArgs: [category, cutoff],
      orderBy: 'publishedAt DESC',
    );
    return results.map((map) => Article.fromMap(map)).toList();
  }

  Future<bool> isStale(String category) async {
    final cutoff = _cutoffMillis();
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM articles WHERE category = ? AND cachedAt > ?',
      [category, cutoff],
    );
    final count = Sqflite.firstIntValue(result) ?? 0;
    return count == 0;
  }

  Future<void> clearExpired() async {
    final cutoff = _cutoffMillis();
    await _db.delete(
      'articles',
      where: 'cachedAt < ?',
      whereArgs: [cutoff],
    );
  }

  Future<void> clearAll() async {
    await _db.delete('articles');
  }

  // Categories
  Future<void> insertCategory(CategoryConfig category) async {
    await _db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteCategory(String id) async {
    await _db.delete('categories', where: 'id = ?', whereArgs: [id]);
    await _db.delete('articles', where: 'category = ?', whereArgs: [id]);
  }

  Future<List<CategoryConfig>> getCategories() async {
    final results = await _db.query('categories');
    return results.map((map) => CategoryConfig.fromMap(map)).toList();
  }

  Future<int> getArticleCount(String categoryId) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as cnt FROM articles WHERE category = ?',
      [categoryId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  int _cutoffMillis() {
    return DateTime.now().subtract(cacheTTL).millisecondsSinceEpoch;
  }

  // Playback state persistence
  Future<void> savePlaybackState({
    required String category,
    String? categoryUrl,
    required int articleIndex,
    required int positionMs,
  }) async {
    await _db.insert(
      'playback_state',
      {
        'id': 1,
        'category': category,
        'category_url': categoryUrl,
        'article_index': articleIndex,
        'position_ms': positionMs,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getPlaybackState() async {
    final results = await _db.query('playback_state', where: 'id = 1');
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<void> clearPlaybackState() async {
    await _db.delete('playback_state');
  }
}
