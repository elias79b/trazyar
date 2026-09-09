import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

import '../../application/banking_provider.dart';
import '../../data/banking_repository.dart';

class BankingDashboardPage extends ConsumerWidget {
  const BankingDashboardPage({super.key, required this.companyId});

  final String companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(bankingDashboardProvider(companyId));

    return CompanyScaffold(
      companyId: companyId,
      currentRoute: '/consultant/companies/$companyId/banking',
      title: 'بانک و نقد',
      body: dashboardAsync.when(
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 44,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(height: 12),
                  Text(error.toString(), textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        },
        data: (data) {
          final analytics = BankingAnalytics(data.bankAccounts);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(bankingDashboardProvider(companyId));

              await ref.read(bankingDashboardProvider(companyId).future);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DashboardHeader(
                    totalLiquidity: data.totalLiquidity,
                    bankBalance: data.totalBankBalance,
                  ),

                  const SizedBox(height: 20),

                  _TopKpis(
                    totalLiquidity: data.totalLiquidity,
                    bankBalance: data.totalBankBalance,
                    loanRemaining: data.totalLoanRemaining,
                    receivedChecks: data.receivedChecks.totalAmount,
                    paidChecks: data.paidChecks.totalAmount,
                  ),

                  const SizedBox(height: 24),

                  _AnalyticsGrid(analytics: analytics),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// HEADER
// ============================================================

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.totalLiquidity,
    required this.bankBalance,
  });

  final double totalLiquidity;
  final double bankBalance;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF40916C)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              color: Color(0xFF1B4332),
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
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'نقدینگی کل: ${_money(totalLiquidity)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مانده بانک',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),

                const SizedBox(height: 3),

                Text(
                  _money(bankBalance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
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

// ============================================================
// KPI
// ============================================================

class _TopKpis extends StatelessWidget {
  const _TopKpis({
    required this.totalLiquidity,
    required this.bankBalance,
    required this.loanRemaining,
    required this.receivedChecks,
    required this.paidChecks,
  });

  final double totalLiquidity;
  final double bankBalance;
  final double loanRemaining;
  final double receivedChecks;
  final double paidChecks;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int count;

        if (constraints.maxWidth >= 1200) {
          count = 5;
        } else if (constraints.maxWidth >= 850) {
          count = 3;
        } else if (constraints.maxWidth >= 550) {
          count = 2;
        } else {
          count = 1;
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: count,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.8,
          children: [
            _KpiCard(
              title: 'نقدینگی کل',
              value: _money(totalLiquidity),
              icon: Icons.account_balance_wallet_rounded,
            ),
            _KpiCard(
              title: 'مانده بانک',
              value: _money(bankBalance),
              icon: Icons.account_balance_rounded,
            ),
            _KpiCard(
              title: 'مانده تسهیلات',
              value: _money(loanRemaining),
              icon: Icons.request_quote_rounded,
            ),
            _KpiCard(
              title: 'چک‌های دریافتی',
              value: _money(receivedChecks),
              icon: Icons.call_received_rounded,
            ),
            _KpiCard(
              title: 'چک‌های پرداختی',
              value: _money(paidChecks),
              icon: Icons.call_made_rounded,
            ),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1B4332).withOpacity(.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF1B4332)),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
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

// ============================================================
// ANALYTICS GRID
// ============================================================

class _AnalyticsGrid extends StatelessWidget {
  const _AnalyticsGrid({required this.analytics});

  final BankingAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1050;

        if (wide) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _NetTurnoverCard(data: analytics.monthlyNetTurnover),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: _ConcentrationCard(
                      data: analytics.bankConcentration,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _DiscrepancyCard(data: analytics.monthlyDiscrepancy),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: _BalanceTrendCard(
                      data: analytics.monthlyBalance,
                      monthOverMonth: analytics.monthOverMonth,
                      yearOverYear: analytics.yearOverYear,
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Column(
          children: [
            _NetTurnoverCard(data: analytics.monthlyNetTurnover),

            const SizedBox(height: 16),

            _ConcentrationCard(data: analytics.bankConcentration),

            const SizedBox(height: 16),

            _DiscrepancyCard(data: analytics.monthlyDiscrepancy),

            const SizedBox(height: 16),

            _BalanceTrendCard(
              data: analytics.monthlyBalance,
              monthOverMonth: analytics.monthOverMonth,
              yearOverYear: analytics.yearOverYear,
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// CHART CARD
// ============================================================

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E8EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),

              if (trailing != null) trailing!,
            ],
          ),

          const SizedBox(height: 10),

          SizedBox(height: 235, width: double.infinity, child: child),
        ],
      ),
    );
  }
}

// ============================================================
// NET TURNOVER
// ============================================================

class _NetTurnoverCard extends StatelessWidget {
  const _NetTurnoverCard({required this.data});

  final List<MonthlyBankMetric> data;

  @override
  Widget build(BuildContext context) {
    return _ChartCard(
      title: 'خالص گردش بانک (خطی)',
      subtitle: 'خالص گردش = بستانکار − بدهکار',
      child: _LineChart(
        data: data,
        lineColor: const Color(0xFF7048C8),
        zeroLine: true,
      ),
    );
  }
}

// ============================================================
// CONCENTRATION
// ============================================================

class _ConcentrationCard extends StatelessWidget {
  const _ConcentrationCard({required this.data});

  final List<BankConcentrationItem> data;

  @override
  Widget build(BuildContext context) {
    return _ChartCard(
      title: 'تمرکز موجودی بانکی (میله‌ای افقی)',
      subtitle: 'سهم هر بانک از کل موجودی بانکی',
      child: _HorizontalBankChart(data: data),
    );
  }
}

// ============================================================
// DISCREPANCY
// ============================================================

class _DiscrepancyCard extends StatelessWidget {
  const _DiscrepancyCard({required this.data});

  final List<MonthlyBankMetric> data;

  @override
  Widget build(BuildContext context) {
    return _ChartCard(
      title: 'روند مغایرت‌ها (خطی)',
      subtitle: 'مجموع مغایرت حساب‌های بانکی',
      child: _LineChart(
        data: data,
        lineColor: const Color(0xFFE53935),
        zeroLine: true,
      ),
    );
  }
}

// ============================================================
// BALANCE TREND
// ============================================================

class _BalanceTrendCard extends StatelessWidget {
  const _BalanceTrendCard({
    required this.data,
    required this.monthOverMonth,
    required this.yearOverYear,
  });

  final List<MonthlyBankMetric> data;
  final double? monthOverMonth;
  final double? yearOverYear;

  @override
  Widget build(BuildContext context) {
    return _ChartCard(
      title: 'روند مانده بانکی (خطی)',
      subtitle: 'مجموع مانده حساب‌های بانکی',

      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ChangeBadge(title: 'ماه قبل', value: monthOverMonth),

          const SizedBox(width: 5),

          _ChangeBadge(title: 'سال قبل', value: yearOverYear),
        ],
      ),

      child: _LineChart(data: data, lineColor: const Color(0xFF2D6CDF)),
    );
  }
}

