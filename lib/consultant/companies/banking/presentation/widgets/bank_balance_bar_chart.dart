import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/banking_repository.dart';

class BankBalanceBarChart extends StatelessWidget {
  const BankBalanceBarChart({
    super.key,
    required this.accounts,
  });

  final List<BankAccountModel> accounts;

  @override
  Widget build(BuildContext context) {
    final visibleAccounts =
    accounts.take(8).toList();

    return Container(
      width: double.infinity,
      height: 360,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'مانده حساب‌های بانکی',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'مقایسه مانده پایان دوره به تفکیک بانک',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: visibleAccounts.isEmpty
                ? const Center(
              child: Text(
                'داده‌ای برای نمایش نمودار وجود ندارد.',
              ),
            )
                : BarChart(
              BarChartData(
                borderData:
                FlBorderData(show: false),
                gridData: FlGridData(
                  drawVerticalLine: false,
                ),
                titlesData: FlTitlesData(
                  topTitles:
                  const AxisTitles(),
                  rightTitles:
                  const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget:
                          (value, meta) {
                        final index =
                        value.toInt();

                        if (index < 0 ||
                            index >=
                                visibleAccounts
                                    .length) {
                          return const SizedBox();
                        }

                        return Padding(
                          padding:
                          const EdgeInsets.only(
                            top: 8,
                          ),
                          child: Text(
                            visibleAccounts[
                            index]
                                .bankName,
                            style:
                            const TextStyle(
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(
                  visibleAccounts.length,
                      (index) {
                    final account =
                    visibleAccounts[index];

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY:
                          account.closingBalance,
                          width: 22,
                          borderRadius:
                          BorderRadius.circular(
                            7,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}