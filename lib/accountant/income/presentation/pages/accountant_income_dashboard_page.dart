import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarazyar/accountant/dashboard/presentation/widgets/accountant_scaffold.dart';
import 'package:tarazyar/accountant/income/application/accountant_income_dashboard_provider.dart';

class AccountantIncomeDashboardPage extends ConsumerWidget {
  final String companyId;

  const AccountantIncomeDashboardPage({super.key, required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountantIncomeDashboardProvider(companyId));

    return AccountantScaffold(
      currentRoute: '/accountant/income',
      title: 'داشبورد درآمد',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, stackTrace) => _ErrorView(
                error: error,
                onRetry: () {
                  ref.invalidate(accountantIncomeDashboardProvider(companyId));
                },
              ),
          data: (data) => _Dashboard(data: data),
        ),
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  final AccountantIncomeDashboardData data;

  const _Dashboard({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1100;
        final isTablet = constraints.maxWidth >= 700;

        return ListView(
          padding: EdgeInsets.all(
            isDesktop
                ? 20
                : isTablet
                ? 16
                : 12,
          ),
          children: [
            _DashboardHeader(data: data),
            const SizedBox(height: 14),
            _KpiRow(data: data),
            const SizedBox(height: 12),
            if (isDesktop)
              _DesktopCharts(data: data)
            else
              _ResponsiveCharts(data: data),
          ],
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final AccountantIncomeDashboardData data;

  const _DashboardHeader({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(.82),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'داشبورد درآمد — حسابدار شرکت',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'تمرکز بر کنترل و مشاهده جزئیات درآمد و دریافتنی‌ها',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),
          if (data.fiscalYear != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'سال ${_persianNumber(data.fiscalYear!)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  final AccountantIncomeDashboardData data;

  const _KpiRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < 700) {
          return Column(
            children: [
              _KpiCard(
                title: 'کل درآمد شرکت',
                value: _money(data.totalIncome),
                unit: 'ریال',
                icon: Icons.account_balance_wallet,
                iconColor: const Color(0xFF2196F3),
              ),
              const SizedBox(height: 8),
              _KpiCard(
                title: 'درآمد عملیاتی',
                value: _money(data.operationalIncome),
                unit: 'ریال',
                icon: Icons.receipt_long_outlined,
                iconColor: const Color(0xFF00A878),
              ),
              const SizedBox(height: 8),
              _KpiCard(
                title: 'درآمد غیرعملیاتی',
                value: _money(data.nonOperationalIncome),
                unit: 'ریال',
                icon: Icons.account_balance,
                iconColor: const Color(0xFF7956C9),
              ),
              const SizedBox(height: 8),
              _KpiCard(
                title: 'سهم درآمد عملیاتی',
                value: '${_number(data.operationalShare)}٪',
                unit: '',
                icon: Icons.percent,
                iconColor: const Color(0xFF2196F3),
              ),
              const SizedBox(height: 8),
              _KpiCard(
                title: 'سهم درآمد غیرعملیاتی',
                value: '${_number(data.nonOperationalShare)}٪',
                unit: '',
                icon: Icons.percent,
                iconColor: const Color(0xFF7956C9),
              ),
            ],
          );
        }

        final double itemWidth = ((width - 32.0) / 5.0).toDouble();

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              width: itemWidth,
              child: _KpiCard(
                title: 'کل درآمد شرکت',
                value: _money(data.totalIncome),
                unit: 'ریال',
                icon: Icons.account_balance_wallet,
                iconColor: const Color(0xFF2196F3),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _KpiCard(
                title: 'درآمد عملیاتی',
                value: _money(data.operationalIncome),
                unit: 'ریال',
                icon: Icons.receipt_long_outlined,
                iconColor: const Color(0xFF00A878),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _KpiCard(
                title: 'درآمد غیرعملیاتی',
                value: _money(data.nonOperationalIncome),
                unit: 'ریال',
                icon: Icons.account_balance,
                iconColor: const Color(0xFF7956C9),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _KpiCard(
                title: 'سهم درآمد عملیاتی',
                value: '${_number(data.operationalShare)}٪',
                unit: '',
                icon: Icons.percent,
                iconColor: const Color(0xFF2196F3),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _KpiCard(
                title: 'سهم درآمد غیرعملیاتی',
                value: '${_number(data.nonOperationalShare)}٪',
                unit: '',
                icon: Icons.percent,
                iconColor: const Color(0xFF7956C9),
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
  final String unit;
  final IconData icon;
  final Color iconColor;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD7E3EC)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF536273),
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF26364A),
                    ),
                  ),
                ),
                if (unit.isNotEmpty)
                  Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 8,
                      color: Color(0xFF8995A3),
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

class _DesktopCharts extends StatelessWidget {
  final AccountantIncomeDashboardData data;

  const _DesktopCharts({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: _ChartCard(
            title: 'ترکیب درآمد عملیاتی و غیرعملیاتی',
            child: _IncomeTypeDonut(data: data),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: _ChartCard(
            title: 'درآمد به تفکیک سرفصل',
            child: _CategoryBarChart(data: data),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 1,
          child: _ChartCard(
            title: 'سهم سرفصل‌های درآمدی از کل درآمد',
            child: _CategoryShareDonut(data: data),
          ),
        ),
      ],
    );
  }
}

class _ResponsiveCharts extends StatelessWidget {
  final AccountantIncomeDashboardData data;

  const _ResponsiveCharts({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ChartCard(
          title: 'ترکیب درآمد عملیاتی و غیرعملیاتی',
          child: _IncomeTypeDonut(data: data),
        ),
        const SizedBox(height: 10),
        _ChartCard(
          title: 'درآمد به تفکیک سرفصل',
          child: _CategoryBarChart(data: data),
        ),
        const SizedBox(height: 10),
        _ChartCard(
          title: 'سهم سرفصل‌های درآمدی از کل درآمد',
          child: _CategoryShareDonut(data: data),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFD7E3EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF30465B),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _IncomeTypeDonut extends StatelessWidget {
  final AccountantIncomeDashboardData data;

  const _IncomeTypeDonut({required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 270,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 400;

          final donut = _Donut(
            values: [data.operationalIncome, data.nonOperationalIncome],
            colors: const [Color(0xFF2196F3), Color(0xFF7252C7)],
            centerValue: _moneyCompact(data.totalIncome),
            centerLabel: 'کل درآمد',
          );

          final legend = _IncomeTypeLegend(data: data);

          if (compact) {
            return Column(children: [Expanded(child: donut), legend]);
          }

          return Row(
            children: [
              Expanded(flex: 5, child: donut),
              const SizedBox(width: 8),
              Expanded(flex: 5, child: legend),
            ],
          );
        },
      ),
    );
  }
}

class _IncomeTypeLegend extends StatelessWidget {
  final AccountantIncomeDashboardData data;

  const _IncomeTypeLegend({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LegendRow(
          color: const Color(0xFF2196F3),
          title: 'درآمد عملیاتی',
          value: _moneyCompact(data.operationalIncome),
          percentage: data.operationalShare,
        ),
        const SizedBox(height: 12),
        _LegendRow(
          color: const Color(0xFF7252C7),
          title: 'درآمد غیرعملیاتی',
          value: _moneyCompact(data.nonOperationalIncome),
          percentage: data.nonOperationalShare,
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String title;
  final String value;
  final double percentage;

  const _LegendRow({
    required this.color,
    required this.title,
    required this.value,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$value ریال',
                style: const TextStyle(fontSize: 10, color: Color(0xFF647487)),
              ),
              Text(
                '${_number(percentage)}٪',
                style: TextStyle(
                  fontSize: 9,
                  color: color,
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

class _CategoryBarChart extends StatelessWidget {
  final AccountantIncomeDashboardData data;

  const _CategoryBarChart({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final items = data.categorySummaries;

    if (items.isEmpty) {
      return const SizedBox(
        height: 270,
        child: _NoData(),
      );
    }

    final maxValue = items
        .map((item) => item.amount)
        .fold<double>(
      0.0,
          (current, value) =>
          math.max(current, value).toDouble(),
    );

    return SizedBox(
      height: 300,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 600;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: SizedBox(
              width: isSmall
                  ? math.max(
                constraints.maxWidth,
                items.length * 125.0,
              )
                  : constraints.maxWidth,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 12,
                  bottom: 8,
                  left: 12,
                  right: 12,
                ),
                child: Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.stretch,
                  children: items.map((item) {
                    return Expanded(
                      child: _IncomeBarItem(
                        item: item,
                        maxValue: maxValue,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _IncomeBarItem extends StatelessWidget {
  final AccountantIncomeCategorySummary item;
  final double maxValue;

  const _IncomeBarItem({
    required this.item,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final barColor = item.isOperational
        ? const Color(0xFF2196F3)
        : const Color(0xFF7252C7);

    final ratio = maxValue <= 0
        ? 0.0
        : (item.amount / maxValue)
        .clamp(0.0, 1.0)
        .toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      child: Column(
        children: [
          // --------------------------------------------------------
          // مقدار
          // --------------------------------------------------------

          SizedBox(
            height: 28,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _moneyCompact(item.amount),
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF526477),
                ),
              ),
            ),
          ),

          const SizedBox(height: 5),

          // --------------------------------------------------------
          // BAR AREA
          // --------------------------------------------------------

          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: ratio == 0
                    ? 0.015
                    : ratio,
                widthFactor: .55,
                child: Container(
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius:
                    const BorderRadius.vertical(
                      top: Radius.circular(5),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // --------------------------------------------------------
          // CATEGORY NAME
          // --------------------------------------------------------

          SizedBox(
            height: 42,
            child: Tooltip(
              message: item.categoryName,
              child: Text(
                item.categoryName,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF667789),
                ),
              ),
            ),
          ),

          // --------------------------------------------------------
          // TYPE
          // --------------------------------------------------------

          Text(
            item.isOperational
                ? 'عملیاتی'
                : 'غیرعملیاتی',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 8,
              color: barColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<AccountantIncomeCategorySummary> items;
  final double maxValue;

  _BarChartPainter({required this.items, required this.maxValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    const double chartLeft = 42.0;
    const double chartRightPadding = 12.0;
    const double chartTop = 18.0;
    const double chartBottom = 220.0;

    final double chartRight = size.width - chartRightPadding;

    final double chartWidth = math.max(0.0, chartRight - chartLeft).toDouble();

    final double chartHeight = math.max(0.0, chartBottom - chartTop).toDouble();

    final gridPaint =
        Paint()
          ..color = const Color(0xFFE7EDF2)
          ..strokeWidth = 1;

    final labelPainter = TextPainter(textDirection: TextDirection.rtl);

    for (int i = 0; i <= 4; i++) {
      final double y = chartBottom - chartHeight * i.toDouble() / 4.0;

      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);

      final double value = maxValue * i.toDouble() / 4.0;

      labelPainter.text = TextSpan(
        text: _moneyShort(value),
        style: const TextStyle(fontSize: 8, color: Color(0xFF7C8B9A)),
      );

      labelPainter.layout();

      labelPainter.paint(canvas, Offset(0, y - labelPainter.height / 2.0));
    }

    final int count = items.length;

    final double slotWidth =
        count == 0 ? chartWidth : chartWidth / count.toDouble();

    for (int i = 0; i < count; i++) {
      final item = items[i];

      final double barHeight =
          maxValue <= 0.0 ? 0.0 : chartHeight * item.amount / maxValue;

      final double x = chartLeft + i.toDouble() * slotWidth + slotWidth * .25;

      final double width = slotWidth * .5;

      final rect = Rect.fromLTWH(x, chartBottom - barHeight, width, barHeight);

      paint.color =
          item.isOperational
              ? const Color(0xFF2196F3)
              : const Color(0xFF7252C7);

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        paint,
      );

      labelPainter.text = TextSpan(
        text: _moneyShort(item.amount),
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: Color(0xFF526477),
        ),
      );

      labelPainter.layout(maxWidth: slotWidth);

      labelPainter.paint(
        canvas,
        Offset(
          x + width / 2.0 - labelPainter.width / 2.0,
          chartBottom - barHeight - labelPainter.height - 4.0,
        ),
      );

      labelPainter.text = TextSpan(
        text: _shortCategoryName(item.categoryName),
        style: const TextStyle(fontSize: 8, color: Color(0xFF667789)),
      );

      labelPainter.layout(maxWidth: slotWidth);

      labelPainter.paint(
        canvas,
        Offset(x + width / 2.0 - labelPainter.width / 2.0, chartBottom + 8.0),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.items != items || oldDelegate.maxValue != maxValue;
  }
}

class _CategoryShareDonut extends StatelessWidget {
  final AccountantIncomeDashboardData data;

  const _CategoryShareDonut({required this.data});

  @override
  Widget build(BuildContext context) {
    final items =
        data.categorySummaries
            .where((item) => item.amount > 0.0)
            .take(7)
            .toList();

    if (items.isEmpty) {
      return const SizedBox(height: 270, child: _NoData());
    }

    final colors = _categoryColors;

    final donut = _Donut(
      values: items.map((item) => item.amount).toList(),
      colors: List.generate(
        items.length,
        (index) => colors[index % colors.length],
      ),
      centerValue: _moneyCompact(data.totalIncome),
      centerLabel: 'کل درآمد',
    );

    final legend = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: _CategoryLegendRow(
              item: items[i],
              color: colors[i % colors.length],
              total: data.totalIncome,
            ),
          ),
      ],
    );

    return SizedBox(
      height: 270,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 400;

          if (compact) {
            return Column(
              children: [
                Expanded(child: donut),
                SizedBox(
                  height: 82,
                  child: SingleChildScrollView(child: legend),
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 5, child: donut),
              const SizedBox(width: 4),
              Expanded(flex: 5, child: SingleChildScrollView(child: legend)),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryLegendRow extends StatelessWidget {
  final AccountantIncomeCategorySummary item;
  final Color color;
  final double total;

  const _CategoryLegendRow({
    required this.item,
    required this.color,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final double percentage = total == 0.0 ? 0.0 : item.amount / total * 100.0;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            item.categoryName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          '${_number(percentage)}٪',
          style: TextStyle(
            fontSize: 8,
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Donut extends StatelessWidget {
  final List<double> values;
  final List<Color> colors;
  final String centerValue;
  final String centerLabel;

  const _Donut({
    required this.values,
    required this.colors,
    required this.centerValue,
    required this.centerLabel,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DonutPainter(values: values, colors: colors),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                centerValue,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF394A5B),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              centerLabel,
              style: const TextStyle(fontSize: 9, color: Color(0xFF7D8995)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  _DonutPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final double total = values.fold<double>(
      0.0,
      (double sum, double value) => sum + value,
    );

    if (total <= 0.0) {
      return;
    }

    final center = Offset(size.width / 2.0, size.height / 2.0);

    final double radius =
        math.min(size.width, size.height).toDouble() / 2.0 - 15.0;

    final double strokeWidth = math.min(28.0, radius * .28).toDouble();

    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt
          ..isAntiAlias = true;

    double startAngle = -math.pi / 2.0;

    for (int i = 0; i < values.length; i++) {
      final double sweep = 2.0 * math.pi * values[i] / total;

      paint.color = colors[i % colors.length];

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2.0),
        startAngle,
        sweep,
        false,
        paint,
      );

      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.colors != colors;
  }
}

class _NoData extends StatelessWidget {
  const _NoData();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_outlined, size: 42, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          const Text(
            'اطلاعاتی برای نمایش وجود ندارد',
            style: TextStyle(fontSize: 11, color: Color(0xFF8995A3)),
          ),
        ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 50, color: Colors.red),
            const SizedBox(height: 12),
            const Text(
              'خطا در دریافت اطلاعات داشبورد درآمد',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
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

String _shortCategoryName(String value) {
  if (value.length <= 12) {
    return value;
  }

  return '${value.substring(0, 11)}…';
}

String _money(double value) {
  final rounded = value.round().toString();

  final buffer = StringBuffer();

  for (int i = 0; i < rounded.length; i++) {
    if (i > 0 && (rounded.length - i) % 3 == 0) {
      buffer.write(',');
    }

    buffer.write(rounded[i]);
  }

  return buffer.toString();
}

String _moneyCompact(double value) {
  if (value >= 1000000000.0) {
    return '${_number(value / 1000000000.0)} میلیارد';
  }

  if (value >= 1000000.0) {
    return '${_number(value / 1000000.0)} میلیون';
  }

  if (value >= 1000.0) {
    return '${_number(value / 1000.0)} هزار';
  }

  return _money(value);
}

String _moneyShort(double value) {
  if (value >= 1000000000.0) {
    return '${_number(value / 1000000000.0)}B';
  }

  if (value >= 1000000.0) {
    return '${_number(value / 1000000.0)}M';
  }

  if (value >= 1000.0) {
    return '${_number(value / 1000.0)}K';
  }

  return _number(value);
}

String _number(double value) {
  if (value == value.roundToDouble()) {
    return _persianNumber(value.round());
  }

  return _persianNumber(value.toStringAsFixed(1));
}

String _persianNumber(Object value) {
  const english = '0123456789.,';
  const persian = '۰۱۲۳۴۵۶۷۸۹٫٬';

  var result = value.toString();

  for (int i = 0; i < english.length; i++) {
    result = result.replaceAll(english[i], persian[i]);
  }

  return result;
}

const _categoryColors = [
  Color(0xFF2196F3),
  Color(0xFF49B7E8),
  Color(0xFF32A889),
  Color(0xFF6BAE45),
  Color(0xFFF0B323),
  Color(0xFFF18B32),
  Color(0xFF7252C7),
];
