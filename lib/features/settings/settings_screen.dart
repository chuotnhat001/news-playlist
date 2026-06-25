import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:news_playlist/models/category_config.dart';
import 'package:news_playlist/providers/content_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  List<CategoryConfig> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final contentService = ref.read(contentServiceProvider);
    final categories = await contentService.getCustomCategories();
    setState(() {
      _categories = categories;
      _loading = false;
    });
  }

  Future<void> _addCategory() async {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();

    if (name.isEmpty || url.isEmpty) return;
    if (!url.startsWith('http')) return;

    final category = CategoryConfig.fromUrl(url, name);
    final contentService = ref.read(contentServiceProvider);
    await contentService.addCategory(category);

    _nameController.clear();
    _urlController.clear();
    await _loadCategories();
  }

  Future<void> _removeCategory(String id) async {
    final contentService = ref.read(contentServiceProvider);
    await contentService.removeCategory(id);
    await _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cấu hình danh mục')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên danh mục',
                          hintText: 'Ví dụ: Quốc tế',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: 'URL trang danh mục',
                          hintText: 'https://soha.vn/quoc-te.htm',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _addCategory,
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm danh mục'),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: _categories.isEmpty
                      ? const Center(
                          child: Text(
                            'Chưa có danh mục nào.\nThêm URL từ soha.vn để bắt đầu.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final cat = _categories[index];
                            return ListTile(
                              leading: const Icon(Icons.rss_feed),
                              title: Text(cat.name),
                              subtitle: Text(cat.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _removeCategory(cat.id),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
