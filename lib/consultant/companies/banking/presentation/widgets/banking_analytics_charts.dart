import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/banking_repository.dart';

class BankingAnalyticsCharts extends StatelessWidget {
  const BankingAnalyticsCharts({super.key, required this.accounts});

  final List<BankAccountModel> accounts;

  @override
  Widget build(BuildContext context) {
    final analytics = BankingAnalyticsCalculator(accounts);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1050;

            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: NetBankTurnoverChart(
                      data: analytics.monthlyNetTurnover,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: BankBalanceConcentrationChart(
                      data: analytics.bankConcentration,
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                NetBankTurnoverChart(data: analytics.monthlyNetTurnover),
                const SizedBox(height: 18),
                BankBalanceConcentrationChart(
                  data: analytics.bankConcentration,
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 18),

        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1050;

            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: BankDiscrepancyTrendChart(
                      data: analytics.monthlyDiscrepancy,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: BankBalanceTrendChart(
                      data: analytics.monthlyBalance,
                      monthOverMonth: analytics.monthOverMonth,
                      yearOverYear: analytics.yearOverYear,
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                BankDiscrepancyTrendChart(data: analytics.monthlyDiscrepancy),
                const SizedBox(height: 18),
                BankBalanceTrendChart(
                  data: analytics.monthlyBalance,
                  monthOverMonth: analytics.monthOverMonth,
                  yearOverYear: analytics.yearOverYear,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ============================================================
// ANALYTICS CALCULATOR
// ============================================================

class BankingAnalyticsCalculator {
  BankingAnalyticsCalculator(List<BankAccountModel> accounts)
    : _accounts = accounts;

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

      final current = map[key];

      final net = account.creditTurnover - account.debitTurnover;

      if (current == null) {
        map[key] = MonthlyBankMetric(year: year, month: month, value: net);
      } else {
        map[key] = current.copyWith(value: current.value + net);
      }
    }

    final result = map.values.toList();

    result.sort((a, b) => a.sortKey.compareTo(b.sortKey));

    return result;
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

      final current = map[key];

      if (current == null) {
        map[key] = MonthlyBankMetric(
          year: year,
          month: month,
          value: account.discrepancy,
        );
      } else {
        map[key] = current.copyWith(value: current.value + account.discrepancy);
      }
    }

    final result = map.values.toList();

    result.sort((a, b) => a.sortKey.compareTo(b.sortKey));

    return result;
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

      final current = map[key];

      if (current == null) {
        map[key] = MonthlyBankMetric(
          year: year,
          month: month,
          value: account.closingBalance,
        );
      } else {
        map[key] = current.copyWith(
          value: current.value + account.closingBalance,
        );
      }
    }

    final result = map.values.toList();

    result.sort((a, b) => a.sortKey.compareTo(b.sortKey));

    return result;
  }

  List<BankConcentrationItem> get bankConcentration {
    final map = <String, double>{};

    for (final account in _accounts) {
      final name = account.bankName.trim();

      if (name.isEmpty) {
        continue;
      }

      map[name] = (map[name] ?? 0) + account.closingBalance;
    }

    final total = map.values.fold<double>(0, (sum, value) => sum + value);

    final result =
        map.entries.map((entry) {
          final percentage = total == 0 ? 0.0 : (entry.value / total) * 100;

          return BankConcentrationItem(
            label: entry.key,
            value: entry.value,
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
    if (monthlyBalance.length < 2) {
      return null;
    }

    final latest = monthlyBalance[monthlyBalance.length - 1];

    final previous = monthlyBalance[monthlyBalance.length - 2];

    return _percentageChange(previous.value, latest.value);
  }

  double? get yearOverYear {
    final values = monthlyBalance;

    if (values.isEmpty) {
      return null;
    }

    final latest = values.last;

    MonthlyBankMetric? previousYear;

    for (final item in values) {
      if (item.month == latest.month && item.year == latest.year - 1) {
        previousYear = item;
        break;
      }
    }

    if (previousYear == null) {
      return null;
    }

    return _percentageChange(previousYear.value, latest.value);
  }

  double? _percentageChange(double previous, double current) {
    if (previous == 0) {
      return null;
    }

    return ((current - previous) / previous) * 100;
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

  MonthlyBankMetric copyWith({int? year, int? month, double? value}) {
    return MonthlyBankMetric(
      year: year ?? this.year,
      month: month ?? this.month,
      value: value ?? this.value,
    );
  }

  String get monthLabel {
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
      return '$year/$month';
    }

    return names[month - 1];
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
// CHART CARD
// ============================================================

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({
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

      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: const Color(0xFFE6E8EB)),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              if (trailing != null) trailing!,
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(height: 235, child: child),
        ],
      ),
    );
  }
}

// ============================================================
// 1. NET BANK TURNOVER
// ============================================================

class NetBankTurnoverChart extends StatelessWidget {
  const NetBankTurnoverChart({super.key, required this.data});

  final List<MonthlyBankMetric> data;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsCard(
      title: 'خالص گردش بانک',

      subtitle: 'خالص گردش = بستانکار − بدهکار',

      child: _LineChart(
        data: data,
        lineColor: const Color(0xFF6F42C1),
        zeroLine: true,
      ),
    );
  }
}

// ============================================================
// 2. BANK CONCENTRATION
// ============================================================

class BankBalanceConcentrationChart extends StatelessWidget {
  const BankBalanceConcentrationChart({super.key, required this.data});

  final List<BankConcentrationItem> data;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsCard(
      title: 'تمرکز موجودی بانکی',

      subtitle: 'سهم هر بانک از کل موجودی بانکی',

      child: _HorizontalConcentrationChart(data: data),
    );
  }
}

// ============================================================
// 3. DISCREPANCY TREND
// ============================================================

class BankDiscrepancyTrendChart extends StatelessWidget {
  const BankDiscrepancyTrendChart({super.key, required this.data});

  final List<MonthlyBankMetric> data;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsCard(
      title: 'روند مغایرت‌ها',

      subtitle: 'مجموع مغایرت حساب‌های بانکی در هر دوره',

      child: _LineChart(
        data: data,
        lineColor: const Color(0xFFE53935),
        zeroLine: true,
      ),
    );
  }
}

// ============================================================
// 4. BALANCE TREND
// ============================================================

class BankBalanceTrendChart extends StatelessWidget {
  const BankBalanceTrendChart({
    super.key,
    required this.data,
    required this.monthOverMonth,
    required this.yearOverYear,
  });

