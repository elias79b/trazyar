import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

class BankingDashboardPage extends StatefulWidget {
  final String companyId;

  const BankingDashboardPage({super.key, required this.companyId});

  @override
  State<BankingDashboardPage> createState() => _BankingDashboardPageState();
}

class _BankingDashboardPageState extends State<BankingDashboardPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loading = true;
  String? _error;

  List<_PeriodPoint> _periods = [];
  List<_BankShare> _bankShares = [];
  List<_LoanPoint> _loans = [];

  double _totalLiquidity = 0;
  double _totalBankLiquidity = 0;
  double _totalCashLiquidity = 0;
  double _totalPettyCash = 0;

  double _totalDiscrepancy = 0;

  double _previousLiquidity = 0;
  double _liquidityChangePercent = 0;

  double _bankDebt = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        _supabase
            .from('cash_fiscal_periods')
            .select('id, company_id, year, month, title, status')
            .eq('company_id', widget.companyId)
            .order('year', ascending: true)
            .order('month', ascending: true),

        _supabase
            .from('bank_account_periods')
            .select(
              'id, period_id, bank_account_id, '
              'opening_balance, debit_turnover, credit_turnover, '
              'closing_balance, ledger_balance, discrepancy',
            )
            .eq('company_id', widget.companyId),

        _supabase
            .from('cash_box_periods')
            .select(
              'id, period_id, cash_box_id, '
              'opening_balance, total_receipts, total_payments, '
              'closing_balance, ledger_balance, discrepancy',
            )
            .eq('company_id', widget.companyId),

        _supabase
            .from('petty_cash_periods')
            .select(
              'id, period_id, petty_cash_id, '
              'opening_balance, total_receipts, total_payments, '
              'closing_balance, ledger_balance, discrepancy',
            )
            .eq('company_id', widget.companyId),

        _supabase
            .from('bank_accounts')
            .select('id, bank_name, account_number')
            .eq('company_id', widget.companyId),

        _supabase
            .from('cash_boxes')
            .select('*')
            .eq('company_id', widget.companyId),

        _supabase
            .from('petty_cash_accounts')
            .select('*')
            .eq('company_id', widget.companyId),

        _supabase
            .from('bank_loans')
            .select(
              'id, bank_name, loan_type, principal_amount, '
              'remaining_amount, interest_rate, start_date, '
              'end_date, monthly_installment',
            )
            .eq('company_id', widget.companyId),
      ]);

      final periods = _maps(results[0]);
      final banks = _maps(results[1]);
      final cashBoxes = _maps(results[2]);
      final pettyCash = _maps(results[3]);
      final bankAccounts = _maps(results[4]);
      final cashBoxMasters = _maps(results[5]);
      final pettyMasters = _maps(results[6]);
      final loans = _maps(results[7]);

      final loaded = _buildDashboardData(
        periods: periods,
        banks: banks,
        cashBoxes: cashBoxes,
        pettyCash: pettyCash,
        bankAccounts: bankAccounts,
        cashBoxMasters: cashBoxMasters,
        pettyMasters: pettyMasters,
        loans: loans,
      );

      if (!mounted) return;

      setState(() {
        _periods = loaded.periods;
        _bankShares = loaded.bankShares;
        _loans = loaded.loans;

        _totalLiquidity = loaded.totalLiquidity;
        _totalBankLiquidity = loaded.totalBankLiquidity;
        _totalCashLiquidity = loaded.totalCashLiquidity;
        _totalPettyCash = loaded.totalPettyCash;

        _totalDiscrepancy = loaded.totalDiscrepancy;

        _previousLiquidity = loaded.previousLiquidity;
        _liquidityChangePercent = loaded.liquidityChangePercent;

        _bankDebt = loaded.bankDebt;

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = _cleanError(e);
      });
    }
  }

  List<Map<String, dynamic>> _maps(dynamic value) {
    return (value as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  _DashboardData _buildDashboardData({
    required List<Map<String, dynamic>> periods,
    required List<Map<String, dynamic>> banks,
    required List<Map<String, dynamic>> cashBoxes,
    required List<Map<String, dynamic>> pettyCash,
    required List<Map<String, dynamic>> bankAccounts,
    required List<Map<String, dynamic>> cashBoxMasters,
    required List<Map<String, dynamic>> pettyMasters,
    required List<Map<String, dynamic>> loans,
  }) {
    final orderedPeriods = [...periods]..sort((a, b) {
      final yearCompare = _int(a['year']).compareTo(_int(b['year']));

      if (yearCompare != 0) {
        return yearCompare;
      }

      return _int(a['month']).compareTo(_int(b['month']));
    });

    final recentPeriods =
        orderedPeriods.length > 12
            ? orderedPeriods.sublist(orderedPeriods.length - 12)
            : orderedPeriods;

    final points = <_PeriodPoint>[];

    for (final period in recentPeriods) {
      final periodId = period['id']?.toString();

      if (periodId == null) continue;

      final bankRows = banks.where(
        (row) => row['period_id']?.toString() == periodId,
      );

      final cashRows = cashBoxes.where(
        (row) => row['period_id']?.toString() == periodId,
      );

      final pettyRows = pettyCash.where(
        (row) => row['period_id']?.toString() == periodId,
      );

      double bank = 0;
      double cash = 0;
      double petty = 0;
      double discrepancy = 0;
      double netTurnover = 0;

      for (final row in bankRows) {
        bank += _num(row['closing_balance']);

        netTurnover +=
            _num(row['debit_turnover']) - _num(row['credit_turnover']);

        discrepancy += _num(row['discrepancy']).abs();
      }

      for (final row in cashRows) {
        cash += _num(row['closing_balance']);
        discrepancy += _num(row['discrepancy']).abs();
      }

      for (final row in pettyRows) {
        petty += _num(row['closing_balance']);
        discrepancy += _num(row['discrepancy']).abs();
      }

      points.add(
        _PeriodPoint(
          year: _int(period['year']),
          month: _int(period['month']),
          label: _monthShort(_int(period['month'])),
          bankBalance: bank,
          cashBalance: cash,
          pettyBalance: petty,
          totalLiquidity: bank + cash + petty,
          netBankTurnover: netTurnover,
          discrepancy: discrepancy,
        ),
      );
    }

    _PeriodPoint? latest;
    _PeriodPoint? previous;

    if (points.isNotEmpty) {
      latest = points.last;
    }

    if (points.length >= 2) {
      previous = points[points.length - 2];
    }

    final latestPeriodId =
        latest == null ? null : recentPeriods.last['id']?.toString();

    final bankSharesMap = <String, double>{};

    if (latestPeriodId != null) {
      for (final row in banks.where(
        (row) => row['period_id']?.toString() == latestPeriodId,
      )) {
        final bankId = row['bank_account_id']?.toString();

        final master = bankAccounts.where(
          (item) => item['id']?.toString() == bankId,
        );

        String bankName = 'بانک';

        if (master.isNotEmpty) {
          final value = master.first['bank_name']?.toString();

          if (value != null && value.trim().isNotEmpty) {
            bankName = value;
          }
        }

        bankSharesMap[bankName] =
            (bankSharesMap[bankName] ?? 0) + _num(row['closing_balance']);
      }
    }

    final latestBankTotal = latest?.bankBalance ?? 0;

    final bankShares =
        bankSharesMap.entries
            .map(
              (entry) => _BankShare(
                name: entry.key,
                amount: entry.value,
                percent:
                    latestBankTotal == 0
                        ? 0
                        : entry.value / latestBankTotal * 100,
              ),
            )
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    final bankDebt = loans.fold<double>(
      0,
      (sum, loan) => sum + _num(loan['remaining_amount']),
    );

    final loanPoints = <_LoanPoint>[];

    final loanGroups = <String, double>{};

    for (final loan in loans) {
      final bankName = loan['bank_name']?.toString().trim();

      final name = bankName == null || bankName.isEmpty ? 'سایر' : bankName;

      loanGroups[name] =
          (loanGroups[name] ?? 0) + _num(loan['remaining_amount']);
    }

    loanGroups.forEach((name, amount) {
      loanPoints.add(_LoanPoint(bankName: name, remainingAmount: amount));
    });

    loanPoints.sort((a, b) => b.remainingAmount.compareTo(a.remainingAmount));

    final totalLiquidity = latest?.totalLiquidity ?? 0;

    final previousLiquidity = previous?.totalLiquidity ?? 0;

    return _DashboardData(
      periods: points,
      bankShares: bankShares,
      loans: loanPoints,
      totalLiquidity: totalLiquidity,
      totalBankLiquidity: latest?.bankBalance ?? 0,
      totalCashLiquidity: latest?.cashBalance ?? 0,
      totalPettyCash: latest?.pettyBalance ?? 0,
      totalDiscrepancy: latest?.discrepancy ?? 0,
      previousLiquidity: previousLiquidity,
      liquidityChangePercent: _changePercent(previousLiquidity, totalLiquidity),
      bankDebt: bankDebt,
    );
  }

  double _changePercent(double previous, double current) {
    if (previous == 0) return 0;

    return ((current - previous) / previous.abs()) * 100;
  }

  int _int(dynamic value) {
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _num(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString().replaceAll(',', '').replaceAll('٬', '').trim(),
        ) ??
        0;
  }

  String _money(dynamic value) {
    final number = _num(value).round();
    final negative = number < 0;
    final text = number.abs().toString();

    final formatted = text.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match.group(1)},',
    );

    return '${negative ? '-' : ''}${_persian(formatted)}';
  }

  String _moneyShort(double value) {
    final abs = value.abs();

    if (abs >= 1000000000) {
      return '${_persian((value / 1000000000).toStringAsFixed(1))} میلیارد';
    }

    if (abs >= 1000000) {
      return '${_persian((value / 1000000).toStringAsFixed(1))} میلیون';
    }

    if (abs >= 1000) {
      return '${_persian((value / 1000).toStringAsFixed(0))} هزار';
    }

    return _money(value);
  }

  String _persian(String value) {
    const en = '0123456789';
    const fa = '۰۱۲۳۴۵۶۷۸۹';

    var result = value;

    for (int i = 0; i < en.length; i++) {
      result = result.replaceAll(en[i], fa[i]);
    }

    return result;
  }

  static String _monthShort(int month) {
    const names = [
      'فروردین',
      'اردیبهشت',
      'خرداد',
      'تیر',
      'مرداد',
      'شهریور',
      'مهر',
      'آبان',
      'آذر',
      'دی',
      'بهمن',
      'اسفند',
    ];

    if (month < 1 || month > 12) {
      return '-';
    }

    return names[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return CompanyScaffold(
      companyId: widget.companyId,
      currentRoute: '/consultant/companies/${widget.companyId}/banking',
      title: 'داشبورد بانک و نقد',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 52,
                color: Colors.red.shade600,
              ),
              const SizedBox(height: 14),
              const Text(
                'دریافت اطلاعات داشبورد انجام نشد',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadDashboard,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('تلاش مجدد'),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1050;

        return RefreshIndicator(
          onRefresh: _loadDashboard,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(compact ? 16 : 24),
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildTopCards(compact),
              const SizedBox(height: 20),
              _buildCharts(compact),
              const SizedBox(height: 20),
              _buildLiquiditySummary(),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final latest = _periods.isNotEmpty ? _periods.last : null;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [Color(0xffeaf5ef), Color(0xfff8fbf9)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffdce9e2)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xffd8eee3),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: Color(0xff176044),
              size: 29,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'داشبورد بانک و نقد',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  latest == null
                      ? 'تحلیل نقدینگی شرکت'
                      : 'آخرین دوره ثبت‌شده: ${latest.label} ${_persian(latest.year.toString())}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'به‌روزرسانی',
            onPressed: _loadDashboard,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCards(bool compact) {
    final cards = [
      _metricCard(
        title: 'کل نقدینگی',
        value: _money(_totalLiquidity),
        subtitle: 'آخرین دوره مالی',
        icon: Icons.account_balance_wallet_rounded,
      ),
      _metricCard(
        title: 'موجودی بانک',
        value: _money(_totalBankLiquidity),
        subtitle: 'مانده حساب‌های بانکی',
        icon: Icons.account_balance_rounded,
      ),
      _metricCard(
        title: 'موجودی نقد',
        value: _money(_totalCashLiquidity + _totalPettyCash),
        subtitle: 'صندوق + تنخواه',
        icon: Icons.payments_rounded,
      ),
      _metricCard(
        title: 'مغایرت',
        value: _money(_totalDiscrepancy),
        subtitle: 'آخرین دوره',
        icon: Icons.compare_arrows_rounded,
        danger: _totalDiscrepancy != 0,
      ),
    ];

    if (compact) {
      return Column(
        children: [
          for (final card in cards) ...[card, const SizedBox(height: 10)],
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    bool danger = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: danger ? const Color(0xffffdada) : const Color(0xffe2e9e5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(
              color: danger ? const Color(0xffffeeee) : const Color(0xffe8f4ee),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: danger ? Colors.red.shade700 : const Color(0xff176044),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color:
                        danger ? Colors.red.shade700 : const Color(0xff17372b),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharts(bool compact) {
    final charts = [
      _chartCard(
        title: 'روند خالص گردش بانک',
        subtitle: 'بدهکار منهای بستانکار در دوره‌های اخیر',
        child: _buildTurnoverChart(),
      ),
      _chartCard(
        title: 'تمرکز موجودی بانک‌ها',
        subtitle: 'سهم هر بانک از موجودی آخرین دوره',
        child: _buildBankShareChart(),
      ),
      _chartCard(
        title: 'روند مغایرت',
        subtitle: 'مجموع مغایرت مطلق در دوره‌های اخیر',
        child: _buildDiscrepancyChart(),
      ),
      _chartCard(
        title: 'تسهیلات و بدهی بانکی',
        subtitle: 'مانده واقعی تسهیلات از جدول bank_loans',
        child: _buildDebtChart(),
      ),
    ];

    if (compact) {
      return Column(
        children: [
          for (final chart in charts) ...[chart, const SizedBox(height: 16)],
        ],
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: charts[0]),
            const SizedBox(width: 16),
            Expanded(child: charts[1]),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: charts[2]),
            const SizedBox(width: 16),
            Expanded(child: charts[3]),
          ],
        ),
      ],
    );
  }

  Widget _chartCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffe2e9e5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 18),
          SizedBox(height: 300, child: child),
        ],
      ),
    );
  }

  Widget _buildTurnoverChart() {
    if (_periods.isEmpty) {
      return _emptyChart();
    }

    final spots = List.generate(
      _periods.length,
      (index) => FlSpot(index.toDouble(), _periods[index].netBankTurnover),
    );

    return LineChart(
      LineChartData(
        minY: _lineMin(_periods.map((e) => e.netBankTurnover).toList()),
        maxY: _lineMax(_periods.map((e) => e.netBankTurnover).toList()),
        gridData: FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: _titles(labels: _periods.map((e) => e.label).toList()),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final index = spot.x.round();
                final label =
                    index >= 0 && index < _periods.length
                        ? _periods[index].label
                        : '';

                return LineTooltipItem(
                  '$label\n${_money(spot.y)}',
                  const TextStyle(fontWeight: FontWeight.w800),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildBankShareChart() {
    if (_bankShares.isEmpty) {
      return _emptyChart(
        text: 'در آخرین دوره اطلاعات حساب بانکی ثبت نشده است.',
      );
    }

    final items = _bankShares.take(6).toList();

    final max = items
        .map((e) => e.percent)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: max == 0 ? 100 : (max * 1.25),
        gridData: FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: const TextStyle(fontSize: 9),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final item = items[groupIndex];

              return BarTooltipItem(
                '${item.name}\n${item.percent.toStringAsFixed(1)}%',
                const TextStyle(fontWeight: FontWeight.w800),
              );
            },
          ),
        ),
        barGroups: List.generate(
          items.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: items[index].percent,
                width: 25,
                borderRadius: BorderRadius.circular(5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscrepancyChart() {
    if (_periods.isEmpty) {
      return _emptyChart();
    }

    final spots = List.generate(
      _periods.length,
      (index) => FlSpot(index.toDouble(), _periods[index].discrepancy),
    );

    final values = _periods.map((e) => e.discrepancy).toList();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: _lineMax(values),
        gridData: FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: _titles(labels: _periods.map((e) => e.label).toList()),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              return spots
                  .map(
                    (spot) => LineTooltipItem(
                      _money(spot.y),
                      const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  )
                  .toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtChart() {
    if (_loans.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_rounded,
            size: 42,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          Text(
            'تسهیلات بانکی ثبت نشده است.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            'بدهی فعلی: ${_money(_bankDebt)}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      );
    }

    final items = _loans.take(6).toList();

    final maxValue = items
        .map((e) => e.remainingAmount)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return Row(
      children: [
        Expanded(
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: maxValue == 0 ? 1000 : maxValue * 1.25,
              gridData: FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    getTitlesWidget: (value, meta) {
                      final index = value.round();

                      if (index < 0 || index >= items.length) {
                        return const SizedBox();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Text(
                          items[index].bankName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 9),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 52,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        _moneyShort(value),
                        style: const TextStyle(fontSize: 8),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final loan = items[groupIndex];

                    return BarTooltipItem(
                      '${loan.bankName}\n${_money(loan.remainingAmount)}',
                      const TextStyle(fontWeight: FontWeight.w800),
                    );
                  },
                ),
              ),
              barGroups: List.generate(
                items.length,
                (index) => BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: items[index].remainingAmount,
                      width: 25,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        SizedBox(
          width: 125,
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xfff7f8f7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'کل بدهی تسهیلات',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                ),
                const SizedBox(height: 7),
                Text(
                  _moneyShort(_bankDebt),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  double _lineMin(List<double> values) {
    if (values.isEmpty) return 0;

    final min = values.reduce((a, b) => a < b ? a : b);

    final max = values.reduce((a, b) => a > b ? a : b);

    final range = (max - min).abs();

    final padding =
        range == 0 ? (max.abs() * .2).clamp(1000, double.infinity) : range * .2;

    return min - padding;
  }

  double _lineMax(List<double> values) {
    if (values.isEmpty) return 1000;

    final min = values.reduce((a, b) => a < b ? a : b);

    final max = values.reduce((a, b) => a > b ? a : b);

    final range = (max - min).abs();

    final padding =
        range == 0 ? (max.abs() * .2).clamp(1000, double.infinity) : range * .2;

    return max + padding;
  }

  FlTitlesData _titles({required List<String> labels}) {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: 1,
          getTitlesWidget: (value, meta) {
            final index = value.round();

            if (index < 0 || index >= labels.length) {
              return const SizedBox();
            }

            return Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(labels[index], style: const TextStyle(fontSize: 8)),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 55,
          getTitlesWidget: (value, meta) {
            return Text(
              _moneyShort(value),
              style: const TextStyle(fontSize: 8),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLiquiditySummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffe2e9e5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'خلاصه وضعیت نقدینگی',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 14,
            children: [
              _summaryItem('بانک', _totalBankLiquidity),
              _summaryItem('صندوق', _totalCashLiquidity),
              _summaryItem('تنخواه', _totalPettyCash),
              _summaryItem('کل نقدینگی', _totalLiquidity),
              _summaryItem(
                'تغییر نسبت به دوره قبل',
                _liquidityChangePercent,
                percent: true,
              ),
              _summaryItem('بدهی تسهیلات', _bankDebt),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String title, double value, {bool percent = false}) {
    return SizedBox(
      width: 205,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xff4a9272),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
          ),
          Text(
            percent
                ? '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}٪'
                : _money(value),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _emptyChart({
    String text = 'اطلاعات کافی برای نمایش نمودار وجود ندارد.',
  }) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
      ),
    );
  }

  String _cleanError(Object e) {
    final text = e.toString();

    if (text.contains('permission denied')) {
      return 'دسترسی لازم برای مشاهده اطلاعات وجود ندارد.';
    }

    if (text.contains('row-level security')) {
      return 'دسترسی امنیتی برای مشاهده اطلاعات این شرکت وجود ندارد.';
    }

    if (text.contains('does not exist')) {
      return 'یکی از جداول یا ستون‌های مورد استفاده در دیتابیس وجود ندارد.\n$text';
    }

    return text.replaceFirst('Exception: ', '');
  }
}

class _PeriodPoint {
  final int year;
  final int month;
  final String label;

  final double bankBalance;
  final double cashBalance;
  final double pettyBalance;

  final double totalLiquidity;
  final double netBankTurnover;
  final double discrepancy;

  const _PeriodPoint({
    required this.year,
    required this.month,
    required this.label,
    required this.bankBalance,
    required this.cashBalance,
    required this.pettyBalance,
    required this.totalLiquidity,
    required this.netBankTurnover,
    required this.discrepancy,
  });
}

class _BankShare {
  final String name;
  final double amount;
  final double percent;

  const _BankShare({
    required this.name,
    required this.amount,
    required this.percent,
  });
}

class _LoanPoint {
  final String bankName;
  final double remainingAmount;

  const _LoanPoint({required this.bankName, required this.remainingAmount});
}

class _DashboardData {
  final List<_PeriodPoint> periods;
  final List<_BankShare> bankShares;
  final List<_LoanPoint> loans;

  final double totalLiquidity;
  final double totalBankLiquidity;
  final double totalCashLiquidity;
  final double totalPettyCash;

  final double totalDiscrepancy;

  final double previousLiquidity;
  final double liquidityChangePercent;

  final double bankDebt;

  const _DashboardData({
    required this.periods,
    required this.bankShares,
    required this.loans,
    required this.totalLiquidity,
    required this.totalBankLiquidity,
    required this.totalCashLiquidity,
    required this.totalPettyCash,
    required this.totalDiscrepancy,
    required this.previousLiquidity,
    required this.liquidityChangePercent,
    required this.bankDebt,
  });
}
