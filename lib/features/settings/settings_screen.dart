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

    if (name.isEmpty || url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập đầy đủ tên và URL')),
        );
      }
      return;
    }
    if (!url.startsWith('https://')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL phải bắt đầu bằng https://')),
        );
      }
      return;
    }

    final category = CategoryConfig.fromUrl(url, name);
    final contentService = ref.read(contentServiceProvider);
    await contentService.addCategory(category);

    if (!mounted) return;
    _nameController.clear();
    _urlController.clear();
    FocusScope.of(context).unfocus();
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Cấu hình danh mục',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D0D2B),
              Color(0xFF1A1A4E),
              Color(0xFF0A2647),
              Color(0xFF144272),
            ],
            stops: [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.cyanAccent))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Tên danh mục',
                              labelStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7)),
                              hintText: 'Ví dụ: Quốc tế',
                              hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.3)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFF00DCFF)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _urlController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'URL trang danh mục',
                              labelStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7)),
                              hintText: 'https://soha.vn/quoc-te.htm',
                              hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.3)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFF00DCFF)),
                              ),
                            ),
                            keyboardType: TextInputType.url,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _addCategory,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyanAccent,
                              foregroundColor: const Color(0xFF0D0D2B),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text(
                              'Thêm danh mục',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                        color: Colors.white.withValues(alpha: 0.1), height: 1),
                    Expanded(
                      child: _categories.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.rss_feed,
                                      size: 48, color: Colors.cyanAccent),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Chưa có danh mục nào',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Thêm URL từ soha.vn để bắt đầu',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.4),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _categories.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final cat = _categories[index];
                                return Container(
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFF00DCFF)
                                          .withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: ListTile(
                                    leading: const Icon(Icons.rss_feed,
                                        color: Color(0xFF00DCFF)),
                                    title: Text(
                                      cat.name,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      cat.url,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.5)),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.redAccent),
                                      onPressed: () =>
                                          _removeCategory(cat.id),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
