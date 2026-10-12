
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarazyar/company_admin/dashboard/presentation/widgets/company_admin_scaffold.dart';
import 'package:tarazyar/company_admin/payroll/application/company_admin_payroll_dashboard_provider.dart';

const _pageBackground = Color(0xfff5f7fb);
const _borderColor = Color(0xffe5e7eb);
const _textSecondary = Color(0xff64748b);
const _primaryColor = Color(0xff2563eb);

class CompanyAdminPayrollDashboardPage extends ConsumerWidget {
const CompanyAdminPayrollDashboardPage({super.key});

@override
Widget build(BuildContext context, WidgetRef ref) {
final payrollState = ref.watch(companyAdminPayrollDashboardProvider);

return payrollState.when(
loading: () => const CompanyAdminScaffold(
child: Scaffold(
backgroundColor: _pageBackground,
body: Center(child: CircularProgressIndicator()),
),
),
error: (error, stackTrace) => CompanyAdminScaffold(
child: Scaffold(
backgroundColor: _pageBackground,
body: Center(
child: Padding(
padding: const EdgeInsets.all(24),
child: _ErrorState(error: error),
),
),
),
),
data: (data) => CompanyAdminScaffold(
child: CompanyAdminPayrollDashboardView(
data: data,
onRefresh: () async {
ref.invalidate(companyAdminPayrollDashboardProvider);
await ref.read(companyAdminPayrollDashboardProvider.future);
},
),
),
);
}
}

class CompanyAdminPayrollDashboardView extends StatelessWidget {
final CompanyAdminPayrollDashboardData data;
final Future<void> Function() onRefresh;

const CompanyAdminPayrollDashboardView({
super.key,
required this.data,
required this.onRefresh,
});

@override
Widget build(BuildContext context) {
final monthly = data.monthly;

return Directionality(
textDirection: TextDirection.rtl,
child: Container(
color: _pageBackground,
child: SafeArea(
child: RefreshIndicator(
onRefresh: onRefresh,
child: SingleChildScrollView(
physics: const AlwaysScrollableScrollPhysics(),
padding: const EdgeInsets.all(20),
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
_Header(data: data),
const SizedBox(height: 20),
if (monthly.isEmpty)
_EmptyState(year: data.currentJalaliYear)
else ...[
_SummaryCards(monthly: monthly),
const SizedBox(height: 20),
_ChartCard(
title: 'روند مبلغ اضافه‌کاری',
subtitle:
'مقایسه مبلغ اضافه‌کاری در دوره‌های تأیید نهایی',
height: 310,
child: _OvertimeLineChart(monthly: monthly),
),
const SizedBox(height: 18),
_ChartCard(
title: 'مقایسه هزینه مراکز هزینه',
subtitle:
'هزینه ثبت‌شده برای مراکز هزینه در دوره‌های تأیید نهایی',
height: 350,
child: _CostCenterBarChart(monthly: monthly),
),
const SizedBox(height: 18),
LayoutBuilder(
builder: (context, constraints) {
final perCapita = _ChartCard(
title: 'روند هزینه سرانه کارکنان',
subtitle:
'هزینه کل حقوق و دستمزد به ازای هر نفر',
height: 320,
child: _PerCapitaLineChart(monthly: monthly),
);

final employees = _ChartCard(
title: 'روند تعداد کارکنان',
subtitle:
'تعداد کارکنان دارای رکورد حقوق در هر دوره',
height: 320,
child: _EmployeeCountLineChart(monthly: monthly),
);

if (constraints.maxWidth < 900) {
return Column(
children: [
perCapita,
const SizedBox(height: 18),
employees,
],
);
}

return Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Expanded(child: perCapita),
const SizedBox(width: 18),
Expanded(child: employees),
],
);
},
),
const SizedBox(height: 18),
_ChartCard(
title: 'روند کل هزینه حقوق و دستمزد',
subtitle: 'حقوق ناخالص به‌علاوه بیمه سهم کارفرما',
height: 320,
child: _TotalPayrollLineChart(monthly: monthly),
),
],
],
),
),
),
),
),
);
}
}

// ============================================================
// HEADER
// ============================================================

