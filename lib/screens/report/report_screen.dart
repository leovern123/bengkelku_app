import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/report_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  // ── Summary state ──────────────────────────────────────────────────────
  ReportSummary? _summary;
  bool _summaryLoading = true;
  String? _summaryError;

  // Filter cascade: tahun → bulan → hari
  int? _filterYear;
  int? _filterMonth;
  int? _filterDay;

  // ── Chart state ────────────────────────────────────────────────────────
  List<ChartPoint> _chartPoints = [];
  bool _chartLoading = true;
  String _chartPeriod = 'monthly';
  int _chartYear = DateTime.now().year;
  int _chartMonth = DateTime.now().month;

  static const _monthShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  static const _monthFull = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  // ── Lifecycle ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _loadChart();
  }

  // ── Summary logic ──────────────────────────────────────────────────────

  Future<void> _loadSummary() async {
    setState(() { _summaryLoading = true; _summaryError = null; });
    try {
      ReportSummary data;
      if (_filterYear != null) {
        final start = _buildStartDate();
        final end   = _buildEndDate();
        data = await ReportService.getProfit(startDate: start, endDate: end);
      } else {
        data = await ReportService.getSummary();
      }
      if (mounted) setState(() { _summary = data; _summaryLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _summaryError = e.toString(); _summaryLoading = false; });
    }
  }

  String _buildStartDate() {
    final y = _filterYear!;
    final m = _filterMonth ?? 1;
    final d = _filterDay ?? 1;
    return '$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
  }

  String _buildEndDate() {
    final y = _filterYear!;
    if (_filterMonth == null) return '$y-12-31';
    if (_filterDay != null) return _buildStartDate();
    final lastDay = DateUtils.getDaysInMonth(y, _filterMonth!);
    return '$y-${_filterMonth.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';
  }

  void _resetFilter() {
    setState(() { _filterYear = null; _filterMonth = null; _filterDay = null; });
    _loadSummary();
  }

  int _daysInMonth(int year, int month) => DateUtils.getDaysInMonth(year, month);

  // ── Chart logic ────────────────────────────────────────────────────────

  Future<void> _loadChart() async {
    setState(() => _chartLoading = true);
    try {
      final data = await ReportService.getChart(
        period: _chartPeriod,
        year: _chartPeriod != 'yearly' ? _chartYear : null,
        month: _chartPeriod == 'daily' ? _chartMonth : null,
      );
      if (mounted) setState(() { _chartPoints = data; _chartLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _chartPoints = []; _chartLoading = false; });
    }
  }

  void _prevPeriod() {
    setState(() {
      if (_chartPeriod == 'daily') {
        if (_chartMonth == 1) { _chartMonth = 12; _chartYear--; }
        else { _chartMonth--; }
      } else if (_chartPeriod == 'monthly') {
        _chartYear--;
      }
    });
    _loadChart();
  }

  void _nextPeriod() {
    setState(() {
      if (_chartPeriod == 'daily') {
        if (_chartMonth == 12) { _chartMonth = 1; _chartYear++; }
        else { _chartMonth++; }
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
    if (_chartPeriod == 'monthly') return _chartYear < now.year;
    return false;
  }

  String get _chartPeriodLabel {
    if (_chartPeriod == 'daily') return '${_monthFull[_chartMonth - 1]} $_chartYear';
    if (_chartPeriod == 'monthly') return '$_chartYear';
    return 'Semua Tahun';
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  String _fmtY(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}jt';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}rb';
    return v.toStringAsFixed(0);
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Keuangan')),
      body: RefreshIndicator(
        onRefresh: () async { await _loadSummary(); await _loadChart(); },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterSection(),
              const SizedBox(height: 12),
              if (_summaryLoading)
                const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(),
                ))
              else if (_summaryError != null)
                EmptyState(
                  icon: Icons.error_outline,
                  message: 'Gagal memuat ringkasan',
                  buttonLabel: 'Coba Lagi',
                  onButton: _loadSummary,
                )
              else if (_summary != null)
                _buildMetrics(_summary!),
              const SizedBox(height: 24),
              _buildChartSection(),
              const SizedBox(height: 24),
              if (_filterYear == null && _summary != null)
                _buildOrderStats(_summary!),
            ],
          ),
        ),
      ),
    );
  }

  // ── Filter widgets ─────────────────────────────────────────────────────

  Widget _buildFilterSection() {
    final now = DateTime.now();
    final years = List.generate(now.year - 2019, (i) => now.year - i);

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text('Filter Periode',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const Spacer(),
              if (_filterYear != null)
                GestureDetector(
                  onTap: _resetFilter,
                  child: const Row(
                    children: [
                      Icon(Icons.close, size: 14, color: AppColors.red),
                      SizedBox(width: 2),
                      Text('Reset', style: TextStyle(fontSize: 12, color: AppColors.red, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Tahun
              Expanded(child: _dropdownFilter<int>(
                hint: 'Tahun',
                value: _filterYear,
                items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                onChanged: (v) {
                  setState(() { _filterYear = v; _filterMonth = null; _filterDay = null; });
                  _loadSummary();
                },
              )),
              const SizedBox(width: 8),
              // Bulan
              Expanded(child: _dropdownFilter<int>(
                hint: 'Bulan',
                value: _filterMonth,
                enabled: _filterYear != null,
                items: List.generate(12, (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text(_monthShort[i]),
                )),
                onChanged: (v) {
                  setState(() { _filterMonth = v; _filterDay = null; });
                  _loadSummary();
                },
              )),
              const SizedBox(width: 8),
              // Hari
              Expanded(child: _dropdownFilter<int>(
                hint: 'Hari',
                value: _filterDay,
                enabled: _filterYear != null && _filterMonth != null,
                items: _filterYear != null && _filterMonth != null
                    ? List.generate(
                        _daysInMonth(_filterYear!, _filterMonth!),
                        (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                      )
                    : [],
                onChanged: (v) {
                  setState(() => _filterDay = v);
                  _loadSummary();
                },
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdownFilter<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    bool enabled = true,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: enabled ? AppColors.background : AppColors.border.withAlpha(80),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint,
              style: TextStyle(
                  fontSize: 12,
                  color: enabled ? AppColors.textMuted : AppColors.border)),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          items: enabled ? items : [],
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }

  // ── Metric widgets ─────────────────────────────────────────────────────

  Widget _buildMetrics(ReportSummary s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Ringkasan Keuangan'),
        const SizedBox(height: 12),
        _metricCard(Icons.payments_outlined, 'Total Pendapatan',
            'Dari transaksi lunas', s.totalIncome, AppColors.primary),
        const SizedBox(height: 8),
        _metricCard(Icons.inventory_2_outlined, 'Total Modal Produk',
            'Harga beli produk terjual', s.totalModal, AppColors.orange),
        const SizedBox(height: 8),
        _metricCard(Icons.money_off_outlined, 'Total Pengeluaran',
            'Pengeluaran operasional', s.totalExpenses, AppColors.red),
        const SizedBox(height: 8),
        _metricCard(Icons.trending_up, 'Laba Kotor',
            'Pendapatan − Modal', s.labaKotor, AppColors.green, highlight: true),
        const SizedBox(height: 8),
        _metricCard(
          Icons.account_balance_wallet_outlined, 'Laba Bersih',
          'Laba Kotor − Pengeluaran', s.labaBersih,
          s.labaBersih >= 0 ? AppColors.primaryDark : AppColors.red,
          highlight: true,
        ),
      ],
    );
  }

  Widget _metricCard(IconData icon, String label, String desc, double value, Color color,
      {bool highlight = false}) {
    return AppCard(
      color: highlight ? color.withAlpha(18) : null,
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: color.withAlpha(30), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(rupiah(value),
              style: TextStyle(
                  fontSize: highlight ? 14 : 13,
                  fontWeight: FontWeight.w800,
                  color: color)),
        ],
      ),
    );
  }

  // ── Chart widgets ──────────────────────────────────────────────────────

  Widget _buildChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Grafik Pendapatan & Laba'),
        const SizedBox(height: 12),

        // Period tabs
        AppCard(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: ['daily', 'monthly', 'yearly'].map((p) {
              final labels = {'daily': 'Harian', 'monthly': 'Bulanan', 'yearly': 'Tahunan'};
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
                    child: Text(
                      labels[p]!,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: active ? Colors.white : AppColors.textMuted),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 10),

        // Period navigator (harian & bulanan)
        if (_chartPeriod != 'yearly')
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _prevPeriod,
                icon: const Icon(Icons.chevron_left, color: AppColors.primary),
                visualDensity: VisualDensity.compact,
              ),
              Text(_chartPeriodLabel,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              IconButton(
                onPressed: _canGoNext ? _nextPeriod : null,
                icon: Icon(Icons.chevron_right,
                    color: _canGoNext ? AppColors.primary : AppColors.border),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),

        const SizedBox(height: 6),

        // Legend
        Row(children: [
          _legendDot(AppColors.primary, 'Pendapatan'),
          const SizedBox(width: 16),
          _legendDot(AppColors.green, 'Laba Bersih (+)'),
          const SizedBox(width: 16),
          _legendDot(AppColors.red, 'Laba Bersih (−)'),
        ]),

        const SizedBox(height: 10),

        // Chart card
        AppCard(
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          child: SizedBox(
            height: 220,
            child: _chartLoading
                ? const Center(child: CircularProgressIndicator())
                : _chartPoints.isEmpty
                    ? const Center(child: Text('Belum ada data',
                        style: TextStyle(color: AppColors.textMuted)))
                    : _buildBarChart(),
          ),
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
    ]);
  }

  Widget _buildBarChart() {
    final maxIncome = _chartPoints.map((p) => p.income).fold(0.0, (a, b) => a > b ? a : b);
    final maxY = (maxIncome * 1.25).clamp(10000.0, double.infinity);
    final barW = _chartPeriod == 'daily' ? 4.0 : _chartPeriod == 'monthly' ? 10.0 : 20.0;

    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: 0,
        groupsSpace: _chartPeriod == 'daily' ? 2 : 8,
        alignment: BarChartAlignment.spaceEvenly,
        barGroups: _chartPoints.asMap().entries.map((e) {
          final i = e.key;
          final p = e.value;
          final lb = p.labaBersih;
          return BarChartGroupData(
            x: i,
            barsSpace: 2,
            barRods: [
              BarChartRodData(
                toY: p.income,
                color: AppColors.primary,
                width: barW,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
              ),
              BarChartRodData(
                toY: lb > 0 ? lb : 0,
                color: lb >= 0 ? AppColors.green : AppColors.red,
                width: barW,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 46,
              interval: maxY / 4,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == meta.max) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(_fmtY(value),
                      style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
                      textAlign: TextAlign.right),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= _chartPoints.length) return const SizedBox.shrink();
                if (_chartPeriod == 'daily' && i % 5 != 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_chartPoints[i].label,
                      style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 0.8),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.primaryDark,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            getTooltipItem: (group, _, rod, rodIndex) {
              final p = _chartPoints[group.x];
              final isIncome = rodIndex == 0;
              final label = isIncome ? 'Pendapatan' : 'Laba Bersih';
              final val = isIncome ? p.income : p.labaBersih;
              return BarTooltipItem(
                '${p.label}\n$label\n${rupiah(val)}',
                const TextStyle(color: Colors.white, fontSize: 11, height: 1.5),
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Order stats ────────────────────────────────────────────────────────

  Widget _buildOrderStats(ReportSummary s) {
    final o = s.orders;
    if (o.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Statistik Order'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _statChip('Total', o['total'] ?? 0, AppColors.textMuted)),
          const SizedBox(width: 8),
          Expanded(child: _statChip('Selesai', o['completed'] ?? 0, AppColors.green)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _statChip('Diproses', o['process'] ?? 0, AppColors.orange)),
          const SizedBox(width: 8),
          Expanded(child: _statChip('Pending', o['pending'] ?? 0, AppColors.primary)),
        ]),
        const SizedBox(height: 8),
        _statChip('Dibatalkan', o['cancelled'] ?? 0, AppColors.red),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _statChip(String label, int count, Color color) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
          Text(count.toString(),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}
