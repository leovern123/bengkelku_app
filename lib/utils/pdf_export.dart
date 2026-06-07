import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/report_service.dart';
import '../models/order_model.dart';
import '../models/payment_model.dart';

// ── Color palette (matches AppColors) ─────────────────────────────────────
const _primary = PdfColor.fromInt(0xFF075FD8);
const _primaryDark = PdfColor.fromInt(0xFF06469D);
const _orange = PdfColor.fromInt(0xFFFF8A00);
const _green = PdfColor.fromInt(0xFF16A34A);
const _red = PdfColor.fromInt(0xFFDC2626);
const _textMuted = PdfColor.fromInt(0xFF6B7280);
const _border = PdfColor.fromInt(0xFFE5EAF2);
const _bg = PdfColor.fromInt(0xFFF5F8FC);

// ══════════════════════════════════════════════════════════════════════════
// Helpers
// ══════════════════════════════════════════════════════════════════════════

String _rupiah(double v) {
  final parts = v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
  return 'Rp $parts';
}

String _fmtDate(String? raw) {
  if (raw == null || raw.isEmpty) return '-';
  try {
    final dt = DateTime.parse(raw).toLocal();
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  } catch (_) {
    return raw.length >= 10 ? raw.substring(0, 10) : raw;
  }
}

String _fmtDateTime(String? raw) {
  if (raw == null || raw.isEmpty) return '-';
  try {
    final dt = DateTime.parse(raw).toLocal();
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return raw;
  }
}

String _statusLabel(String s) {
  switch (s) {
    case 'pending': return 'Pending';
    case 'process': return 'Diproses';
    case 'completed': return 'Selesai';
    case 'cancelled': return 'Dibatalkan';
    default: return s;
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

PdfColor _statusColor(String s) {
  switch (s) {
    case 'pending': return _primary;
    case 'process': return _orange;
    case 'completed': return _green;
    case 'cancelled': return _red;
    default: return _textMuted;
  }
}

// ── Shared header ──────────────────────────────────────────────────────────

pw.Widget _header(String title, {String? subtitle}) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(16),
    decoration: const pw.BoxDecoration(color: _primary),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('BENGKELKU',
          style: pw.TextStyle(
              color: PdfColors.white, fontSize: 20, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 2),
      pw.Text(title,
          style: const pw.TextStyle(color: PdfColors.white, fontSize: 13)),
      if (subtitle != null)
        pw.Text(subtitle,
            style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
    ]),
  );
}

pw.Widget _divider() => pw.Divider(color: _border, height: 1);

pw.Widget _kv(String label, String value,
    {bool bold = false, PdfColor? valueColor}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: const pw.TextStyle(color: _textMuted, fontSize: 11)),
        pw.Text(value,
            style: pw.TextStyle(
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                fontSize: bold ? 13 : 11,
                color: valueColor ?? PdfColors.black)),
      ],
    ),
  );
}

// ── Table helpers ──────────────────────────────────────────────────────────

pw.Widget _tableHeader(List<String> cols, List<double> widths) {
  return pw.Container(
    color: _primary,
    child: pw.Row(
      children: List.generate(cols.length, (i) {
        return pw.Container(
          width: widths[i],
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          child: pw.Text(cols[i],
              style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold)),
        );
      }),
    ),
  );
}

pw.Widget _tableRow(List<String> cells, List<double> widths, bool odd,
    {List<PdfColor?> cellColors = const []}) {
  return pw.Container(
    color: odd ? _bg : PdfColors.white,
    child: pw.Row(
      children: List.generate(cells.length, (i) {
        final color = i < cellColors.length ? cellColors[i] : null;
        return pw.Container(
          width: widths[i],
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: pw.Text(cells[i],
              style: pw.TextStyle(
                  fontSize: 9,
                  color: color ?? PdfColors.black)),
        );
      }),
    ),
  );
}

String _nowFormatted() {
  final now = DateTime.now();
  return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} '
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
}

pw.Widget _footer(String? period) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(top: 8),
    child: pw.Text(
      'Dicetak: ${_nowFormatted()}${period != null ? '  •  Periode: $period' : ''}',
      style: const pw.TextStyle(fontSize: 8, color: _textMuted),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════
// EXPORT: Ringkasan
// ══════════════════════════════════════════════════════════════════════════

Future<void> exportRingkasan(ReportSummary s, {String? period}) async {
  final doc = pw.Document();
  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(0),
    build: (ctx) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _header('Laporan Ringkasan', subtitle: period ?? 'Semua Periode'),
        pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Keuangan
              pw.Text('Keuangan',
                  style: pw.TextStyle(
                      fontSize: 13, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              _kv('Total Pendapatan', _rupiah(s.totalIncome),
                  bold: true, valueColor: _primary),
              _divider(),
              _kv('Total Modal Produk', _rupiah(s.totalModal)),
              _divider(),
              _kv('Total Pengeluaran', _rupiah(s.totalExpenses),
                  valueColor: _red),
              _divider(),
              _kv('Laba Kotor', _rupiah(s.labaKotor)),
              _divider(),
              _kv('Laba Bersih', _rupiah(s.labaBersih),
                  bold: true, valueColor: _green),
              pw.SizedBox(height: 20),

              // Order
              if (s.orders.isNotEmpty) ...[
                pw.Text('Statistik Order',
                    style: pw.TextStyle(
                        fontSize: 13, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                ...s.orders.entries.map((e) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: _kv(_statusLabel(e.key), '${e.value} order'),
                  );
                }),
              ],

              pw.SizedBox(height: 24),
              _footer(period),
            ],
          ),
        ),
      ],
    ),
  ));
  await Printing.layoutPdf(onLayout: (_) async => doc.save());
}

