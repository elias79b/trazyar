import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tarazyar/company_admin/dashboard/presentation/widgets/company_admin_scaffold.dart';

/// داشبورد هزینه مدیرعامل؛ فقط از جداول موجود دیتابیس استفاده می‌کند.
class CompanyAdminExpenseDashboardPage extends StatefulWidget {
  const CompanyAdminExpenseDashboardPage({super.key});

  @override
  State<CompanyAdminExpenseDashboardPage> createState() =>
      _CompanyAdminExpenseDashboardPageState();
}

class _CompanyAdminExpenseDashboardPageState
    extends State<CompanyAdminExpenseDashboardPage> {
  final SupabaseClient _db = Supabase.instance.client;
  final NumberFormat _money = NumberFormat('#,##0', 'en_US');

  static const Map<int, String> _months = {
    1: 'فروردین',
    2: 'اردیبهشت',
    3: 'خرداد',
    4: 'تیر',
    5: 'مرداد',
    6: 'شهریور',
    7: 'مهر',
    8: 'آبان',
    9: 'آذر',
    10: 'دی',
    11: 'بهمن',
    12: 'اسفند',
  };

  bool _loading = true;
  String? _error;
  String? _companyId;
  int? _selectedYear;
  List<int> _years = [];
  List<Map<String, dynamic>> _periods = [];
  List<Map<String, dynamic>> _recognitions = [];
  List<Map<String, dynamic>> _previousYearRecognitions = [];
  Map<String, String> _categoryNames = {};
  Map<String, String> _categoryTypes = {};
  double _payrollTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard({int? year}) async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final user = _db.auth.currentUser;
      if (user == null) {
        throw Exception('ابتدا وارد حساب کاربری شوید.');
      }

      final membership = await _db
          .from('company_users')
          .select('company_id')
          .eq('user_id', user.id)
          .eq('role', 'company_admin')
          .eq('is_active', true)
          .limit(1)
          .maybeSingle();

      if (membership == null || membership['company_id'] == null) {
        throw Exception('شرکت فعال برای این حساب مدیرعامل پیدا نشد.');
      }

      final companyId = membership['company_id'].toString();

      // حقوق و دستمزد از هزینه‌هایی محاسبه می‌شود که منبع آن‌ها payroll است.
      final payrollRows = await _db
          .from('expenses')
          .select('amount')
          .eq('company_id', companyId)
          .eq('source_type', 'payroll');
      final payrollTotal = List<Map<String, dynamic>>.from(payrollRows)
          .fold<double>(
            0,
            (sum, row) => sum + ((row['amount'] as num?)?.toDouble() ?? 0),
          );
      final yearRows = await _db
          .from('expense_fiscal_years')
          .select('year, title')
          .eq('company_id', companyId)
          .order('year', ascending: false);

      final years = yearRows
          .map<int>((row) => (row['year'] as num).toInt())
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));

      final selectedYear =
          year ?? _selectedYear ?? (years.isNotEmpty ? years.first : null);

      if (selectedYear == null) {
        if (!mounted) return;
        setState(() {
          _companyId = companyId;
          _payrollTotal = payrollTotal;
          _years = years;
          _selectedYear = null;
          _periods = [];
          _recognitions = [];
          _previousYearRecognitions = [];
          _previousYearPeriodIds = [];
          _previousYearPeriodMonths = {};
          _categoryNames = {};
          _categoryTypes = {};
          _loading = false;
        });
        return;
      }

      final periodsResponse = await _db
          .from('expense_fiscal_periods')
          .select('id, year, month, title, status, fiscal_year_id')
          .eq('company_id', companyId)
          .eq('year', selectedYear)
          .order('month');

      final periods = List<Map<String, dynamic>>.from(periodsResponse);
      final periodIds =
          periods.map((p) => p['id'].toString()).toList(growable: false);

      List<Map<String, dynamic>> recognitions = [];
      if (periodIds.isNotEmpty) {
        final recognitionResponse = await _db
            .from('expense_recognitions')
            .select(
                'id, fiscal_period_id, category_id, amount, description, created_at')
            .eq('company_id', companyId)
            .inFilter('fiscal_period_id', periodIds)
            .order('created_at', ascending: false);
        recognitions = List<Map<String, dynamic>>.from(recognitionResponse);
      }

      final previousYear = selectedYear - 1;
      final previousPeriodRows = await _db
          .from('expense_fiscal_periods')
          .select('id, month')
          .eq('company_id', companyId)
          .eq('year', previousYear);
      final previousPeriodIds = previousPeriodRows
          .map((row) => row['id'].toString())
          .toList(growable: false);
      final previousPeriodMonths = <String, int>{
        for (final row in previousPeriodRows)
          row['id'].toString(): (row['month'] as num).toInt(),
      };
      List<Map<String, dynamic>> previousYearRecognitions = [];
      if (previousPeriodIds.isNotEmpty) {
        final previousResponse = await _db
            .from('expense_recognitions')
            .select('id, fiscal_period_id, category_id, amount, description, created_at')
            .eq('company_id', companyId)
            .inFilter('fiscal_period_id', previousPeriodIds);
        previousYearRecognitions =
            List<Map<String, dynamic>>.from(previousResponse);
      }

      final categoryResponse = await _db
          .from('expense_categories')
          .select('id, name, expense_type')
          .eq('company_id', companyId);
      final categoryNames = <String, String>{};
      final categoryTypes = <String, String>{};
      for (final row in categoryResponse) {
        final id = row['id'].toString();
        categoryNames[id] = (row['name'] ?? 'بدون نام').toString();
        categoryTypes[id] = (row['expense_type'] ?? 'operational').toString();
      }

      if (!mounted) return;
      setState(() {
        _companyId = companyId;
        _payrollTotal = payrollTotal;
        _years = years;
        _selectedYear = selectedYear;
        _periods = periods;
        _recognitions = recognitions;
        _previousYearRecognitions = previousYearRecognitions;
        _previousYearPeriodIds = previousPeriodIds;
        _previousYearPeriodMonths = previousPeriodMonths;
        _categoryNames = categoryNames;
        _categoryTypes = categoryTypes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e);
        _loading = false;
      });
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    if (text.contains('permission denied') ||
        text.contains('row-level security') ||
        text.contains('RLS')) {
      return 'دسترسی به اطلاعات هزینه‌ها مجاز نیست. سیاست‌های دسترسی Supabase را بررسی کنید.';
    }
    return text.replaceFirst('Exception: ', '');
  }

  double _amount(Map<String, dynamic> row) {
    final value = row['amount'];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double get _total => _recognitions.fold<double>(
      0, (sum, row) => sum + _amount(row));

  double _totalForType(String type) {
    return _recognitions.fold<double>(0, (sum, row) {
      final categoryId = row['category_id']?.toString();
      if (categoryId == null || _categoryTypes[categoryId] != type) {
        return sum;
      }
      return sum + _amount(row);
    });
  }

  double get _operationalTotal => _totalForType('operational');
  double get _nonOperationalTotal => _totalForType('non_operational');

  int _statusCount(String status) =>
      _periods.where((p) => p['status'] == status).length;

  String _statusLabel(String? status) {
    switch (status) {
      case 'open':
        return 'باز';
      case 'submitted_to_company_admin':
        return 'ارسال‌شده برای مدیرعامل';
      case 'submitted_to_consultant':
        return 'ارسال‌شده برای مشاور';
      case 'approved':
        return 'تأییدشده';
      case 'closed':
        return 'بسته‌شده';
      default:
        return status ?? 'نامشخص';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'approved':
      case 'closed':
        return const Color(0xFF19734F);
      case 'submitted_to_consultant':
        return const Color(0xFF2676B8);
      case 'submitted_to_company_admin':
        return const Color(0xFFB7791F);
      default:
        return const Color(0xFF68756F);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompanyAdminScaffold(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F8F6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF17231D),
          elevation: 0,
          title: const Text('هزینه‌ها'),
          actions: [
            IconButton(
              tooltip: 'بازخوانی',
              onPressed: _loading ? null : () => _loadDashboard(),
              icon: const Icon(Icons.refresh),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : RefreshIndicator(
                    onRefresh: () => _loadDashboard(),
                    child: _buildContent(),
                  ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 44, color: Colors.red),
                const SizedBox(height: 12),
                const Text('بارگذاری داشبورد هزینه ناموفق بود',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _loadDashboard(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('تلاش دوباره'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(22),
      children: [
        _buildHeader(),
        const SizedBox(height: 18),
        if (_years.isEmpty)
          _buildNoYears()
        else ...[
          _buildMetrics(),
          const SizedBox(height: 22),
          _buildAnalyticsCharts(),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE6E0)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F3E9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.trending_down,
                color: Color(0xFF19734F), size: 30),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('داشبورد هزینه',
                    style:
                        TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                Text('تحلیل هزینه‌ها و مقایسه سهم دسته‌بندی‌ها',
                    style: TextStyle(color: Color(0xFF68756F))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoYears() {
    return _emptyCard(
      'هنوز سال مالی هزینه‌ای برای شرکت ثبت نشده است. ابتدا از بخش دوره‌های مالی هزینه، سال مالی ایجاد کنید.',
      icon: Icons.calendar_month_outlined,
    );
  }

  Widget _buildYearSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDCE6E0)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: Color(0xFF19734F)),
          const SizedBox(width: 10),
          const Text('سال مالی',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          DropdownButton<int>(
            value: _selectedYear,
            underline: const SizedBox.shrink(),
            items: _years
                .map((year) => DropdownMenuItem<int>(
                      value: year,
                      child: Text(year.toString()),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) _loadDashboard(year: value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics() {
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth > 1000
          ? 4
          : constraints.maxWidth > 650
              ? 2
              : 1;
      final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
      final cards = [
        _MetricData('کل هزینه‌ها', _money.format(_total), Icons.storage),
        _MetricData('هزینه‌های عملیاتی', _money.format(_operationalTotal), Icons.settings_outlined),
        _MetricData('هزینه‌های غیرعملیاتی', _money.format(_nonOperationalTotal), Icons.account_balance_wallet_outlined),
        _MetricData('هزینه‌های حقوق و دستمزد', _money.format(_payrollTotal), Icons.groups_outlined),
      ];
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: cards
            .map((item) => SizedBox(
                  width: width,
                  child: _metricCard(item),
                ))
            .toList(),
      );
    });
  }

  Widget _metricCard(_MetricData data) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE6E0)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F3E9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: const Color(0xFF19734F)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF68756F))),
                const SizedBox(height: 7),
                Text(data.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.bold)),
                if (data.title.contains('هزینه'))
                  const Text('ریال',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFF68756F))),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildAnalyticsCharts() {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 950;
      final chartWidth = wide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          SizedBox(width: chartWidth, child: _chartCard(
            'روند هزینه‌ها در ماه‌های سال',
            SizedBox(height: 250, child: _buildMonthlyBarChart()),
          )),
          SizedBox(width: chartWidth, child: _chartCard(
            'سهم هزینه‌ها به تفکیک نوع',
            SizedBox(height: 250, child: _buildTypeDonutChart()),
          )),
          SizedBox(width: chartWidth, child: _chartCard(
            'مقایسه با دوره مشابه سال قبل',
            SizedBox(height: 250, child: _buildYearComparisonChart()),
          )),
          SizedBox(width: chartWidth, child: _chartCard(
            'سهم هر دسته از کل هزینه‌ها',
            SizedBox(height: 280, child: _buildCategoryDonutChart()),
          )),
        ],
      );
    });
  }

  Widget _chartCard(String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE6E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 18),
          chart,
        ],
      ),
    );
  }

  double _monthlyTotal(int month, {bool previousYear = false}) {
    final rows = previousYear ? _previousYearRecognitions : _recognitions;
    final periods = previousYear
        ? const <Map<String, dynamic>>[]
        : _periods;
    if (!previousYear) {
      final ids = periods
          .where((p) => (p['month'] as num?)?.toInt() == month)
          .map((p) => p['id'].toString())
          .toSet();
      return rows.where((r) => ids.contains(r['fiscal_period_id']?.toString()))
          .fold<double>(0, (sum, r) => sum + _amount(r));
    }
    final prevPeriodIds = _previousYearPeriodIds;
    final ids = prevPeriodIds
        .where((id) => _previousYearPeriodMonths[id] == month)
        .toSet();
    return rows.where((r) => ids.contains(r['fiscal_period_id']?.toString()))
        .fold<double>(0, (sum, r) => sum + _amount(r));
  }

  List<String> _previousYearPeriodIds = [];
  Map<String, int> _previousYearPeriodMonths = {};

  Widget _buildMonthlyBarChart() {
    final maxValue = List<int>.generate(12, (i) => i + 1)
        .map((m) => _monthlyTotal(m)).fold<double>(0, (a, b) => a > b ? a : b);
    return BarChart(BarChartData(
      maxY: maxValue <= 0 ? 10 : maxValue * 1.2,
      gridData: FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(enabled: true),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 48,
          getTitlesWidget: (value, meta) => Text(_compactMoney(value),
            style: const TextStyle(fontSize: 9, color: Color(0xFF68756F))),
        )),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 34,
          getTitlesWidget: (value, meta) {
            final month = value.toInt() + 1;
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_shortMonth(month), style: const TextStyle(fontSize: 9)),
            );
          },
        )),
      ),
      barGroups: List.generate(12, (index) => BarChartGroupData(
        x: index,
        barRods: [BarChartRodData(
          toY: _monthlyTotal(index + 1),
          color: const Color(0xFF168CE0),
          width: 12,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        )],
      )),
    ));
  }

  Widget _buildTypeDonutChart() {
    final operational = _operationalTotal;
    final nonOperational = _nonOperationalTotal;
    final total = operational + nonOperational;
    if (total <= 0) return _chartEmpty('برای این سال داده‌ای برای نمایش وجود ندارد.');
    return Row(children: [
      Expanded(
        flex: 5,
        child: PieChart(PieChartData(
          sectionsSpace: 3,
          centerSpaceRadius: 42,
          sections: [
            PieChartSectionData(value: operational, color: const Color(0xFF168CE0),
              radius: 35, showTitle: false),
            PieChartSectionData(value: nonOperational, color: const Color(0xFF7545C4),
              radius: 35, showTitle: false),
          ],
        )),
      ),
      Expanded(
        flex: 4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _legendDot(const Color(0xFF168CE0), 'عملیاتی', operational, total),
            const SizedBox(height: 14),
            _legendDot(const Color(0xFF7545C4), 'غیرعملیاتی', nonOperational, total),
            const SizedBox(height: 16),
            Text('${_money.format(total)} ریال', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    ]);
  }

  Widget _buildYearComparisonChart() {
    final current = List<double>.generate(12, (i) => _monthlyTotal(i + 1));
    final previous = List<double>.generate(12, (i) => _monthlyTotal(i + 1, previousYear: true));
    final maxValue = [...current, ...previous].fold<double>(0, (a, b) => a > b ? a : b);
    return LineChart(LineChartData(
      minY: 0,
      maxY: maxValue <= 0 ? 10 : maxValue * 1.2,
      gridData: FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 48,
          getTitlesWidget: (v, meta) => Text(_compactMoney(v), style: const TextStyle(fontSize: 9)))),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 34,
          getTitlesWidget: (v, meta) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_shortMonth(v.toInt() + 1), style: const TextStyle(fontSize: 9)),
          ))),
      ),
      lineBarsData: [
        LineChartBarData(spots: List.generate(12, (i) => FlSpot(i.toDouble(), current[i])),
          isCurved: true, color: const Color(0xFF168CE0), barWidth: 3,
          dotData: FlDotData(show: true)),
        LineChartBarData(spots: List.generate(12, (i) => FlSpot(i.toDouble(), previous[i])),
          isCurved: true, color: const Color(0xFF7545C4), barWidth: 3,
          dotData: FlDotData(show: true)),
      ],
    ));
  }

  Widget _buildCategoryDonutChart() {
    final totals = <String, double>{};
    for (final row in _recognitions) {
      final id = row['category_id']?.toString();
      if (id == null) continue;
      totals[id] = (totals[id] ?? 0) + _amount(row);
    }
    final sorted = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(6).toList();
    final total = top.fold<double>(0, (sum, e) => sum + e.value);
    if (total <= 0) return _chartEmpty('هنوز هزینه‌ای به دسته‌بندی‌ها متصل نشده است.');
    const colors = [
      Color(0xFF168CE0), Color(0xFF4AB8EE), Color(0xFF28A56B),
      Color(0xFFFFB62D), Color(0xFF9A4D9B), Color(0xFF7545C4),
    ];
    return Row(children: [
      Expanded(flex: 5, child: PieChart(PieChartData(
        sectionsSpace: 2, centerSpaceRadius: 38,
        sections: List.generate(top.length, (i) => PieChartSectionData(
          value: top[i].value, color: colors[i % colors.length], radius: 32, showTitle: false)),
      ))),
      Expanded(flex: 5, child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(top.length, (i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: _legendDot(colors[i % colors.length],
            _categoryNames[top[i].key] ?? 'دسته‌بندی نامشخص', top[i].value, total),
        )),
      )),
    ]);
  }

  Widget _legendDot(Color color, String label, double value, double total) {
    final percent = total == 0 ? 0 : value / total * 100;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 9, height: 9, margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 7),
      Expanded(child: Text('$label  ${percent.toStringAsFixed(1)}٪',
        style: const TextStyle(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis)),
    ]);
  }

  Widget _chartEmpty(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Text(message, textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF68756F))),
    ),
  );

  String _shortMonth(int month) {
    const names = ['فرو', 'ارد', 'خرد', 'تیر', 'مرد', 'شهر', 'مهر', 'آبا', 'آذر', 'دی', 'بهم', 'اسف'];
    return month >= 1 && month <= 12 ? names[month - 1] : '';
  }

  String _compactMoney(double value) {
    if (value >= 1000000000) return '${(value / 1000000000).toStringAsFixed(0)}ب';
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(0)}م';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}ه';
    return value.toStringAsFixed(0);
  }

  Widget _buildWorkflowSummary() {
    final items = [
      ('باز', 'open', const Color(0xFF68756F)),
      ('ارسال‌شده برای مدیرعامل', 'submitted_to_company_admin',
          const Color(0xFFB7791F)),
      ('ارسال‌شده برای مشاور', 'submitted_to_consultant',
          const Color(0xFF2676B8)),
      ('تأییدشده', 'approved', const Color(0xFF19734F)),
      ('بسته‌شده', 'closed', const Color(0xFF46564E)),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map((item) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFDCE6E0)),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                          color: item.$3, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(item.$1),
                    const SizedBox(width: 10),
                    Text(_statusCount(item.$2).toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildPeriods() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE6E0)),
      ),
      child: Column(
        children: List.generate(_periods.length, (index) {
          final period = _periods[index];
          final month = (period['month'] as num?)?.toInt() ?? 0;
          final status = period['status']?.toString();
          final total = _recognitions
              .where((r) => r['fiscal_period_id'].toString() ==
                  period['id'].toString())
              .fold<double>(0, (sum, row) => sum + _amount(row));
          return Column(
            children: [
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F3E9),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.calendar_today,
                      color: Color(0xFF19734F)),
                ),
                title: Text(
                  (period['title']?.toString().trim().isNotEmpty ?? false)
                      ? period['title'].toString()
                      : (_months[month] ?? 'ماه $month'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('مجموع شناسایی: ${_money.format(total)} ریال'),
                ),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                        color: _statusColor(status),
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              if (index != _periods.length - 1)
                const Divider(height: 1, indent: 18, endIndent: 18),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildRecentRecognitions() {
    final rows = _recognitions.take(8).toList();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE6E0)),
      ),
      child: Column(
        children: List.generate(rows.length, (index) {
          final row = rows[index];
          final categoryId = row['category_id']?.toString();
          final category = categoryId == null
              ? 'بدون دسته‌بندی'
              : (_categoryNames[categoryId] ?? 'دسته‌بندی نامشخص');
          final amount = _money.format(_amount(row));
          final description = row['description']?.toString().trim() ?? '';
          return Column(
            children: [
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0F3E9),
                  child: Icon(Icons.trending_down, color: Color(0xFF19734F)),
                ),
                title: Text(category,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(description.isEmpty ? 'بدون توضیحات' : description,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: Text('$amount ریال',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF19734F))),
              ),
              if (index != rows.length - 1)
                const Divider(height: 1, indent: 18, endIndent: 18),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _emptyCard(String message, {IconData icon = Icons.info_outline}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE6E0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: const Color(0xFF19734F)),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _MetricData {
  const _MetricData(this.title, this.value, this.icon);
  final String title;
  final String value;
  final IconData icon;
}
