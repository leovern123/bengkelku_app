import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../services/payment_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common.dart';
import 'receipt_screen.dart';

class PaymentScreen extends StatefulWidget {
  final OrderModel order;
  const PaymentScreen({super.key, required this.order});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _paidCtrl = TextEditingController();
  String _method = 'cash';
  double _change = 0;
  bool _loading = false;

  final _methods = [
    {'key': 'cash', 'label': 'Tunai', 'icon': Icons.money},
    {'key': 'qris', 'label': 'QRIS', 'icon': Icons.qr_code},
    {'key': 'transfer', 'label': 'Transfer', 'icon': Icons.account_balance},
    {'key': 'debit', 'label': 'Debit', 'icon': Icons.credit_card},
  ];

  @override
  void initState() {
    super.initState();
    _paidCtrl.text = widget.order.totalAmount.toStringAsFixed(0);
    _paidCtrl.addListener(_calc);
    _calc();
  }

  @override
  void dispose() {
    _paidCtrl.dispose();
    super.dispose();
  }

  void _calc() {
    final paid = double.tryParse(_paidCtrl.text) ?? 0;
    setState(() => _change = paid - widget.order.totalAmount);
  }

  Future<void> _submit() async {
    final paid = double.tryParse(_paidCtrl.text) ?? 0;
    if (paid <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Masukkan jumlah bayar'), backgroundColor: AppColors.red));
      return;
    }
    if (paid < widget.order.totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Kurang ${rupiah(widget.order.totalAmount - paid)}'),
        backgroundColor: AppColors.red,
      ));
      return;
    }

    setState(() => _loading = true);
    try {
      final payment = await PaymentService.create(
        orderId: widget.order.orderId,
        paymentMethod: _method,
        paidAmount: paid,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ReceiptScreen(order: widget.order, payment: payment)),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pembayaran gagal'), backgroundColor: AppColors.red));
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order summary
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(title: 'Ringkasan Order'),
                  const SizedBox(height: 12),
                  _row('No. Order', widget.order.orderCode),
                  _row('Pelanggan', widget.order.customer?.customerName ?? '-'),
                  _row('Kendaraan', widget.order.vehicle?.licensePlate ?? '-'),
                  const Divider(height: 20, color: AppColors.border),
                  ...widget.order.details.map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(child: Text(d.item?.itemName ?? d.itemId,
                                style: const TextStyle(fontSize: 13))),
                            Text('${d.quantity}x', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            const SizedBox(width: 8),
                            Text(rupiah(d.subtotal), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          ],
                        ),
                      )),
                  const Divider(height: 20, color: AppColors.border),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                      Text(rupiah(widget.order.totalAmount),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Payment method
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(title: 'Metode Pembayaran'),
                  const SizedBox(height: 12),
                  Row(
                    children: _methods.map((m) {
                      final active = _method == m['key'];
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _method = m['key'] as String),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: active ? AppColors.primary : AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: active ? AppColors.primary : AppColors.border),
                            ),
                            child: Column(
                              children: [
                                Icon(m['icon'] as IconData,
                                    color: active ? Colors.white : AppColors.textMuted, size: 20),
                                const SizedBox(height: 4),
                                Text(m['label'] as String,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: active ? Colors.white : AppColors.textMuted)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _paidCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah Bayar',
                      prefixText: 'Rp ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _change >= 0 ? AppColors.green.withAlpha(20) : AppColors.red.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _change >= 0 ? AppColors.green.withAlpha(80) : AppColors.red.withAlpha(80)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Kembalian', style: TextStyle(fontWeight: FontWeight.w700)),
                        Text(
                          rupiah(_change < 0 ? 0 : _change),
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: _change >= 0 ? AppColors.green : AppColors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Proses Pembayaran',
              icon: Icons.check_circle_outline,
              isLoading: _loading,
              onPressed: _submit,
              color: AppColors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(width: 90, child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13))),
            const Text(': ', style: TextStyle(color: AppColors.textMuted)),
            Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          ],
        ),
      );
}
