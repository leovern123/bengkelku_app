import 'package:flutter/material.dart';
import '../../models/mechanic_model.dart';
import '../../services/mechanic_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common.dart';
import 'mechanic_form_screen.dart';

class MechanicListScreen extends StatefulWidget {
  const MechanicListScreen({super.key});

  @override
  State<MechanicListScreen> createState() => _MechanicListScreenState();
}

class _MechanicListScreenState extends State<MechanicListScreen> {
  List<MechanicModel> _all = [];
  String _search = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _all = await MechanicService.getAll();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<MechanicModel> get _filtered => _all.where((m) {
        final q = _search.toLowerCase();
        if (q.isEmpty) return true;
        return m.mechanicName.toLowerCase().contains(q) ||
            (m.nik ?? '').contains(q) ||
            (m.phoneNumber ?? '').contains(q) ||
            (m.notes ?? '').toLowerCase().contains(q);
      }).toList();

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  Future<void> _delete(MechanicModel m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Mekanik'),
        content: Text('Hapus mekanik "${m.mechanicName}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await MechanicService.delete(m.mechanicId);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Mekanik dihapus'),
            backgroundColor: AppColors.green));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Gagal menghapus mekanik'),
            backgroundColor: AppColors.red));
      }
    }
  }

  Widget _buildAvatar(MechanicModel m) {
    if (m.photoUrl != null && m.photoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          m.photoUrl!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultAvatar(),
        ),
      );
    }
    return _defaultAvatar();
  }

  Widget _defaultAvatar() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.engineering, color: AppColors.primaryDark, size: 24),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mekanik')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryDark,
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('Tambah Mekanik', style: TextStyle(color: Colors.white)),
        onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MechanicFormScreen()))
            .then((_) => _load()),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: AppSearchBar(
                hint: 'Cari nama, NIK, telepon...',
                onChanged: (v) => setState(() => _search = v)),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? const EmptyState(
                            message: 'Tidak ada mekanik',
                            icon: Icons.engineering_outlined)
                        : ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(18, 0, 18, 100),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final m = _filtered[i];
                              final dateStr = _formatDate(m.updatedAt);
                              return AppCard(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    _buildAvatar(m),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(m.mechanicName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 15,
                                                  color: AppColors.textPrimary)),
                                          if (m.nik != null && m.nik!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Row(children: [
                                                const Icon(Icons.badge_outlined,
                                                    size: 12,
                                                    color: AppColors.textMuted),
                                                const SizedBox(width: 4),
                                                Text('NIK: ${m.nik!}',
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: AppColors.textMuted)),
                                              ]),
                                            ),
                                          if (m.phoneNumber != null &&
                                              m.phoneNumber!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Row(children: [
                                                const Icon(Icons.phone_outlined,
                                                    size: 12,
                                                    color: AppColors.textMuted),
                                                const SizedBox(width: 4),
                                                Text(m.phoneNumber!,
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: AppColors.textMuted)),
                                              ]),
                                            ),
                                          if (m.notes != null &&
                                              m.notes!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Row(children: [
                                                const Icon(Icons.notes_outlined,
                                                    size: 12,
                                                    color: AppColors.textMuted),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(m.notes!,
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          color: AppColors.textMuted),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis),
                                                ),
                                              ]),
                                            ),
                                          if (dateStr.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Row(children: [
                                                const Icon(Icons.update_outlined,
                                                    size: 12,
                                                    color: AppColors.textMuted),
                                                const SizedBox(width: 4),
                                                Text('Update: $dateStr',
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        color: AppColors.textMuted)),
                                              ]),
                                            ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (val) async {
                                        if (val == 'update') {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    MechanicFormScreen(
                                                        mechanic: m)),
                                          );
                                          _load();
                                        } else if (val == 'delete') {
                                          _delete(m);
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(
                                            value: 'update',
                                            child: Text('Update')),
                                        const PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Hapus',
                                                style: TextStyle(
                                                    color: AppColors.red))),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