// ============================================================
// ANALYTICS ENGINE
// ============================================================

class BankingAnalytics {
  BankingAnalytics(List<BankAccountModel> accounts) : _accounts = accounts;

  final List<BankAccountModel> _accounts;

  List<MonthlyBankMetric> get monthlyNetTurnover {
    final map = <String, MonthlyBankMetric>{};

    for (final account in _accounts) {
      final year = account.fiscalYear;

      final month = account.fiscalMonth;

      if (year == null || month == null || month < 1 || month > 12) {
        continue;
      }

      final key = '$year-$month';

      final value = (account.creditTurnover - account.debitTurnover).toDouble();

      final old = map[key];

      if (old == null) {
        map[key] = MonthlyBankMetric(year: year, month: month, value: value);
      } else {
        map[key] = old.copyWith(value: (old.value + value).toDouble());
      }
    }

    return _sort(map.values.toList());
  }

  List<MonthlyBankMetric> get monthlyDiscrepancy {
    final map = <String, MonthlyBankMetric>{};

    for (final account in _accounts) {
      final year = account.fiscalYear;

      final month = account.fiscalMonth;

      if (year == null || month == null || month < 1 || month > 12) {
        continue;
      }

      final key = '$year-$month';

      final value = account.discrepancy.toDouble();

      final old = map[key];

      if (old == null) {
        map[key] = MonthlyBankMetric(year: year, month: month, value: value);
      } else {
        map[key] = old.copyWith(value: (old.value + value).toDouble());
      }
    }

    return _sort(map.values.toList());
  }

