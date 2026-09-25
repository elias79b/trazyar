import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tarazyar/consultant/companies/income/application/income_access_provider.dart';
import 'package:tarazyar/consultant/companies/income/application/income_dashboard_provider.dart';
import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

const Color _projectColor = Color(0xFF163A2B);
const Color _projectColorLight = Color(0xFF245B45);
const Color _projectColorSoft = Color(0xFFEAF2EE);

class IncomeDashboardPage extends ConsumerWidget {
  final String companyId;

  const IncomeDashboardPage({super.key, required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(incomeDashboardProvider(companyId));

    return CompanyScaffold(
      companyId: companyId,
      currentRoute: '/consultant/companies/$companyId/income',
      title: 'درآمد',
      body: dashboardAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: _projectColor),
            ),
        error:
            (error, stack) => _ErrorView(
              error: error,
              onRetry: () {
                ref.invalidate(incomeDashboardProvider(companyId));
              },
            ),
        data: (data) {
          if (!data.hasFiscalYear) {
            return _NoFiscalYearView(companyId: companyId);
          }

          return _DashboardContent(companyId: companyId, data: data);
        },
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  final String companyId;
  final IncomeDashboardData data;

  const _DashboardContent({required this.companyId, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessAsync = ref.watch(incomeAccessProvider(companyId));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RefreshIndicator(
        color: _projectColor,
        onRefresh: () async {
          ref.invalidate(incomeDashboardProvider(companyId));

          await ref.read(incomeDashboardProvider(companyId).future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(26, 22, 26, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DashboardHeader(
                data: data,
                companyId: companyId,
                accessAsync: accessAsync,
              ),
              const SizedBox(height: 18),
              _TopSummary(data: data),
              const SizedBox(height: 18),
              _ChartsGrid(data: data),
              const SizedBox(height: 18),
              _ReceivablesSection(data: data),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final IncomeDashboardData data;
  final String companyId;
  final AsyncValue<IncomeAccess> accessAsync;

  const _DashboardHeader({
    required this.data,
    required this.companyId,
    required this.accessAsync,
  });

  @override
  Widget build(BuildContext context) {
    final canManage = accessAsync.valueOrNull?.canCreatePeriods == true;

    return Container(
      height: 84,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [_projectColor, _projectColorLight],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _projectColor.withValues(alpha: .18),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'داشبورد تحلیلی درآمد',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'تمرکز بر تحلیل روندها، شناسایی نقاط ضعف و ارائه پیشنهادهای مدیریتی',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .80),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: .10)),
            ),
            child: Text(
              'سال مالی ${_fa((data.fiscalYear ?? 0).toString())}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
          if (canManage) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'مدیریت دوره‌های درآمد',
              onPressed: () {
                context.push('/consultant/companies/$companyId/income/periods');
              },
              icon: const Icon(
                Icons.calendar_month_rounded,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TopSummary extends StatelessWidget {
  final IncomeDashboardData data;

  const _TopSummary({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final count =
            width >= 1000
                ? 4
                : width >= 650
                ? 2
                : 1;

        const gap = 12.0;

        final itemWidth = (width - ((count - 1) * gap)) / count;

        final cards = [
          _SummaryCard(
            title: 'کل درآمد سال',
            value: _money(data.totalIncome),
            subtitle: 'درآمد شناسایی‌شده',
            icon: Icons.account_balance_wallet_rounded,
          ),
          _SummaryCard(
            title: 'درآمد عملیاتی',
            value: _money(data.operationalIncome),
            subtitle: 'از کل درآمد',
            icon: Icons.trending_up_rounded,
          ),
          _SummaryCard(
            title: 'درآمد غیرعملیاتی',
            value: _money(data.nonOperationalIncome),
            subtitle: 'از کل درآمد',
            icon: Icons.category_rounded,
          ),
          _SummaryCard(
            title: 'مانده دریافتنی',
            value: _money(data.remainingReceivables),
            subtitle: 'اسناد دریافت‌شده کسر شده',
            icon: Icons.receipt_long_rounded,
          ),
        ];

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children:
              cards
                  .map((card) => SizedBox(width: itemWidth, child: card))
                  .toList(),
        );
      },
    );
  }
}

class _ChartsGrid extends StatelessWidget {
  final IncomeDashboardData data;

  const _ChartsGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final twoColumns = width >= 1050;

        final chartWidth = twoColumns ? (width - 12) / 2 : width;

        if (!twoColumns) {
          return Column(
            children: [
              _TrendChart(data: data),
              const SizedBox(height: 12),
              _IncomeMixChart(data: data),
              const SizedBox(height: 12),
              _ComparisonChart(data: data),
              const SizedBox(height: 12),
              _ManagementAlerts(data: data),
            ],
          );
        }

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: chartWidth,
              height: 330,
              child: _TrendChart(data: data),
            ),
            SizedBox(
              width: chartWidth,
              height: 330,
              child: _IncomeMixChart(data: data),
            ),
            SizedBox(
              width: chartWidth,
              height: 330,
              child: _ComparisonChart(data: data),
            ),
            SizedBox(
              width: chartWidth,
              height: 330,
              child: _ManagementAlerts(data: data),
            ),
          ],
        );
      },
    );
  }
}

