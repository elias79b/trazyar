import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

import '../../application/income_dashboard_provider.dart';

class IncomeDashboardPage extends ConsumerWidget {
  final String companyId;

  const IncomeDashboardPage({super.key, required this.companyId});

  // =====================================================
  // اعداد فارسی
  // =====================================================

  String _toPersianDigits(String value) {
    const english = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';

    var result = value;

    for (var i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], persian[i]);
    }

    return result;
  }

  // =====================================================
  // فرمت مبلغ
  // =====================================================

  String _formatAmount(num value, {bool compact = false}) {
    if (compact) {
      if (value.abs() >= 1000000000) {
        return '${_toPersianDigits((value / 1000000000).toStringAsFixed(1))} میلیارد';
      }

      if (value.abs() >= 1000000) {
        return '${_toPersianDigits((value / 1000000).toStringAsFixed(1))} میلیون';
      }

      if (value.abs() >= 1000) {
        return '${_toPersianDigits((value / 1000).toStringAsFixed(1))} هزار';
      }
    }

    final number = value.toDouble();

    final text =
        number.truncateToDouble() == number
            ? number.toStringAsFixed(0)
            : number.toStringAsFixed(2);

    final parts = text.split('.');

    final integerPart = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    final result = parts.length > 1 ? '$integerPart.${parts[1]}' : integerPart;

    return _toPersianDigits(result);
  }

  String _formatPercent(double value) {
    final fixed =
        value.abs() >= 100
            ? value.toStringAsFixed(0)
            : value.toStringAsFixed(1);

    return _toPersianDigits(fixed);
  }

  // =====================================================
  // کارت KPI
  // =====================================================

  Widget _kpiCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    double? growth,
  }) {
    final theme = Theme.of(context);

    final hasGrowth = growth != null;
    final positive = (growth ?? 0) >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 6),
            color: Colors.black.withValues(alpha: 0.04),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const Spacer(),
              if (hasGrowth)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color:
                        positive
                            ? Colors.green.withValues(alpha: 0.10)
                            : Colors.red.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        positive ? Icons.trending_up : Icons.trending_down,
                        size: 14,
                        color: positive ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${_formatPercent(growth!)}٪',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: positive ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // هدر نمودار
  // =====================================================

  Widget _chartHeader({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =====================================================
  // نمودار روند درآمد
  // =====================================================

  Widget _buildIncomeTrendChart(
    BuildContext context,
    IncomeDashboardData data,
  ) {
    final monthly = data.monthlyData;

    double maxValue = 0;

    for (final month in monthly) {
      maxValue = math.max(maxValue, month.amount);
    }

    if (maxValue <= 0) {
      maxValue = 100;
    }

    // کمی فضا بالای نمودار
    final chartMax = maxValue * 1.15;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _chartHeader(
            context: context,
            title: 'روند درآمد',
            subtitle: 'مبلغ واقعی درآمد در ۶ ماه شمسی اخیر',
            icon: Icons.show_chart,
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 330,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: chartMax,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: chartMax / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withValues(alpha: 0.12),
                      strokeWidth: 1,
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
                      reservedSize: 72,
                      interval: chartMax / 4,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatChartAmount(value),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        if (index < 0 || index >= monthly.length) {
                          return const SizedBox();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            monthly[index].label,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        final index = spot.x.toInt();

                        if (index < 0 || index >= monthly.length) {
                          return null;
                        }

                        final month = monthly[index];

                        return LineTooltipItem(
                          '${month.label}\n'
                          '${_formatAmount(month.amount)} ریال',
                          const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (int i = 0; i < monthly.length; i++)
                        FlSpot(i.toDouble(), monthly[i].amount),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.25,
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Theme.of(context).colorScheme.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.16),
                          Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.01),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatChartAmount(double value) {
    if (value.abs() >= 1000000000) {
      return _toPersianDigits('${(value / 1000000000).toStringAsFixed(1)}B');
    }

    if (value.abs() >= 1000000) {
      return _toPersianDigits('${(value / 1000000).toStringAsFixed(0)}M');
    }

    if (value.abs() >= 1000) {
      return _toPersianDigits('${(value / 1000).toStringAsFixed(0)}K');
    }

    return _toPersianDigits(value.toStringAsFixed(0));
  }

  // =====================================================
  // نمودار وضعیت
  // =====================================================

  Widget _buildStatusChart(BuildContext context, IncomeDashboardData data) {
    final sections = <PieChartSectionData>[];

    if (data.receivedIncome > 0) {
      sections.add(
        PieChartSectionData(
          value: data.receivedIncome,
          title: '${_formatPercent(data.receivedPercentage)}٪',
          radius: 62,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (data.pendingIncome > 0) {
      sections.add(
        PieChartSectionData(
          value: data.pendingIncome,
          title: '${_formatPercent(data.pendingPercentage)}٪',
          radius: 62,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (data.cancelledIncome > 0) {
      sections.add(
        PieChartSectionData(
          value: data.cancelledIncome,
          title: '${_formatPercent(data.cancelledPercentage)}٪',
          radius: 62,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chartHeader(
            context: context,
            title: 'وضعیت درآمدها',
            subtitle: 'توزیع درآمد بر اساس وضعیت',
            icon: Icons.pie_chart_outline,
          ),
          const SizedBox(height: 25),
          SizedBox(
            height: 220,
            child:
                sections.isEmpty
                    ? const Center(child: Text('داده‌ای برای نمایش وجود ندارد'))
                    : PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 55,
                        sectionsSpace: 3,
                      ),
                    ),
          ),
          const SizedBox(height: 12),
          _legendItem(
            context,
            'دریافت شده',
            data.receivedIncome,
            data.totalIncome,
          ),
          _legendItem(
            context,
            'در انتظار',
            data.pendingIncome,
            data.totalIncome,
          ),
          _legendItem(
            context,
            'لغو شده',
            data.cancelledIncome,
            data.totalIncome,
          ),
        ],
      ),
    );
  }

  Widget _legendItem(
    BuildContext context,
    String title,
    double amount,
    double total,
  ) {
    final percentage = total <= 0 ? 0 : amount / total;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _legendColor(title),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 12))),
          Text(
            '${_formatAmount(amount)} ریال',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Text(
            '${_formatPercent(percentage * 100)}٪',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Color _legendColor(String title) {
    if (title == 'دریافت شده') {
      return Colors.green;
    }

    if (title == 'در انتظار') {
      return Colors.orange;
    }

    return Colors.red;
  }

  // =====================================================
  // مقایسه ماه جاری و قبل
  // =====================================================

  Widget _buildMonthComparison(BuildContext context, IncomeDashboardData data) {
    final maxValue = math.max(
      data.currentMonthIncome,
      data.previousMonthIncome,
    );

    final safeMax = maxValue <= 0 ? 1 : maxValue;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chartHeader(
            context: context,
            title: 'مقایسه درآمد ماهانه',
            subtitle: 'ماه جاری در برابر ماه قبل',
            icon: Icons.bar_chart,
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 280,
            child: BarChart(
              BarChartData(
                maxY: safeMax * 1.25,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withValues(alpha: 0.12),
                      strokeWidth: 1,
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
                      reservedSize: 65,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatChartAmount(value),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) {
                          return Text(
                            data.previousMonthName,
                            style: const TextStyle(fontSize: 11),
                          );
                        }

                        if (value == 1) {
                          return Text(
                            data.currentMonthName,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }

                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: data.previousMonthIncome,
                        width: 45,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: data.currentMonthIncome,
                        width: 45,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ],
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label =
                          groupIndex == 0
                              ? data.previousMonthName
                              : data.currentMonthName;

                      return BarTooltipItem(
                        '$label\n'
                        '${_formatAmount(rod.toY)} ریال',
                        const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // هشدارهای مدیریتی
  // =====================================================

  Widget _buildWarnings(BuildContext context, IncomeDashboardData data) {
    final warnings = <Widget>[];

    if (data.pendingIncome > 0) {
      warnings.add(
        _warningItem(
          context,
          icon: Icons.access_time,
          title: 'درآمدهای در انتظار دریافت',
          description:
              '${_formatAmount(data.pendingIncome)} ریال هنوز دریافت نشده است.',
          iconColor: Colors.orange,
        ),
      );
    }

    if (data.monthGrowthPercentage < 0) {
      warnings.add(
        _warningItem(
          context,
          icon: Icons.trending_down,
          title: 'کاهش درآمد ماه جاری',
          description: 'درآمد ماه جاری نسبت به ماه قبل کاهش داشته است.',
          iconColor: Colors.red,
        ),
      );
    }

    if (data.cancelledIncome > 0) {
      warnings.add(
        _warningItem(
          context,
          icon: Icons.cancel_outlined,
          title: 'درآمدهای لغو شده',
          description:
              '${_formatAmount(data.cancelledIncome)} ریال درآمد لغو شده ثبت شده است.',
          iconColor: Colors.red,
        ),
      );
    }

    if (warnings.isEmpty) {
      warnings.add(
        _warningItem(
          context,
          icon: Icons.check_circle_outline,
          title: 'وضعیت مناسب',
          description: 'مورد مهمی برای پیگیری در اطلاعات درآمد ثبت نشده است.',
          iconColor: Colors.green,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chartHeader(
            context: context,
            title: 'هشدارهای مدیریتی',
            subtitle: 'موارد مهم قابل پیگیری',
            icon: Icons.notifications_active_outlined,
          ),
          const SizedBox(height: 15),
          ...warnings,
        ],
      ),
    );
  }

  Widget _warningItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Insights
  // =====================================================

  Widget _buildInsights(BuildContext context, IncomeDashboardData data) {
    final topCategory =
        data.categoryData.isNotEmpty ? data.categoryData.first : null;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chartHeader(
            context: context,
            title: 'خلاصه مدیریتی',
            subtitle: 'برداشت سریع از وضعیت درآمد',
            icon: Icons.insights_outlined,
          ),
          const SizedBox(height: 20),
          _insightRow(
            'کل درآمد ثبت شده',
            '${_formatAmount(data.totalIncome)} ریال',
          ),
          _insightRow(
            'تعداد درآمدها',
            _toPersianDigits(data.totalCount.toString()),
          ),
          _insightRow(
            'دریافت شده',
            '${_formatAmount(data.receivedIncome)} ریال',
          ),
          _insightRow(
            'در انتظار دریافت',
            '${_formatAmount(data.pendingIncome)} ریال',
          ),
          if (topCategory != null)
            _insightRow('بیشترین دسته‌بندی', topCategory.name),
        ],
      ),
    );
  }

  Widget _insightRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 12))),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Build
  // =====================================================

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(incomeDashboardProvider(companyId));

    return CompanyScaffold(
      companyId: companyId,
      title: 'داشبورد درآمد',
      currentRoute: '/consultant/companies/$companyId/income',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: dashboardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 55),
                  const SizedBox(height: 15),
                  const Text(
                    'خطا در دریافت اطلاعات داشبورد',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.invalidate(incomeDashboardProvider(companyId));
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('تلاش مجدد'),
                  ),
                ],
              ),
            );
          },
          data: (data) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(incomeDashboardProvider(companyId));

                await ref.read(incomeDashboardProvider(companyId).future);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =========================
                    // عنوان
                    // =========================
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'داشبورد درآمد',
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'تحلیل و بررسی عملکرد درآمد شرکت',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'به‌روزرسانی',
                          onPressed: () {
                            ref.invalidate(incomeDashboardProvider(companyId));
                          },
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // =========================
                    // KPI
                    // =========================
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;

                        final columns =
                            width >= 1200
                                ? 4
                                : width >= 750
                                ? 2
                                : 1;

                        final spacing = 14.0;

                        final itemWidth =
                            columns == 1
                                ? width
                                : (width - ((columns - 1) * spacing)) / columns;

                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: [
                            SizedBox(
                              width: itemWidth,
                              child: _kpiCard(
                                context: context,
                                title: 'کل درآمد',
                                value:
                                    '${_formatAmount(data.totalIncome)} ریال',
                                subtitle:
                                    '${_toPersianDigits(data.totalCount.toString())} ثبت درآمد',
                                icon: Icons.account_balance_wallet_outlined,
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _kpiCard(
                                context: context,
                                title: 'دریافت شده',
                                value:
                                    '${_formatAmount(data.receivedIncome)} ریال',
                                subtitle:
                                    '${_formatPercent(data.receivedPercentage)}٪ از کل درآمد',
                                icon: Icons.payments_outlined,
                                growth: data.receivedGrowthPercentage,
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _kpiCard(
                                context: context,
                                title: 'در انتظار دریافت',
                                value:
                                    '${_formatAmount(data.pendingIncome)} ریال',
                                subtitle:
                                    '${_formatPercent(data.pendingPercentage)}٪ از کل درآمد',
                                icon: Icons.access_time_outlined,
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _kpiCard(
                                context: context,
                                title: 'درآمد امروز',
                                value:
                                    '${_formatAmount(data.todayIncome)} ریال',
                                subtitle: 'ثبت شده در امروز',
                                icon: Icons.today_outlined,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    // =========================
                    // نمودار + هشدار
                    // =========================
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 1000;

                        if (wide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildIncomeTrendChart(context, data),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                flex: 2,
                                child: _buildWarnings(context, data),
                              ),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            _buildIncomeTrendChart(context, data),
                            const SizedBox(height: 18),
                            _buildWarnings(context, data),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    // =========================
                    // وضعیت + مقایسه
                    // =========================
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 1000;

                        if (wide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildStatusChart(context, data)),
                              const SizedBox(width: 18),
                              Expanded(
                                child: _buildMonthComparison(context, data),
                              ),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            _buildStatusChart(context, data),
                            const SizedBox(height: 18),
                            _buildMonthComparison(context, data),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    _buildInsights(context, data),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
