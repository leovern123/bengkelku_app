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
  String _txFilter = 'all';

  List<StockReport> _stocks = [];
  bool _stockLoading = true;
  String? _stockCategory;

  List<FavoriteReport> _favorites = [];
  bool _favLoading = true;
  String? _favError;
  int _favTab = 0; // 0 = Sparepart, 1 = Jasa

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
    _tab = TabController(length: 4, vsync: this);
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
      _loadStock(),
      _loadChart(),
      _loadFavorites(),
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
    _loadFavorites();
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

  Future<void> _loadStock() async {
    setState(() => _stockLoading = true);
    try {
      final d = await ReportService.getStock();
      if (mounted) setState(() { _stocks = d; _stockLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _stockLoading = false);
    }
  }

  Future<void> _loadFavorites() async {
    setState(() { _favLoading = true; _favError = null; });
    try {
      final d = await ReportService.getFavorites(startDate: _startDate, endDate: _endDate);
      if (mounted) setState(() { _favorites = d; _favLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _favLoading = false; _favError = e.toString(); });
    }
  }

  Future<void> _loadChart() async {
    setState(() => _chartLoading = true);
    try {
      final apiPeriod = _chartPeriod == 'all' ? 'yearly' : _chartPeriod;
      final d = await ReportService.getChart(
        period: apiPeriod,
        year: (_chartPeriod == 'monthly') ? _chartYear : (_chartPeriod == 'daily' ? _chartYear : null),
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
    if (_chartPeriod == 'yearly' || _chartPeriod == 'all') return false;
    if (_chartPeriod == 'daily') return !(_chartYear == now.year && _chartMonth == now.month);
    return _chartYear < now.year;
  }

  bool get _showNavigation => _chartPeriod == 'daily' || _chartPeriod == 'monthly';

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
          await exportStok(_stocks);
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
            Tab(text: 'Stok Produk'),
            Tab(text: 'Favorit'),
          ],
        ),
      ),
      body: Column(
        children: [
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
                _buildStok(),
                _buildFavorit(),
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
              // ── Ringkasan keuangan ─────────────────────────────────
              const SectionTitle(title: 'Ringkasan Keuangan'),
              const SizedBox(height: 10),
              _metricRow(Icons.payments_outlined, 'Total Pendapatan',
                  'Uang masuk dari semua transaksi', _summary!.totalIncome, AppColors.primary),
              _metricRow(Icons.inventory_2_outlined, 'Modal Produk',
                  'Biaya pengadaan produk yang terjual', _summary!.totalModal, AppColors.orange),
              _metricRow(Icons.money_off_outlined, 'Total Pengeluaran',
                  'Biaya operasional & pengeluaran lain', _summary!.totalExpenses, AppColors.red),
              const SizedBox(height: 4),
              _metricDivider('Laba Kotor',
                  'Pendapatan dikurangi modal produk',
                  _summary!.labaKotor, AppColors.green),
              _metricDivider('Laba Bersih',
                  'Laba kotor dikurangi pengeluaran',
                  _summary!.labaBersih,
                  _summary!.labaBersih >= 0 ? AppColors.primaryDark : AppColors.red,
                  bold: true),
            ],
            const SizedBox(height: 20),

            // ── Statistik order (all-time only) ───────────────────────
            if (_filterYear == null && _summary != null && _summary!.orders.isNotEmpty) ...[
              const SectionTitle(title: 'Statistik Order'),
              const SizedBox(height: 10),
              _buildOrderStats(_summary!.orders),
              const SizedBox(height: 20),
            ],

            // ── Grafik ────────────────────────────────────────────────
            _buildChartSection(),
          ],
        ),
      ),
    );
  }

  Widget _metricRow(IconData icon, String label, String desc, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withAlpha(25), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Text(desc, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ])),
          Text(rupiah(value),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ]),
      ),
    );
  }

  Widget _metricDivider(String label, String desc, double value, Color color, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        color: color.withAlpha(15),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withAlpha(30), shape: BoxShape.circle),
            child: Icon(
              value >= 0 ? Icons.trending_up : Icons.trending_down,
              color: color, size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(
                fontSize: bold ? 14 : 13,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary)),
            Text(desc, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ])),
          Text(rupiah(value),
              style: TextStyle(
                  fontSize: bold ? 15 : 13,
                  fontWeight: FontWeight.w900,
                  color: color)),
        ]),
      ),
    );
  }

  Widget _buildOrderStats(Map<String, int> o) {
    return Row(children: [
      Expanded(child: _statChip('Total\nOrder', o['total'] ?? 0, AppColors.textMuted, Icons.receipt_long_outlined)),
      const SizedBox(width: 8),
      Expanded(child: _statChip('Selesai', o['completed'] ?? 0, AppColors.green, Icons.check_circle_outline)),
      const SizedBox(width: 8),
      Expanded(child: _statChip('Diproses', o['process'] ?? 0, AppColors.orange, Icons.timelapse_outlined)),
    ]);
  }

  Widget _statChip(String label, int count, Color color, IconData icon) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted), textAlign: TextAlign.center),
      ]),
    );
  }

  // ── Chart section ──────────────────────────────────────────────────────

  Widget _buildChartSection() {
    final periods = ['all', 'monthly', 'daily'];
    final labels = {'all': 'Semua', 'monthly': 'Bulanan', 'daily': 'Harian'};


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Grafik Keuangan'),
        const SizedBox(height: 10),

        // Period toggle
        AppCard(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: periods.map((p) {
              final active = _chartPeriod == p;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_chartPeriod != p) {
                      setState(() => _chartPeriod = p);
                      _loadChart();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 8),
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

        // Navigation (hanya untuk Harian & Bulanan)
        if (_showNavigation) ...[
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            IconButton(
              onPressed: _prevPeriod,
              icon: const Icon(Icons.chevron_left, color: AppColors.primary),
              visualDensity: VisualDensity.compact,
            ),
            Text(
              _chartPeriod == 'daily'
                  ? '${_monthFull[_chartMonth - 1]} $_chartYear'
                  : '$_chartYear',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            IconButton(
              onPressed: _canGoNext ? _nextPeriod : null,
              icon: Icon(Icons.chevron_right,
                  color: _canGoNext ? AppColors.primary : AppColors.border),
              visualDensity: VisualDensity.compact,
            ),
          ]),
        ] else
          const SizedBox(height: 8),

        // Legenda
        Row(children: [
          _legendItem(AppColors.primary, 'Pendapatan', 'Uang masuk'),
          const SizedBox(width: 14),
          _legendItem(AppColors.green, 'Laba', 'Untung bersih'),
          const SizedBox(width: 14),
          _legendItem(AppColors.red, 'Rugi', 'Laba negatif'),
        ]),
        const SizedBox(height: 8),

        // Chart
        AppCard(
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          child: SizedBox(
            height: 220,
            child: _chartLoading
                ? const Center(child: CircularProgressIndicator())
                : (_chartPoints.isEmpty ||
                        _chartPoints.every((p) => p.income == 0 && p.modal == 0 && p.expenses == 0))
                    ? const Center(
                        child: Text('Belum ada data untuk periode ini',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13)))
                    : _buildLineChart(),
          ),
        ),

      ],
    );
  }

  Widget _legendItem(Color color, String title, String desc) => Row(children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 5),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      Text(desc, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
    ]),
  ]);

  Widget _buildLineChart() {
    final maxVal = _chartPoints.map((p) => p.income).fold(0.0, (a, b) => a > b ? a : b);
    final maxY = (maxVal * 1.3).clamp(10000.0, double.infinity);
    final showDots = _chartPoints.length <= 15;

    final incomeSpots = _chartPoints.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.income))
        .toList();
    final labaSpots = _chartPoints.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.labaBersih.clamp(0.0, double.infinity)))
        .toList();

    return LineChart(LineChartData(
      maxY: maxY,
      minY: 0,
      lineBarsData: [
        // Garis Pendapatan — area terisi biru
        LineChartBarData(
          spots: incomeSpots,
          isCurved: true,
          color: AppColors.primary,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: showDots,
            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
              radius: 3.5,
              color: AppColors.primary,
              strokeWidth: 1.5,
              strokeColor: Colors.white,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [AppColors.primary.withAlpha(70), AppColors.primary.withAlpha(5)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        // Garis Laba Bersih — putus-putus hijau
        LineChartBarData(
          spots: labaSpots,
          isCurved: true,
          color: AppColors.green,
          barWidth: 2,
          isStrokeCapRound: true,
          dashArray: [6, 3],
          dotData: FlDotData(
            show: showDots,
            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
              radius: 3,
              color: AppColors.green,
              strokeWidth: 1.5,
              strokeColor: Colors.white,
            ),
          ),
        ),
      ],
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 44,
          interval: maxY / 4,
          getTitlesWidget: (v, m) {
            if (v == 0 || v == m.max) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(_fmtY(v),
                  style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
                  textAlign: TextAlign.right),
            );
          },
        )),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 20,
          getTitlesWidget: (v, m) {
            final i = v.toInt();
            if (i < 0 || i >= _chartPoints.length) return const SizedBox.shrink();
            if (_chartPeriod == 'daily' && i % 5 != 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_chartPoints[i].label,
                  style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
            );
          },
        )),
      ),
      gridData: FlGridData(
        drawVerticalLine: false,
        horizontalInterval: maxY / 4,
        getDrawingHorizontalLine: (_) =>
            const FlLine(color: AppColors.border, strokeWidth: 0.8),
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.primaryDark,
          tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          getTooltipItems: (spots) {
            final idx = spots.first.x.toInt();
            if (idx < 0 || idx >= _chartPoints.length) {
              return spots.map((_) => null).toList();
            }
            final p = _chartPoints[idx];
            final laba = p.labaBersih;
            return [
              LineTooltipItem(
                '📅 ${p.label}\n'
                '💰 Pendapatan: ${rupiah(p.income)}\n'
                '📦 Modal: ${rupiah(p.modal)}\n'
                '🧾 Pengeluaran: ${rupiah(p.expenses)}\n'
                '${laba >= 0 ? '✅ Laba Bersih' : '❌ Rugi'}: ${rupiah(laba)}',
                TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  height: 1.7,
                  fontWeight: FontWeight.w500,
                ),
              ),
              // Titik kedua (laba) — tidak tampilkan tooltip sendiri
              null,
            ];
          },
        ),
      ),
    ));
  }

  // ══════════════════════════════════════════════════════════════════════
  // TAB 2 — TRANSAKSI
  // ══════════════════════════════════════════════════════════════════════

  List<TransactionReport> get _txFiltered {
    switch (_txFilter) {
      case 'pending':
        return _transactions.where((t) => t.orderStatus == 'pending').toList();
      case 'process':
        return _transactions.where((t) => t.orderStatus == 'process').toList();
      case 'lunas':
        return _transactions.where((t) => t.isPaid).toList();
      default:
        return _transactions;
    }
  }

  Widget _buildTransaksi() {
    final list = _txFiltered;
    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: _txLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              // Filter chips
              Container(
                color: AppColors.card,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    _txChip('all', 'Semua', AppColors.primary),
                    const SizedBox(width: 8),
                    _txChip('pending', 'Pending', AppColors.primary),
                    const SizedBox(width: 8),
                    _txChip('process', 'Diproses', AppColors.orange),
                    const SizedBox(width: 8),
                    _txChip('lunas', 'Lunas', AppColors.green),
                  ]),
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? const EmptyState(message: 'Tidak ada transaksi', icon: Icons.receipt_long_outlined)
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _txCard(list[i]),
                      ),
              ),
            ]),
    );
  }

  Widget _txChip(String key, String label, Color color) {
    final active = _txFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _txFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: active ? color : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : AppColors.textMuted,
            )),
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
            child: Text(statusLabel,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
          ),
        ]),
        const SizedBox(height: 6),
        _infoRow(Icons.person_outline, t.customerName),
        _infoRow(Icons.two_wheeler, t.vehiclePlate),
        _infoRow(Icons.shopping_bag_outlined, '${t.itemCount} item'),
        if (t.createdByName != null)
          _infoRow(Icons.badge_outlined, 'Oleh: ${t.createdByName}'),
        const Divider(height: 14),
        Row(children: [
          Text(_fmtDateDisplay(t.createdAt),
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const Spacer(),
          Text(rupiah(t.totalAmount),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
          const SizedBox(width: 8),
          if (t.isPaid)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: AppColors.green.withAlpha(30),
                  borderRadius: BorderRadius.circular(6)),
              child: const Text('LUNAS',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.green)),
            ),
        ]),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // TAB 3 — STOK PRODUK
  // ══════════════════════════════════════════════════════════════════════

  void _showCategoryPicker(List<String> categories) {
    String search = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModal) {
          final filtered = categories
              .where((c) => c.toLowerCase().contains(search.toLowerCase()))
              .toList();
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, scrollCtrl) => Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Pilih Kategori',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Cari kategori...',
                      prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (v) => setModal(() => search = v),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    controller: scrollCtrl,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.all_inclusive, color: AppColors.primary),
                        title: const Text('Semua Kategori'),
                        selected: _stockCategory == null,
                        selectedColor: AppColors.primary,
                        onTap: () {
                          setState(() => _stockCategory = null);
                          Navigator.pop(ctx);
                        },
                      ),
                      const Divider(height: 1),
                      ...filtered.map((c) => ListTile(
                            leading: const Icon(Icons.category_outlined, color: AppColors.textMuted),
                            title: Text(c),
                            selected: _stockCategory == c,
                            selectedColor: AppColors.primary,
                            onTap: () {
                              setState(() => _stockCategory = c);
                              Navigator.pop(ctx);
                            },
                          )),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildStok() {
    final categories = _stocks.map((s) => s.categoryName).toSet().toList()..sort();
    final list = _stockCategory == null
        ? _stocks
        : _stocks.where((s) => s.categoryName == _stockCategory).toList();

    return RefreshIndicator(
      onRefresh: _loadStock,
      child: _stockLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              // Dropdown kategori (dengan search di dalam)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: GestureDetector(
                  onTap: () => _showCategoryPicker(categories),
                  child: AbsorbPointer(
                    child: TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.category_outlined),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_stockCategory != null)
                              GestureDetector(
                                onTap: () => setState(() => _stockCategory = null),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: Icon(Icons.close, size: 18, color: AppColors.textMuted),
                                ),
                              ),
                            const Icon(Icons.keyboard_arrow_down, size: 20),
                            const SizedBox(width: 8),
                          ],
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      controller: TextEditingController(
                        text: _stockCategory ?? 'Semua Kategori',
                      ),
                    ),
                  ),
                ),
              ),
              // Legend
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
                child: list.isEmpty
                    ? const EmptyState(message: 'Tidak ada data stok', icon: Icons.inventory_2_outlined)
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _stockCard(list[i]),
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
  // TAB 4 — FAVORIT
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildFavorit() {
    final sparepart = _favorites.where((f) => !f.isService).toList();
    final jasa = _favorites.where((f) => f.isService).toList();
    final list = _favTab == 0 ? sparepart : jasa;

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: _favLoading
          ? const Center(child: CircularProgressIndicator())
          : _favError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_favError!,
                        style: const TextStyle(color: AppColors.red, fontSize: 13),
                        textAlign: TextAlign.center),
                  ))
              : Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(children: [
                      _favTabBtn(0, 'Sparepart', Icons.build_outlined),
                      const SizedBox(width: 8),
                      _favTabBtn(1, 'Jasa', Icons.miscellaneous_services_outlined),
                    ]),
                  ),
                  Expanded(
                    child: list.isEmpty
                        ? EmptyState(
                            message: 'Tidak ada ${_favTab == 0 ? 'sparepart' : 'jasa'} favorit',
                            icon: Icons.star_outline)
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: list.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) => _favCard(list[i], i + 1),
                          ),
                  ),
                ]),
    );
  }

  Widget _favTabBtn(int index, String label, IconData icon) {
    final active = _favTab == index;
    final color = index == 0 ? AppColors.primary : AppColors.green;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _favTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? color : AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? color : AppColors.border),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16, color: active ? Colors.white : AppColors.textMuted),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : AppColors.textMuted)),
          ]),
        ),
      ),
    );
  }

  Widget _favCard(FavoriteReport f, int rank) {
    final isService = f.isService;
    final color = isService ? AppColors.green : AppColors.primary;
    final rankColor = rank == 1
        ? const Color(0xFFFFD700)
        : rank == 2
            ? const Color(0xFFC0C0C0)
            : rank == 3
                ? const Color(0xFFCD7F32)
                : AppColors.textMuted;

    return AppCard(
      child: Row(children: [
        SizedBox(
          width: 32,
          child: Text(
            '#$rank',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w900, color: rankColor),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.center,
          child: Icon(
            isService ? Icons.miscellaneous_services_outlined : Icons.build_outlined,
            color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(f.itemName,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(f.typeName,
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w600, color: color)),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(f.categoryName,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ]),
          ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Row(children: [
            const Icon(Icons.shopping_cart_outlined, size: 13, color: AppColors.textMuted),
            const SizedBox(width: 3),
            Text('${f.totalQty}x',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 2),
          Text(rupiah(f.totalRevenue),
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textMuted)),
        ]),
      ]),
    );
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
