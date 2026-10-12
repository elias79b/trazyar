import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/company_admin_banking_provider.dart';
import '../../../dashboard/presentation/widgets/company_admin_scaffold.dart';

class CompanyAdminBankingPage
    extends ConsumerWidget {
  const CompanyAdminBankingPage({
    super.key,
  });

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final banking =
    ref.watch(
      companyAdminBankingProvider,
    );

    return CompanyAdminScaffold(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: banking.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) {
            return _ErrorView(
              error: error,
              onRetry: () {
                ref.invalidate(
                  companyAdminBankingProvider,
                );
              },
            );
          },
          data: (data) {
            return _BankingDashboard(
              data: data,
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// DASHBOARD
// ============================================================

class _BankingDashboard
    extends StatelessWidget {
  final CompanyAdminBankingData data;

  const _BankingDashboard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          _buildHeader(),

          const SizedBox(height: 22),

          _buildKpis(),

          const SizedBox(height: 24),

          _buildCharts(),

          const SizedBox(height: 24),

          _buildQuickAccess(),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Text(
                'نقد و بانک',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF17221D),
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'نمای مدیریتی نقدینگی، بانک‌ها، چک‌ها و تعهدات بانکی',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF718078),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7F0),
            borderRadius:
            BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: Color(0xFF167A4A),
              ),
              const SizedBox(width: 7),
              Text(
                '${data.months.last.title} ${data.months.last.year}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF167A4A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // KPI
  // ============================================================

  Widget _buildKpis() {
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            icon:
            Icons.account_balance_wallet_rounded,
            title: 'نقدینگی کل',
            value:
            _money(data.totalLiquidity),
            subtitle:
            'بانک + صندوق + تنخواه',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _KpiCard(
            icon:
            Icons.account_balance_rounded,
            title: 'موجودی بانک',
            value:
            _money(data.bankBalance),
            subtitle:
            '${data.bankAccountCount} حساب بانکی',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _KpiCard(
            icon:
            Icons.account_balance_wallet_outlined,
            title: 'موجودی صندوق',
            value:
            _money(data.cashBalance),
            subtitle:
            '${data.cashBoxCount} صندوق',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _KpiCard(
            icon: Icons.payments_outlined,
            title: 'موجودی تنخواه',
            value:
            _money(data.pettyCashBalance),
            subtitle:
            '${data.pettyCashCount} تنخواه',
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CHARTS
  // ============================================================

  Widget _buildCharts() {
    return Column(
      children: [
        Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Expanded(
              child:
              _buildBankBalanceChart(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child:
              _buildTurnoverChart(),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Expanded(
              child:
              _buildLoanChart(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child:
              _buildChecksChart(),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // CHART 1
  // روند مانده بانک‌ها
  // ============================================================

  Widget _buildBankBalanceChart() {
    final lines =
    <LineChartBarData>[];

    for (
    int bankIndex = 0;
    bankIndex <
        data.bankBalanceSeries.length;
    bankIndex++
    ) {
      final bank =
      data.bankBalanceSeries[
      bankIndex];

      lines.add(
        LineChartBarData(
          spots: List.generate(
            bank.values.length,
                (index) {
              return FlSpot(
                index.toDouble(),
                bank.values[index],
              );
            },
          ),
          isCurved: true,
          barWidth: 2.4,
          color:
          _chartColor(bankIndex),
          dotData: const FlDotData(
            show: true,
          ),
          belowBarData:
          BarAreaData(
            show: false,
          ),
        ),
      );
    }

    return _ChartCard(
      title:
      'روند مانده بانک‌ها (خطی)',
      child: Column(
        children: [
          SizedBox(
            height: 270,
            child: lines.isEmpty
                ? _emptyChart(
              'اطلاعات مانده بانک‌ها موجود نیست',
            )
                : LineChart(
              LineChartData(
                minY: 0,
                gridData:
                FlGridData(
                  show: true,
                  drawVerticalLine:
                  false,
                  horizontalInterval:
                  _interval(
                    _maxBankValue(),
                  ),
                ),
                borderData:
                FlBorderData(
                  show: false,
                ),
                titlesData:
                FlTitlesData(
                  topTitles:
                  const AxisTitles(
                    sideTitles:
                    SideTitles(
                      showTitles: false,
                    ),
                  ),
                  rightTitles:
                  const AxisTitles(
                    sideTitles:
                    SideTitles(
                      showTitles: false,
                    ),
                  ),
                  bottomTitles:
                  AxisTitles(
                    sideTitles:
                    SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 1,
                      getTitlesWidget:
                          (value, meta) {
                        final index =
                        value.toInt();

                        if (index <
                            0 ||
                            index >=
                                data.months.length) {
                          return const SizedBox();
                        }

                        return Padding(
                          padding:
                          const EdgeInsets.only(
                            top: 7,
                          ),
                          child:
                          Text(
                            data.months[index]
                                .title,
                            style:
                            const TextStyle(
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles:
                  AxisTitles(
                    sideTitles:
                    SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget:
                          (value, meta) {
                        return Text(
                          _compact(
                            value,
                          ),
                          style:
                          const TextStyle(
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData:
                lines,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment:
            WrapAlignment.center,
            spacing: 14,
            runSpacing: 7,
            children:
            List.generate(
              data.bankBalanceSeries
                  .length,
                  (index) {
                return _LegendItem(
                  color:
                  _chartColor(index),
                  label: data
                      .bankBalanceSeries[
                  index]
                      .bankName,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CHART 2
  // گردش بدهکار و بستانکار
  // ============================================================

  Widget _buildTurnoverChart() {
    double maxValue = 0;

    for (
    int i = 0;
    i < data.debitValues.length;
    i++
    ) {
      if (data.debitValues[i] >
          maxValue) {
        maxValue =
        data.debitValues[i];
      }

      if (data.creditValues[i] >
          maxValue) {
        maxValue =
        data.creditValues[i];
      }
    }

    return _ChartCard(
      title:
      'گردش بدهکار و بستانکار (ستونی گروهی)',
      child: Column(
        children: [
          SizedBox(
            height: 270,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: maxValue == 0
                    ? 100
                    : maxValue * 1.15,
                gridData:
                FlGridData(
                  show: true,
                  drawVerticalLine:
                  false,
                ),
                borderData:
                FlBorderData(
                  show: false,
                ),
                titlesData:
                FlTitlesData(
                  topTitles:
                  const AxisTitles(
                    sideTitles:
                    SideTitles(
                      showTitles: false,
                    ),
                  ),
                  rightTitles:
                  const AxisTitles(
                    sideTitles:
                    SideTitles(
                      showTitles: false,
                    ),
                  ),
                  bottomTitles:
                  AxisTitles(
                    sideTitles:
                    SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget:
                          (value, meta) {
                        final index =
                        value.toInt();

                        if (index <
                            0 ||
                            index >=
                                data.months.length) {
                          return const SizedBox();
                        }

                        return Padding(
                          padding:
                          const EdgeInsets.only(
                            top: 7,
                          ),
                          child: Text(
                            data.months[index]
                                .title,
                            style:
                            const TextStyle(
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles:
                  AxisTitles(
                    sideTitles:
                    SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget:
                          (value, meta) {
                        return Text(
                          _compact(
                            value,
                          ),
                          style:
                          const TextStyle(
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups:
                List.generate(
                  data.months.length,
                      (index) {
                    return BarChartGroupData(
                      x: index,
                      barsSpace: 4,
                      barRods: [
                        BarChartRodData(
                          toY:
                          data.debitValues[
                          index],
                          width: 9,
                          color:
                          const Color(
                            0xFF3978D5,
                          ),
                          borderRadius:
                          BorderRadius.zero,
                        ),
                        BarChartRodData(
                          toY:
                          data.creditValues[
                          index],
                          width: 9,
                          color:
                          const Color(
                            0xFF5DAE72,
                          ),
                          borderRadius:
                          BorderRadius.zero,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              _LegendItem(
                color:
                Color(0xFF3978D5),
                label:
                'گردش بدهکار',
              ),
              SizedBox(width: 18),
              _LegendItem(
                color:
                Color(0xFF5DAE72),
                label:
                'گردش بستانکار',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CHART 3
  // روند بدهی بانکی
  // ============================================================

  Widget _buildLoanChart() {
    return _ChartCard(
      title:
      'روند بدهی بانکی (خطی)',
      child: SizedBox(
        height: 310,
        child: !data.hasLoanHistory
            ? _emptyChartWithDescription(
          icon:
          Icons.timeline_outlined,
          title:
          'تاریخچه ماهانه بدهی بانکی موجود نیست',
          description:
          'در حال حاضر مانده وام‌ها در Supabase به‌صورت فعلی ذخیره شده است و تاریخچه ماهانه ندارد.',
        )
            : const SizedBox(),
      ),
    );
  }

  // ============================================================
  // CHART 4
  // چک‌های دریافتی و پرداختی
  // ============================================================

  Widget _buildChecksChart() {
    double maxValue = 0;

    for (
    int i = 0;
    i < data.receivedCheckValues.length;
    i++
    ) {
      if (data.receivedCheckValues[i] >
          maxValue) {
        maxValue =
        data.receivedCheckValues[i];
      }

      if (data.paidCheckValues[i] >
          maxValue) {
        maxValue =
        data.paidCheckValues[i];
      }
    }

    return _ChartCard(
      title:
      'روند چک‌های دریافتی و پرداختی (ستونی گروهی)',
      child: Column(
        children: [
          SizedBox(
            height: 270,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: maxValue == 0
                    ? 100
                    : maxValue * 1.15,
                gridData:
                FlGridData(
                  show: true,
                  drawVerticalLine:
                  false,
                ),
                borderData:
                FlBorderData(
                  show: false,
                ),
                titlesData:
                FlTitlesData(
                  topTitles:
                  const AxisTitles(
                    sideTitles:
                    SideTitles(
                      showTitles: false,
                    ),
                  ),
                  rightTitles:
                  const AxisTitles(
                    sideTitles:
                    SideTitles(
                      showTitles: false,
                    ),
                  ),
                  bottomTitles:
                  AxisTitles(
                    sideTitles:
                    SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget:
                          (value, meta) {
                        final index =
                        value.toInt();

                        if (index <
                            0 ||
                            index >=
                                data.months.length) {
                          return const SizedBox();
                        }

                        return Padding(
                          padding:
                          const EdgeInsets.only(
                            top: 7,
                          ),
                          child: Text(
                            data.months[index]
                                .title,
                            style:
                            const TextStyle(
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles:
                  AxisTitles(
                    sideTitles:
                    SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget:
                          (value, meta) {
                        return Text(
                          _compact(
                            value,
                          ),
                          style:
                          const TextStyle(
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups:
                List.generate(
                  data.months.length,
                      (index) {
                    return BarChartGroupData(
                      x: index,
                      barsSpace: 4,
                      barRods: [
                        BarChartRodData(
                          toY:
                          data.receivedCheckValues[
                          index],
                          width: 9,
                          color:
                          const Color(
                            0xFF3978D5,
                          ),
                          borderRadius:
                          BorderRadius.zero,
                        ),
                        BarChartRodData(
                          toY:
                          data.paidCheckValues[
                          index],
                          width: 9,
                          color:
                          const Color(
                            0xFFF39A27,
                          ),
                          borderRadius:
                          BorderRadius.zero,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              _LegendItem(
                color:
                Color(0xFF3978D5),
                label:
                'چک‌های دریافتی',
              ),
              SizedBox(width: 18),
              _LegendItem(
                color:
                Color(0xFFF39A27),
                label:
                'چک‌های پرداختی',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK ACCESS
  // ============================================================

  Widget _buildQuickAccess() {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon:
            Icons.account_balance_outlined,
            title:
            'حساب‌های بانکی',
            route:
            '/company-admin/banking/accounts',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickAction(
            icon:
            Icons.account_balance_wallet_outlined,
            title:
            'صندوق‌ها',
            route:
            '/company-admin/banking/cash-boxes',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickAction(
            icon:
            Icons.receipt_long_outlined,
            title:
            'چک‌ها',
            route:
            '/company-admin/banking/received-checks',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickAction(
            icon:
            Icons.bar_chart_outlined,
            title:
            'گزارش‌های نقد و بانک',
            route:
            '/company-admin/banking/reports',
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  double _maxBankValue() {
    double max = 0;

    for (final bank
    in data.bankBalanceSeries) {
      for (final value
      in bank.values) {
        if (value > max) {
          max = value;
        }
      }
    }

    return max;
  }
}

// ============================================================
// KPI CARD
// ============================================================

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const _KpiCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color:
          const Color(0xFFE2E8E5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration:
            BoxDecoration(
              color:
              const Color(0xFFEAF7F0),
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color:
              const Color(0xFF167A4A),
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                  const TextStyle(
                    fontSize: 11,
                    color:
                    Color(0xFF718078),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w800,
                    color:
                    Color(0xFF17221D),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style:
                  const TextStyle(
                    fontSize: 9,
                    color:
                    Color(0xFF718078),
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
// CHART CARD
// ============================================================

class _ChartCard
    extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.fromLTRB(
        18,
        16,
        18,
        14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(15),
        border: Border.all(
          color:
          const Color(0xFFE2E8E5),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
            const TextStyle(
              fontSize: 14,
              fontWeight:
              FontWeight.w800,
              color:
              Color(0xFF17221D),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ============================================================
// LEGEND
// ============================================================

class _LegendItem
    extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({
    required this.label,
    required this.color,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Row(
      mainAxisSize:
      MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration:
          BoxDecoration(
            color: color,
            borderRadius:
            BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style:
          const TextStyle(
            fontSize: 10,
            color:
            Color(0xFF4F5C55),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// QUICK ACTION
// ============================================================

class _QuickAction
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String route;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.route,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Material(
      color: Colors.white,
      borderRadius:
      BorderRadius.circular(13),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(13),
        onTap: () {
          context.go(route);
        },
        child: Container(
          padding:
          const EdgeInsets.all(15),
          decoration:
          BoxDecoration(
            borderRadius:
            BorderRadius.circular(13),
            border: Border.all(
              color:
              const Color(0xFFE2E8E5),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color:
                const Color(0xFF167A4A),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style:
                  const TextStyle(
                    fontSize: 12,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    Color(0xFF17221D),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// EMPTY CHART
// ============================================================

Widget _emptyChart(
    String message,
    ) {
  return Center(
    child: Text(
      message,
      textAlign:
      TextAlign.center,
      style:
      const TextStyle(
        fontSize: 12,
        color:
        Color(0xFF718078),
      ),
    ),
  );
}

Widget _emptyChartWithDescription({
  required IconData icon,
  required String title,
  required String description,
}) {
  return Center(
    child: Padding(
      padding:
      const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 42,
            color:
            const Color(0xFF718078),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign:
            TextAlign.center,
            style:
            const TextStyle(
              fontSize: 13,
              fontWeight:
              FontWeight.w800,
              color:
              Color(0xFF17221D),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            description,
            textAlign:
            TextAlign.center,
            style:
            const TextStyle(
              fontSize: 11,
              color:
              Color(0xFF718078),
            ),
          ),
        ],
      ),
    ),
  );
}

// ============================================================
// ERROR
// ============================================================

class _ErrorView
    extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(30),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 14),
            const Text(
              'خطا در دریافت اطلاعات نقد و بانک',
              style:
              TextStyle(
                fontSize: 16,
                fontWeight:
                FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
                fontSize: 11,
                color:
                Color(0xFF718078),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text(
                'تلاش مجدد',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// COLORS
// ============================================================

Color _chartColor(
    int index,
    ) {
  const colors = [
    Color(0xFF3978D5),
    Color(0xFF5DAE72),
    Color(0xFFF39A27),
    Color(0xFFE04B4B),
    Color(0xFF8B5FBF),
    Color(0xFF26A6A1),
  ];

  return colors[
  index % colors.length];
}

// ============================================================
// FORMAT
// ============================================================

String _money(
    double value,
    ) {
  return '${_number(value)} ریال';
}

String _number(
    double value,
    ) {
  final raw =
  value.round().toString();

  final result =
  StringBuffer();

  for (
  int i = 0;
  i < raw.length;
  i++
  ) {
    if (i > 0 &&
        (raw.length - i) % 3 == 0) {
      result.write(',');
    }

    result.write(raw[i]);
  }

  return result.toString();
}

String _compact(
    double value,
    ) {
  if (value >= 1000000000) {
    return '${(value / 1000000000).toStringAsFixed(1)}B';
  }

  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }

  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(0)}K';
  }

  return value.toStringAsFixed(0);
}

double _interval(
    double max,
    ) {
  if (max <= 0) {
    return 1;
  }

  return max / 4;
}