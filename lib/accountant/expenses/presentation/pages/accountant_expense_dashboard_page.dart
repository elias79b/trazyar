import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarazyar/accountant/expenses/application/accountant_expense_dashboard_provider.dart';
import 'package:tarazyar/accountant/dashboard/presentation/widgets/accountant_scaffold.dart';

class AccountantExpenseDashboardPage extends ConsumerWidget {
  const AccountantExpenseDashboardPage({super.key, required this.companyId});

  final String companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountantExpenseDashboardProvider(companyId));

    return AccountantScaffold(
      currentRoute: '/accountant/expenses',
      title: 'داشبورد هزینه‌ها',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) {
            return _ExpenseDashboardError(
              message: error.toString(),
              onRetry: () {
                ref.invalidate(accountantExpenseDashboardProvider(companyId));
              },
            );
          },
          data: (data) {
            if (!data.hasData) {
              return _EmptyExpenseDashboard(
                onRefresh: () {
                  ref.invalidate(accountantExpenseDashboardProvider(companyId));
                },
              );
            }

            return _ExpenseDashboardContent(
              data: data,
              onRefresh: () {
                ref.invalidate(accountantExpenseDashboardProvider(companyId));
              },
            );
          },
        ),
      ),
    );
  }
}

class _ExpenseDashboardContent extends StatelessWidget {
  const _ExpenseDashboardContent({required this.data, required this.onRefresh});

  final AccountantExpenseDashboardData data;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final bool isMobile = width < 700;
        final bool isTablet = width >= 700 && width < 1100;

        final int cardColumns =
        isMobile
            ? 1
            : isTablet
            ? 2
            : 5;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DashboardHeader(data: data, onRefresh: onRefresh),
              const SizedBox(height: 16),
              _SummaryCards(data: data, columns: cardColumns),
              const SizedBox(height: 16),
              _ChartsSection(
                data: data,
                isMobile: isMobile,
                isTablet: isTablet,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.data, required this.onRefresh});

  final AccountantExpenseDashboardData data;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.payments_outlined,
              color: theme.colorScheme.primary,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'داشبورد هزینه‌ها',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.selectedPeriod?.displayTitle ?? 'دوره مالی',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'به‌روزرسانی',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.data, required this.columns});

  final AccountantExpenseDashboardData data;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryCardData(
        title: 'کل هزینه جاری ماه',
        amount: data.totalExpense,
        icon: Icons.account_balance_wallet_outlined,
        iconColor: const Color(0xFF1688E8),
        changePercent: data.changePercent,
      ),
      _SummaryCardData(
        title: 'هزینه‌های عملیاتی',
        amount: data.operationalTotal,
        icon: Icons.settings_outlined,
        iconColor: const Color(0xFF14A96D),
        sharePercent: data.operationalShare,
      ),
      _SummaryCardData(
        title: 'هزینه‌های غیرعملیاتی',
        amount: data.nonOperationalTotal,
        icon: Icons.analytics_outlined,
        iconColor: const Color(0xFF7544C7),
        sharePercent: data.nonOperationalShare,
      ),
      _SummaryCardData(
        title: 'سهم هزینه‌های عملیاتی',
        amount: data.operationalShare,
        icon: Icons.pie_chart_outline_rounded,
        iconColor: const Color(0xFF1688E8),
        isPercent: true,
      ),
      _SummaryCardData(
        title: 'سهم هزینه‌های غیرعملیاتی',
        amount: data.nonOperationalShare,
        icon: Icons.donut_small_outlined,
        iconColor: const Color(0xFF7544C7),
        isPercent: true,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 156,
      ),
      itemBuilder: (context, index) {
        return _SummaryCard(data: cards[index]);
      },
    );
  }
}

class _SummaryCardData {
  const _SummaryCardData({
    required this.title,
    required this.amount,
    required this.icon,
    required this.iconColor,
    this.changePercent,
    this.sharePercent,
    this.isPercent = false,
  });

  final String title;
  final double amount;
  final IconData icon;
  final Color iconColor;
  final double? changePercent;
  final double? sharePercent;
  final bool isPercent;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final _SummaryCardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bool hasChange = data.changePercent != null && !data.isPercent;

