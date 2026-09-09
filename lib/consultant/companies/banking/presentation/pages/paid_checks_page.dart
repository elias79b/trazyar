import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

import '../../application/banking_provider.dart';
import '../widgets/check_form_dialog.dart';
import '../widgets/paid_checks_table.dart';

class PaidChecksPage extends ConsumerWidget {
  const PaidChecksPage({super.key, required this.companyId});

  final String companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(bankingDashboardProvider(companyId));

    return CompanyScaffold(
      companyId: companyId,
      currentRoute: '/consultant/companies/$companyId/banking/paid-checks',
      title: 'چک‌های پرداختی',
      body: dashboardAsync.when(
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(error.toString(), textAlign: TextAlign.center),
            ),
          );
        },
        data: (data) {
          final summary = data.paidChecks;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(
                  companyId: companyId,
                  count: summary.count,
                  totalAmount: summary.totalAmount,
                ),

                const SizedBox(height: 24),

                _OverviewCards(
                  count: summary.count,
                  totalAmount: summary.totalAmount,
                  checks: summary.checks,
                ),

                const SizedBox(height: 24),

                PaidChecksTable(companyId: companyId, checks: summary.checks),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// HEADER
// ============================================================

class _Header extends StatelessWidget {
  const _Header({
    required this.companyId,
    required this.count,
    required this.totalAmount,
  });

  final String companyId;
  final int count;
  final double totalAmount;

  String _money(double value) {
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF40916C)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 850;

          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'چک‌های پرداختی',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$count چک | مبلغ کل: ${_money(totalAmount)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          );

          final button = FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1B4332),
            ),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (_) {
                  return CheckFormDialog(
                    companyId: companyId,
                    type: CheckType.paid,
                  );
                },
              );
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('ثبت چک پرداختی'),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.call_made_rounded,
                        color: Color(0xFF1B4332),
                        size: 31,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: title),
                  ],
                ),
                const SizedBox(height: 18),
                button,
              ],
            );
          }

          return Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.call_made_rounded,
                  color: Color(0xFF1B4332),
                  size: 31,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: title),
              const SizedBox(width: 16),
              button,
            ],
          );
        },
      ),
    );
  }
}

// ============================================================
// OVERVIEW
// ============================================================

class _OverviewCards extends StatelessWidget {
  const _OverviewCards({
    required this.count,
    required this.totalAmount,
    required this.checks,
  });

  final int count;
  final double totalAmount;
  final List<dynamic> checks;

  String _money(double value) {
    return value.toStringAsFixed(0);
  }

  int _upcomingCount() {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final limit = today.add(const Duration(days: 3));

    var result = 0;

    for (final item in checks) {
      final dueDate = item.dueDate;

      if (dueDate == null) {
        continue;
      }

      final date = DateTime(dueDate.year, dueDate.month, dueDate.day);

      if (!date.isBefore(today) && !date.isAfter(limit)) {
        result++;
      }
    }

    return result;
  }

  int _overdueCount() {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    var result = 0;

    for (final item in checks) {
      final dueDate = item.dueDate;

      if (dueDate == null) {
        continue;
      }

      final date = DateTime(dueDate.year, dueDate.month, dueDate.day);

      if (date.isBefore(today)) {
        result++;
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns;

        if (constraints.maxWidth >= 1100) {
          columns = 4;
        } else if (constraints.maxWidth >= 700) {
          columns = 2;
        } else {
          columns = 1;
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.3,
          children: [
            _OverviewCard(
              title: 'تعداد چک',
              value: count.toString(),
              icon: Icons.receipt_long_rounded,
            ),
            _OverviewCard(
              title: 'مبلغ کل',
              value: _money(totalAmount),
              icon: Icons.payments_outlined,
            ),
            _OverviewCard(
              title: 'نزدیک سررسید',
              value: _upcomingCount().toString(),
              icon: Icons.schedule_rounded,
              warning: _upcomingCount() > 0,
            ),
            _OverviewCard(
              title: 'سررسید شده',
              value: _overdueCount().toString(),
              icon: Icons.warning_amber_rounded,
              danger: _overdueCount() > 0,
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// OVERVIEW CARD
// ============================================================

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.title,
    required this.value,
    required this.icon,
    this.warning = false,
    this.danger = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final bool warning;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        danger
            ? Colors.red.shade700
            : warning
            ? Colors.orange.shade700
            : const Color(0xFF1B4332);

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
              color: iconColor.withOpacity(.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor),
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
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
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
