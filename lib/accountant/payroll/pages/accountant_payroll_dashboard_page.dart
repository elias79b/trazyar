import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarazyar/accountant/dashboard/presentation/widgets/accountant_scaffold.dart';
import 'package:tarazyar/accountant/payroll/application/accountant_payroll_dashboard_provider.dart';

class AccountantPayrollDashboardPage extends ConsumerWidget {
  final String companyId;

  const AccountantPayrollDashboardPage({super.key, required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountantPayrollDashboardProvider(companyId));

    return AccountantScaffold(
      currentRoute: '/accountant/payroll',
      title: 'حقوق و دستمزد',
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stackTrace) => _ErrorView(
              error: error,
              onRetry: () {
                ref.invalidate(accountantPayrollDashboardProvider(companyId));
              },
            ),
        data: (data) => _PayrollDashboard(data: data),
      ),
    );
  }
}

class _PayrollDashboard extends StatelessWidget {
  final AccountantPayrollDashboardData data;

  const _PayrollDashboard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 850;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isMobile ? 14 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(data: data),
                const SizedBox(height: 16),
                _KpiGrid(data: data, isMobile: isMobile),
                const SizedBox(height: 16),
                if (isMobile) ...[
                  _DepartmentChart(data: data),
                  const SizedBox(height: 14),
                  _SalaryMixChart(data: data),
                  const SizedBox(height: 14),
                  _OvertimeCostCenterChart(data: data),
                ] else
                  SizedBox(
                    height: 330,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _DepartmentChart(data: data)),
                        const SizedBox(width: 14),
                        Expanded(child: _SalaryMixChart(data: data)),
                        const SizedBox(width: 14),
                        Expanded(child: _OvertimeCostCenterChart(data: data)),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                _PeriodSummary(data: data),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AccountantPayrollDashboardData data;

  const _Header({required this.data});

  @override
  Widget build(BuildContext context) {
    final latest = data.periods.isEmpty ? null : data.periods.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E9EE)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F6EF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.payments_outlined,
              color: Color(0xFF159957),
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'داشبورد عملیاتی حقوق و دستمزد',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  latest == null
                      ? 'وضعیت حقوق و دستمزد شرکت'
                      : 'اطلاعات تا ${_monthName(latest.month)} ${latest.year}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (latest != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _statusColor(latest.status).withOpacity(.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _statusLabel(latest.status),
                style: TextStyle(
                  color: _statusColor(latest.status),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final AccountantPayrollDashboardData data;
  final bool isMobile;

  const _KpiGrid({required this.data, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _KpiCard(
        title: 'تعداد کارکنان',
        value: _formatNumber(data.totalEmployees),
        unit: 'نفر',
        subtitle: '${_formatNumber(data.activeEmployees)} نفر فعال',
        icon: Icons.groups_rounded,
        iconColor: const Color(0xFF159957),
      ),
      _KpiCard(
        title: 'کل حقوق و مزایا',
        value: _formatMoney(data.totalGrossSalary),
        unit: 'میلیارد ریال',
        subtitle: 'حقوق ناخالص',
        icon: Icons.account_balance_wallet_rounded,
        iconColor: const Color(0xFF1976D2),
      ),
      _KpiCard(
        title: 'بیمه سهم کارفرما',
        value: _formatMoney(data.totalEmployerInsurance),
        unit: 'میلیارد ریال',
        subtitle: 'هزینه بیمه کارفرما',
        icon: Icons.verified_user_rounded,
        iconColor: const Color(0xFF7B3FB5),
      ),
      _KpiCard(
        title: 'هزینه کل حقوق و دستمزد',
        value: _formatMoney(data.totalPayrollCost),
        unit: 'میلیارد ریال',
        subtitle: 'حقوق و مزایا + بیمه کارفرما',
        icon: Icons.payments_rounded,
        iconColor: const Color(0xFFFF8A00),
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i < cards.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 118),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5EBEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
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
              color: iconColor.withOpacity(.09),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 25),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        unit,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DepartmentChart extends StatelessWidget {
  final AccountantPayrollDashboardData data;

  const _DepartmentChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final items = data.departments.take(5).toList();

    final maxValue =
        items.isEmpty ? 1.0 : items.map((e) => e.grossSalary).reduce(math.max);

    return _ChartCard(
      title: 'هزینه حقوق و مزایا به تفکیک واحد سازمانی',
      child:
          items.isEmpty
              ? const _EmptyChart()
              : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final item in items) ...[
                    _HorizontalBar(
                      label: item.department,
                      value: item.grossSalary,
                      maxValue: maxValue,
                    ),
                    const SizedBox(height: 13),
                  ],
                ],
              ),
    );
  }
}

class _HorizontalBar extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;

  const _HorizontalBar({
    required this.label,
    required this.value,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue <= 0 ? 0.0 : value / maxValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_formatMoney(value)} میلیارد',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            minHeight: 11,
            value: ratio.clamp(0.0, 1.0),
            backgroundColor: const Color(0xFFE8EDF2),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2878D4)),
          ),
        ),
      ],
    );
  }
}

class _SalaryMixChart extends StatelessWidget {
  final AccountantPayrollDashboardData data;

