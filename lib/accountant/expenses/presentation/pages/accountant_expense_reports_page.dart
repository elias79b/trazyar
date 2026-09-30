import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarazyar/accountant/expenses/application/accountant_expense_reports_provider.dart';

class AccountantExpenseReportsPage extends ConsumerStatefulWidget {
  final String companyId;

  const AccountantExpenseReportsPage({
    super.key,
    required this.companyId,
  });

  @override
  ConsumerState<AccountantExpenseReportsPage> createState() =>
      _AccountantExpenseReportsPageState();
}

class _AccountantExpenseReportsPageState
    extends ConsumerState<AccountantExpenseReportsPage> {
  String? _selectedYearId;
  String? _selectedPeriodId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      accountantExpenseReportsProvider(widget.companyId),
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xfff5f7f9),
        body: state.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => _ErrorView(
            message: error.toString(),
            onRetry: () {
              ref.invalidate(
                accountantExpenseReportsProvider(widget.companyId),
              );
            },
          ),
          data: (data) {
            return _buildContent(
              context,
              data,
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context,
      AccountantExpenseReportsData data,
      ) {
    final years = data.openYears;

    if (years.isEmpty) {
      return const _EmptyView(
        title: 'سال مالی ثبت نشده است',
        description: 'برای مشاهده گزارش هزینه ابتدا یک سال مالی ایجاد کنید.',
      );
    }

    final selectedYear = _resolveYear(data);

    if (selectedYear == null) {
      return const _EmptyView(
        title: 'سال مالی یافت نشد',
        description: 'سال مالی انتخاب‌شده در دسترس نیست.',
      );
    }

    final periods = data.periods
        .where(
          (period) => period.fiscalYearId == selectedYear.id,
    )
        .toList()
      ..sort(
            (a, b) => _monthValue(a.month).compareTo(
          _monthValue(b.month),
        ),
      );

    final selectedPeriod = _resolvePeriod(periods);

    if (selectedPeriod == null) {
      return _buildShell(
        context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(
              data,
              years,
              selectedYear,
              periods,
              null,
            ),
            const SizedBox(height: 24),
            const _EmptyView(
              title: 'دوره مالی یافت نشد',
              description: 'برای این سال مالی هنوز دوره‌ای ایجاد نشده است.',
            ),
          ],
        ),
      );
    }

    final total = data.totalForPeriod(
      selectedPeriod.id,
    );

    final operational = data.operationalTotalForPeriod(
      selectedPeriod.id,
    );

    final nonOperational = data.nonOperationalTotalForPeriod(
      selectedPeriod.id,
    );

    final previousPeriod = _previousPeriod(
      data,
      selectedPeriod,
    );

    final previousTotal = previousPeriod == null
        ? 0.0
        : data.totalForPeriod(
      previousPeriod.id,
    );

    final changePercent = previousTotal == 0
        ? (total == 0 ? 0.0 : 100.0)
        : ((total - previousTotal) / previousTotal) * 100;

    final breakdown = data.categoryBreakdownForPeriod(
      selectedPeriod.id,
    );

    final selectedYearNumber = _intValue(selectedYear.year);

    final monthlyTrend = data.monthlyTrendForYear(
      selectedYearNumber,
    );

    final quarterlyTrend = data.quarterlyTrendForYear(
      selectedYearNumber,
    );

    return _buildShell(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(
            data,
            years,
            selectedYear,
            periods,
            selectedPeriod,
          ),
          const SizedBox(height: 20),
          _buildSummaryCards(
            total: total,
            operational: operational,
            nonOperational: nonOperational,
            changePercent: changePercent,
          ),
          const SizedBox(height: 20),
          _buildCharts(
            operational: operational,
            nonOperational: nonOperational,
            breakdown: breakdown,
          ),
          const SizedBox(height: 20),
          _buildTrendSection(
            monthlyTrend: monthlyTrend,
            quarterlyTrend: quarterlyTrend,
          ),
          const SizedBox(height: 20),
          _buildCategoryTable(
            breakdown: breakdown,
            total: total,
          ),
          const SizedBox(height: 20),
          _buildPayableInfo(),
        ],
      ),
    );
  }

  Widget _buildShell(
      BuildContext context, {
        required Widget child,
      }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth >= 1400
            ? 1320.0
            : constraints.maxWidth >= 1000
            ? 1180.0
            : double.infinity;

        return SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth < 600 ? 14 : 24,
                  vertical: constraints.maxWidth < 600 ? 14 : 24,
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
      AccountantExpenseReportsData data,
      List<AccountantExpenseReportFiscalYear> years,
      AccountantExpenseReportFiscalYear selectedYear,
      List<AccountantExpenseReportFiscalPeriod> periods,
      AccountantExpenseReportFiscalPeriod? selectedPeriod,
      ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xffe7ebef),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;

          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'گزارش هزینه',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff17212b),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                selectedPeriod == null
                    ? 'گزارش‌گیری و تحلیل هزینه‌های شرکت'
                    : 'گزارش ${selectedPeriod.monthTitle} سال ${_digits(selectedPeriod.year.toString())}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xff7a8793),
                ),
              ),
            ],
          );

          final selectors = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: compact ? constraints.maxWidth : 190,
                child: DropdownButtonFormField<
                    AccountantExpenseReportFiscalYear>(
                  value: selectedYear,
                  isExpanded: true,
                  decoration: _dropdownDecoration('سال مالی'),
                  items: years
                      .map(
                        (item) => DropdownMenuItem<
                        AccountantExpenseReportFiscalYear>(
                      value: item,
                      child: Text(
                        item.title ??
                            'سال ${_digits(item.year.toString())}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    final firstPeriods = data.periods
                        .where(
                          (period) =>
                      period.fiscalYearId == value.id,
                    )
                        .toList()
                      ..sort(
                            (a, b) => _monthValue(a.month).compareTo(
                          _monthValue(b.month),
                        ),
                      );

                    setState(() {
                      _selectedYearId = value.id;
                      _selectedPeriodId = firstPeriods.isEmpty
                          ? null
                          : firstPeriods.first.id;
                    });
                  },
                ),
              ),
              SizedBox(
                width: compact ? constraints.maxWidth : 190,
                child: DropdownButtonFormField<
                    AccountantExpenseReportFiscalPeriod>(
                  value: selectedPeriod,
                  isExpanded: true,
                  decoration: _dropdownDecoration('ماه'),
                  items: periods
                      .map(
                        (item) => DropdownMenuItem<
                        AccountantExpenseReportFiscalPeriod>(
                      value: item,
                      child: Text(
                        item.monthTitle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _selectedPeriodId = value.id;
                    });
                  },
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                title,
                const SizedBox(height: 18),
                selectors,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 20),
              selectors,
            ],
          );
        },
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xfff8fafb),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xffe1e7eb),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xffe1e7eb),
        ),
      ),
    );
  }

  Widget _buildSummaryCards({
    required double total,
    required double operational,
    required double nonOperational,
    required double changePercent,
  }) {
    final cards = [
      _SummaryCardData(
        title: 'کل هزینه دوره',
        value: _money(total),
        description: 'مجموع هزینه‌های ثبت‌شده',
        icon: Icons.account_balance_wallet_outlined,
      ),
      _SummaryCardData(
        title: 'هزینه عملیاتی',
        value: _money(operational),
        description: 'هزینه‌های عملیاتی',
        icon: Icons.business_center_outlined,
      ),
      _SummaryCardData(
        title: 'هزینه غیرعملیاتی',
        value: _money(nonOperational),
        description: 'هزینه‌های غیرعملیاتی',
        icon: Icons.swap_vertical_circle_outlined,
      ),
      _SummaryCardData(
        title: 'تغییر نسبت به ماه قبل',
        value: '${_signed(changePercent)}٪',
        description: 'مقایسه با دوره قبلی',
        icon: changePercent >= 0
            ? Icons.trending_up
            : Icons.trending_down,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final columns = width >= 1100
            ? 4
            : width >= 700
            ? 2
            : 1;

        final itemWidth = columns == 1
            ? width
            : (width - ((columns - 1) * 14)) / columns;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: cards
              .map(
                (card) => SizedBox(
              width: itemWidth,
              child: _SummaryCard(data: card),
            ),
          )
              .toList(),
        );
      },
    );
  }

  Widget _buildCharts({
    required double operational,
    required double nonOperational,
    required List<AccountantExpenseReportCategoryBreakdown>
    breakdown,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;

        final composition = _ChartCard(
          title: 'ترکیب هزینه‌های عملیاتی و غیرعملیاتی',
          child: SizedBox(
            height: 300,
            child: _buildCompositionChart(
              operational,
              nonOperational,
            ),
          ),
        );

        final categoryChart = _ChartCard(
          title: 'هزینه‌ها به تفکیک سرفصل',
          child: SizedBox(
            height: 300,
            child: _buildCategoryBarChart(
              breakdown,
            ),
          ),
        );

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: composition),
              const SizedBox(width: 16),
              Expanded(child: categoryChart),
            ],
          );
        }

        return Column(
          children: [
            composition,
            const SizedBox(height: 16),
            categoryChart,
          ],
        );
      },
    );
  }

  Widget _buildCompositionChart(
      double operational,
      double nonOperational,
      ) {
    final total = operational + nonOperational;

    if (total <= 0) {
      return const _NoChartData();
    }

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 58,
              sectionsSpace: 4,
              sections: [
                PieChartSectionData(
                  value: operational,
                  title: '${_share(operational, total)}٪',
                  radius: 75,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  value: nonOperational,
                  title: '${_share(nonOperational, total)}٪',
                  radius: 75,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          flex: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(
                title: 'عملیاتی',
                value: _money(operational),
              ),
              const SizedBox(height: 14),
              _LegendItem(
                title: 'غیرعملیاتی',
                value: _money(nonOperational),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBarChart(
      List<AccountantExpenseReportCategoryBreakdown> breakdown,
      ) {
    final items = breakdown
        .where(
          (item) => _categoryAmount(item) > 0,
    )
        .take(8)
        .toList();

    if (items.isEmpty) {
      return const _NoChartData();
    }

    final maxValue = items.fold<double>(
      0,
          (previous, item) {
        final amount = _categoryAmount(item);
        return amount > previous ? amount : previous;
      },
    );

    return BarChart(
      BarChartData(
        maxY: maxValue == 0 ? 1 : maxValue * 1.2,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) {
                return Text(
                  _compactMoney(value),
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xff7b8791),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 46,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();

                if (index < 0 || index >= items.length) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: 70,
                    child: Text(
                      _categoryName(items[index]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xff66737e),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(
          items.length,
              (index) {
            final item = items[index];

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: _categoryAmount(item),
                  width: 22,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTrendSection({
    required List<AccountantExpenseReportMonthlyPoint> monthlyTrend,
    required List<AccountantExpenseReportQuarterPoint>
    quarterlyTrend,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;

        final monthly = _ChartCard(
          title: 'روند ماهانه هزینه',
          child: SizedBox(
            height: 300,
            child: _buildMonthlyLineChart(
              monthlyTrend,
            ),
          ),
        );

        final quarterly = _ChartCard(
          title: 'روند فصلی هزینه',
          child: SizedBox(
            height: 300,
            child: _buildQuarterChart(
              quarterlyTrend,
            ),
          ),
        );

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: monthly),
              const SizedBox(width: 16),
              Expanded(child: quarterly),
            ],
          );
        }

        return Column(
          children: [
            monthly,
            const SizedBox(height: 16),
            quarterly,
          ],
        );
      },
    );
  }

  Widget _buildMonthlyLineChart(
      List<AccountantExpenseReportMonthlyPoint> points,
      ) {
    final items = points.toList()
      ..sort(
            (a, b) => _monthValue(a.month).compareTo(
          _monthValue(b.month),
        ),
      );

    if (items.isEmpty) {
      return const _NoChartData();
    }

    final maxValue = items.fold<double>(
      0,
          (previous, item) {
        final amount = _monthlyAmount(item);
        return amount > previous ? amount : previous;
      },
    );

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxValue == 0 ? 1 : maxValue * 1.2,
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) {
                return Text(
                  _compactMoney(value),
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xff7b8791),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final month = value.toInt();

                if (month < 1 || month > 12) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _digits(month.toString()),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xff66737e),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            spots: items
                .map(
                  (item) => FlSpot(
                _monthValue(item.month).toDouble(),
                _monthlyAmount(item),
              ),
            )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuarterChart(
      List<AccountantExpenseReportQuarterPoint> points,
      ) {
    final items = points.toList()
      ..sort(
            (a, b) => _quarterValue(a.quarter).compareTo(
          _quarterValue(b.quarter),
        ),
      );

    if (items.isEmpty) {
      return const _NoChartData();
    }

    final maxValue = items.fold<double>(
      0,
          (previous, item) {
        final amount = _quarterAmount(item);
        return amount > previous ? amount : previous;
      },
    );

    return BarChart(
      BarChartData(
        maxY: maxValue == 0 ? 1 : maxValue * 1.2,
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) {
                return Text(
                  _compactMoney(value),
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xff7b8791),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final quarter = value.toInt();

                if (quarter < 1 || quarter > 4) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'فصل ${_digits(quarter.toString())}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xff66737e),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: items
            .map(
              (item) => BarChartGroupData(
            x: _quarterValue(item.quarter),
            barRods: [
              BarChartRodData(
                toY: _quarterAmount(item),
                width: 32,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(7),
                ),
              ),
            ],
          ),
        )
            .toList(),
      ),
    );
  }

  Widget _buildCategoryTable({
    required List<AccountantExpenseReportCategoryBreakdown>
    breakdown,
    required double total,
  }) {
    final items = breakdown
        .where(
          (item) => _categoryAmount(item) > 0,
    )
        .toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xffe7ebef),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'جزئیات هزینه به تفکیک سرفصل',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xff17212b),
            ),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: _NoDataText(
                text: 'برای این دوره هزینه‌ای ثبت نشده است.',
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 32,
                headingRowHeight: 46,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 64,
                columns: const [
                  DataColumn(label: Text('سرفصل')),
                  DataColumn(label: Text('مبلغ')),
                  DataColumn(label: Text('سهم از کل')),
                ],
                rows: items.map((item) {
                  final amount = _categoryAmount(item);

                  final share = total <= 0
                      ? 0
                      : ((amount / total) * 100).round();

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          _categoryName(item),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${_money(amount)} ریال',
                        ),
                      ),
                      DataCell(
                        Text(
                          '${_digits(share.toString())}٪',
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPayableInfo() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xffe7ebef),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xffedf7f1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: Color(0xff27834d),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حساب‌های پرداختنی',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff17212b),
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'حساب‌های پرداختنی به‌صورت مستقل از دوره‌های هزینه مدیریت می‌شوند.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xff7b8791),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AccountantExpenseReportFiscalYear? _resolveYear(
      AccountantExpenseReportsData data,
      ) {
    if (_selectedYearId != null) {
      for (final year in data.openYears) {
        if (year.id == _selectedYearId) {
          return year;
        }
      }
    }

    if (data.openYears.isEmpty) {
      return null;
    }

    return data.openYears.first;
  }

  AccountantExpenseReportFiscalPeriod? _resolvePeriod(
      List<AccountantExpenseReportFiscalPeriod> periods,
      ) {
    if (periods.isEmpty) {
      return null;
    }

    if (_selectedPeriodId != null) {
      for (final period in periods) {
        if (period.id == _selectedPeriodId) {
          return period;
        }
      }
    }

    return periods.first;
  }

  AccountantExpenseReportFiscalPeriod? _previousPeriod(
      AccountantExpenseReportsData data,
      AccountantExpenseReportFiscalPeriod current,
      ) {
    AccountantExpenseReportFiscalPeriod? previous;

    final currentYear = _intValue(current.year);
    final currentMonth = _monthValue(current.month);

    for (final period in data.periods) {
      final year = _intValue(period.year);
      final month = _monthValue(period.month);

      if (currentMonth > 1 &&
          year == currentYear &&
          month == currentMonth - 1) {
        previous = period;
      }

      if (currentMonth == 1 &&
          year == currentYear - 1 &&
          month == 12) {
        previous = period;
      }
    }

    return previous;
  }

  double _categoryAmount(
      AccountantExpenseReportCategoryBreakdown item,
      ) {
    return item.amount;
  }

  String _categoryName(
      AccountantExpenseReportCategoryBreakdown item,
      ) {
    return item.categoryName;
  }

  int _monthValue(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  int _quarterValue(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  int _intValue(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  double _monthlyAmount(
      AccountantExpenseReportMonthlyPoint item,
      ) {
    return item.amount;
  }

  double _quarterAmount(
      AccountantExpenseReportQuarterPoint item,
      ) {
    return item.amount;
  }

  String _money(double value) {
    return _digits(
      value.round().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (match) => '${match.group(1)},',
      ),
    );
  }

  String _compactMoney(double value) {
    if (value >= 1000000000) {
      return '${_digits(
        (value / 1000000000).toStringAsFixed(1),
      )}B';
    }

    if (value >= 1000000) {
      return '${_digits(
        (value / 1000000).toStringAsFixed(1),
      )}M';
    }

    if (value >= 1000) {
      return '${_digits(
        (value / 1000).toStringAsFixed(0),
      )}K';
    }

    return _digits(
      value.round().toString(),
    );
  }

  String _signed(double value) {
    final rounded = value.round();

    if (rounded > 0) {
      return '+${_digits(rounded.toString())}';
    }

    return _digits(
      rounded.toString(),
    );
  }

  int _share(
      double value,
      double total,
      ) {
    if (total == 0) {
      return 0;
    }

    return ((value / total) * 100).round();
  }

  String _digits(String value) {
    const english = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';

    var result = value;

    for (var i = 0; i < english.length; i++) {
      result = result.replaceAll(
        english[i],
        persian[i],
      );
    }

    return result;
  }
}