  final List<MonthlyBankMetric> data;
  final double? monthOverMonth;
  final double? yearOverYear;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsCard(
      title: 'روند مانده بانکی',

      subtitle: 'روند مجموع مانده حساب‌های بانکی',

      trailing: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          _ChangeBadge(title: 'ماه قبل', value: monthOverMonth),

          const SizedBox(width: 6),

          _ChangeBadge(title: 'سال قبل', value: yearOverYear),
        ],
      ),

      child: _LineChart(data: data, lineColor: const Color(0xFF2D6CDF)),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 8),
            ),
            const SizedBox(height: 2),
            const Text(
              'داده کافی نیست',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }

    final positive = value! >= 0;

    final color = positive ? Colors.green.shade700 : Colors.red.shade700;

    final icon =
        positive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),

      decoration: BoxDecoration(
        color: color.withOpacity(.06),

        borderRadius: BorderRadius.circular(8),

        border: Border.all(color: color.withOpacity(.15)),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(icon, size: 12, color: color),

          const SizedBox(width: 2),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 8),
              ),

              Text(
                '${value!.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
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
          'داده تاریخی کافی برای نمایش نمودار وجود ندارد.',
          textAlign: TextAlign.center,
        ),
      );
    }

    final visible = data.length > 8 ? data.sublist(data.length - 8) : data;

    return CustomPaint(
      painter: _LineChartPainter(
        data: visible,
        lineColor: lineColor,
        zeroLine: zeroLine,
      ),
      child: const SizedBox.expand(),
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

    const left = 42.0;
    const right = 8.0;
    const top = 12.0;
    const bottom = 32.0;

    final chartWidth = math.max(1, size.width - left - right);

    final chartHeight = math.max(1, size.height - top - bottom);

    var minValue = data.first.value;

    var maxValue = data.first.value;

    for (final item in data) {
      minValue = math.min(minValue, item.value);

      maxValue = math.max(maxValue, item.value);
    }

    if (zeroLine) {
      minValue = math.min(minValue, 0);

      maxValue = math.max(maxValue, 0);
    }

    if ((maxValue - minValue).abs() < 0.000001) {
      maxValue += 1;
      minValue -= 1;
    }

    final gridPaint =
        Paint()
          ..color = const Color(0xFFE8EBEF)
          ..strokeWidth = 1;

    const gridLines = 4;

    for (var i = 0; i <= gridLines; i++) {
      final y = top + (chartHeight / gridLines) * i;

      canvas.drawLine(Offset(left, y), Offset(left + chartWidth, y), gridPaint);
    }

    if (zeroLine && minValue < 0 && maxValue > 0) {
      final zeroY = top + (maxValue / (maxValue - minValue)) * chartHeight;

      final zeroPaint =
          Paint()
            ..color = const Color(0xFFBFC5CC)
            ..strokeWidth = 1.4;

      canvas.drawLine(
        Offset(left, zeroY),
        Offset(left + chartWidth, zeroY),
        zeroPaint,
      );
    }

    final points = <Offset>[];

    for (var i = 0; i < data.length; i++) {
      final item = data[i];

      final x =
          data.length == 1
              ? left + chartWidth / 2
              : left + (chartWidth / (data.length - 1)) * i;

      final ratio = (item.value - minValue) / (maxValue - minValue);

      final y = top + chartHeight * (1 - ratio);

      points.add(Offset(x, y));
    }

    final path = Path();

    for (var i = 0; i < points.length; i++) {
      if (i == 0) {
        path.moveTo(points[i].dx, points[i].dy);
      } else {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }

    final linePaint =
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    final fillPath = Path.from(path);

    fillPath.lineTo(points.last.dx, top + chartHeight);

    fillPath.lineTo(points.first.dx, top + chartHeight);

    fillPath.close();

    final fillPaint =
        Paint()
          ..color = lineColor.withOpacity(.06)
          ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    final dotPaint = Paint()..color = lineColor;

    for (final point in points) {
      canvas.drawCircle(point, 3.6, dotPaint);
    }

    final textStyle = const TextStyle(color: Color(0xFF606872), fontSize: 9);

    for (var i = 0; i < data.length; i++) {
      final label = data[i].monthLabel;

      final painter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.rtl,
      );

      painter.layout(maxWidth: 65);

      var x = points[i].dx - painter.width / 2;

      if (x < left) {
        x = left;
      }

      if (x + painter.width > left + chartWidth) {
        x = left + chartWidth - painter.width;
      }

      painter.paint(canvas, Offset(x, top + chartHeight + 8));
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return true;
  }
}

// ============================================================
// CONCENTRATION CHART
// ============================================================

class _HorizontalConcentrationChart extends StatelessWidget {
  const _HorizontalConcentrationChart({required this.data});

  final List<BankConcentrationItem> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('اطلاعات موجودی بانکی وجود ندارد.'));
    }

    return Column(
      children: [
        for (var i = 0; i < data.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),

            child: Row(
              children: [
                SizedBox(
                  width: 82,

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
                        height: 22,

                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,

                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),

                      FractionallySizedBox(
                        widthFactor: (data[i].percentage / 100).clamp(0.0, 1.0),

                        child: Container(
                          height: 22,

                          decoration: BoxDecoration(
                            color: const Color(0xFF2D6CDF),

                            borderRadius: BorderRadius.circular(7),
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
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const Spacer(),

        Row(
          children: [
            Expanded(
              child: Text(
                'سهم از کل موجودی بانکی',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 9),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// FORMAT
// ============================================================

String _formatAmount(double value) {
  final abs = value.abs();

  if (abs >= 1000000000) {
    return '${(value / 1000000000).toStringAsFixed(1)}B';
  }

  if (abs >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }

  if (abs >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }

  return value.toStringAsFixed(0);
}