class _Header extends StatelessWidget {
final CompanyAdminPayrollDashboardData data;

const _Header({required this.data});

@override
Widget build(BuildContext context) {
final latest = data.monthly.isEmpty ? null : data.monthly.last;

return Container(
padding: const EdgeInsets.all(22),
decoration: _cardDecoration(),
child: LayoutBuilder(
builder: (context, constraints) {
final compact = constraints.maxWidth < 600;

final heading = Row(
children: [
Container(
width: 54,
height: 54,
decoration: BoxDecoration(
color: const Color(0xffeef6ff),
borderRadius: BorderRadius.circular(15),
),
child: const Icon(
Icons.payments_outlined,
color: Color(0xff1677d2),
size: 29,
),
),
const SizedBox(width: 14),
const Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'داشبورد حقوق و دستمزد',
style: TextStyle(
fontSize: 20,
fontWeight: FontWeight.w800,
),
),
SizedBox(height: 5),
Text(
'پایش هزینه نیروی انسانی و روند حقوق و دستمزد',
style: TextStyle(
color: _textSecondary,
fontSize: 12,
),
),
],
),
),
],
);

final period = latest == null
? const SizedBox.shrink()
    : Container(
padding: const EdgeInsets.symmetric(
horizontal: 14,
vertical: 10,
),
decoration: BoxDecoration(
color: const Color(0xfff0fdf4),
borderRadius: BorderRadius.circular(12),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'آخرین دوره تأییدشده',
style: TextStyle(
fontSize: 11,
color: _textSecondary,
),
),
const SizedBox(height: 4),
Text(
latest.period.label,
style: const TextStyle(
fontWeight: FontWeight.w800,
color: Color(0xff15803d),
),
),
],
),
);

if (compact) {
return Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
heading,
if (latest != null) ...[
const SizedBox(height: 16),
Align(
alignment: Alignment.centerRight,
child: period,
),
],
],
);
}

return Row(
children: [
Expanded(child: heading),
if (latest != null) ...[
const SizedBox(width: 16),
period,
],
],
);
},
),
);
}
}

// ============================================================
// SUMMARY CARDS
// ============================================================

class _SummaryCards extends StatelessWidget {
final List<PayrollDashboardMonthlyData> monthly;

const _SummaryCards({required this.monthly});

@override
Widget build(BuildContext context) {
final latest = monthly.last;

return LayoutBuilder(
builder: (context, constraints) {
final columns = constraints.maxWidth >= 1100
? 4
    : constraints.maxWidth >= 600
? 2
    : 1;

final spacing = 14.0;
final width =
(constraints.maxWidth - (spacing * (columns - 1))) /
columns;

final cards = [
_SummaryCard(
width: width,
title: 'کل هزینه حقوق',
value: _money(latest.totalPayrollCost),
icon: Icons.account_balance_wallet_outlined,
iconColor: const Color(0xff2563eb),
),
_SummaryCard(
width: width,
title: 'تعداد کارکنان',
value: _number(latest.employeeCount),
icon: Icons.groups_outlined,
iconColor: const Color(0xff059669),
),
_SummaryCard(
width: width,
title: 'هزینه سرانه',
value: _money(latest.perCapitaCost),
icon: Icons.person_outline,
iconColor: const Color(0xff7c3aed),
),
_SummaryCard(
width: width,
title: 'مبلغ اضافه‌کاری',
value: _money(latest.overtimeAmount),
icon: Icons.more_time_outlined,
iconColor: const Color(0xffea580c),
),
];

return Wrap(
spacing: spacing,
runSpacing: spacing,
children: cards,
);
},
);
}
}

class _SummaryCard extends StatelessWidget {
final double width;
final String title;
final String value;
final IconData icon;
final Color iconColor;

const _SummaryCard({
required this.width,
required this.title,
required this.value,
required this.icon,
required this.iconColor,
});

@override
Widget build(BuildContext context) {
return SizedBox(
width: width,
child: Container(
constraints: const BoxConstraints(minHeight: 100),
padding: const EdgeInsets.all(17),
decoration: _cardDecoration(),
child: Row(
children: [
Container(
width: 44,
height: 44,
decoration: BoxDecoration(
color: iconColor.withOpacity(.10),
borderRadius: BorderRadius.circular(12),
),
child: Icon(icon, color: iconColor),
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisAlignment: MainAxisAlignment.center,
children: [
Text(
title,
style: const TextStyle(
fontSize: 12,
color: _textSecondary,
),
),
const SizedBox(height: 7),
Text(
value,
maxLines: 2,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
fontSize: 17,
fontWeight: FontWeight.w800,
),
),
],
),
),
],
),
),
);
}
}

// ============================================================
// CHART CARD
// ============================================================