// ══════════════════════════════════════════════════════════════════════════
// EXPORT: Transaksi
// ══════════════════════════════════════════════════════════════════════════

Future<void> exportTransaksi(List<TransactionReport> list,
    {String? period}) async {
  final doc = pw.Document();

  const cols = ['No. Order', 'Pelanggan', 'Kendaraan', 'Item', 'Total', 'Status', 'Tanggal'];
  const widths = [70.0, 90.0, 75.0, 28.0, 70.0, 58.0, 65.0];

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(0),
    header: (ctx) => _header('Laporan Transaksi', subtitle: period ?? 'Semua Periode'),
    footer: (ctx) => pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(24, 4, 24, 8),
      child: _footer(period),
    ),
    build: (ctx) => [
      pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: pw.Text('Total: ${list.length} transaksi',
            style: const pw.TextStyle(fontSize: 10, color: _textMuted)),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 24),
        child: pw.Column(children: [
          _tableHeader(cols, widths),
          ...list.asMap().entries.map((e) {
            final t = e.value;
            return _tableRow([
              t.orderCode,
              t.customerName,
              t.vehiclePlate,
              '${t.itemCount}',
              _rupiah(t.totalAmount),
              _statusLabel(t.orderStatus),
              _fmtDate(t.createdAt),
            ], widths, e.key.isOdd,
                cellColors: [
                  null, null, null, null, null,
                  _statusColor(t.orderStatus),
                  null,
                ]);
          }),
        ]),
      ),
    ],
  ));
  await Printing.layoutPdf(onLayout: (_) async => doc.save());
}

// ══════════════════════════════════════════════════════════════════════════
// EXPORT: Pembayaran
// ══════════════════════════════════════════════════════════════════════════

Future<void> exportPembayaran(List<PaymentReport> list,
    {String? period}) async {
  final doc = pw.Document();

  const cols = ['No. Order', 'Pelanggan', 'Total', 'Dibayar', 'Kembalian', 'Metode', 'Tanggal'];
  const widths = [70.0, 90.0, 65.0, 65.0, 65.0, 55.0, 60.0];

  final grandTotal = list.fold(0.0, (s, p) => s + p.paidAmount);

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(0),
    header: (ctx) => _header('Laporan Pembayaran', subtitle: period ?? 'Semua Periode'),
    footer: (ctx) => pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(24, 4, 24, 8),
      child: _footer(period),
    ),
    build: (ctx) => [
      pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Total: ${list.length} pembayaran',
                style: const pw.TextStyle(fontSize: 10, color: _textMuted)),
            pw.Text('Grand Total: ${_rupiah(grandTotal)}',
                style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _primary)),
          ],
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 24),
        child: pw.Column(children: [
          _tableHeader(cols, widths),
          ...list.asMap().entries.map((e) {
            final p = e.value;
            return _tableRow([
              p.orderCode,
              p.customerName,
              _rupiah(p.totalAmount),
              _rupiah(p.paidAmount),
              _rupiah(p.changeAmount),
              _methodLabel(p.paymentMethod),
              _fmtDate(p.paymentDate),
            ], widths, e.key.isOdd);
          }),
        ]),
      ),
    ],
  ));
  await Printing.layoutPdf(onLayout: (_) async => doc.save());
}

// ══════════════════════════════════════════════════════════════════════════
// EXPORT: Stok
// ══════════════════════════════════════════════════════════════════════════

