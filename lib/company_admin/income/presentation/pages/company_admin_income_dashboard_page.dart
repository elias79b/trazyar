import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarazyar/company_admin/dashboard/presentation/widgets/company_admin_scaffold.dart';
import 'package:tarazyar/company_admin/income/application/company_admin_income_dashboard_provider.dart';

class CompanyAdminIncomeDashboardPage extends ConsumerWidget {
  const CompanyAdminIncomeDashboardPage({super.key});

  static const Color _primary = Color(0xFF168052);
  static const Color _background = Color(0xFFF5F8F5);
  static const Color _text = Color(0xFF24312B);
  static const Color _muted = Color(0xFF78857D);
  static const Color _border = Color(0xFFE5EBE6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(companyAdminIncomeDashboardProvider);

    return CompanyAdminScaffold(
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: dashboardAsync.when(
            loading:
                () => const Center(
                  child: CircularProgressIndicator(color: _primary),
                ),
            error: (error, stackTrace) => _buildError(ref, error),
            data:
                (data) => RefreshIndicator(
                  color: _primary,
                  onRefresh: () async {
                    await ref.refresh(
                      companyAdminIncomeDashboardProvider.future,
                    );
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final horizontalPadding =
                          width >= 1200
                              ? 28.0
                              : width >= 700
                              ? 20.0
                              : 14.0;

                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          24,
                          horizontalPadding,
                          32,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1500),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildPageHeader(data),
                                const SizedBox(height: 26),
                                _buildMetricGrid(context: context, data: data),
                                const SizedBox(height: 24),
                                _buildMonthlyChart(data),
                                const SizedBox(height: 20),
                                LayoutBuilder(
                                  builder: (context, chartConstraints) {
                                    if (chartConstraints.maxWidth < 760) {
                                      return Column(
                                        children: [
                                          _buildCategoryChart(data),
                                          const SizedBox(height: 20),
                                          _buildReceivablesChart(data),
                                        ],
                                      );
                                    }

                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _buildCategoryChart(data),
                                        ),
                                        const SizedBox(width: 20),
                                        Expanded(
                                          child: _buildReceivablesChart(data),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader(dynamic data) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'داشبورد درآمد',
              style: TextStyle(
                fontSize: 14,
                color: _muted,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'نمای کلی درآمد',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: _text,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'گزارش وضعیت درآمدها و مطالبات شرکت',
              style: TextStyle(fontSize: 13, color: _muted),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                size: 19,
                color: _primary,
              ),
              const SizedBox(width: 9),
              Text(
                'سال مالی ${data.selectedYear ?? '—'}',
                style: const TextStyle(
                  color: _text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricGrid({
    required BuildContext context,
    required dynamic data,
  }) {
    final metrics = <_IncomeMetric>[
      _IncomeMetric(
        title: 'کل درآمد ثبت‌شده',
        value: _money(data.totalIncome),
        subtitle: 'مجموع درآمدهای ثبت‌شده',
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFF168052),
        background: const Color(0xFFE8F5ED),
      ),
      _IncomeMetric(
        title: 'رشد نسبت به سال قبل',
        value: '${data.growthPercent.toStringAsFixed(1)}٪',
        subtitle: 'مقایسه با سال مالی قبل',
        icon: Icons.trending_up_rounded,
        color:
            data.growthPercent >= 0
                ? const Color(0xFF168052)
                : const Color(0xFFC43D3D),
        background:
            data.growthPercent >= 0
                ? const Color(0xFFE8F5ED)
                : const Color(0xFFFCECEC),
      ),
      _IncomeMetric(
        title: 'درآمد عملیاتی',
        value: _money(data.operationalIncome),
        subtitle: 'درآمد حاصل از فعالیت‌های اصلی',
        icon: Icons.business_center_outlined,
        color: const Color(0xFF168E9B),
        background: const Color(0xFFE6F5F6),
      ),
      _IncomeMetric(
        title: 'درآمد غیرعملیاتی',
        value: _money(data.nonOperationalIncome),
        subtitle: 'سایر درآمدهای ثبت‌شده',
        icon: Icons.account_balance_outlined,
        color: const Color(0xFF7651C9),
        background: const Color(0xFFF0EBFC),
      ),
      _IncomeMetric(
        title: 'اسناد دریافتی',
        value: _money(data.receivedDocuments),
        subtitle: 'مبلغ اسناد دریافت‌شده',
        icon: Icons.description_outlined,
        color: const Color(0xFF2878D0),
        background: const Color(0xFFE9F2FD),
      ),
      _IncomeMetric(
        title: 'مطالبات باقی‌مانده',
        value: _money(data.outstandingReceivables),
        subtitle: 'مبالغ وصول‌نشده',
        icon: Icons.pending_actions_rounded,
        color: const Color(0xFFC47721),
        background: const Color(0xFFFFF3E3),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns =
            width >= 1100
                ? 3
                : width >= 650
                ? 2
                : 1;

        final aspectRatio =
            columns == 3
                ? 2.05
                : columns == 2
                ? 2.25
                : 2.8;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            return _MetricCard(metric: metrics[index]);
          },
        );
      },
    );
  }

  Widget _buildMonthlyChart(dynamic data) {
    final points = data.monthlyTrend;

    return _ChartCard(
      title: 'روند درآمد ماهانه',
      subtitle: 'مقایسه درآمد ثبت‌شده در ماه‌های سال مالی',
      icon: Icons.show_chart_rounded,
      child:
          points.isEmpty
              ? const _EmptyChart()
              : SizedBox(
                height: 280,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: _niceInterval(
                        points.map((e) => e.amount.toDouble()).toList(),
                      ),
                      getDrawingHorizontalLine:
                          (value) => FlLine(
                            color: _border,
                            strokeWidth: 1,
                            dashArray: [4, 4],
                          ),
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
                          reservedSize: 52,
                          getTitlesWidget: (value, meta) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                _compactMoney(value),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: _muted,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 34,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();

                            if (index < 0 || index >= points.length) {
                              return const SizedBox.shrink();
                            }

                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 10,
                              child: Text(
                                points[index].label.toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: _muted,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (spots) {
                          return spots.map((spot) {
                            final index = spot.x.toInt();
                            final label =
                                index >= 0 && index < points.length
                                    ? points[index].label.toString()
                                    : '';

                            return LineTooltipItem(
                              '$label\n${_money(spot.y)}',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < points.length; i++)
                            FlSpot(i.toDouble(), points[i].amount.toDouble()),
                        ],
                        isCurved: true,
                        curveSmoothness: 0.25,
                        color: _primary,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: points.length <= 12,
                          getDotPainter: (spot, percent, bar, index) {
                            return FlDotCirclePainter(
                              radius: 3.5,
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor: _primary,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: _primary.withOpacity(0.09),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildCategoryChart(dynamic data) {
    final categories = data.categoryBreakdown;

    final double total = categories.fold<double>(
      0.0,
          (double sum, IncomeCategoryPoint item) {
        return sum + item.amount.toDouble();
      },
    );

    const colors = [
      Color(0xFF168052),
      Color(0xFF2878D0),
      Color(0xFF7651C9),
      Color(0xFFF0A33A),
      Color(0xFF168E9B),
      Color(0xFFD45F77),
      Color(0xFF82918A),
    ];

    return _ChartCard(
      title: 'ترکیب درآمد',
      subtitle: 'سهم هر دسته از کل درآمد',
      icon: Icons.donut_large_rounded,
      child:
          categories.isEmpty || total <= 0
              ? const _EmptyChart()
              : Column(
                children: [
                  SizedBox(
                    height: 210,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 48,
                              sections: [
                                for (var i = 0; i < categories.length; i++)
                                  PieChartSectionData(
                                    value: categories[i].amount.toDouble(),
                                    color: colors[i % colors.length],
                                    radius: 27,
                                    title: '',
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'کل درآمد',
                                  style: TextStyle(fontSize: 12, color: _muted),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _compactMoney(total),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: _text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(categories.length, (index) {
                    final category = categories[index];
                    final percentage =
                        total == 0
                            ? 0.0
                            : category.amount.toDouble() / total * 100;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: colors[index % colors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              category.name.toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _text,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${percentage.toStringAsFixed(1)}٪',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _text,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
    );
  }

  Widget _buildReceivablesChart(dynamic data) {
    final points = data.receivablesTrend;

    return _ChartCard(
      title: 'وضعیت مطالبات',
      subtitle: 'مقایسه مبلغ مطالبات با اسناد دریافتی',
      icon: Icons.bar_chart_rounded,
      child:
          points.isEmpty
              ? const _EmptyChart()
              : SizedBox(
                height: 280,
                child: BarChart(
                  BarChartData(
                    maxY: _barMaxY(points),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final label =
                              groupIndex < points.length
                                  ? points[groupIndex].label.toString()
                                  : '';

                          final title =
                              rodIndex == 0 ? 'مطالبات' : 'اسناد دریافتی';

                          return BarTooltipItem(
                            '$label\n$title: ${_money(rod.toY)}',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine:
                          (value) => FlLine(
                            color: _border,
                            strokeWidth: 1,
                            dashArray: [4, 4],
                          ),
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
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                _compactMoney(value),
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: _muted,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();

                            if (index < 0 || index >= points.length) {
                              return const SizedBox.shrink();
                            }

                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 8,
                              child: Text(
                                points[index].label.toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: _muted,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      for (var i = 0; i < points.length; i++)
                        BarChartGroupData(
                          x: i,
                          barsSpace: 5,
                          barRods: [
                            BarChartRodData(
                              toY: points[i].amount.toDouble(),
                              color: const Color(0xFF168052),
                              width: points.length > 8 ? 7 : 12,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                            BarChartRodData(
                              toY: points[i].secondaryAmount.toDouble(),
                              color: const Color(0xFF76B7E5),
                              width: points.length > 8 ? 7 : 12,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
      footer: const Wrap(
        spacing: 18,
        runSpacing: 8,
        children: [
          _LegendItem(color: Color(0xFF168052), label: 'مطالبات'),
          _LegendItem(color: Color(0xFF76B7E5), label: 'اسناد دریافتی'),
        ],
      ),
    );
  }

  Widget _buildError(WidgetRef ref, Object error) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 44,
                  color: Color(0xFFC43D3D),
                ),
                const SizedBox(height: 16),
                const Text(
                  'دریافت اطلاعات درآمد ناموفق بود',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    ref.invalidate(companyAdminIncomeDashboardProvider);
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('تلاش مجدد'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _money(num value) {
    final rounded = value.round();
    final raw = rounded.abs().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < raw.length; i++) {
      buffer.write(raw[i]);

      final remaining = raw.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write(',');
      }
    }

    return '${rounded < 0 ? '-' : ''}$buffer';
  }

  static String _compactMoney(num value) {
    final number = value.toDouble().abs();

    if (number >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    }

    if (number >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (number >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }

    return value.toStringAsFixed(0);
  }


  static double _niceInterval(List<dynamic> values) {
    if (values.isEmpty) return 1;

    final maxValue = values.fold<double>(
      0,
          (maximum, value) => math.max(
        maximum,
        (value as num).toDouble(),
      ),
    );

    if (maxValue <= 0) return 1;

    return maxValue / 4;
  }


  static double _barMaxY(dynamic points) {
    double maximum = 0;

    for (final point in points) {
      maximum = math.max(maximum, point.amount.toDouble());
      maximum = math.max(maximum, point.secondaryAmount.toDouble());
    }

    return maximum <= 0 ? 10 : maximum * 1.2;
  }
}

class _IncomeMetric {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color background;

  const _IncomeMetric({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.background,
  });
}

class _MetricCard extends StatelessWidget {
  final _IncomeMetric metric;

  const _MetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EBE6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: metric.background,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(metric.icon, color: metric.color, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  metric.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4D5A52),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: metric.color,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            metric.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Color(0xFF87938B)),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Widget? footer;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EBE6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5ED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF168052), size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF24312B),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF87938B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
          if (footer != null) ...[const SizedBox(height: 18), footer!],
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_chart_outlined_rounded,
              size: 42,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'داده‌ای برای نمایش وجود ندارد',
              style: TextStyle(fontSize: 12, color: Color(0xFF87938B)),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF657269)),
        ),
      ],
    );
  }
}
