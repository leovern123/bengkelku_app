import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/order_model.dart';
import '../../models/payment_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/pdf_export.dart';
import '../../widgets/common.dart';

class ReceiptScreen extends StatefulWidget {
  final OrderModel order;
  final PaymentModel payment;
  const ReceiptScreen({super.key, required this.order, required this.payment});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  String _kasir = '-';

  @override
  void initState() {
    super.initState();
    _loadKasir();
  }

  Future<void> _loadKasir() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonDecode(prefs.getString('user_data') ?? '{}');
    final name = data['name'] ?? '-';
    if (mounted) {
      setState(() => _kasir = name);
      // Auto-cetak nota setelah layar terbuka
      await exportStruk(widget.order, widget.payment, kasir: name);
    }
  }

  Future<void> _cetakUlang() async {
    await exportStruk(widget.order, widget.payment, kasir: _kasir);
  }

  String _formatDate(String? dt) {
    if (dt == null) return '-';
    try {
      final d = DateTime.parse(dt).toLocal();
      return '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dt;
    }
  }

  String _methodLabel(String m) {
    switch (m) {
      case 'cash': return 'Tunai';
      case 'qris': return 'QRIS';
      case 'transfer': return 'Transfer Bank';
      case 'debit': return 'Kartu Debit';
      default: return m;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nota Pembayaran'),
        backgroundColor: AppColors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () =>
                Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (_) => false),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Success banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 52),
                  SizedBox(height: 8),
                  Text('Pembayaran Berhasil!',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Receipt
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  const Column(
                    children: [
                      Icon(Icons.two_wheeler, size: 40, color: AppColors.primaryDark),
                      SizedBox(height: 6),
                      Text('BENGKELKU',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
                      Text('Nota Bengkel Motor',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.border),

                  _receiptRow('No. Order', widget.order.orderCode),
                  _receiptRow('Tanggal', _formatDate(widget.payment.paymentDate)),
                  _receiptRow('Kasir', _kasir),
                  const Divider(height: 16, color: AppColors.border),

                  _receiptRow('Pelanggan', widget.order.customer?.customerName ?? '-'),
                  _receiptRow('Kendaraan',
                      '${widget.order.vehicle?.licensePlate ?? '-'} ${widget.order.vehicle?.brand != null ? '(${widget.order.vehicle!.brand} ${widget.order.vehicle?.model ?? ''})' : ''}'),
                  const Divider(height: 16, color: AppColors.border),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Detail Layanan',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                  const SizedBox(height: 8),
                  ...widget.order.details.map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(child: Text(d.item?.itemName ?? d.itemId,
                                style: const TextStyle(fontSize: 13))),
                            Text('${d.quantity}x',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            const SizedBox(width: 8),
                            Text(rupiah(d.subtotal),
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          ],
                        ),
                      )),
                  const Divider(height: 16, color: AppColors.border),

                  _receiptRow('Total', rupiah(widget.order.totalAmount), bold: true, valueColor: AppColors.primary),
                  _receiptRow('Metode', _methodLabel(widget.payment.paymentMethod)),
                  _receiptRow('Dibayar', rupiah(widget.payment.paidAmount)),
                  _receiptRow('Kembalian', rupiah(widget.payment.changeAmount),
                      valueColor: AppColors.green),
                  const Divider(height: 20, color: AppColors.border),

                  const Center(
                    child: Text('Terima kasih atas kepercayaan Anda!',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, fontSize: 13, color: AppColors.textMuted)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            PrimaryButton(
              label: 'Cetak Ulang Nota',
              icon: Icons.print_outlined,
              color: AppColors.primary,
              onPressed: _cetakUlang,
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: 'Order Lagi',
              icon: Icons.receipt_long,
              color: AppColors.orange,
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context, '/open-bill', (r) => r.settings.name == '/dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          Text(value,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
                  fontSize: bold ? 15 : 13,
                  color: valueColor ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}
