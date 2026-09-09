import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

import '../../application/expense_dashboard_provider.dart';

// ============================================================
// EXPENSE DASHBOARD
// ============================================================

class ExpenseDashboardPage extends ConsumerWidget {
  const ExpenseDashboardPage({super.key, required this.companyId});

  final String companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(expenseDashboardProvider(companyId));

    return CompanyScaffold(
      companyId: companyId,
      currentRoute: '/consultant/companies/$companyId/expenses',
      title: 'داشبورد هزینه‌ها',
      body: dashboardAsync.when(
        loading: () => const _LoadingView(),
        error: (error, stackTrace) {
          return _ErrorView(
            error: error,
            onRetry: () {
              ref.invalidate(expenseDashboardProvider(companyId));
            },
          );
        },
        data: (data) {
          return _ExpenseDashboardBody(data: data);
        },
      ),
    );
  }
}

// ============================================================
// COLORS
// ============================================================

class _ExpenseColors {
  static const background = Color(0xFFF6F8F7);

  static const card = Colors.white;

  static const text = Color(0xFF1F2937);

  static const muted = Color(0xFF64748B);

  static const border = Color(0xFFE2E8F0);

  static const primary = Color(0xFFE67E00);

  static const primaryDark = Color(0xFFC96500);

  static const operational = Color(0xFFE67E00);

  static const nonOperational = Color(0xFFDC2626);

  static const operationalLight = Color(0xFFFFF1DF);

  static const nonOperationalLight = Color(0xFFFFE8E8);

  static const categoryColors = <Color>[
    Color(0xFF1683E8),
    Color(0xFF2FA8E5),
    Color(0xFF43A047),
    Color(0xFF66BB6A),
    Color(0xFF8E44AD),
    Color(0xFFFF7043),
    Color(0xFFFFB300),
    Color(0xFF7E57C2),
    Color(0xFFAB47BC),
    Color(0xFF26A69A),
    Color(0xFF5C6BC0),
    Color(0xFFEF5350),
  ];
}

// ============================================================
// DASHBOARD BODY
// ============================================================

class _ExpenseDashboardBody extends StatelessWidget {
  const _ExpenseDashboardBody({required this.data});

  final ExpenseDashboardData data;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _ExpenseColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: _horizontalPadding(width),
              right: _horizontalPadding(width),
              top: 22,
              bottom: 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DashboardHeader(data: data),

                const SizedBox(height: 20),

                _KpiGrid(data: data),

                const SizedBox(height: 20),

                _ChartsLayout(data: data, width: width),
              ],
            ),
          );
        },
      ),
    );
  }

  double _horizontalPadding(double width) {
    if (width >= 1600) {
      return 32;
    }

    if (width >= 1200) {
      return 26;
    }

    if (width >= 800) {
      return 18;
    }

    return 12;
  }
}

