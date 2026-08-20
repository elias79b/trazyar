import 'package:flutter/material.dart';

class BankLoanKpiCards extends StatelessWidget {
  const BankLoanKpiCards({
    super.key,
    required this.loanCount,
    required this.totalPrincipal,
    required this.totalRemaining,
    required this.totalMonthlyInstallments,
  });

  final int loanCount;
  final double totalPrincipal;
  final double totalRemaining;
  final double totalMonthlyInstallments;

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
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: count,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.2,
          children: [
            _LoanKpiCard(
              title: 'تعداد تسهیلات',
              value: loanCount.toString(),
              icon: Icons.request_quote_rounded,
            ),
            _LoanKpiCard(
              title: 'مبلغ اولیه تسهیلات',
              value: _money(totalPrincipal),
              icon: Icons.account_balance_wallet_rounded,
            ),
            _LoanKpiCard(
              title: 'مانده تسهیلات',
              value: _money(totalRemaining),
              icon: Icons.money_rounded,
            ),
            _LoanKpiCard(
              title: 'مجموع اقساط ماهانه',
              value: _money(totalMonthlyInstallments),
              icon: Icons.calendar_month_rounded,
            ),
          ],
        );
      },
    );
  }
}

class _LoanKpiCard extends StatelessWidget {
  const _LoanKpiCard({
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
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1B4332).withOpacity(.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF1B4332)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
