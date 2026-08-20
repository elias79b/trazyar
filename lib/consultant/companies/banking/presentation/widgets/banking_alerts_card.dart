import 'package:flutter/material.dart';

import '../../data/banking_repository.dart';

class BankingAlertsCard extends StatelessWidget {
  const BankingAlertsCard({super.key, required this.data});

  final BankingDashboardData data;

  @override
  Widget build(BuildContext context) {
    final alerts = <_BankingAlert>[];

    for (final account in data.bankAccounts) {
      if (account.discrepancy != 0) {
        alerts.add(
          _BankingAlert(
            title: 'مغایرت حساب ${account.bankName}',
            description:
                'مبلغ مغایرت: ${account.discrepancy.toStringAsFixed(0)}',
            icon: Icons.warning_amber_rounded,
            color: Colors.orange,
          ),
        );
      }
    }

    for (final cash in data.cashBoxes) {
      if (cash.discrepancy != 0) {
        alerts.add(
          _BankingAlert(
            title: 'مغایرت ${cash.boxName}',
            description: 'مبلغ مغایرت: ${cash.discrepancy.toStringAsFixed(0)}',
            icon: Icons.warning_amber_rounded,
            color: Colors.orange,
          ),
        );
      }
    }

    if (data.totalLiquidity < 0) {
      alerts.add(
        const _BankingAlert(
          title: 'هشدار نقدینگی',
          description: 'مانده نقدینگی منفی است.',
          icon: Icons.error_outline_rounded,
          color: Colors.red,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                color: Color(0xFF1B4332),
              ),
              SizedBox(width: 10),
              Text(
                'هشدارهای بانک و نقد',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (alerts.isEmpty)
            const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: Colors.green),
                SizedBox(width: 10),
                Text('در حال حاضر هشدار فعالی وجود ندارد.'),
              ],
            )
          else
            ...alerts.map(
              (alert) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(alert.icon, color: alert.color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alert.description,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BankingAlert {
  const _BankingAlert({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
}