  List<MonthlyBankMetric> get monthlyBalance {
    final map = <String, MonthlyBankMetric>{};

    for (final account in _accounts) {
      final year = account.fiscalYear;

      final month = account.fiscalMonth;

      if (year == null || month == null || month < 1 || month > 12) {
        continue;
      }

      final key = '$year-$month';

      final value = account.closingBalance.toDouble();

      final old = map[key];

      if (old == null) {
        map[key] = MonthlyBankMetric(year: year, month: month, value: value);
      } else {
        map[key] = old.copyWith(value: (old.value + value).toDouble());
      }
    }

    return _sort(map.values.toList());
  }

  List<BankConcentrationItem> get bankConcentration {
    final map = <String, double>{};

    for (final account in _accounts) {
      final name = account.bankName.trim();

      if (name.isEmpty) {
        continue;
      }

      final amount = account.closingBalance.toDouble();

      map[name] = ((map[name] ?? 0.0) + amount).toDouble();
    }

    final total = map.values.fold<double>(
      0.0,
      (sum, value) => (sum + value).toDouble(),
    );

    final result =
        map.entries.map((entry) {
          final percentage =
              total == 0.0 ? 0.0 : ((entry.value / total) * 100.0).toDouble();

          return BankConcentrationItem(
            label: entry.key,
            value: entry.value.toDouble(),
            percentage: percentage,
          );
        }).toList();

    result.sort((a, b) => b.value.compareTo(a.value));

    if (result.length > 5) {
      return result.sublist(0, 5);
    }

    return result;
  }

  double? get monthOverMonth {
    final values = monthlyBalance;

    if (values.length < 2) {
      return null;
    }

    final current = values[values.length - 1];

    final previous = values[values.length - 2];

    return _percentageChange(previous.value, current.value);
  }

  double? get yearOverYear {
    final values = monthlyBalance;

    if (values.isEmpty) {
      return null;
    }

    final current = values.last;

    for (final item in values) {
      if (item.month == current.month && item.year == current.year - 1) {
        return _percentageChange(item.value, current.value);
      }
    }

    return null;
  }

  List<MonthlyBankMetric> _sort(List<MonthlyBankMetric> values) {
    values.sort((a, b) => a.sortKey.compareTo(b.sortKey));

    if (values.length > 8) {
      return values.sublist(values.length - 8);
    }

    return values;
  }

  double? _percentageChange(double previous, double current) {
    if (previous == 0.0) {
      return null;
    }

    return (((current - previous) / previous) * 100.0).toDouble();
  }
}

// ============================================================
// DATA MODELS
// ============================================================

class MonthlyBankMetric {
  const MonthlyBankMetric({
    required this.year,
    required this.month,
    required this.value,
  });

  final int year;
  final int month;
  final double value;

  int get sortKey => year * 100 + month;

  String get monthLabel {
    const labels = [
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
      return '$year/$month';
    }

    return labels[month - 1];
  }

  MonthlyBankMetric copyWith({double? value}) {
    return MonthlyBankMetric(
      year: year,
      month: month,
      value: value ?? this.value,
    );
  }
}

class BankConcentrationItem {
  const BankConcentrationItem({
    required this.label,
    required this.value,
    required this.percentage,
  });