// ============================================================
// HEADER
// ============================================================

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.data});

  final ExpenseDashboardData data;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final jalali = Jalali.now();

    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _ExpenseColors.primary,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: _ExpenseColors.primary.withOpacity(.18),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.receipt_long_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'داشبورد هزینه‌ها',
                style: TextStyle(
                  color: _ExpenseColors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                'گزارش وضعیت هزینه‌های شرکت در ${_monthName(jalali.month)} ${_persianDigits(jalali.year.toString())}',
                style: const TextStyle(
                  color: _ExpenseColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (width < 650) {
      return header;
    }

    return Row(
      children: [
        Expanded(child: header),

        const SizedBox(width: 12),

        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _ExpenseColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.receipt_outlined,
                color: _ExpenseColors.primary,
                size: 18,
              ),

              const SizedBox(width: 7),

              Text(
                '${_persianDigits(data.expenseCount.toString())} ثبت هزینه',
                style: const TextStyle(
                  color: _ExpenseColors.text,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// KPI GRID
// ============================================================

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.data});

  final ExpenseDashboardData data;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final cards = <Widget>[
      _KpiCard(
        title: 'کل هزینه‌های ماه جاری',
        value: '${_formatAmount(data.currentMonthExpense)} ریال',
        icon: Icons.payments_rounded,
        color: _ExpenseColors.primary,
        subtitle: _growthText(data.monthlyGrowth),
      ),

      _KpiCard(
        title: 'هزینه‌های عملیاتی',
        value: '${_formatAmount(data.operationalExpense)} ریال',
        icon: Icons.settings_rounded,
        color: _ExpenseColors.operational,
        subtitle: '${_formatPercent(data.operationalShare)} از کل هزینه',
      ),

      _KpiCard(
        title: 'هزینه‌های غیرعملیاتی',
        value: '${_formatAmount(data.nonOperationalExpense)} ریال',
        icon: Icons.trending_down_rounded,
        color: _ExpenseColors.nonOperational,
        subtitle: '${_formatPercent(data.nonOperationalShare)} از کل هزینه',
      ),

      _KpiCard(
        title: 'سهم هزینه‌های عملیاتی',
        value: _formatPercent(data.operationalShare),
        icon: Icons.pie_chart_rounded,
        color: _ExpenseColors.operational,
        subtitle: 'نسبت به کل هزینه',
      ),

      _KpiCard(
        title: 'سهم هزینه‌های غیرعملیاتی',
        value: _formatPercent(data.nonOperationalShare),
        icon: Icons.donut_large_rounded,
        color: _ExpenseColors.nonOperational,
        subtitle: 'نسبت به کل هزینه',
      ),
    ];

    // --------------------------------------------------------
    // DESKTOP
    // 5 COLUMNS
    // --------------------------------------------------------

    if (width >= 1250) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            Expanded(child: SizedBox(height: 116, child: cards[i])),

            if (i != cards.length - 1) const SizedBox(width: 10),
          ],
        ],
      );
    }

    // --------------------------------------------------------
    // LAPTOP / TABLET
    // 3 + 2
    // --------------------------------------------------------

    if (width >= 850) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: SizedBox(height: 116, child: cards[0])),

              const SizedBox(width: 10),

              Expanded(child: SizedBox(height: 116, child: cards[1])),

              const SizedBox(width: 10),

              Expanded(child: SizedBox(height: 116, child: cards[2])),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(child: SizedBox(height: 116, child: cards[3])),

              const SizedBox(width: 10),

              Expanded(child: SizedBox(height: 116, child: cards[4])),

              const Spacer(),
            ],
          ),
        ],
      );
    }

    // --------------------------------------------------------
    // MOBILE
    // 2 COLUMNS
    // --------------------------------------------------------

    if (width >= 500) {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children:
            cards.map((card) {
              return SizedBox(
                width: (width - 10) / 2,
                height: 110,
                child: card,
              );
            }).toList(),
      );
    }

    // --------------------------------------------------------
    // VERY SMALL MOBILE
    // --------------------------------------------------------

    return Column(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          SizedBox(width: double.infinity, height: 100, child: cards[i]),

          if (i != cards.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

// ============================================================
// KPI CARD
// ============================================================

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: _ExpenseColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ExpenseColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 22),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ExpenseColors.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 5),

                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: const TextStyle(
                      color: _ExpenseColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 5),

                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ExpenseColors.muted,
                          fontSize: 7.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CHARTS LAYOUT
// ============================================================

class _ChartsLayout extends StatelessWidget {
  const _ChartsLayout({required this.data, required this.width});

  final ExpenseDashboardData data;
  final double width;

  @override
  Widget build(BuildContext context) {
    // ========================================================
    // LARGE DESKTOP
    // ========================================================

    if (width >= 1350) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 4, child: _TypeCompositionChart(data: data)),

          const SizedBox(width: 14),

          Expanded(flex: 5, child: _CategoryBarChartCard(data: data)),

          const SizedBox(width: 14),

          Expanded(flex: 4, child: _CategoryPieChartCard(data: data)),
        ],
      );
    }

    // ========================================================
    // TABLET
    // ========================================================

    if (width >= 850) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _TypeCompositionChart(data: data)),

              const SizedBox(width: 14),

              Expanded(child: _CategoryPieChartCard(data: data)),
            ],
          ),

          const SizedBox(height: 14),

          _CategoryBarChartCard(data: data),
        ],
      );
    }

    // ========================================================
    // MOBILE
    // ========================================================

    return Column(
      children: [
        _TypeCompositionChart(data: data),

        const SizedBox(height: 14),

        _CategoryBarChartCard(data: data),

        const SizedBox(height: 14),

        _CategoryPieChartCard(data: data),
      ],
    );
  }
}

// ============================================================
// CHART CARD
// ============================================================

class _DashboardChartCard extends StatelessWidget {
  const _DashboardChartCard({
    required this.title,
    required this.icon,
    required this.height,
    required this.child,
  });

