import 'package:flutter/material.dart';

class BankingKpiCards extends StatelessWidget {
  const BankingKpiCards({
    super.key,
    required this.totalBankBalance,
    required this.totalCashBalance,
    required this.receivedChecks,
    required this.paidChecks,
  });

  final double totalBankBalance;
  final double totalCashBalance;
  final double receivedChecks;
  final double paidChecks;

  String _money(double value) {
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int count;

        if (constraints.maxWidth >= 1100) {
          count = 4;
        } else if (constraints.maxWidth >= 700) {
          count = 2;
        } else {
          count = 1;
        }

        return GridView.count(
          shrinkWrap: true,
          physics:
          const NeverScrollableScrollPhysics(),
          crossAxisCount: count,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.2,
          children: [
            _KpiCard(
              title: 'مانده کل بانک‌ها',
              value: _money(totalBankBalance),
              icon: Icons.account_balance_rounded,
            ),
            _KpiCard(
              title: 'مانده کل صندوق',
              value: _money(totalCashBalance),
              icon: Icons.payments_rounded,
            ),
            _KpiCard(
              title: 'چک‌های دریافتنی',
              value: _money(receivedChecks),
              icon: Icons.call_received_rounded,
            ),
            _KpiCard(
              title: 'چک‌های پرداختنی',
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color:
              const Color(0xFF1B4332).withOpacity(.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1B4332),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 19,
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