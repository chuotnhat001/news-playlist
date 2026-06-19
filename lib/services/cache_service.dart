import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'package:news_playlist/models/article.dart';

class CacheService {
  static const cacheTTL = Duration(hours: 6);

  late Database _db;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/news_playlist.db';
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(Article.createTableSQL);
      },
    );
  }

  Future<void> initWithDatabase(Database db) async {
    _db = db;
    await _db.execute(Article.createTableSQL);
  }

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

  int _cutoffMillis() {
    return DateTime.now().subtract(cacheTTL).millisecondsSinceEpoch;
  }
}
