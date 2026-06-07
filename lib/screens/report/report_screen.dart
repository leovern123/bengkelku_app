import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/report_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/pdf_export.dart';
import '../../widgets/common.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  // ── Shared filter ──────────────────────────────────────────────────────
  int? _filterYear;
  int? _filterMonth;
  int? _filterDay;

  // ── Data states ────────────────────────────────────────────────────────
  ReportSummary? _summary;
  bool _summaryLoading = true;

  List<TransactionReport> _transactions = [];
  bool _txLoading = true;

  List<PaymentReport> _payments = [];
  bool _payLoading = true;

  List<StockReport> _stocks = [];
  bool _stockLoading = true;

  // Chart
  List<ChartPoint> _chartPoints = [];
  bool _chartLoading = true;
  String _chartPeriod = 'monthly';

  bool _exporting = false;
  int _chartYear = DateTime.now().year;
  int _chartMonth = DateTime.now().month;

  static const _monthShort = [
    'Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des',
  ];
  static const _monthFull = [
    'Januari','Februari','Maret','April','Mei','Juni',
    'Juli','Agustus','September','Oktober','November','Desember',
  ];

  // ── Lifecycle ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadSummary(),
      _loadTransactions(),
      _loadPayments(),
      _loadStock(),
      _loadChart(),
    ]);
  }

  // ── Filter helpers ─────────────────────────────────────────────────────

  String? get _startDate {
    if (_filterYear == null) return null;
    final m = _filterMonth ?? 1;
    final d = _filterDay ?? 1;
    return '$_filterYear-${m.toString().padLeft(2,'0')}-${d.toString().padLeft(2,'0')}';
  }

  String? get _endDate {
    if (_filterYear == null) return null;
    if (_filterMonth == null) return '$_filterYear-12-31';
    if (_filterDay != null) return _startDate;
    final last = DateUtils.getDaysInMonth(_filterYear!, _filterMonth!);
    return '$_filterYear-${_filterMonth.toString().padLeft(2,'0')}-${last.toString().padLeft(2,'0')}';
  }

  void _onFilterChanged() {
    _loadSummary();
    _loadTransactions();
    _loadPayments();
    // stock doesn't use date filter
  }

  void _resetFilter() {
    setState(() { _filterYear = null; _filterMonth = null; _filterDay = null; });
    _onFilterChanged();
  }

  // ── Data loaders ───────────────────────────────────────────────────────

  Future<void> _loadSummary() async {
    setState(() => _summaryLoading = true);
    try {
      final d = _filterYear != null
          ? await ReportService.getProfit(startDate: _startDate, endDate: _endDate)
          : await ReportService.getSummary();
      if (mounted) setState(() { _summary = d; _summaryLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _summaryLoading = false);
    }
  }

  Future<void> _loadTransactions() async {
    setState(() => _txLoading = true);
    try {
      final d = await ReportService.getTransactions(startDate: _startDate, endDate: _endDate);
      if (mounted) setState(() { _transactions = d; _txLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _txLoading = false);
    }
  }

  Future<void> _loadPayments() async {
    setState(() => _payLoading = true);
    try {
      final d = await ReportService.getPayments(startDate: _startDate, endDate: _endDate);
      if (mounted) setState(() { _payments = d; _payLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _payLoading = false);
    }
  }

  Future<void> _loadStock() async {
    setState(() => _stockLoading = true);
    try {
      final d = await ReportService.getStock();
      if (mounted) setState(() { _stocks = d; _stockLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _stockLoading = false);
    }
  }

  Future<void> _loadChart() async {
    setState(() => _chartLoading = true);
    try {
      final d = await ReportService.getChart(
        period: _chartPeriod,
        year: _chartPeriod != 'yearly' ? _chartYear : null,
        month: _chartPeriod == 'daily' ? _chartMonth : null,
      );
      if (mounted) setState(() { _chartPoints = d; _chartLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _chartPoints = []; _chartLoading = false; });
    }
  }

  // ── Chart navigation ───────────────────────────────────────────────────

  void _prevPeriod() {
    setState(() {
      if (_chartPeriod == 'daily') {
        _chartMonth == 1 ? (_chartMonth = 12, _chartYear--) : _chartMonth--;
      } else if (_chartPeriod == 'monthly') {
        _chartYear--;
      }
    });
    _loadChart();
  }

  void _nextPeriod() {
    setState(() {
      if (_chartPeriod == 'daily') {
        _chartMonth == 12 ? (_chartMonth = 1, _chartYear++) : _chartMonth++;
      } else if (_chartPeriod == 'monthly') {
        _chartYear++;
      }
    });
    _loadChart();
  }

  bool get _canGoNext {
    final now = DateTime.now();
    if (_chartPeriod == 'yearly') return false;
    if (_chartPeriod == 'daily') return !(_chartYear == now.year && _chartMonth == now.month);
    return _chartYear < now.year;
  }

  // ── Period label ───────────────────────────────────────────────────────

  String? get _periodLabel {
    if (_filterYear == null) return null;
    if (_filterMonth == null) return '$_filterYear';
    if (_filterDay == null) return '${_monthFull[_filterMonth! - 1]} $_filterYear';
    return '$_filterDay ${_monthFull[_filterMonth! - 1]} $_filterYear';
  }

  // ── Export ─────────────────────────────────────────────────────────────

  Future<void> _exportByTab() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      switch (_tab.index) {
        case 0:
          if (_summary != null) await exportRingkasan(_summary!, period: _periodLabel);
          break;
        case 1:
          await exportTransaksi(_transactions, period: _periodLabel);
          break;
        case 2:
          await exportPembayaran(_payments, period: _periodLabel);
          break;
        case 3:
          await exportStok(_stocks);
          break;
        case 4:
          if (_summary != null) await exportKeuntungan(_summary!, period: _periodLabel);
          break;
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Gagal mengekspor laporan'),
            backgroundColor: AppColors.red));
      }
    }
    if (mounted) setState(() => _exporting = false);
  }

  // ── Y-axis formatter ───────────────────────────────────────────────────

  String _fmtY(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}jt';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}rb';
    return v.toStringAsFixed(0);
  }

  // ── Date display ───────────────────────────────────────────────────────

  String _fmtDateDisplay(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
    } catch (_) {
      return raw.substring(0, 10);
    }
  }

  // ── BUILD ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
        actions: [
          _exporting
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
              : IconButton(
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  tooltip: 'Export PDF',
                  onPressed: _exportByTab,
                ),
        ],
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Ringkasan'),
            Tab(text: 'Transaksi'),
            Tab(text: 'Pembayaran'),
            Tab(text: 'Stok Produk'),
            Tab(text: 'Keuntungan'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter bar (shared, always visible)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _buildFilterBar(),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _buildRingkasan(),
                _buildTransaksi(),
                _buildPembayaran(),
                _buildStok(),
                _buildKeuntungan(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── FILTER BAR ─────────────────────────────────────────────────────────

  Widget _buildFilterBar() {
    final now = DateTime.now();
    final years = List.generate(now.year - 2019, (i) => now.year - i);

    return AppCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text('Filter Periode',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const Spacer(),
              if (_filterYear != null)
                GestureDetector(
                  onTap: _resetFilter,
                  child: const Row(children: [
                    Icon(Icons.close, size: 14, color: AppColors.red),
                    SizedBox(width: 2),
                    Text('Reset', style: TextStyle(fontSize: 12, color: AppColors.red, fontWeight: FontWeight.w600)),
                  ]),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _dropdown<int>(
              hint: 'Tahun',
              value: _filterYear,
              items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
              onChanged: (v) {
                setState(() { _filterYear = v; _filterMonth = null; _filterDay = null; });
                _onFilterChanged();
              },
            )),
            const SizedBox(width: 8),
            Expanded(child: _dropdown<int>(
              hint: 'Bulan',
              value: _filterMonth,
              enabled: _filterYear != null,
              items: List.generate(12, (i) => DropdownMenuItem(value: i+1, child: Text(_monthShort[i]))),
              onChanged: (v) {
                setState(() { _filterMonth = v; _filterDay = null; });
                _onFilterChanged();
              },
            )),
            const SizedBox(width: 8),
            Expanded(child: _dropdown<int>(
              hint: 'Hari',
              value: _filterDay,
              enabled: _filterYear != null && _filterMonth != null,
              items: (_filterYear != null && _filterMonth != null)
                  ? List.generate(
                      DateUtils.getDaysInMonth(_filterYear!, _filterMonth!),
                      (i) => DropdownMenuItem(value: i+1, child: Text('${i+1}')))
                  : [],
              onChanged: (v) {
                setState(() => _filterDay = v);
                _onFilterChanged();
              },
            )),
          ]),
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    bool enabled = true,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: enabled ? AppColors.background : AppColors.border.withAlpha(80),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: TextStyle(fontSize: 12, color: enabled ? AppColors.textMuted : AppColors.border)),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          items: enabled ? items : [],
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // TAB 1 — RINGKASAN
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildRingkasan() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_summaryLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (_summary != null) ...[
              const SectionTitle(title: 'Ringkasan Keuangan'),
              const SizedBox(height: 10),
              _metricRow(Icons.payments_outlined, 'Total Pendapatan', _summary!.totalIncome, AppColors.primary),
              _metricRow(Icons.inventory_2_outlined, 'Total Modal Produk', _summary!.totalModal, AppColors.orange),
              _metricRow(Icons.money_off_outlined, 'Total Pengeluaran', _summary!.totalExpenses, AppColors.red),
              _metricRow(Icons.trending_up, 'Laba Kotor', _summary!.labaKotor, AppColors.green, bold: true),
              _metricRow(Icons.account_balance_wallet_outlined, 'Laba Bersih',
                  _summary!.labaBersih, _summary!.labaBersih >= 0 ? AppColors.primaryDark : AppColors.red, bold: true),
            ],
            const SizedBox(height: 20),
            // Order stats (all-time only)
            if (_filterYear == null && _summary != null && _summary!.orders.isNotEmpty) ...[
              const SectionTitle(title: 'Statistik Order'),
              const SizedBox(height: 10),
              _buildOrderStats(_summary!.orders),
              const SizedBox(height: 20),
            ],
            // Chart
            _buildChartSection(),
          ],
        ),
      ),
    );
  }

  Widget _metricRow(IconData icon, String label, double value, Color color, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        color: bold ? color.withAlpha(15) : null,
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: color.withAlpha(30), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
          Text(rupiah(value),
              style: TextStyle(fontSize: bold ? 14 : 13, fontWeight: FontWeight.w800, color: color)),
        ]),
      ),
    );
  }

  Widget _buildOrderStats(Map<String, int> o) {
    return Row(children: [
      Expanded(child: _statChip('Total', o['total'] ?? 0, AppColors.textMuted)),
      const SizedBox(width: 8),
      Expanded(child: _statChip('Selesai', o['completed'] ?? 0, AppColors.green)),
      const SizedBox(width: 8),
      Expanded(child: _statChip('Proses', o['process'] ?? 0, AppColors.orange)),
    ]);
  }

  Widget _statChip(String label, int count, Color color) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(children: [
        Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ]),
    );
  }

  // ── Chart section ──────────────────────────────────────────────────────

  Widget _buildChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Grafik Pendapatan & Laba'),
        const SizedBox(height: 10),
        // Period tabs
        AppCard(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: ['daily','monthly','yearly'].map((p) {
              final labels = {'daily':'Harian','monthly':'Bulanan','yearly':'Tahunan'};
              final active = _chartPeriod == p;
              return Expanded(
                child: GestureDetector(
                  onTap: () { if (_chartPeriod != p) { setState(() => _chartPeriod = p); _loadChart(); } },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(labels[p]!,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                            color: active ? Colors.white : AppColors.textMuted)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (_chartPeriod != 'yearly') ...[
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            IconButton(onPressed: _prevPeriod, icon: const Icon(Icons.chevron_left, color: AppColors.primary), visualDensity: VisualDensity.compact),
            Text(
              _chartPeriod == 'daily' ? '${_monthFull[_chartMonth-1]} $_chartYear' : '$_chartYear',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            IconButton(
              onPressed: _canGoNext ? _nextPeriod : null,
              icon: Icon(Icons.chevron_right, color: _canGoNext ? AppColors.primary : AppColors.border),
              visualDensity: VisualDensity.compact,
            ),
          ]),
        ],
        const SizedBox(height: 6),
        Row(children: [
          _legendDot(AppColors.primary, 'Pendapatan'),
          const SizedBox(width: 12),
          _legendDot(AppColors.green, 'Laba (+)'),
          const SizedBox(width: 12),
          _legendDot(AppColors.red, 'Laba (−)'),
        ]),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          child: SizedBox(
            height: 200,
            child: _chartLoading
                ? const Center(child: CircularProgressIndicator())
                : (_chartPoints.isEmpty || _chartPoints.every((p) => p.income == 0 && p.modal == 0 && p.expenses == 0))
                    ? const Center(child: Text('Belum ada data', style: TextStyle(color: AppColors.textMuted)))
                    : _buildBarChart(),
          ),
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) => Row(children: [
    Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
  ]);

  Widget _buildBarChart() {
    final maxIncome = _chartPoints.map((p) => p.income).fold(0.0, (a, b) => a > b ? a : b);
    final maxY = (maxIncome * 1.25).clamp(10000.0, double.infinity);
    final barW = _chartPeriod == 'daily' ? 4.0 : _chartPeriod == 'monthly' ? 10.0 : 20.0;

    return BarChart(BarChartData(
      maxY: maxY, minY: 0,
      groupsSpace: _chartPeriod == 'daily' ? 2 : 8,
      alignment: BarChartAlignment.spaceEvenly,
      barGroups: _chartPoints.asMap().entries.map((e) {
        final p = e.value;
        final lb = p.labaBersih;
        return BarChartGroupData(x: e.key, barsSpace: 2, barRods: [
          BarChartRodData(toY: p.income, color: AppColors.primary, width: barW,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
          BarChartRodData(toY: lb > 0 ? lb : 0, color: lb >= 0 ? AppColors.green : AppColors.red,
              width: barW, borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
        ]);
      }).toList(),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 44, interval: maxY / 4,
          getTitlesWidget: (v, m) {
            if (v == 0 || v == m.max) return const SizedBox.shrink();
            return Padding(padding: const EdgeInsets.only(right: 4),
              child: Text(_fmtY(v), style: const TextStyle(fontSize: 9, color: AppColors.textMuted), textAlign: TextAlign.right));
          },
        )),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 20,
          getTitlesWidget: (v, m) {
            final i = v.toInt();
            if (i < 0 || i >= _chartPoints.length) return const SizedBox.shrink();
            if (_chartPeriod == 'daily' && i % 5 != 0) return const SizedBox.shrink();
            return Padding(padding: const EdgeInsets.only(top: 4),
              child: Text(_chartPoints[i].label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)));
          },
        )),
      ),
      gridData: FlGridData(drawVerticalLine: false, horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 0.8)),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (_) => AppColors.primaryDark,
        tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        getTooltipItem: (group, _, rod, ri) {
          final p = _chartPoints[group.x];
          final isIncome = ri == 0;
          return BarTooltipItem(
            '${p.label}\n${isIncome ? 'Pendapatan' : 'Laba Bersih'}\n${rupiah(isIncome ? p.income : p.labaBersih)}',
            const TextStyle(color: Colors.white, fontSize: 11, height: 1.5),
          );
        },
      )),
    ));
  }

  // ══════════════════════════════════════════════════════════════════════
  // TAB 2 — TRANSAKSI
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildTransaksi() {
    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: _txLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? const EmptyState(message: 'Tidak ada transaksi', icon: Icons.receipt_long_outlined)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _transactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _txCard(_transactions[i]),
                ),
    );
  }

  Widget _txCard(TransactionReport t) {
    final statusColor = AppColors.statusColor(t.orderStatus);
    final statusLabel = AppColors.statusLabel(t.orderStatus);
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(t.orderCode,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(30),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: statusColor.withAlpha(100)),
            ),
            child: Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
          ),
        ]),
        const SizedBox(height: 6),
        _infoRow(Icons.person_outline, t.customerName),
        _infoRow(Icons.directions_car_outlined, t.vehiclePlate),
        _infoRow(Icons.shopping_bag_outlined, '${t.itemCount} item'),
        if (t.createdByName != null)
          _infoRow(Icons.badge_outlined, 'Oleh: ${t.createdByName}'),
        const Divider(height: 14),
        Row(children: [
          Text(_fmtDateDisplay(t.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const Spacer(),
          Text(rupiah(t.totalAmount),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
          const SizedBox(width: 8),
          if (t.isPaid)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.green.withAlpha(30), borderRadius: BorderRadius.circular(6)),
              child: const Text('LUNAS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.green)),
            ),
        ]),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // TAB 3 — PEMBAYARAN
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildPembayaran() {
    return RefreshIndicator(
      onRefresh: _loadPayments,
      child: _payLoading
          ? const Center(child: CircularProgressIndicator())
          : _payments.isEmpty
              ? const EmptyState(message: 'Tidak ada pembayaran', icon: Icons.payments_outlined)
              : Column(children: [
                  if (_payments.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: AppCard(
                        color: AppColors.primary.withAlpha(15),
                        child: Row(children: [
                          const Icon(Icons.payments, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          const Text('Total', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                          const Spacer(),
                          Text(
                            rupiah(_payments.fold(0.0, (s, p) => s + p.totalAmount)),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.primary),
                          ),
                        ]),
                      ),
                    ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _payments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _payCard(_payments[i]),
                    ),
                  ),
                ]),
    );
  }

  Widget _payCard(PaymentReport p) {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(p.orderCode,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.green.withAlpha(30),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              p.paymentMethod.toUpperCase(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.green),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        _infoRow(Icons.person_outline, p.customerName),
        _infoRow(Icons.calendar_today_outlined, _fmtDateDisplay(p.paymentDate)),
        const Divider(height: 14),
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Bayar', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            Text(rupiah(p.paidAmount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          ]),
          const SizedBox(width: 20),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Kembalian', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            Text(rupiah(p.changeAmount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
          ]),
          const Spacer(),
          Text(rupiah(p.totalAmount),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
        ]),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // TAB 4 — STOK PRODUK
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildStok() {
    return RefreshIndicator(
      onRefresh: _loadStock,
      child: _stockLoading
          ? const Center(child: CircularProgressIndicator())
          : _stocks.isEmpty
              ? const EmptyState(message: 'Tidak ada data stok', icon: Icons.inventory_2_outlined)
              : Column(children: [
                  // Legend stok
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                        _stockLegend(AppColors.red, 'Kritis (≤5)'),
                        _stockLegend(AppColors.orange, 'Rendah (≤10)'),
                        _stockLegend(AppColors.green, 'Aman (>10)'),
                      ]),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _stocks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _stockCard(_stocks[i]),
                    ),
                  ),
                ]),
    );
  }

  Widget _stockLegend(Color color, String label) => Row(children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 5),
    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
  ]);

  Widget _stockCard(StockReport s) {
    final color = s.isLow ? AppColors.red : s.isWarning ? AppColors.orange : AppColors.green;
    return AppCard(
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.center,
          child: Text('${s.stock}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.itemName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('${s.categoryName} · ${s.typeName}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ])),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(rupiah(s.sellingPrice),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
          Text('Modal: ${rupiah(s.purchasePrice)}',
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ]),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // TAB 5 — KEUNTUNGAN
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildKeuntungan() {
    return RefreshIndicator(
      onRefresh: _loadSummary,
      child: _summaryLoading
          ? const Center(child: CircularProgressIndicator())
          : _summary == null
              ? EmptyState(message: 'Gagal memuat data', icon: Icons.error_outline, buttonLabel: 'Coba Lagi', onButton: _loadSummary)
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SectionTitle(title: 'Analisis Keuntungan'),
                    const SizedBox(height: 12),
                    // Big laba card
                    AppCard(
                      color: (_summary!.labaBersih >= 0 ? AppColors.green : AppColors.red).withAlpha(20),
                      child: Column(children: [
                        Text(
                          _summary!.labaBersih >= 0 ? 'UNTUNG' : 'RUGI',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: _summary!.labaBersih >= 0 ? AppColors.green : AppColors.red),
                        ),
                        const SizedBox(height: 4),
                        Text(rupiah(_summary!.labaBersih.abs()),
                            style: TextStyle(
                                fontSize: 28, fontWeight: FontWeight.w900,
                                color: _summary!.labaBersih >= 0 ? AppColors.green : AppColors.red)),
                        const SizedBox(height: 2),
                        const Text('Laba Bersih', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    // Breakdown
                    _profitRow('Pendapatan', _summary!.totalIncome, AppColors.primary, isAdd: true),
                    _profitRow('Modal Produk', _summary!.totalModal, AppColors.orange, isAdd: false),
                    _profitDivider('Laba Kotor', _summary!.labaKotor),
                    _profitRow('Pengeluaran', _summary!.totalExpenses, AppColors.red, isAdd: false),
                    _profitDivider('Laba Bersih', _summary!.labaBersih, bold: true),
                    const SizedBox(height: 20),
                    // Margin info
                    if (_summary!.totalIncome > 0)
                      AppCard(
                        child: Column(children: [
                          _marginRow('Margin Kotor',
                              (_summary!.labaKotor / _summary!.totalIncome * 100)),
                          const Divider(height: 16),
                          _marginRow('Margin Bersih',
                              (_summary!.labaBersih / _summary!.totalIncome * 100)),
                        ]),
                      ),
                  ]),
                ),
    );
  }

  Widget _profitRow(String label, double value, Color color, {required bool isAdd}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AppCard(
        child: Row(children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(isAdd ? '+' : '−',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
          Text(rupiah(value), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }

  Widget _profitDivider(String label, double value, {bool bold = false}) {
    final color = value >= 0 ? AppColors.green : AppColors.red;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: AppCard(
        color: color.withAlpha(15),
        child: Row(children: [
          Text('= $label', style: TextStyle(
              fontSize: bold ? 14 : 13,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              color: AppColors.textPrimary)),
          const Spacer(),
          Text(rupiah(value), style: TextStyle(
              fontSize: bold ? 15 : 13,
              fontWeight: FontWeight.w900,
              color: color)),
        ]),
      ),
    );
  }

  Widget _marginRow(String label, double pct) {
    final color = pct >= 0 ? AppColors.green : AppColors.red;
    return Row(children: [
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
      const Spacer(),
      Text('${pct.toStringAsFixed(1)}%',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
    ]);
  }

  // ── Shared helpers ─────────────────────────────────────────────────────

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ]),
    );
  }
}
