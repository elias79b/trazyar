import 'package:flutter/material.dart';

import '../../data/banking_repository.dart';

class BankingCheckAlerts extends StatelessWidget {
  const BankingCheckAlerts({
    super.key,
    required this.receivedChecks,
    required this.paidChecks,
  });

  final List<CheckModel> receivedChecks;
  final List<CheckModel> paidChecks;

  @override
  Widget build(BuildContext context) {
    final alerts = <_CheckAlert>[];

    final today = _dateOnly(DateTime.now());
    final threeDaysLater = today.add(const Duration(days: 3));

    // =========================================================
    // RECEIVED CHECKS
    // =========================================================

    for (final check in receivedChecks) {
      final dueDate = check.dueDate;

      if (dueDate != null) {
        final date = _dateOnly(dueDate);

        if (date.isBefore(today)) {
          alerts.add(
            _CheckAlert(
              title: 'چک دریافتی سررسید شده',
              description:
                  'شماره چک: ${check.checkNumber} | '
                  'بانک: ${check.bankName} | '
                  'مبلغ: ${_money(check.amount)}',
              icon: Icons.warning_amber_rounded,
              color: Colors.red,
              priority: 3,
            ),
          );
        } else if (!date.isAfter(threeDaysLater)) {
          final days = date.difference(today).inDays;

          alerts.add(
            _CheckAlert(
              title: 'چک دریافتی نزدیک سررسید',
              description:
                  'شماره چک: ${check.checkNumber} | '
                  '$days روز تا سررسید',
              icon: Icons.schedule_rounded,
              color: Colors.orange,
              priority: 2,
            ),
          );
        }
      }

      if (_hasProblemStatus(check.status)) {
        alerts.add(
          _CheckAlert(
            title: 'وضعیت غیرعادی چک دریافتی',
            description:
                'شماره چک: ${check.checkNumber} | '
                'وضعیت: ${check.status}',
            icon: Icons.error_outline_rounded,
            color: Colors.red,
            priority: 3,
          ),
        );
      }
    }

    // =========================================================
    // PAID CHECKS
    // =========================================================

    for (final check in paidChecks) {
      final dueDate = check.dueDate;

      if (dueDate != null) {
        final date = _dateOnly(dueDate);

        if (date.isBefore(today)) {
          alerts.add(
            _CheckAlert(
              title: 'چک پرداختی سررسید شده',
              description:
                  'شماره چک: ${check.checkNumber} | '
                  'بانک: ${check.bankName} | '
                  'مبلغ: ${_money(check.amount)}',
              icon: Icons.warning_amber_rounded,
              color: Colors.red,
              priority: 3,
            ),
          );
        } else if (!date.isAfter(threeDaysLater)) {
          final days = date.difference(today).inDays;

          alerts.add(
            _CheckAlert(
              title: 'چک پرداختی نزدیک سررسید',
              description:
                  'شماره چک: ${check.checkNumber} | '
                  '$days روز تا سررسید',
              icon: Icons.schedule_rounded,
              color: Colors.orange,
              priority: 2,
            ),
          );
        }
      }

      if (_hasProblemStatus(check.status)) {
        alerts.add(
          _CheckAlert(
            title: 'وضعیت غیرعادی چک پرداختی',
            description:
                'شماره چک: ${check.checkNumber} | '
                'وضعیت: ${check.status}',
            icon: Icons.error_outline_rounded,
            color: Colors.red,
            priority: 3,
          ),
        );
      }
    }

    alerts.sort((a, b) => b.priority.compareTo(a.priority));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: alerts.isEmpty ? Colors.grey.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                      alerts.isEmpty
                          ? Colors.green.withOpacity(.10)
                          : Colors.orange.withOpacity(.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  alerts.isEmpty
                      ? Icons.verified_rounded
                      : Icons.notifications_active_rounded,
                  color:
                      alerts.isEmpty
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'هشدارهای چک',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ],
          ),

          const SizedBox(height: 18),

          if (alerts.isEmpty)
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('در حال حاضر هشدار فعالی برای چک‌ها وجود ندارد.'),
                ),
              ],
            )
          else
            ...alerts.map(
              (alert) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: alert.color.withOpacity(.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              alert.description,
                              style: TextStyle(
                                color: Colors.grey.shade700,
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
            ),
        ],
      ),
    );
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _money(double value) {
    return value.toStringAsFixed(0);
  }

  bool _hasProblemStatus(String status) {
    final normalized = status.trim().toLowerCase();

    if (normalized.isEmpty) {
      return false;
    }

    const problemStatuses = [
      'برگشتی',
      'برگشت',
      'باطل',
      'باطل شده',
      'مشکل‌دار',
      'مشکل دار',
      'returned',
      'bounced',
      'cancelled',
      'canceled',
    ];

    return problemStatuses.any((item) => normalized.contains(item));
  }
}

class _CheckAlert {
  const _CheckAlert({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.priority,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int priority;
}