  final String label;
  final double value;
  final double percentage;
}

// ============================================================
// LINE CHART
// ============================================================

class _LineChart extends StatelessWidget {
  const _LineChart({
    required this.data,
    required this.lineColor,
    this.zeroLine = false,
  });

  final List<MonthlyBankMetric> data;
  final Color lineColor;
  final bool zeroLine;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'داده دوره‌ای کافی برای نمایش نمودار وجود ندارد.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: CustomPaint(
        painter: _LineChartPainter(
          data: data,
          lineColor: lineColor,
          zeroLine: zeroLine,
        ),
      ),
    );
  }
}

// ============================================================
// LINE PAINTER
// ============================================================

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.data,
    required this.lineColor,
    required this.zeroLine,
  });

  final List<MonthlyBankMetric> data;
  final Color lineColor;
  final bool zeroLine;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }

    const left = 44.0;

    const right = 12.0;

    const top = 14.0;

    const bottom = 34.0;

    final chartWidth = math.max(1.0, size.width - left - right);

    final chartHeight = math.max(1.0, size.height - top - bottom);

    double minValue = data.first.value;

    double maxValue = data.first.value;

    for (final item in data) {
      minValue = math.min(minValue, item.value);

      maxValue = math.max(maxValue, item.value);
    }

    // ========================================================
    // ZERO-CENTERED MODE
    //
    // برای مغایرت:
    // صفر دقیقاً وسط قرار می‌گیرد.
    // ========================================================

    if (zeroLine) {
      final maxAbs = math.max(minValue.abs(), maxValue.abs());

      final padded = maxAbs == 0.0 ? 1.0 : maxAbs * 1.15;

      minValue = -padded;

      maxValue = padded;
    }

    if ((maxValue - minValue).abs() < 0.000001) {
      final padding = maxValue.abs() * .15 + 1.0;

      minValue -= padding;

      maxValue += padding;
    }

    final range = maxValue - minValue;

    // ========================================================
    // GRID
    // ========================================================

    final gridPaint =
        Paint()
          ..color = const Color(0xFFE9ECEF)
          ..strokeWidth = 1.0;

    for (var i = 0; i <= 4; i++) {
      final y = top + chartHeight * i / 4.0;

      canvas.drawLine(Offset(left, y), Offset(left + chartWidth, y), gridPaint);
    }

    // ========================================================
    // ZERO LINE
    // ========================================================

    if (zeroLine && minValue <= 0.0 && maxValue >= 0.0) {
      final zeroRatio = (0.0 - minValue) / range;

      final zeroY = top + chartHeight * (1.0 - zeroRatio);

      final zeroPaint =
          Paint()
            ..color = const Color(0xFF626B75)
            ..strokeWidth = 1.7;

      canvas.drawLine(
        Offset(left, zeroY),
        Offset(left + chartWidth, zeroY),
        zeroPaint,
      );

      // برچسب صفر
      _drawYAxisText(canvas, '0', left, zeroY);
    }

    // ========================================================
    // POINTS
    // ========================================================

    final points = <Offset>[];

    for (var i = 0; i < data.length; i++) {
      final normalized = (data[i].value - minValue) / range;

      final x =
          data.length == 1
              ? left + chartWidth / 2.0
              : left + chartWidth * i / (data.length - 1);

      final y = top + chartHeight * (1.0 - normalized);

      points.add(Offset(x, y));
    }

    // ========================================================
    // FILL
    // ========================================================

    final fillPath = Path();

    if (zeroLine) {
      final zeroRatio = (0.0 - minValue) / range;

      final zeroY = top + chartHeight * (1.0 - zeroRatio);

      fillPath.moveTo(points.first.dx, zeroY);

      for (final point in points) {
        fillPath.lineTo(point.dx, point.dy);
      }

      fillPath.lineTo(points.last.dx, zeroY);

      fillPath.close();
    } else {
      fillPath.moveTo(points.first.dx, top + chartHeight);

      for (final point in points) {
        fillPath.lineTo(point.dx, point.dy);
      }

      fillPath.lineTo(points.last.dx, top + chartHeight);

      fillPath.close();
    }

    final fillPaint =
        Paint()
          ..color = lineColor.withOpacity(.055)
          ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // ========================================================
    // LINE
    // ========================================================

    final linePath = Path();

    for (var i = 0; i < points.length; i++) {
      if (i == 0) {
        linePath.moveTo(points[i].dx, points[i].dy);
      } else {
        linePath.lineTo(points[i].dx, points[i].dy);
      }
    }

    final linePaint =
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);

    // ========================================================
    // DOTS
    // ========================================================

    final dotPaint = Paint()..color = lineColor;

    for (final point in points) {
      canvas.drawCircle(point, 3.5, dotPaint);
    }

    // ========================================================
    // X LABELS
    // ========================================================

    for (var i = 0; i < data.length; i++) {
      _drawBottomText(
        canvas,
        data[i].monthLabel,
        points[i].dx,
        top + chartHeight + 7,
      );
    }

    // ========================================================
    // Y LABELS
    // ========================================================

    for (var i = 0; i <= 4; i++) {
      final ratio = i / 4.0;

      final value = maxValue - range * ratio;

      final y = top + chartHeight * ratio;

      // در حالت مغایرت، صفر را قبلاً
      // جداگانه کشیده‌ایم.
      if (zeroLine && value.abs() < range * .001) {
        continue;
      }

      _drawYAxisText(canvas, _compactNumber(value), left, y);
    }
  }

  void _drawBottomText(Canvas canvas, String text, double x, double y) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Color(0xFF626A73), fontSize: 8),
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
    );

    painter.layout(maxWidth: 70);

    painter.paint(canvas, Offset(x - painter.width / 2, y));
  }

  void _drawYAxisText(Canvas canvas, String text, double left, double y) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Color(0xFF747C85), fontSize: 8),
      ),
      textDirection: TextDirection.ltr,
    );

    painter.layout();

    painter.paint(
      canvas,
      Offset(left - painter.width - 7, y - painter.height / 2),
    );
  }

  String _compactNumber(double value) {
    final absolute = value.abs();

    if (absolute >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    }

    if (absolute >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (absolute >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }

    return value.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return true;
  }
}

