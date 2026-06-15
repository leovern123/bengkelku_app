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
  String _search = '';
  int _tab = 1; // 1=Sparepart, 2=Jasa

  List<CategoryModel> get _sparepart =>
      _categories.where((c) => c.itemTypeId == 1).toList();

  List<CategoryModel> get _jasa =>
      _categories.where((c) => c.itemTypeId == 2).toList();

  List<CategoryModel> get _filtered {
    final list = _tab == 1 ? _sparepart : _jasa;
    if (_search.isEmpty) return list;
    return list
        .where((c) => c.categoryName.toLowerCase().contains(_search.toLowerCase()))
        .toList();
  }


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
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
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
          const SnackBar(
              content: Text('Gagal menghapus kategori'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _categoryCard(CategoryModel cat, Color color, IconData icon) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(cat.categoryName,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
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
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => _delete(cat),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabBtn(int key, String label, int count) {
    final active = _tab == key;
    return GestureDetector(
      onTap: () => setState(() => _tab = key),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Column(
          children: [
            Text('$count',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: active ? Colors.white : AppColors.textPrimary)),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _tab == 1 ? AppColors.green : AppColors.orange;
    final icon = _tab == 1 ? Icons.inventory_2_outlined : Icons.build_outlined;
    final filtered = _filtered;

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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: AppSearchBar(
              hint: 'Cari kategori...',
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: _tabBtn(1, 'Sparepart', _sparepart.length)),
                const SizedBox(width: 8),
                Expanded(child: _tabBtn(2, 'Jasa', _jasa.length)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _categories.isEmpty
                        ? const EmptyState(
                            message: 'Belum ada kategori',
                            icon: Icons.category_outlined)
                        : filtered.isEmpty
                            ? EmptyState(
                                message: _search.isEmpty
                                    ? 'Belum ada kategori'
                                    : 'Kategori tidak ditemukan',
                                icon: _search.isEmpty
                                    ? Icons.category_outlined
                                    : Icons.search_off_outlined)
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (_, i) =>
                                    _categoryCard(filtered[i], color, icon),
                              ),
                  ),
          ),
        ],
      ),
    );
  }
}