  const _SalaryMixChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MixItem(
        title: 'حقوق پایه',
        value: data.totalBaseSalary,
        color: const Color(0xFF2878D4),
      ),
      _MixItem(
        title: 'اضافه‌کاری',
        value: data.totalOvertimeAmount,
        color: const Color(0xFF46A7D8),
      ),
      _MixItem(
        title: 'پاداش',
        value: data.totalBonusAmount,
        color: const Color(0xFFFFA11A),
      ),
      _MixItem(
        title: 'مزایا',
        value: data.totalAllowanceAmount,
        color: const Color(0xFFE74C3C),
      ),
    ];

    final total = items.fold<double>(0, (sum, item) => sum + item.value);

    return _ChartCard(
      title: 'ترکیب حقوق و مزایا',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 175,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(175, 175),
                  painter: _DonutPainter(items: items, total: total),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatMoney(total),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'میلیارد ریال',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 9,
            children: [
              for (final item in items)
                _LegendItem(
                  title: item.title,
                  value: item.value,
                  total: total,
                  color: item.color,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MixItem {
  final String title;
  final double value;
  final Color color;

  const _MixItem({
    required this.title,
    required this.value,
    required this.color,
  });
}

class _DonutPainter extends CustomPainter {
  final List<_MixItem> items;
  final double total;

  _DonutPainter({required this.items, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final radius = math.min(size.width, size.height) / 2 - 10;

    const strokeWidth = 28.0;

    final backgroundPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = const Color(0xFFE8EDF2);

    canvas.drawCircle(center, radius, backgroundPaint);

    if (total <= 0) return;

    double startAngle = -math.pi / 2;

    for (final item in items) {
      if (item.value <= 0) continue;

      final sweep = (item.value / total) * math.pi * 2;

      final paint =
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.butt
            ..color = item.color;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
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
    return oldDelegate.total != total ||
        oldDelegate.items.length != items.length;
  }
}

class _LegendItem extends StatelessWidget {
  final String title;
  final double value;
  final double total;
  final Color color;

  const _LegendItem({
    required this.title,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percent = total <= 0 ? 0 : (value / total) * 100;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$title ${percent.toStringAsFixed(1)}%',
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _OvertimeCostCenterChart extends StatelessWidget {
  final AccountantPayrollDashboardData data;

  const _OvertimeCostCenterChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final items = data.overtimeByCostCenter.take(5).toList();

    final maxValue =
        items.isEmpty
            ? 1.0
            : items.map((e) => e.overtimeAmount).reduce(math.max);

    return _ChartCard(
      title: 'اضافه‌کاری به تفکیک مرکز هزینه (مبلغ)',
      child:
          items.isEmpty
              ? const _EmptyChart()
              : SizedBox(
                height: 220,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final item in items)
                      Expanded(
                        child: _VerticalBar(
                          title: item.title,
                          value: item.overtimeAmount,
                          maxValue: maxValue,
                        ),
                      ),
                  ],
                ),
              ),
    );
  }
}

class _VerticalBar extends StatelessWidget {
  final String title;
  final double value;
  final double maxValue;

  const _VerticalBar({
    required this.title,
    required this.value,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue <= 0 ? 0.0 : value / maxValue;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            _formatMoney(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: ratio.clamp(0.05, 1.0),
                child: Container(
                  width: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFF28A873),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(5),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            title,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
          ),
        ],
      ),
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5EBEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _PeriodSummary extends StatelessWidget {
  final AccountantPayrollDashboardData data;

  const _PeriodSummary({required this.data});

  @override
  Widget build(BuildContext context) {
    final periods = data.periods.take(6).toList();

    if (periods.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5EBEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'خلاصه دوره‌های حقوق و دستمزد',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 44,
              dataRowMaxHeight: 54,
              columns: const [
                DataColumn(label: Text('دوره')),
                DataColumn(label: Text('وضعیت')),
                DataColumn(label: Text('کارکنان')),
                DataColumn(label: Text('حقوق ناخالص')),
                DataColumn(label: Text('حقوق خالص')),
                DataColumn(label: Text('اضافه‌کاری')),
              ],
              rows: [
                for (final period in periods)
                  DataRow(
                    cells: [
                      DataCell(
                        Text('${_monthName(period.month)} ${period.year}'),
                      ),
                      DataCell(Text(_statusLabel(period.status))),
                      DataCell(Text(_formatNumber(period.recordsCount))),
                      DataCell(
                        Text('${_formatMoney(period.grossSalary)} میلیارد'),
                      ),
                      DataCell(
                        Text('${_formatMoney(period.netSalary)} میلیارد'),
                      ),
                      DataCell(
                        Text('${_formatMoney(period.overtimeAmount)} میلیارد'),
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

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 42,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 8),
            Text(
              'اطلاعاتی برای نمایش وجود ندارد',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
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
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE4E8EC)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 46,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'خطا در دریافت اطلاعات حقوق و دستمزد',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatNumber(num value) {
  final text = value.round().toString();

  return text.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
}

String _formatMoney(double value) {
  final billion = value / 1000000000;

  if (billion >= 1000) {
    return billion.toStringAsFixed(0);
  }

  if (billion >= 100) {
    return billion.toStringAsFixed(0);
  }

  if (billion >= 10) {
    return billion.toStringAsFixed(1);
  }

  return billion.toStringAsFixed(2);
}

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
    return 'ماه';
  }

  return months[month - 1];
}

String _statusLabel(String status) {
  switch (status.trim().toLowerCase()) {
    case 'open':
      return 'باز';
    case 'closed':
      return 'بسته';
    case 'approved':
      return 'تأیید شده';
    case 'submitted':
      return 'ارسال شده';
    default:
      return status.isEmpty ? 'نامشخص' : status;
  }
}

Color _statusColor(String status) {
  switch (status.trim().toLowerCase()) {
    case 'open':
      return const Color(0xFF159957);
    case 'closed':
      return const Color(0xFF7A7F87);
    case 'approved':
      return const Color(0xFF1976D2);
    default:
      return const Color(0xFFFF8A00);
  }
}