// ============================================================
// HORIZONTAL BANK CHART
// ============================================================

class _HorizontalBankChart extends StatelessWidget {
  const _HorizontalBankChart({required this.data});

  final List<BankConcentrationItem> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'اطلاعات موجودی بانکی وجود ندارد.',
          style: TextStyle(fontSize: 11),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < data.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 84,
                    child: Text(
                      data[i].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),

                        FractionallySizedBox(
                          widthFactor: (data[i].percentage / 100.0).clamp(
                            0.0,
                            1.0,
                          ),
                          child: Container(
                            height: 18,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D6CDF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  SizedBox(
                    width: 36,
                    child: Text(
                      '${data[i].percentage.toStringAsFixed(0)}%',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================
// CHANGE BADGE
// ============================================================

class _ChangeBadge extends StatelessWidget {
  const _ChangeBadge({required this.title, required this.value});

  final String title;
  final double? value;

  @override
  Widget build(BuildContext context) {
    if (value == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 7),
            ),
            const SizedBox(height: 2),
            const Text(
              '--',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      );
    }

    final positive = value! >= 0;

    // در این داشبورد:
    // افزایش موجودی = مثبت/سبز
    // کاهش موجودی = منفی/قرمز
    final color = positive ? Colors.green.shade700 : Colors.red.shade700;

    final icon =
        positive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.07),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),

          const SizedBox(width: 2),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 7),
              ),

              Text(
                '${value!.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HELPERS
// ============================================================

String _money(double value) {
  final rounded = value.round();

  final negative = rounded < 0;

  final digits = rounded.abs().toString();

  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }

    buffer.write(digits[i]);
  }

  final result = buffer.toString();

  return negative ? '-$result' : result;
}