    final bool isIncrease = (data.changePercent ?? 0) >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: data.iconColor.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, color: data.iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data.isPercent
                      ? '${_formatNumber(data.amount, decimals: 1)}٪'
                      : _formatMoney(data.amount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.isPercent ? 'نسبت به کل هزینه' : 'ریال',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (hasChange) ...[
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Icon(
                        isIncrease
                            ? Icons.north_east_rounded
                            : Icons.south_east_rounded,
                        size: 15,
                        color:
                        isIncrease
                            ? const Color(0xFF149B69)
                            : const Color(0xFFD94B4B),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${_formatNumber(data.changePercent!.abs(), decimals: 1)}٪',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color:
                          isIncrease
                              ? const Color(0xFF149B69)
                              : const Color(0xFFD94B4B),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'نسبت به ماه قبل',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartsSection extends StatelessWidget {
  const _ChartsSection({
    required this.data,
    required this.isMobile,
    required this.isTablet,
  });

  final AccountantExpenseDashboardData data;
  final bool isMobile;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        children: [
          _CompositionCard(data: data),
          const SizedBox(height: 14),
          _CategoryBarCard(data: data),
          const SizedBox(height: 14),
          _CategoryShareCard(data: data),
        ],
      );
    }

    if (isTablet) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _CompositionCard(data: data)),
              const SizedBox(width: 14),
              Expanded(child: _CategoryShareCard(data: data)),
            ],
          ),
          const SizedBox(height: 14),
          _CategoryBarCard(data: data),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 4, child: _CompositionCard(data: data)),
        const SizedBox(width: 14),
        Expanded(flex: 6, child: _CategoryBarCard(data: data)),
        const SizedBox(width: 14),
        Expanded(flex: 5, child: _CategoryShareCard(data: data)),
      ],
    );
  }
}

class _DashboardChartCard extends StatelessWidget {
  const _DashboardChartCard({
    required this.title,
    required this.child,
    this.height = 370,
  });

