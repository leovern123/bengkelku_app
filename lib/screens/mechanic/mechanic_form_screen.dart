import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/mechanic_model.dart';
import '../../services/mechanic_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common.dart';

class MechanicFormScreen extends StatefulWidget {
  final MechanicModel? mechanic;
  const MechanicFormScreen({super.key, this.mechanic});

  @override
  State<MechanicFormScreen> createState() => _MechanicFormScreenState();
}

class _MechanicFormScreenState extends State<MechanicFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _nikCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  XFile? _photo;
  Uint8List? _photoBytes;
  bool _loading = false;

  bool get isEdit => widget.mechanic != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      _nameCtrl.text = widget.mechanic!.mechanicName;
      _nikCtrl.text = widget.mechanic!.nik ?? '';
      _phoneCtrl.text = widget.mechanic!.phoneNumber ?? '';
      _addressCtrl.text = widget.mechanic!.address ?? '';
      _notesCtrl.text = widget.mechanic!.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nikCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 40, maxWidth: 200, maxHeight: 200);
    if (picked != null && mounted) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _photo = picked;
        _photoBytes = bytes;
      });
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(99)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              title: const Text('Ambil Foto', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (_photo != null || (widget.mechanic?.photoUrl != null))
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.red),
                title: const Text('Hapus Foto', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() { _photo = null; _photoBytes = null; });
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _parseError(dynamic e) {
    if (e is DioException) {
      if (e.response != null) {
        final data = e.response!.data;
        if (data is Map) {
          final errors = data['errors'];
          if (errors is Map) {
            return errors.values.expand((v) => v is List ? v : [v]).join('\n');
          }
          return data['message']?.toString() ?? 'Error ${e.response!.statusCode}';
        }
        return 'Server error ${e.response!.statusCode}';
      }
      return 'Network error: ${e.message}';
    }
    return 'Error: $e';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final data = {
        'mechanic_name': _nameCtrl.text.trim(),
        'nik': _nikCtrl.text.trim(),
        'phone_number': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'notes': _notesCtrl.text.trim(),
      };

      if (isEdit) {
        await MechanicService.update(widget.mechanic!.mechanicId, data, photo: _photo);
      } else {
        await MechanicService.create(data, photo: _photo);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Mekanik berhasil ${isEdit ? 'diperbarui' : 'ditambahkan'}'),
        backgroundColor: AppColors.green,
      ));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_parseError(e)), backgroundColor: AppColors.red));
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final existingPhotoUrl = widget.mechanic?.photoUrl;
    final hasPhoto = _photoBytes != null || existingPhotoUrl != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Update Mekanik' : 'Tambah Mekanik')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Picker
              Center(
                child: GestureDetector(
                  onTap: _showPhotoOptions,
                  child: Stack(
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withAlpha(15),
                          border: Border.all(
                            color: hasPhoto ? AppColors.primary : AppColors.border,
                            width: hasPhoto ? 2.5 : 1.5,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _photoBytes != null
                            ? Image.memory(_photoBytes!, fit: BoxFit.cover)
                            : existingPhotoUrl != null
                                ? Image.network(
                                    existingPhotoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.engineering,
                                      size: 48,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : const Icon(Icons.engineering, size: 48, color: AppColors.primary),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text('Ketuk untuk ubah foto', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ),
              const SizedBox(height: 20),

              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Informasi Mekanik',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Mekanik',
                        prefixIcon: Icon(Icons.engineering_outlined, color: AppColors.textMuted),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Nama mekanik wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nikCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'NIK',
                        prefixIcon: Icon(Icons.badge_outlined, color: AppColors.textMuted),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'NIK wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'No. Telepon',
                        prefixIcon: Icon(Icons.phone_outlined, color: AppColors.textMuted),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'No. telepon wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Alamat',
                        prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.textMuted),
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Alamat wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Keterangan',
                        prefixIcon: Icon(Icons.notes_outlined, color: AppColors.textMuted),
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Keterangan wajib diisi'
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: isEdit ? 'Update Mekanik' : 'Tambah Mekanik',
                icon: isEdit ? Icons.save : Icons.add,
                isLoading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
