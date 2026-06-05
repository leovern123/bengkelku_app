import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../services/item_category_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common.dart';
import 'category_form_screen.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  List<CategoryModel> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _categories = await ItemCategoryService.getAll();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete(CategoryModel category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text('Yakin ingin menghapus kategori ${category.categoryName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ItemCategoryService.delete(category.itemCategoryId);
        _load();
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus kategori'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Kategori')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CategoryFormScreen()),
          );
          if (res == true) _load();
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _categories.isEmpty
                  ? const EmptyState(message: 'Belum ada kategori', icon: Icons.category)
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final cat = _categories[i];
                        return AppCard(
                          padding: const EdgeInsets.all(12),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.category, color: AppColors.primary),
                            ),
                            title: Text(cat.categoryName,
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () async {
                                    final res = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => CategoryFormScreen(category: cat)),
                                    );
                                    if (res == true) _load();
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _delete(cat),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
