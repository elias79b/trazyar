import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/consultant/dashboard/analytics/application/financial_analysis_provider.dart';
import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';



class FinancialAnalysisPage extends ConsumerWidget {
  final String companyId;

  const FinancialAnalysisPage({super.key, required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = financialAnalysisProvider(companyId);

    final state = ref.watch(provider);

    return CompanyScaffold(
      companyId: companyId,
      currentRoute: '/consultant/companies/$companyId/financial-analysis',
      title: 'تحلیل مالی',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) {
            return _ErrorView(
              error: error,
              onRetry: () {
                ref.invalidate(provider);
              },
            );
          },
          data: (data) {
            return _FinancialAnalysisContent(
              companyId: companyId,
              data: data,
              onRefresh: () {
                ref.invalidate(provider);
              },
            );
          },
        ),
      ),
    );
  }
}

class _FinancialAnalysisContent extends StatelessWidget {
  final String companyId;
  final FinancialAnalysisData data;
  final VoidCallback onRefresh;

  const _FinancialAnalysisContent({
    required this.companyId,
    required this.data,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final horizontalPadding =
            width >= 1200
                ? 28.0
                : width >= 700
                ? 22.0
                : 14.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            20,
            horizontalPadding,
            40,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(onRefresh: onRefresh),

              const SizedBox(height: 18),

              _MainKpis(data: data),

              const SizedBox(height: 18),

              _LiquidityCard(data: data),

              const SizedBox(height: 18),

              _ResponsiveCharts(data: data),

              const SizedBox(height: 18),

              _ResponsiveBottomSection(data: data),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}

/* -------------------------------------------------------------------------- */
/* HEADER                                                                     */
/* -------------------------------------------------------------------------- */

class _Header extends StatelessWidget {
  final VoidCallback onRefresh;

  const _Header({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF1B4332).withOpacity(.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: Color(0xFF1B4332),
              size: 26,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تحلیل مالی',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'نمای کلی درآمد، هزینه، سود و نقدینگی شرکت',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          IconButton(
            onPressed: onRefresh,
            tooltip: 'به‌روزرسانی',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* KPI                                                                        */
/* -------------------------------------------------------------------------- */

class _MainKpis extends StatelessWidget {
  final FinancialAnalysisData data;

  const _MainKpis({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final int count;

        if (width >= 1150) {
          count = 4;
        } else if (width >= 700) {
          count = 2;
        } else {
          count = 1;
        }

        final gap = 12.0;

        final cardWidth =
            count == 1 ? width : (width - ((count - 1) * gap)) / count;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: cardWidth,
              child: _KpiCard(
                title: 'درآمد کل',
                value: _money(data.totalIncome),
                icon: Icons.trending_up_rounded,
                iconColor: const Color(0xFF16A34A),
              ),
            ),

            SizedBox(
              width: cardWidth,
              child: _KpiCard(
                title: 'هزینه کل',
                value: _money(data.totalExpense),
                icon: Icons.trending_down_rounded,
                iconColor: const Color(0xFFEA580C),
              ),
            ),

            SizedBox(
              width: cardWidth,
              child: _KpiCard(
                title: data.profit >= 0 ? 'سود خالص' : 'زیان خالص',
                value: _money(data.profit.abs()),
                icon:
                    data.profit >= 0
                        ? Icons.account_balance_wallet_rounded
                        : Icons.warning_amber_rounded,
                iconColor:
                    data.profit >= 0
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFDC2626),
              ),
            ),

            SizedBox(
              width: cardWidth,
              child: _KpiCard(
                title: 'حاشیه سود',
                value: '${_number(data.profitMargin)}٪',
                icon: Icons.percent_rounded,
                iconColor: const Color(0xFF7C3AED),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
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

/* -------------------------------------------------------------------------- */
/* LIQUIDITY                                                                  */
/* -------------------------------------------------------------------------- */

class _LiquidityCard extends StatelessWidget {
  final FinancialAnalysisData data;

  const _LiquidityCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      title: 'وضعیت نقدینگی',
      subtitle: 'موجودی فعلی بانک، صندوق و تنخواه',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          final int count;

          if (width >= 1000) {
            count = 4;
          } else if (width >= 620) {
            count = 2;
          } else {
            count = 1;
          }

          const gap = 10.0;

          final itemWidth =
              count == 1 ? width : (width - ((count - 1) * gap)) / count;

          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              SizedBox(
                width: itemWidth,
                child: _LiquidityItem(
                  title: 'بانک',
                  value: data.liquidityPart(data.bankBalance),
                  icon: Icons.account_balance_rounded,
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _LiquidityItem(
                  title: 'صندوق',
                  value: data.liquidityPart(data.cashBalance),
                  icon: Icons.point_of_sale_rounded,
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _LiquidityItem(
                  title: 'تنخواه',
                  value: data.liquidityPart(data.pettyCashBalance),
                  icon: Icons.payments_rounded,
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _LiquidityItem(
                  title: 'نقدینگی کل',
                  value: data.liquidityPart(data.liquidity),
                  icon: Icons.account_balance_wallet_rounded,
                  emphasized: true,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

extension _LiquidityExtension on FinancialAnalysisData {
  String liquidityPart(double value) {
    return _money(value);
  }

  double get bankBalance {
    return 0;
  }

  double get cashBalance {
    return 0;
  }

  double get pettyCashBalance {
    return 0;
  }
}

class _LiquidityItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool emphasized;

  const _LiquidityItem({
    required this.title,
    required this.value,
    required this.icon,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:
            emphasized
                ? const Color(0xFF1B4332).withOpacity(.07)
                : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: const Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
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

/* -------------------------------------------------------------------------- */
/* CHARTS                                                                     */
/* -------------------------------------------------------------------------- */

class _ResponsiveCharts extends StatelessWidget {
  final FinancialAnalysisData data;

  const _ResponsiveCharts({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1000) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _TrendCard(data: data)),
              const SizedBox(width: 16),
              Expanded(child: _StructureCard(data: data)),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TrendCard(data: data),
            const SizedBox(height: 16),
            _StructureCard(data: data),
          ],
        );
      },
    );
  }
}

/* -------------------------------------------------------------------------- */
/* TREND                                                                      */
/* -------------------------------------------------------------------------- */

class _TrendCard extends StatelessWidget {
  final FinancialAnalysisData data;

  const _TrendCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      title: 'روند مالی',
      subtitle: 'مقایسه درآمد، هزینه و سود شش ماه اخیر',
      child: SizedBox(
        height: 330,
        child: data.monthlyData.isEmpty ? const _EmptyChart() : _buildChart(),
      ),
    );
  }

  Widget _buildChart() {
    final maxValue = _calculateMax(data);

    final minValue = _calculateMin(data);

    return LineChart(
      LineChartData(
        minY: minValue,
        maxY: maxValue,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _safeInterval(maxValue, minValue),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(y: 0, strokeWidth: 1, dashArray: [5, 5]),
          ],
        ),
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
              reservedSize: 32,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();

                if (index < 0 || index >= data.monthlyData.length) {
                  return const SizedBox();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    data.monthlyData[index].label,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF64748B),
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 58,
              interval: _safeInterval(maxValue, minValue),
              getTitlesWidget: (value, meta) {
                return Text(
                  _compactMoney(value),
                  style: const TextStyle(fontSize: 8, color: Color(0xFF64748B)),
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
                String title;

                if (spot.barIndex == 0) {
                  title = 'درآمد';
                } else if (spot.barIndex == 1) {
                  title = 'هزینه';
                } else {
                  title = 'سود';
                }

                return LineTooltipItem(
                  '$title\n${_money(spot.y)}',
                  const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          _line(data.monthlyData.map((e) => e.income).toList()),
          _line(data.monthlyData.map((e) => e.expense).toList()),
          _line(data.monthlyData.map((e) => e.profit).toList()),
        ],
      ),
    );
  }

  LineChartBarData _line(List<double> values) {
    return LineChartBarData(
      spots: [
        for (int i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
      ],
      isCurved: true,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* STRUCTURE                                                                  */
/* -------------------------------------------------------------------------- */

class _StructureCard extends StatelessWidget {
  final FinancialAnalysisData data;

  const _StructureCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.totalIncome + data.totalExpense;

    if (total <= 0) {
      return _CardShell(
        title: 'ساختار درآمد و هزینه',
        subtitle: 'مقایسه سهم درآمد و هزینه',
        child: const SizedBox(height: 260, child: _EmptyChart()),
      );
    }

    return _CardShell(
      title: 'ساختار درآمد و هزینه',
      subtitle: 'مقایسه سهم درآمد و هزینه',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 215,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 55,
                sectionsSpace: 3,
                sections: [
                  PieChartSectionData(
                    value: data.totalIncome,
                    title:
                        '${((data.totalIncome / total) * 100).toStringAsFixed(0)}٪',
                    radius: 62,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  PieChartSectionData(
                    value: data.totalExpense,
                    title:
                        '${((data.totalExpense / total) * 100).toStringAsFixed(0)}٪',
                    radius: 62,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 24,
            runSpacing: 10,
            children: [
              _StructureLegend(
                title: 'درآمد',
                value: data.totalIncome,
                icon: Icons.circle,
              ),
              _StructureLegend(
                title: 'هزینه',
                value: data.totalExpense,
                icon: Icons.circle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StructureLegend extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;

  const _StructureLegend({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 9, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
        ),
        const SizedBox(width: 5),
        Text(
          _money(value),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/* BOTTOM                                                                     */
/* -------------------------------------------------------------------------- */

class _ResponsiveBottomSection extends StatelessWidget {
  final FinancialAnalysisData data;

  const _ResponsiveBottomSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1000) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _ExpenseCategoriesCard(data: data)),
              const SizedBox(width: 16),
              Expanded(child: _AlertsCard(data: data)),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ExpenseCategoriesCard(data: data),
            const SizedBox(height: 16),
            _AlertsCard(data: data),
          ],
        );
      },
    );
  }
}

/* -------------------------------------------------------------------------- */
/* EXPENSE CATEGORIES                                                         */
/* -------------------------------------------------------------------------- */

class _ExpenseCategoriesCard extends StatelessWidget {
  final FinancialAnalysisData data;

  const _ExpenseCategoriesCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final categories = data.expenseCategories.take(6).toList();

    if (categories.isEmpty) {
      return _CardShell(
        title: 'دسته‌های اصلی هزینه',
        subtitle: 'بیشترین هزینه‌ها بر اساس دسته‌بندی',
        child: const SizedBox(height: 180, child: _EmptyChart()),
      );
    }

    final maxValue = _expenseMaxValue(categories);

    return _CardShell(
      title: 'دسته‌های اصلی هزینه',
      subtitle: 'شش دسته با بیشترین مبلغ',
      child: SizedBox(
        height: 300,
        child: BarChart(
          BarChartData(
            minY: 0,
            maxY: maxValue,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxValue / 4,
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
                  reservedSize: 55,
                  interval: maxValue / 4,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      _compactMoney(value),
                      style: const TextStyle(
                        fontSize: 8,
                        color: Color(0xFF64748B),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 52,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();

                    if (index < 0 || index >= categories.length) {
                      return const SizedBox();
                    }

                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: SizedBox(
                        width: 70,
                        child: Text(
                          categories[index].name,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 8,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (int i = 0; i < categories.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: categories[i].amount,
                      width: 25,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* ALERTS                                                                     */
/* -------------------------------------------------------------------------- */

class _AlertsCard extends StatelessWidget {
  final FinancialAnalysisData data;

  const _AlertsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final items = <_AlertItem>[];

    if (data.profit < 0) {
      items.add(
        const _AlertItem(
          icon: Icons.warning_amber_rounded,
          title: 'شرکت در وضعیت زیان‌ده است',
          subtitle: 'هزینه‌ها از درآمد بیشتر شده‌اند.',
        ),
      );
    }

    if (data.pendingIncome > 0) {
      items.add(
        _AlertItem(
          icon: Icons.schedule_rounded,
          title: 'درآمد معوق وجود دارد',
          subtitle: '${_money(data.pendingIncome)} درآمد هنوز دریافت نشده است.',
        ),
      );
    }

    if (data.loans > 0) {
      items.add(
        _AlertItem(
          icon: Icons.account_balance_rounded,
          title: 'مانده تسهیلات وجود دارد',
          subtitle: '${_money(data.loans)} مانده تسهیلات شرکت است.',
        ),
      );
    }

    if (data.receivedChecks > 0) {
      items.add(
        _AlertItem(
          icon: Icons.receipt_long_rounded,
          title: 'چک دریافتی باز وجود دارد',
          subtitle: '${_money(data.receivedChecks)} چک دریافتی تسویه نشده است.',
        ),
      );
    }

    if (data.paidChecks > 0) {
      items.add(
        _AlertItem(
          icon: Icons.payments_rounded,
          title: 'چک پرداختی باز وجود دارد',
          subtitle: '${_money(data.paidChecks)} چک پرداختی تسویه نشده است.',
        ),
      );
    }

    if (items.isEmpty) {
      items.add(
        const _AlertItem(
          icon: Icons.check_circle_rounded,
          title: 'هشدار مهمی وجود ندارد',
          subtitle: 'در حال حاضر مورد مهمی برای پیگیری ثبت نشده است.',
        ),
      );
    }

    return _CardShell(
      title: 'هشدارهای مالی',
      subtitle: 'مواردی که نیاز به توجه دارند',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < items.length; i++)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                items[i],
                if (i != items.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _AlertItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF97316).withOpacity(.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFFF97316), size: 21),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.5,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/* CARD SHELL                                                                 */
/* -------------------------------------------------------------------------- */

class _CardShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _CardShell({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 17),
          child,
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* EMPTY                                                                      */
/* -------------------------------------------------------------------------- */

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.bar_chart_rounded, size: 38, color: Color(0xFFCBD5E1)),
          SizedBox(height: 8),
          Text(
            'اطلاعاتی برای نمایش وجود ندارد',
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* ERROR                                                                      */
/* -------------------------------------------------------------------------- */

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(height: 12),
            const Text(
              'خطا در دریافت تحلیل مالی',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* HELPERS                                                                    */
/* -------------------------------------------------------------------------- */

double _calculateMax(FinancialAnalysisData data) {
  double maxValue = 0;

  for (final item in data.monthlyData) {
    if (item.income > maxValue) {
      maxValue = item.income;
    }

    if (item.expense > maxValue) {
      maxValue = item.expense;
    }

    if (item.profit.abs() > maxValue) {
      maxValue = item.profit.abs();
    }
  }

  if (maxValue <= 0) {
    return 100;
  }

  return maxValue * 1.20;
}

double _calculateMin(FinancialAnalysisData data) {
  double minValue = 0;

  for (final item in data.monthlyData) {
    if (item.profit < minValue) {
      minValue = item.profit;
    }
  }

  if (minValue == 0) {
    return 0;
  }

  return minValue * 1.20;
}

double _safeInterval(double maxValue, double minValue) {
  final range = maxValue - minValue;

  if (range <= 0) {
    return 1;
  }

  return range / 4;
}

double _expenseMaxValue(List<FinancialCategoryData> categories) {
  double maxValue = 0;

  for (final item in categories) {
    if (item.amount > maxValue) {
      maxValue = item.amount;
    }
  }

  if (maxValue <= 0) {
    return 100;
  }

  return maxValue * 1.20;
}

String _money(double value) {
  final rounded = value.round();

  final raw = rounded.abs().toString();

  final formatted = raw.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );

  final persian = formatted
      .replaceAll('0', '۰')
      .replaceAll('1', '۱')
      .replaceAll('2', '۲')
      .replaceAll('3', '۳')
      .replaceAll('4', '۴')
      .replaceAll('5', '۵')
      .replaceAll('6', '۶')
      .replaceAll('7', '۷')
      .replaceAll('8', '۸')
      .replaceAll('9', '۹')
      .replaceAll(',', '٬');

  if (value < 0) {
    return '-$persian';
  }

  return persian;
}

String _number(double value) {
  final raw = value.toStringAsFixed(1);

  return raw
      .replaceAll('0', '۰')
      .replaceAll('1', '۱')
      .replaceAll('2', '۲')
      .replaceAll('3', '۳')
      .replaceAll('4', '۴')
      .replaceAll('5', '۵')
      .replaceAll('6', '۶')
      .replaceAll('7', '۷')
      .replaceAll('8', '۸')
      .replaceAll('9', '۹')
      .replaceAll('.', '٫');
}

String _compactMoney(double value) {
  final abs = value.abs();

  double number;
  String suffix;

  if (abs >= 1000000000) {
    number = value / 1000000000;
    suffix = 'م';
  } else if (abs >= 1000000) {
    number = value / 1000000;
    suffix = 'م‌ت';
  } else if (abs >= 1000) {
    number = value / 1000;
    suffix = 'ه';
  } else {
    number = value;
    suffix = '';
  }

  final text =
      number.abs() >= 100
          ? number.toStringAsFixed(0)
          : number.toStringAsFixed(1);

  final persian = text
      .replaceAll('0', '۰')
      .replaceAll('1', '۱')
      .replaceAll('2', '۲')
      .replaceAll('3', '۳')
      .replaceAll('4', '۴')
      .replaceAll('5', '۵')
      .replaceAll('6', '۶')
      .replaceAll('7', '۷')
      .replaceAll('8', '۸')
      .replaceAll('9', '۹')
      .replaceAll('.', '٫');

  if (number < 0) {
    return '-$persian$suffix';
  }

  return '$persian$suffix';
}