  final String title;
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.right,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _CompositionCard extends StatelessWidget {
  const _CompositionCard({required this.data});

  final AccountantExpenseDashboardData data;

  @override
  Widget build(BuildContext context) {
    return _DashboardChartCard(
      title: 'ترکیب هزینه‌های عملیاتی و غیرعملیاتی',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool compact = constraints.maxWidth < 380;

          return Column(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: compact ? 58 : 72,
                        sections: [
                          PieChartSectionData(
                            value: data.operationalTotal,
                            title: '',
                            radius: compact ? 55 : 68,
                            color: const Color(0xFF1688E8),
                          ),
                          PieChartSectionData(
                            value: data.nonOperationalTotal,
                            title: '',
                            radius: compact ? 55 : 68,
                            color: const Color(0xFF7544C7),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatCompactMoney(data.totalExpense),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'ریال',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'کل هزینه‌ها',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 18,
                runSpacing: 8,
                children: [
                  _LegendItem(
                    color: const Color(0xFF1688E8),
                    title: 'هزینه‌های عملیاتی',
                    value:
                    '${_formatNumber(data.operationalShare, decimals: 1)}٪',
                  ),
                  _LegendItem(
                    color: const Color(0xFF7544C7),
                    title: 'هزینه‌های غیرعملیاتی',
                    value:
                    '${_formatNumber(data.nonOperationalShare, decimals: 1)}٪',
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryBarCard extends StatelessWidget {
  const _CategoryBarCard({required this.data});

  final AccountantExpenseDashboardData data;

  @override
  Widget build(BuildContext context) {
    final categories = data.topCategories;

    return _DashboardChartCard(
      title: 'هزینه‌ها به تفکیک سرفصل',
      height: 370,
      child:
      categories.isEmpty
          ? const _NoChartData()
          : LayoutBuilder(
        builder: (context, constraints) {
          final maxValue = categories.fold<double>(
            0.0,
                (max, item) => item.amount > max ? item.amount : max,
          );

          return BarChart(
            BarChartData(
              maxY: maxValue == 0 ? 10 : maxValue * 1.22,
              minY: 0,
              alignment: BarChartAlignment.spaceAround,
              groupsSpace: 14,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _chartInterval(maxValue),
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: .55),
                    strokeWidth: 1,
                  );
                },
              ),
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
                    interval: _chartInterval(maxValue),
                    getTitlesWidget: (value, meta) {
                      return Text(
                        _formatCompactNumber(value),
                        style: Theme.of(context).textTheme.labelSmall,
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 62,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();

                      if (index < 0 || index >= categories.length) {
                        return const SizedBox.shrink();
                      }

                      final category = categories[index];

                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SizedBox(
                          width: 72,
                          child: Text(
                            category.categoryName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(fontSize: 10),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final category = categories[groupIndex];

                    return BarTooltipItem(
                      '${category.categoryName}\n'
                          '${_formatMoney(category.amount)} ریال',
                      const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
              barGroups: List.generate(categories.length, (index) {
                final item = categories[index];

                return BarChartGroupData(
                  x: index,
                  barsSpace: 0,
                  barRods: [
                    BarChartRodData(
                      toY: item.amount,
                      width: categories.length > 10 ? 12 : 20,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(5),
                      ),
                      color:
                      item.expenseType == 'operational'
                          ? const Color(0xFF1688E8)
                          : const Color(0xFF7544C7),
                    ),
                  ],
                );
              }),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryShareCard extends StatelessWidget {
  const _CategoryShareCard({required this.data});

  final AccountantExpenseDashboardData data;

  @override
  Widget build(BuildContext context) {
    final categories = data.topCategories;

    return _DashboardChartCard(
      title: 'سهم سرفصل‌های هزینه از کل هزینه‌ها',
      height: 370,
      child:
      categories.isEmpty
          ? const _NoChartData()
          : LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius:
                        constraints.maxWidth < 360 ? 52 : 64,
                        sections: List.generate(categories.length, (
                            index,
                            ) {
                          final item = categories[index];

                          return PieChartSectionData(
                            value: item.amount,
                            title: '',
                            radius:
                            constraints.maxWidth < 360 ? 50 : 62,
                            color: _chartColor(index),
                          );
                        }),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatCompactMoney(data.totalExpense),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'ریال',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'کل هزینه‌ها',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 112),
                child: SingleChildScrollView(
                  child: Column(
                    children:
                    categories.map((item) {
                      final index = categories.indexOf(item);

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 3,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _chartColor(index),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                item.categoryName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                Theme.of(
                                  context,
                                ).textTheme.labelSmall,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_formatNumber(item.sharePercent, decimals: 1)}٪',
                              style: Theme.of(
                                context,
                              ).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.title,
    required this.value,
  });

  final Color color;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$title  $value',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _NoChartData extends StatelessWidget {
  const _NoChartData();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'برای این دوره اطلاعات هزینه‌ای ثبت نشده است.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _EmptyExpenseDashboard extends StatelessWidget {
  const _EmptyExpenseDashboard({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 58,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: .7),
            ),
            const SizedBox(height: 14),
            Text(
              'هنوز دوره مالی هزینه‌ای ایجاد نشده است.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'پس از ایجاد دوره و ثبت هزینه‌ها، اطلاعات داشبورد در این بخش نمایش داده می‌شود.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('به‌روزرسانی'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseDashboardError extends StatelessWidget {
  const _ExpenseDashboardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

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
              size: 54,
              color: Color(0xFFD94B4B),
            ),
            const SizedBox(height: 12),
            Text(
              'خطا در دریافت اطلاعات داشبورد هزینه',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
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

Color _chartColor(int index) {
  const colors = [
    Color(0xFF1688E8),
    Color(0xFF2FA9E8),
    Color(0xFF45B96B),
    Color(0xFF7AC943),
    Color(0xFFF0A202),
    Color(0xFFFF6B35),
    Color(0xFF7544C7),
    Color(0xFF9B51E0),
    Color(0xFF5E60CE),
    Color(0xFF00A896),
    Color(0xFFEF476F),
    Color(0xFF118AB2),
  ];

  return colors[index % colors.length];
}

double _chartInterval(double maxValue) {
  if (maxValue <= 0) {
    return 1;
  }

  final raw = maxValue / 4;

  if (raw >= 1000000000) {
    return 1000000000;
  }

  if (raw >= 500000000) {
    return 500000000;
  }

  if (raw >= 100000000) {
    return 100000000;
  }

  if (raw >= 50000000) {
    return 50000000;
  }

  if (raw >= 10000000) {
    return 10000000;
  }

  if (raw >= 1000000) {
    return 1000000;
  }

  if (raw >= 100000) {
    return 100000;
  }

  if (raw >= 10000) {
    return 10000;
  }

  if (raw >= 1000) {
    return 1000;
  }

  return 100;
}

String _formatMoney(double value) {
  return _formatNumber(value, decimals: 0);
}

String _formatCompactMoney(double value) {
  if (value.abs() >= 1000000000) {
    return '${_formatNumber(value / 1000000000, decimals: 2)} میلیارد';
  }

  if (value.abs() >= 1000000) {
    return '${_formatNumber(value / 1000000, decimals: 2)} میلیون';
  }

  if (value.abs() >= 1000) {
    return '${_formatNumber(value / 1000, decimals: 1)} هزار';
  }

  return _formatNumber(value, decimals: 0);
}

String _formatCompactNumber(double value) {
  if (value.abs() >= 1000000000) {
    return '${_formatNumber(value / 1000000000, decimals: 1)}B';
  }

  if (value.abs() >= 1000000) {
    return '${_formatNumber(value / 1000000, decimals: 1)}M';
  }

  if (value.abs() >= 1000) {
    return '${_formatNumber(value / 1000, decimals: 1)}K';
  }

  return _formatNumber(value, decimals: 0);
}

String _formatNumber(double value, {int decimals = 0}) {
  final fixed = value.toStringAsFixed(decimals);

  final parts = fixed.split('.');
  final integerPart = parts.first;
  final decimalPart = parts.length > 1 ? parts[1] : null;

  final negative = integerPart.startsWith('-');
  final digits = negative ? integerPart.substring(1) : integerPart;

  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }

    buffer.write(digits[i]);
  }

  final result = StringBuffer();

  if (negative) {
    result.write('-');
  }

  result.write(buffer.toString());

  if (decimalPart != null && decimals > 0) {
    result
      ..write('.')
      ..write(decimalPart);
  }

  return _toPersianDigits(result.toString());
}

String _toPersianDigits(String value) {
  const english = '0123456789';
  const persian = '۰۱۲۳۴۵۶۷۸۹';

  var result = value;

  for (var i = 0; i < english.length; i++) {
    result = result.replaceAll(english[i], persian[i]);
  }

  return result;
}