class _TrendChart extends StatelessWidget {
  final IncomeDashboardData data;

  const _TrendChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxValue = data.months
        .map((e) => e.totalIncome)
        .fold<double>(
          0.0,
          (previous, value) => math.max(previous, value).toDouble(),
        );

    return _ChartCard(
      title: 'تحلیل روند درآمد',
      icon: Icons.bar_chart_rounded,
      child: SizedBox(
        height: 245,
        child: _MonthlyBars(months: data.months, maxValue: maxValue),
      ),
    );
  }
}

class _MonthlyBars extends StatelessWidget {
  final List<IncomeDashboardMonth> months;
  final double maxValue;

  const _MonthlyBars({required this.months, required this.maxValue});

  @override
  Widget build(BuildContext context) {
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children:
          months.map((month) {
            final value = month.totalIncome;

            final ratio = (value / safeMax).clamp(0.0, 1.0).toDouble();

            final barHeight = math.max(4.0, ratio * 150.0).toDouble();

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 25,
                      child:
                          value > 0
                              ? FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _compactMoney(value),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                              : null,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 21,
                          height: barHeight,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Color(0xFF245B45), Color(0xFF4D9272)],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(5),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _shortMonth(month.title),
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }
}

class _IncomeMixChart extends StatelessWidget {
  final IncomeDashboardData data;

  const _IncomeMixChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final categories = [...data.categoryTotals]
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return _ChartCard(
      title: 'تحلیل سهم سرفصل‌ها',
      icon: Icons.donut_large_rounded,
      child: SizedBox(
        height: 245,
        child:
            categories.isEmpty
                ? const _EmptyChart(
                  text: 'هنوز درآمدی برای تحلیل سرفصل‌ها ثبت نشده است',
                )
                : Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Center(
                        child: SizedBox(
                          width: 165,
                          height: 165,
                          child: _DonutChart(
                            categories: categories,
                            total: data.totalIncome,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final item = categories[index];

                          final percent =
                              data.totalIncome <= 0
                                  ? 0.0
                                  : (item.amount / data.totalIncome) * 100;

                          return Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      _chartColors[index % _chartColors.length],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 9),
                                ),
                              ),
                              Text(
                                '${_fa(percent.toStringAsFixed(1))}٪',
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

class _DonutChart extends StatelessWidget {
  final List<IncomeCategoryTotal> categories;
  final double total;

  const _DonutChart({required this.categories, required this.total});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DonutPainter(categories: categories, total: total),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _compactMoney(total),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 3),
            Text(
              'مجموع درآمد',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 8),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<IncomeCategoryTotal> categories;
  final double total;

  _DonutPainter({required this.categories, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final radius = math.min(size.width, size.height) / 2;

    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 25
          ..strokeCap = StrokeCap.butt;

    double start = -math.pi / 2;

    if (total <= 0) {
      paint.color = Colors.grey.shade300;

      canvas.drawArc(rect, 0, math.pi * 2, false, paint);

      return;
    }

    for (int i = 0; i < categories.length; i++) {
      final item = categories[i];

      final sweep = (item.amount / total) * math.pi * 2;

      paint.color = _chartColors[i % _chartColors.length];

      canvas.drawArc(rect, start, sweep, false, paint);

      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.categories != categories || oldDelegate.total != total;
  }
}

class _ComparisonChart extends StatelessWidget {
  final IncomeDashboardData data;

  const _ComparisonChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final current = data.currentMonth;

    final previous = data.previousMonth;

    return _ChartCard(
      title: 'مقایسه رشد درآمد و دریافتنی‌ها',
      icon: Icons.compare_arrows_rounded,
      child: SizedBox(
        height: 245,
        child:
            current == null
                ? const _EmptyChart(text: 'اطلاعات ماه جاری در دسترس نیست')
                : _ComparisonBars(current: current, previous: previous),
      ),
    );
  }
}

class _ComparisonBars extends StatelessWidget {
  final IncomeDashboardMonth current;
  final IncomeDashboardMonth? previous;

  const _ComparisonBars({required this.current, required this.previous});

  @override
  Widget build(BuildContext context) {
    final maxValue = [
      current.totalIncome,
      current.receivables,
      previous?.totalIncome ?? 0.0,
      previous?.receivables ?? 0.0,
    ].fold<double>(
      0.0,
      (previousValue, value) => math.max(previousValue, value).toDouble(),
    );

    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ComparisonGroup(
                title: previous?.title ?? 'ماه قبل',
                income: previous?.totalIncome ?? 0.0,
                receivables: previous?.receivables ?? 0.0,
                maxValue: safeMax,
              ),
              _ComparisonGroup(
                title: current.title,
                income: current.totalIncome,
                receivables: current.receivables,
                maxValue: safeMax,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: Color(0xFF245B45), text: 'درآمد'),
            SizedBox(width: 18),
            _LegendDot(color: Color(0xFF78909C), text: 'دریافتنی'),
          ],
        ),
      ],
    );
  }
}

class _ComparisonGroup extends StatelessWidget {
  final String title;
  final double income;
  final double receivables;
  final double maxValue;