class _ChartCard extends StatelessWidget {
final String title;
final String subtitle;
final double height;
final Widget child;

const _ChartCard({
required this.title,
required this.subtitle,
required this.height,
required this.child,
});

@override
Widget build(BuildContext context) {
return Container(
height: height,
padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
decoration: _cardDecoration(),
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
Text(
title,
style: const TextStyle(
fontSize: 15,
fontWeight: FontWeight.w800,
),
),
const SizedBox(height: 4),
Text(
subtitle,
style: const TextStyle(
fontSize: 11,
color: _textSecondary,
),
),
const SizedBox(height: 12),
Expanded(child: child),
],
),
);
}
}

// ============================================================
// LINE CHARTS
// ============================================================

class _OvertimeLineChart extends StatelessWidget {
final List<PayrollDashboardMonthlyData> monthly;

const _OvertimeLineChart({required this.monthly});

@override
Widget build(BuildContext context) {
return _buildLineChart(
monthly: monthly,
valueBuilder: (item) => item.overtimeAmount,
color: const Color(0xff1677d2),
tooltipBuilder: (item) => _money(item.overtimeAmount),
leftFormatter: _compactMoney,
);
}
}

class _TotalPayrollLineChart extends StatelessWidget {
final List<PayrollDashboardMonthlyData> monthly;

const _TotalPayrollLineChart({required this.monthly});

@override
Widget build(BuildContext context) {
return _buildLineChart(
monthly: monthly,
valueBuilder: (item) => item.totalPayrollCost,
color: const Color(0xff2563eb),
tooltipBuilder: (item) => _money(item.totalPayrollCost),
leftFormatter: _compactMoney,
);
}
}

class _PerCapitaLineChart extends StatelessWidget {
final List<PayrollDashboardMonthlyData> monthly;

const _PerCapitaLineChart({required this.monthly});

@override
Widget build(BuildContext context) {
return _buildLineChart(
monthly: monthly,
valueBuilder: (item) => item.perCapitaCost,
color: const Color(0xff7c3aed),
tooltipBuilder: (item) => _money(item.perCapitaCost),
leftFormatter: _compactMoney,
);
}
}

class _EmployeeCountLineChart extends StatelessWidget {
final List<PayrollDashboardMonthlyData> monthly;

const _EmployeeCountLineChart({required this.monthly});

@override
Widget build(BuildContext context) {
return _buildLineChart(
monthly: monthly,
valueBuilder: (item) => item.employeeCount.toDouble(),
color: const Color(0xff059669),
tooltipBuilder: (item) => '${_number(item.employeeCount)} نفر',
leftFormatter: (value) => _number(value.round()),
);
}
}

Widget _buildLineChart({
required List<PayrollDashboardMonthlyData> monthly,
required double Function(PayrollDashboardMonthlyData item) valueBuilder,
required Color color,
required String Function(PayrollDashboardMonthlyData item) tooltipBuilder,
required String Function(double value) leftFormatter,
}) {
if (monthly.isEmpty) {
return const Center(child: Text('اطلاعاتی برای نمایش وجود ندارد.'));
}

final spots = <FlSpot>[
for (var i = 0; i < monthly.length; i++)
FlSpot(
i.toDouble(),
math.max(0, valueBuilder(monthly[i])),
),
];

final maxValue = _maxValue(spots.map((spot) => spot.y));
final chartMax = maxValue <= 0 ? 1.0 : maxValue * 1.2;

return LineChart(
LineChartData(
minX: 0,
maxX: math.max(1, monthly.length - 1).toDouble(),
minY: 0,
maxY: chartMax,
gridData: _gridData(maxValue),
borderData: FlBorderData(show: false),
lineTouchData: LineTouchData(
enabled: true,
touchTooltipData: LineTouchTooltipData(
getTooltipItems: (spots) => spots.map((spot) {
final index = spot.x.round();
if (index < 0 || index >= monthly.length) {
return null;
}

final item = monthly[index];
return LineTooltipItem(
'${item.period.label}\n${tooltipBuilder(item)}',
const TextStyle(
color: Colors.white,
fontWeight: FontWeight.w700,
fontSize: 11,
),
);
}).toList(),
),
),
titlesData: _titlesData(
monthly: monthly,
maxValue: chartMax,
leftFormatter: leftFormatter,
),
lineBarsData: [
LineChartBarData(
spots: spots,
isCurved: true,
barWidth: 3,
color: color,
isStrokeCapRound: true,
dotData: FlDotData(
show: true,
getDotPainter: (spot, percent, barData, index) {
return FlDotCirclePainter(
radius: 4,
color: color,
strokeWidth: 2,
strokeColor: Colors.white,
);
},
),
belowBarData: BarAreaData(
show: true,
color: color.withOpacity(.07),
),
),
],
),
);
}

