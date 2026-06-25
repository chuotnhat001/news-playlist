class CategoryConfig {
  final String id;
  final String name;
  final String url;
  final String source;

  const CategoryConfig({
    required this.id,
    required this.name,
    required this.url,
    required this.source,
  });

  static const createTableSQL = '''
    CREATE TABLE IF NOT EXISTS categories (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      url TEXT NOT NULL,
      source TEXT NOT NULL
    )
  ''';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'source': source,
    };
  }

  factory CategoryConfig.fromMap(Map<String, dynamic> map) {
    return CategoryConfig(
      id: map['id'] as String,
      name: map['name'] as String,
      url: map['url'] as String,
      source: map['source'] as String,
    );
  }

  factory CategoryConfig.fromUrl(String url, String name) {
    final uri = Uri.parse(url);
    final host = uri.host;
    String source;
    if (host.contains('soha.vn')) {
      source = 'soha';
    } else if (host.contains('dantri.com.vn')) {
      source = 'dantri';
    } else {
      source = host;
    }
    final id = '${source}_${name.toLowerCase().replaceAll(' ', '-')}';
    return CategoryConfig(id: id, name: name, url: url, source: source);
  }
}