  const _ComparisonGroup({
    required this.title,
    required this.income,
    required this.receivables,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          height: 165,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _SmallBar(
                value: income,
                maxValue: maxValue,
                color: const Color(0xFF245B45),
              ),
              const SizedBox(width: 8),
              _SmallBar(
                value: receivables,
                maxValue: maxValue,
                color: const Color(0xFF78909C),
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        Text(
          title,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _SmallBar extends StatelessWidget {
  final double value;
  final double maxValue;
  final Color color;

  const _SmallBar({
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (value / maxValue).clamp(0.0, 1.0).toDouble();

    final height = math.max(4.0, ratio * 135.0).toDouble();

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          _compactMoney(value),
          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 3),
        Container(
          width: 25,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
          ),
        ),
      ],
    );
  }
}

class _ManagementAlerts extends StatelessWidget {
  final IncomeDashboardData data;

  const _ManagementAlerts({required this.data});

  @override
  Widget build(BuildContext context) {
    final alerts = _buildAlerts(data);

    return _ChartCard(
      title: 'هشدارهای مدیریتی',
      icon: Icons.warning_amber_rounded,
      titleColor: alerts.isNotEmpty ? const Color(0xFFD32F2F) : null,
      child: SizedBox(
        height: 245,
        child:
            alerts.isEmpty
                ? const _EmptyChart(
                  text: 'در حال حاضر هشدار مدیریتی فعالی وجود ندارد',
                )
                : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  itemCount: alerts.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final alert = alerts[index];

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(alert.icon, size: 18, color: alert.color),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            alert.text,
                            style: const TextStyle(fontSize: 10, height: 1.6),
                          ),
                        ),
                      ],
                    );
                  },
                ),
      ),
    );
  }
}

List<_DashboardAlert> _buildAlerts(IncomeDashboardData data) {
  final result = <_DashboardAlert>[];

  final current = data.currentMonth;

  if (current != null && current.isEmpty) {
    result.add(
      const _DashboardAlert(
        text: 'درآمد ماه جاری هنوز ثبت نشده است.',
        icon: Icons.calendar_today_rounded,
        color: Color(0xFFE53935),
      ),
    );
  }

  if (data.remainingReceivables > 0) {
    result.add(
      const _DashboardAlert(
        text: 'بخشی از درآمد ثبت‌شده هنوز دریافت نشده است.',
        icon: Icons.account_balance_wallet_rounded,
        color: Color(0xFFFF9800),
      ),
    );
  }

  if (current != null && current.totalIncome > 0 && current.receivables <= 0) {
    result.add(
      const _DashboardAlert(
        text: 'برای درآمد ماه جاری حساب دریافتنی ثبت نشده است.',
        icon: Icons.info_outline_rounded,
        color: Color(0xFFFF9800),
      ),
    );
  }

  if (current?.isClosed == true) {
    result.add(
      const _DashboardAlert(
        text: 'دوره ماه جاری بسته شده است.',
        icon: Icons.lock_rounded,
        color: Color(0xFFF9A825),
      ),
    );
  }

  if (data.completedMonths < 12) {
    result.add(
      _DashboardAlert(
        text:
            '${_fa((12 - data.completedMonths).toString())} ماه سال مالی هنوز ثبت درآمد یا دریافتنی ندارد.',
        icon: Icons.pending_actions_rounded,
        color: const Color(0xFFFF9800),
      ),
    );
  }

  return result;
}

