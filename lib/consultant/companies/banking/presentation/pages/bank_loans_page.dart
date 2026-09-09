import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

import '../../application/banking_provider.dart';
import '../widgets/bank_loan_form_dialog.dart';
import '../widgets/bank_loans_table.dart';
import '../widgets/bank_loan_kpi_cards.dart';

class BankLoansPage extends ConsumerWidget {
  const BankLoansPage({super.key, required this.companyId});

  final String companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(bankingDashboardProvider(companyId));

    return CompanyScaffold(
      companyId: companyId,
      currentRoute: '/consultant/companies/$companyId/banking/loans',
      title: 'تسهیلات بانکی',
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
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                _Header(
                  companyId: companyId,
                  count: data.loanCount,
                  totalRemaining: data.totalLoanRemaining,
                ),

                const SizedBox(height: 24),

                BankLoanKpiCards(
                  loanCount: data.loanCount,
                  totalPrincipal: data.totalLoanPrincipal,
                  totalRemaining: data.totalLoanRemaining,
                  totalMonthlyInstallments: data.totalMonthlyInstallments,
                ),

                const SizedBox(height: 24),

                _SummaryCard(
                  loanCount: data.loanCount,
                  totalPrincipal: data.totalLoanPrincipal,
                  totalRemaining: data.totalLoanRemaining,
                  monthlyInstallments: data.totalMonthlyInstallments,
                ),

                const SizedBox(height: 24),

                BankLoansTable(companyId: companyId, loans: data.bankLoans),

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
    required this.totalRemaining,
  });

  final String companyId;
  final int count;
  final double totalRemaining;

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
                'تسهیلات بانکی',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                '$count تسهیلات',

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
                  return BankLoanFormDialog(companyId: companyId);
                },
              );
            },

            icon: const Icon(Icons.request_quote_rounded),

            label: const Text('ثبت تسهیلات'),
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
                        Icons.request_quote_rounded,
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
                  Icons.request_quote_rounded,
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
// SUMMARY CARD
// ============================================================

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.loanCount,
    required this.totalPrincipal,
    required this.totalRemaining,
    required this.monthlyInstallments,
  });

  final int loanCount;
  final double totalPrincipal;
  final double totalRemaining;
  final double monthlyInstallments;

  String _money(double value) {
    return value.toStringAsFixed(0);
  }

  double _remainingRatio() {
    if (totalPrincipal <= 0) {
      return 0;
    }

    final ratio = totalRemaining / totalPrincipal;

    if (ratio < 0) {
      return 0;
    }

    if (ratio > 1) {
      return 1;
    }

    return ratio;
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _remainingRatio();

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
          const Text(
            'خلاصه وضعیت تسهیلات',

            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  title: 'تعداد',
                  value: loanCount.toString(),
                ),
              ),

              Expanded(
                child: _SummaryItem(
                  title: 'اصل تسهیلات',
                  value: _money(totalPrincipal),
                ),
              ),

              Expanded(
                child: _SummaryItem(
                  title: 'مانده',
                  value: _money(totalRemaining),
                ),
              ),

              Expanded(
                child: _SummaryItem(
                  title: 'اقساط ماهانه',
                  value: _money(monthlyInstallments),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            'نسبت مانده به اصل تسهیلات',

            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),

            child: LinearProgressIndicator(
              value: ratio,

              minHeight: 10,

              backgroundColor: Colors.grey.shade200,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '${(ratio * 100).toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SUMMARY ITEM
// ============================================================

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 12),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            title,

            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),

          const SizedBox(height: 6),

          Text(
            value,

            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