  final String title;
  final IconData icon;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _ExpenseColors.card,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _ExpenseColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: _ExpenseColors.primary.withOpacity(.09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _ExpenseColors.primary, size: 18),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ExpenseColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Expanded(child: child),
        ],
      ),
    );
  }
}

// ============================================================
// TYPE COMPOSITION
// ============================================================

class _TypeCompositionChart extends StatelessWidget {
  const _TypeCompositionChart({required this.data});

  final ExpenseDashboardData data;

  @override
  Widget build(BuildContext context) {
    return _DashboardChartCard(
      title: 'ترکیب هزینه‌های عملیاتی و غیرعملیاتی',
      icon: Icons.donut_large_rounded,
      height: 400,
      child:
          data.totalExpense <= 0
              ? const _NoDataView()
              : LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 340) {
                    return Column(
                      children: [
                        Expanded(flex: 6, child: _TypeDonut(data: data)),

                        const SizedBox(height: 8),

                        Expanded(flex: 4, child: _TypeLegend(data: data)),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(flex: 6, child: _TypeDonut(data: data)),

                      const SizedBox(width: 10),

                      Expanded(flex: 5, child: _TypeLegend(data: data)),
                    ],
                  );
                },
              ),
    );
  }
}

// ============================================================
// TYPE DONUT
// ============================================================

class _TypeDonut extends StatelessWidget {
  const _TypeDonut({required this.data});

  final ExpenseDashboardData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSize = math.min(constraints.maxWidth, constraints.maxHeight);

        final size = math.max(150.0, maxSize);

        final radius = math.max(42.0, size * .30);

        final centerRadius = math.max(34.0, size * .20);

        final operational = data.operationalExpense.toDouble();