// ============================================================
// COST CENTER BAR CHART
// ============================================================

class _CostCenterBarChart extends StatelessWidget {
final List<PayrollDashboardMonthlyData> monthly;

const _CostCenterBarChart({required this.monthly});

@override
Widget build(BuildContext context) {
final centerNames = <String>{};

for (final item in monthly) {
centerNames.addAll(item.costCenterCosts.keys);
}

final centers = centerNames.toList()
..sort((a, b) {
final aTotal = monthly.fold<double>(
0,
(sum, item) => sum + (item.costCenterCosts[a] ?? 0),
);
final bTotal = monthly.fold<double>(
0,
(sum, item) => sum + (item.costCenterCosts[b] ?? 0),
);
return bTotal.compareTo(aTotal);
});

final visibleCenters = centers.take(6).toList();

if (visibleCenters.isEmpty) {
return const Center(
child: Text(
'اطلاعات مرکز هزینه برای دوره‌های تأییدشده وجود ندارد.',
textAlign: TextAlign.center,
),
);
}

final maxValue = _maxValue([
for (final item in monthly)
for (final center in visibleCenters)
item.costCenterCosts[center] ?? 0,
]);

final chartMax = maxValue <= 0 ? 1.0 : maxValue * 1.2;

return BarChart(
BarChartData(
minY: 0,
maxY: chartMax,
gridData: _gridData(chartMax),
borderData: FlBorderData(show: false),
barTouchData: BarTouchData(
enabled: true,
touchTooltipData: BarTouchTooltipData(
getTooltipItem: (group, groupIndex, rod, rodIndex) {
if (groupIndex < 0 ||
groupIndex >= monthly.length ||
rodIndex < 0 ||
rodIndex >= visibleCenters.length) {
return null;
}

final center = visibleCenters[rodIndex];

return BarTooltipItem(
'$center\n${_money(rod.toY)}',
const TextStyle(
color: Colors.white,
fontWeight: FontWeight.w700,
fontSize: 11,
),
);
},
),
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
reservedSize: 58,
interval: _safeInterval(chartMax),
getTitlesWidget: (value, meta) => Text(
_compactMoney(value),
style: const TextStyle(
fontSize: 9,
color: _textSecondary,
),
),
),
),
bottomTitles: AxisTitles(
sideTitles: SideTitles(
showTitles: true,
reservedSize: 38,
getTitlesWidget: (value, meta) {
final index = value.toInt();

if (index < 0 || index >= monthly.length) {
return const SizedBox.shrink();
}

return SideTitleWidget(
axisSide: meta.axisSide,
space: 7,
child: Text(
monthly[index].period.shortLabel,
style: const TextStyle(
fontSize: 9,
color: _textSecondary,
),
),
);
},
),
),
),
barGroups: [
for (var i = 0; i < monthly.length; i++)
BarChartGroupData(
x: i,
barsSpace: 3,
barRods: [
for (var j = 0; j < visibleCenters.length; j++)
BarChartRodData(
toY: math.max(
0,
monthly[i].costCenterCosts[visibleCenters[j]] ?? 0,
),
width: visibleCenters.length <= 3 ? 14 : 9,
borderRadius: BorderRadius.circular(3),
),
],
),
],
),
);
}
}

// ============================================================
// EMPTY / ERROR STATES
// ============================================================

class _EmptyState extends StatelessWidget {
final int year;

const _EmptyState({required this.year});

@override
Widget build(BuildContext context) {
return Container(
padding: const EdgeInsets.symmetric(vertical: 65, horizontal: 24),
decoration: _cardDecoration(),
child: Column(
children: [
const Icon(
Icons.analytics_outlined,
size: 55,
color: Color(0xff94a3b8),
),
const SizedBox(height: 16),
const Text(
'هنوز اطلاعات حقوق و دستمزد تأیید نهایی نشده است.',
textAlign: TextAlign.center,
style: TextStyle(
fontWeight: FontWeight.w800,
fontSize: 16,
),
),
const SizedBox(height: 8),
Text(
'دوره‌های تأیید نهایی‌شده در داشبورد مدیریتی نمایش داده می‌شوند.',
textAlign: TextAlign.center,
style: const TextStyle(color: _textSecondary),
),
const SizedBox(height: 8),
Text(
'سال جاری: ${_number(year)}',
style: const TextStyle(
color: _textSecondary,
fontSize: 12,
),
),
],
),
);
}
}