class _SummaryCardData {
  final String title;
  final String value;
  final String description;
  final IconData icon;

  const _SummaryCardData({
    required this.title,
    required this.value,
    required this.description,
    required this.icon,
  });
}

class _SummaryCard extends StatelessWidget {
  final _SummaryCardData data;

  const _SummaryCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xffe7ebef),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xffedf7f1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              data.icon,
              color: const Color(0xff27834d),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xff7b8791),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff17212b),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.description,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xff9aa4ac),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xffe7ebef),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xff17212b),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String title;
  final String value;

  const _LegendItem({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xff27834d),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xff66737e),
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xff17212b),
          ),
        ),
      ],
    );
  }
}

class _NoChartData extends StatelessWidget {
  const _NoChartData();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 42,
            color: Color(0xffb5bec5),
          ),
          SizedBox(height: 10),
          Text(
            'داده‌ای برای نمایش وجود ندارد',
            style: TextStyle(
              color: Color(0xff7b8791),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoDataText extends StatelessWidget {
  final String text;

  const _NoDataText({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xff7b8791),
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String title;
  final String description;

  const _EmptyView({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(50),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.analytics_outlined,
              size: 54,
              color: Color(0xffb4bec6),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xff26323b),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xff7b8791),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 52,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 14),
            const Text(
              'خطا در دریافت گزارش هزینه',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }
}