class _DashboardAlert {
  final String text;
  final IconData icon;
  final Color color;

  const _DashboardAlert({
    required this.text,
    required this.icon,
    required this.color,
  });
}

class _ReceivablesSection extends StatelessWidget {
  final IncomeDashboardData data;

  const _ReceivablesSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.totalReceivables;

    final received = data.totalReceivedDocuments;

    final percent =
        total <= 0 ? 0.0 : (received / total).clamp(0.0, 1.0).toDouble();

    return _ChartCard(
      title: 'وضعیت حساب‌های دریافتنی',
      icon: Icons.receipt_long_rounded,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ReceivableMetric(
                  title: 'کل دریافتنی',
                  value: _money(total),
                ),
              ),
              Expanded(
                child: _ReceivableMetric(
                  title: 'دریافت‌شده',
                  value: _money(received),
                ),
              ),
              Expanded(
                child: _ReceivableMetric(
                  title: 'مانده',
                  value: _money(data.remainingReceivables),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 9,
              color: _projectColorLight,
              backgroundColor: _projectColorSoft,
            ),
          ),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${_fa((percent * 100).toStringAsFixed(1))}٪ دریافت شده',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceivableMetric extends StatelessWidget {
  final String title;
  final String value;

  const _ReceivableMetric({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color? titleColor;

  const _ChartCard({
    required this.title,
    required this.icon,
    required this.child,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE6F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 17,
                color: titleColor ?? const Color(0xFF315A91),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: titleColor ?? const Color(0xFF315A91),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E7F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _projectColor.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20, color: _projectColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendDot({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 9)),
      ],
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String text;

  const _EmptyChart({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insert_chart_outlined_rounded,
              size: 38,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 9),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoFiscalYearView extends StatelessWidget {
  final String companyId;

  const _NoFiscalYearView({required this.companyId});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    size: 55,
                    color: _projectColor,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'هنوز سال مالی ایجاد نشده است',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'ابتدا سال مالی را ایجاد کنید. سیستم ۱۲ ماه آن را به‌صورت خودکار ایجاد می‌کند.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _projectColor,
                    ),
                    onPressed: () {
                      context.push(
                        '/consultant/companies/$companyId/income/periods',
                      );
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('ایجاد سال مالی'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 45,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              const Text(
                'خطا در دریافت اطلاعات داشبورد',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: _projectColor),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('تلاش مجدد'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _chartColors = [
  Color(0xFF245B45),
  Color(0xFF4D9272),
  Color(0xFF78909C),
  Color(0xFF26A69A),
  Color(0xFF66BB6A),
  Color(0xFFFFB300),
  Color(0xFFFF7043),
  Color(0xFF7E57C2),
];

String _money(double value) {
  return '${_formatNumber(value.round().toString())} ریال';
}

String _compactMoney(double value) {
  if (value == 0) {
    return '۰';
  }

  if (value.abs() >= 1000000000) {
    return '${_fa((value / 1000000000).toStringAsFixed(1))}B';
  }

  if (value.abs() >= 1000000) {
    return '${_fa((value / 1000000).toStringAsFixed(1))}M';
  }

  if (value.abs() >= 1000) {
    return '${_fa((value / 1000).toStringAsFixed(1))}K';
  }

  return _fa(value.round().toString());
}

String _formatNumber(String value) {
  final chars = value.split('');

  final buffer = StringBuffer();

  for (int i = 0; i < chars.length; i++) {
    if (i > 0 && (chars.length - i) % 3 == 0) {
      buffer.write(',');
    }

    buffer.write(chars[i]);
  }

  return _fa(buffer.toString());
}

String _shortMonth(String value) {
  if (value.length <= 3) {
    return value;
  }

  return value.substring(0, 3);
}

String _fa(String value) {
  const en = '0123456789';

  const fa = '۰۱۲۳۴۵۶۷۸۹';

  var result = value;

  for (int i = 0; i < en.length; i++) {
    result = result.replaceAll(en[i], fa[i]);
  }

  return result;
}
