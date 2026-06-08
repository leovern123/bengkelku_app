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
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.green,
            foregroundColor: Colors.white,
            title: const Text('Nota Pembayaran',
                style: TextStyle(fontWeight: FontWeight.w700)),
            actions: [
              IconButton(
                icon: const Icon(Icons.home_rounded, color: Colors.white),
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, '/dashboard', (_) => false),
              ),
              const SizedBox(width: 4),
            ],
            expandedHeight: 180,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF166534), AppColors.green],
                  ),
                ),
                child: const SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 40),
                      Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 56),
                      SizedBox(height: 8),
                      Text(
                        'Pembayaran Berhasil!',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900),
                      ),
                      Text(
                        'Nota otomatis dicetak',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(18),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Column(
                          children: [
                            Icon(Icons.two_wheeler_rounded,
                                size: 36, color: AppColors.primaryDark),
                            SizedBox(height: 6),
                            Text('BENGKELKU',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primaryDark,
                                    letterSpacing: 1)),
                            Text('Nota Bengkel Motor',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: _DottedDivider(),
                        ),
                        _row('No. Order', widget.order.orderCode),
                        _row('Tanggal',
                            _formatDate(widget.payment.paymentDate)),
                        _row('Kasir', _kasir),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: _DottedDivider(),
                        ),
                        _row('Pelanggan',
                            widget.order.customer?.customerName ?? '-'),
                        _row('Kendaraan',
                            '${widget.order.vehicle?.licensePlate ?? '-'}${widget.order.vehicle?.brand != null ? ' (${widget.order.vehicle!.brand} ${widget.order.vehicle?.model ?? ''})' : ''}'),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: _DottedDivider(),
                        ),
                        const Text('Detail Layanan',
                            style: TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 13)),
                        const SizedBox(height: 10),
                        ...widget.order.details.map((d) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                      child: Text(
                                          d.item?.itemName ?? d.itemId,
                                          style:
                                              const TextStyle(fontSize: 13))),
                                  Text('${d.quantity}x',
                                      style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12)),
                                  const SizedBox(width: 10),
                                  Text(rupiah(d.subtotal),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13)),
                                ],
                              ),
                            )),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: _DottedDivider(),
                        ),
                        _row('Total', rupiah(widget.order.totalAmount),
                            bold: true, valueColor: AppColors.primary),
                        _row('Metode', _methodLabel(widget.payment.paymentMethod)),
                        _row('Dibayar', rupiah(widget.payment.paidAmount)),
                        _row('Kembalian',
                            rupiah(widget.payment.changeAmount),
                            valueColor: AppColors.green),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: _DottedDivider(),
                        ),
                        const Center(
                          child: Text(
                            'Terima kasih atas kepercayaan Anda!',
                            style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                                color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Cetak Ulang Nota',
                    icon: Icons.print_rounded,
                    color: AppColors.primary,
                    onPressed: _cetakUlang,
                  ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: 'Order Lagi',
                    icon: Icons.receipt_long_rounded,
                    color: AppColors.orange,
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/open-bill',
                      (r) => r.settings.name == '/dashboard',
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value,
      {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
                    fontSize: bold ? 15 : 13,
                    color: valueColor ?? AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _DottedDivider extends StatelessWidget {
  const _DottedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final count = (constraints.maxWidth / 8).floor();
      return Row(
        children: List.generate(
          count,
          (_) => Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              height: 1,
              color: AppColors.border,
            ),
          ),
        ),
      );
    });
  }
}