        final nonOperational = data.nonOperationalExpense.toDouble();

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    centerSpaceRadius: centerRadius,
                    sectionsSpace: 3.0,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        value: operational,
                        color: _ExpenseColors.operational,
                        title: '',
                        radius: radius,
                      ),
                      PieChartSectionData(
                        value: nonOperational,
                        color: _ExpenseColors.nonOperational,
                        title: '',
                        radius: radius,
                      ),
                    ],
                  ),
                ),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _formatCompactAmount(data.totalExpense),
                        style: const TextStyle(
                          color: _ExpenseColors.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),

                    const SizedBox(height: 3),

                    const Text(
                      'میلیارد ریال',
                      style: TextStyle(
                        color: _ExpenseColors.muted,
                        fontSize: 8,
                      ),
                    ),

                    const Text(
                      'کل هزینه‌ها',
                      style: TextStyle(
                        color: _ExpenseColors.muted,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// TYPE LEGEND
// ============================================================

class _TypeLegend extends StatelessWidget {
  const _TypeLegend({required this.data});

  final ExpenseDashboardData data;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TypeLegendItem(
            color: _ExpenseColors.operational,
            title: 'هزینه‌های عملیاتی',
            amount: data.operationalExpense,
            percentage: data.operationalShare,
          ),

          const SizedBox(height: 10),

          _TypeLegendItem(
            color: _ExpenseColors.nonOperational,
            title: 'هزینه‌های غیرعملیاتی',
            amount: data.nonOperationalExpense,
            percentage: data.nonOperationalShare,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TYPE LEGEND ITEM
// ============================================================

class _TypeLegendItem extends StatelessWidget {
  const _TypeLegendItem({
    required this.color,
    required this.title,
    required this.amount,
    required this.percentage,
  });

  final Color color;
  final String title;
  final num amount;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(.055),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ExpenseColors.text,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${_formatAmount(amount)} ریال',
              style: const TextStyle(
                color: _ExpenseColors.text,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(height: 2),

          Text(
            '${_formatPercent(percentage)} از کل هزینه',
            style: const TextStyle(color: _ExpenseColors.muted, fontSize: 8),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CATEGORY BAR
// ============================================================

class _CategoryBarChartCard extends StatelessWidget {
  const _CategoryBarChartCard({required this.data});

  final ExpenseDashboardData data;

  @override
  Widget build(BuildContext context) {
    return _DashboardChartCard(
      title: 'هزینه‌ها به تفکیک سرفصل',
      icon: Icons.bar_chart_rounded,
      height: 400,
      child:
          data.categorySummaries.isEmpty
              ? const _NoDataView()
              : _CategoryBarChart(data: data),
    );
  }
}

// ============================================================
// CATEGORY BAR CHART
// ============================================================

class _CategoryBarChart extends StatelessWidget {
  const _CategoryBarChart({required this.data});

  final ExpenseDashboardData data;

  @override
  Widget build(BuildContext context) {
    final categories = data.categorySummaries;

    final values = categories.map((item) => item.amount.toDouble());

    final maxAmount = values.fold<double>(0.0, (previous, current) {
      return math.max(previous, current);
    });

    final interval = _calculateInterval(maxAmount);

    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 2, left: 2, bottom: 4),
      child: BarChart(
        BarChartData(
          minY: 0.0,

          maxY: maxAmount <= 0.0 ? 1.0 : maxAmount * 1.18,

          alignment: BarChartAlignment.spaceAround,

          groupsSpace: 7.0,

          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: const Color(0xFFE2E8F0),
                strokeWidth: 1.0,
                dashArray: [5, 5],
              );
            },
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
                interval: interval,
                getTitlesWidget: (value, meta) {
                  if (value < 0) {
                    return const SizedBox.shrink();
                  }

                  return Text(
                    _formatCompact(value),
                    style: const TextStyle(
                      color: _ExpenseColors.muted,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),

            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 62,
                getTitlesWidget: (value, meta) {
                  final index = value.round();

                  if (index < 0 || index >= categories.length) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: 62,
                      child: Text(
                        categories[index].name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ExpenseColors.muted,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          barGroups: List.generate(categories.length, (index) {
            final amount = categories[index].amount.toDouble();

            final color =
                _ExpenseColors.categoryColors[index %
                    _ExpenseColors.categoryColors.length];

            return BarChartGroupData(
              x: index,
              barsSpace: 0.0,
              barRods: [
                BarChartRodData(
                  toY: amount,
                  width: 17.0,
                  color: color,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  double _calculateInterval(double maxAmount) {
    if (maxAmount <= 0.0) {
      return 1.0;
    }

    final raw = maxAmount / 5.0;

    if (raw >= 1000000000.0) {
      return (raw / 1000000000.0).ceil().toDouble() * 1000000000.0;
    }

    if (raw >= 1000000.0) {
      return (raw / 1000000.0).ceil().toDouble() * 1000000.0;
    }

    if (raw >= 1000.0) {
      return (raw / 1000.0).ceil().toDouble() * 1000.0;
    }

    return math.max(1.0, raw.ceil().toDouble());
  }
}

// ============================================================
// CATEGORY PIE
// ============================================================

class _CategoryPieChartCard extends StatelessWidget {
  const _CategoryPieChartCard({required this.data});

  final ExpenseDashboardData data;

  @override
  Widget build(BuildContext context) {
    return _DashboardChartCard(
      title: 'سهم سرفصل‌ها از کل هزینه‌ها',
      icon: Icons.pie_chart_rounded,
      height: 400,
      child:
          data.categorySummaries.isEmpty
              ? const _NoDataView()
              : LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 340) {
                    return Column(
                      children: [
                        Expanded(flex: 6, child: _CategoryPie(data: data)),

                        const SizedBox(height: 8),

                        Expanded(flex: 4, child: _CategoryLegend(data: data)),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(flex: 6, child: _CategoryPie(data: data)),

                      const SizedBox(width: 8),

                      Expanded(flex: 5, child: _CategoryLegend(data: data)),
                    ],
                  );
                },
              ),
    );
  }
}

// ============================================================
// CATEGORY PIE
// ============================================================

class _CategoryPie extends StatelessWidget {
  const _CategoryPie({required this.data});

  final ExpenseDashboardData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSize = math.min(constraints.maxWidth, constraints.maxHeight);

        final size = math.max(150.0, maxSize);

        final radius = math.max(42.0, size * .29);

        final centerRadius = math.max(32.0, size * .19);

        final sections = List.generate(data.categorySummaries.length, (index) {
          final item = data.categorySummaries[index];

          final color =
              _ExpenseColors.categoryColors[index %
                  _ExpenseColors.categoryColors.length];

          return PieChartSectionData(
            value: item.amount.toDouble(),
            color: color,
            title: '',
            radius: radius,
          );
        });

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    centerSpaceRadius: centerRadius,
                    sectionsSpace: 2.0,
                    startDegreeOffset: -90,
                    sections: sections,
                  ),
                ),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _formatCompactAmount(data.totalExpense),
                        style: const TextStyle(
                          color: _ExpenseColors.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),

                    const SizedBox(height: 3),

                    const Text(
                      'میلیارد ریال',
                      style: TextStyle(
                        color: _ExpenseColors.muted,
                        fontSize: 8,
                      ),
                    ),

                    const Text(
                      'کل هزینه‌ها',
                      style: TextStyle(
                        color: _ExpenseColors.muted,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// CATEGORY LEGEND
// ============================================================

class _CategoryLegend extends StatelessWidget {
  const _CategoryLegend({required this.data});

  final ExpenseDashboardData data;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: data.categorySummaries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final item = data.categorySummaries[index];

        final color =
            _ExpenseColors.categoryColors[index %
                _ExpenseColors.categoryColors.length];

        return Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),

            const SizedBox(width: 6),

            Expanded(
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ExpenseColors.text,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(width: 5),

            Text(
              _formatPercent(item.percentage),
              style: const TextStyle(
                color: _ExpenseColors.text,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// NO DATA
// ============================================================

class _NoDataView extends StatelessWidget {
  const _NoDataView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: _ExpenseColors.primary.withOpacity(.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              color: _ExpenseColors.primary,
              size: 27,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'داده‌ای برای نمایش وجود ندارد',
            style: TextStyle(
              color: _ExpenseColors.text,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// LOADING
// ============================================================

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: _ExpenseColors.primary),
    );
  }
}

// ============================================================
// ERROR
// ============================================================

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _ExpenseColors.nonOperational.withOpacity(.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: _ExpenseColors.nonOperational,
                size: 32,
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              'خطا در دریافت داشبورد هزینه‌ها',
              style: TextStyle(
                color: _ExpenseColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: _ExpenseColors.muted, fontSize: 10),
            ),

            const SizedBox(height: 16),

            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: _ExpenseColors.primary,
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HELPERS
// ============================================================

String _growthText(num? growth) {
  if (growth == null) {
    return 'نسبت به ماه قبل';
  }

  final value = growth.toDouble();

  if (value == 0.0) {
    return 'بدون تغییر نسبت به ماه قبل';
  }

  final direction = value > 0 ? 'افزایش' : 'کاهش';

  return '$direction ${_formatPercent(value.abs())} نسبت به ماه قبل';
}

// ============================================================

String _monthName(int month) {
  const months = [
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
    return '';
  }

  return months[month - 1];
}

// ============================================================

String _formatAmount(num amount) {
  final raw = amount.round().toString();

  final buffer = StringBuffer();

  for (int i = 0; i < raw.length; i++) {
    buffer.write(raw[i]);

    final remaining = raw.length - i - 1;

    if (remaining > 0 && remaining % 3 == 0) {
      buffer.write(',');
    }
  }

  return _persianDigits(buffer.toString());
}

// ============================================================

String _formatCompactAmount(num amount) {
  final value = amount.toDouble();

  if (value.abs() >= 1000000000.0) {
    return _persianDigits((value / 1000000000.0).toStringAsFixed(1));
  }

  if (value.abs() >= 1000000.0) {
    return _persianDigits((value / 1000000.0).toStringAsFixed(1));
  }

  if (value.abs() >= 1000.0) {
    return _persianDigits((value / 1000.0).toStringAsFixed(1));
  }

  return _formatAmount(value);
}

// ============================================================

String _formatCompact(double value) {
  final number = value.toDouble();

  if (number.abs() >= 1000000000.0) {
    return _persianDigits('${(number / 1000000000.0).toStringAsFixed(0)}B');
  }

  if (number.abs() >= 1000000.0) {
    return _persianDigits('${(number / 1000000.0).toStringAsFixed(0)}M');
  }

  if (number.abs() >= 1000.0) {
    return _persianDigits('${(number / 1000.0).toStringAsFixed(0)}K');
  }

  return _persianDigits(number.round().toString());
}

// ============================================================

String _formatPercent(num value) {
  return '${_persianDigits(value.toDouble().toStringAsFixed(1))}%';
}

// ============================================================

String _persianDigits(String value) {
  const english = '0123456789';

  const persian = '۰۱۲۳۴۵۶۷۸۹';

  return value.split('').map((char) {
    final index = english.indexOf(char);

    if (index < 0) {
      return char;
    }

    return persian[index];
  }).join();
}