Future<void> exportStok(List<StockReport> list) async {
  final doc = pw.Document();

  const cols = ['Nama Produk', 'Kategori', 'Tipe', 'Stok', 'Modal', 'Harga Jual'];
  const widths = [120.0, 80.0, 60.0, 35.0, 75.0, 75.0];

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(0),
    header: (ctx) => _header('Laporan Stok Produk'),
    footer: (ctx) => pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(24, 4, 24, 8),
      child: _footer(null),
    ),
    build: (ctx) => [
      pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: pw.Text('Total: ${list.length} produk',
            style: const pw.TextStyle(fontSize: 10, color: _textMuted)),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 24),
        child: pw.Column(children: [
          _tableHeader(cols, widths),
          ...list.asMap().entries.map((e) {
            final s = e.value;
            PdfColor? stockColor;
            if (s.isLow) { stockColor = _red; }
            else if (s.isWarning) { stockColor = _orange; }
            return _tableRow([
              s.itemName,
              s.categoryName,
              s.typeName,
              '${s.stock}',
              _rupiah(s.purchasePrice),
              _rupiah(s.sellingPrice),
            ], widths, e.key.isOdd,
                cellColors: [null, null, null, stockColor, null, null]);
          }),
        ]),
      ),
    ],
  ));
  await Printing.layoutPdf(onLayout: (_) async => doc.save());
}

// ══════════════════════════════════════════════════════════════════════════
// EXPORT: Keuntungan (reuse summary dengan label berbeda)
// ══════════════════════════════════════════════════════════════════════════

Future<void> exportKeuntungan(ReportSummary s, {String? period}) async {
  final doc = pw.Document();
  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(0),
    build: (ctx) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _header('Laporan Keuntungan', subtitle: period ?? 'Semua Periode'),
        pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _kv('Total Pendapatan', _rupiah(s.totalIncome),
                  bold: true, valueColor: _primary),
              _divider(),
              _kv('Total Modal Produk', _rupiah(s.totalModal)),
              _divider(),
              _kv('Total Pengeluaran', _rupiah(s.totalExpenses),
                  valueColor: _red),
              _divider(),
              pw.SizedBox(height: 8),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _border),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(children: [
                  _kv('Laba Kotor', _rupiah(s.labaKotor),
                      valueColor: _primaryDark),
                  pw.SizedBox(height: 4),
                  _kv('Laba Bersih', _rupiah(s.labaBersih),
                      bold: true, valueColor: _green),
                ]),
              ),
              pw.SizedBox(height: 24),
              _footer(period),
            ],
          ),
        ),
      ],
    ),
  ));
  await Printing.layoutPdf(onLayout: (_) async => doc.save());
}

// ══════════════════════════════════════════════════════════════════════════
// EXPORT: Struk Pembayaran (nota)
// ══════════════════════════════════════════════════════════════════════════

Future<void> exportStruk(OrderModel order, PaymentModel payment,
    {String kasir = '-'}) async {
  final doc = pw.Document();

  doc.addPage(pw.Page(
    // Lebar struk thermal: 80mm
    pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity,
        marginAll: 8 * PdfPageFormat.mm),
    build: (ctx) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // Header
          pw.Center(
            child: pw.Column(children: [
              pw.Text('BENGKELKU',
                  style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: _primaryDark)),
              pw.Text('Nota Bengkel Motor',
                  style: const pw.TextStyle(fontSize: 9, color: _textMuted)),
            ]),
          ),
          pw.SizedBox(height: 8),
          _divider(),
          pw.SizedBox(height: 6),
          _kv('No. Order', order.orderCode),
          _kv('Tanggal', _fmtDateTime(payment.paymentDate)),
          _kv('Kasir', kasir),
          if (order.customer != null)
            _kv('Pelanggan', order.customer!.customerName),
          if (order.vehicle != null)
            _kv('Kendaraan', order.vehicle!.licensePlate),
          if (order.mechanic != null)
            _kv('Mekanik', order.mechanic!.mechanicName),
          pw.SizedBox(height: 6),
          _divider(),
          pw.SizedBox(height: 6),
          pw.Text('Detail',
              style: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          ...order.details.map((d) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                        child: pw.Text(d.item?.itemName ?? d.itemId,
                            style: const pw.TextStyle(fontSize: 9))),
                    pw.SizedBox(width: 4),
                    pw.Text('${d.quantity}x',
                        style: const pw.TextStyle(
                            fontSize: 9, color: _textMuted)),
                    pw.SizedBox(width: 4),
                    pw.Text(_rupiah(d.subtotal),
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              )),
          pw.SizedBox(height: 6),
          _divider(),
          pw.SizedBox(height: 6),
          _kv('Total', _rupiah(order.totalAmount),
              bold: true, valueColor: _primary),
          _kv('Metode', _methodLabel(payment.paymentMethod)),
          _kv('Dibayar', _rupiah(payment.paidAmount)),
          _kv('Kembalian', _rupiah(payment.changeAmount),
              valueColor: _green),
          pw.SizedBox(height: 10),
          _divider(),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text('Terima kasih atas kepercayaan Anda!',
                style: const pw.TextStyle(
                    fontSize: 8, color: _textMuted),
                textAlign: pw.TextAlign.center),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(_nowFormatted(),
                style: const pw.TextStyle(fontSize: 8, color: _textMuted)),
          ),
        ],
      );
    },
  ));

  await Printing.layoutPdf(onLayout: (_) async => doc.save());
}