class _ErrorState extends StatelessWidget {
final Object error;

const _ErrorState({required this.error});

@override
Widget build(BuildContext context) {
return Container(
constraints: const BoxConstraints(maxWidth: 600),
padding: const EdgeInsets.all(28),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(18),
border: Border.all(color: const Color(0xfffecaca)),
),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
const Icon(
Icons.error_outline,
color: Color(0xffdc2626),
size: 52,
),
const SizedBox(height: 15),
const Text(
'خطا در دریافت اطلاعات حقوق و دستمزد',
textAlign: TextAlign.center,
style: TextStyle(
fontWeight: FontWeight.w800,
fontSize: 16,
),
),
const SizedBox(height: 10),
Text(
error.toString(),
textAlign: TextAlign.center,
style: const TextStyle(
color: _textSecondary,
fontSize: 13,
),
),
],
),
);
}
}

// ============================================================
// CHART HELPERS
// ============================================================

FlGridData _gridData(double maxValue) {
return FlGridData(
show: true,
drawVerticalLine: false,
horizontalInterval: _safeInterval(maxValue),
getDrawingHorizontalLine: (value) => const FlLine(
color: _borderColor,
strokeWidth: 1,
),
);
}

FlTitlesData _titlesData({
required List<PayrollDashboardMonthlyData> monthly,
required double maxValue,
required String Function(double value) leftFormatter,
}) {
return FlTitlesData(
topTitles: const AxisTitles(
sideTitles: SideTitles(showTitles: false),
),
rightTitles: const AxisTitles(
sideTitles: SideTitles(showTitles: false),
),
leftTitles: AxisTitles(
sideTitles: SideTitles(
showTitles: true,
reservedSize: 58,
interval: _safeInterval(maxValue),
getTitlesWidget: (value, meta) => Text(
leftFormatter(value),
style: const TextStyle(
fontSize: 9,
color: _textSecondary,
),
),
),
),
bottomTitles: AxisTitles(
sideTitles: SideTitles(
showTitles: true,
reservedSize: 38,
getTitlesWidget: (value, meta) {
final index = value.round();

if (index < 0 || index >= monthly.length) {
return const SizedBox.shrink();
}

return SideTitleWidget(
axisSide: meta.axisSide,
space: 7,
child: Text(
monthly[index].period.shortLabel,
style: const TextStyle(
fontSize: 9,
color: _textSecondary,
),
),
);
},
),
),
);
}

double _maxValue(Iterable<double> values) {
var result = 0.0;

for (final value in values) {
if (value.isFinite) {
result = math.max(result, value);
}
}

return result;
}

double _safeInterval(double maxValue) {
if (maxValue <= 0 || !maxValue.isFinite) return 1;

final interval = maxValue / 4;

if (interval <= 1) return 1;
if (interval <= 10) return interval.ceilToDouble();
if (interval <= 100) return (interval / 10).ceil() * 10;
if (interval <= 1000) return (interval / 100).ceil() * 100;

return (interval / 1000).ceil() * 1000;
}

BoxDecoration _cardDecoration() {
return BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(16),
border: Border.all(color: _borderColor),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(.025),
blurRadius: 12,
offset: const Offset(0, 4),
),
],
);
}

// ============================================================
// NUMBER FORMATTERS
// ============================================================

String _money(double value) => '${_formatNumber(value.round())} ریال';

String _compactMoney(double value) {
if (!value.isFinite) return '۰';

if (value.abs() >= 1000000000) {
return '${_formatDecimal(value / 1000000000)}B';
}

if (value.abs() >= 1000000) {
return '${_formatDecimal(value / 1000000)}M';
}

if (value.abs() >= 1000) {
return '${_formatDecimal(value / 1000)}K';
}

return _formatNumber(value.round());
}

String _number(int value) => _formatNumber(value);

String _formatDecimal(double value) {
if (value == value.roundToDouble()) {
return _formatNumber(value.round());
}

return value.toStringAsFixed(1).replaceAll('.', '/');
}

String _formatNumber(int value) {
final formatted = value.toString().replaceAllMapped(
RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
(match) => '${match.group(1)},',
);

return formatted
    .replaceAll('0', '۰')
    .replaceAll('1', '۱')
    .replaceAll('2', '۲')
    .replaceAll('3', '۳')
    .replaceAll('4', '۴')
    .replaceAll('5', '۵')
    .replaceAll('6', '۶')
    .replaceAll('7', '۷')
    .replaceAll('8', '۸')
    .replaceAll('9', '۹');
}
