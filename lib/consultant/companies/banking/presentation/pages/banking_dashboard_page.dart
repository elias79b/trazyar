import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/consultant/companies/banking/presentation/widgets/create_bank_account_dialog.dart';

import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

import '../../application/banking_provider.dart';

import '../widgets/banking_kpi_cards.dart';
import '../widgets/bank_balance_bar_chart.dart';
import '../widgets/bank_accounts_table.dart';
import '../widgets/banking_alerts_card.dart';
import '../widgets/cash_box_form_dialog.dart';
import '../widgets/cash_boxes_table.dart';
import '../widgets/bank_loan_form_dialog.dart';
import '../widgets/bank_loans_table.dart';
import '../widgets/bank_loan_kpi_cards.dart';
import '../widgets/check_form_dialog.dart';
import '../widgets/received_checks_table.dart';
import '../widgets/paid_checks_table.dart';
import '../widgets/banking_check_alerts.dart';
import '../widgets/petty_cash_form_dialog.dart';
import '../widgets/petty_cash_table.dart';

class BankingDashboardPage extends ConsumerWidget {
  const BankingDashboardPage({
    super.key,
    required this.companyId,
  });

  final String companyId;

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final dashboardAsync = ref.watch(
      bankingDashboardProvider(companyId),
    );

    return CompanyScaffold(
      companyId: companyId,
      currentRoute:
      '/consultant/companies/$companyId/banking',
      title: 'بانک و نقد',
      body: dashboardAsync.when(
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },

        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                error.toString(),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },

        data: (data) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(
                bankingDashboardProvider(companyId),
              );

              await ref.read(
                bankingDashboardProvider(companyId).future,
              );
            },

            child: SingleChildScrollView(
              physics:
              const AlwaysScrollableScrollPhysics(),

              padding:
              const EdgeInsets.all(24),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  _Header(
                    totalLiquidity:
                    data.totalLiquidity,
                    companyId:
                    companyId,
                  ),

                  const SizedBox(height: 24),

                  // =====================================================
                  // BANK / CASH / CHECK KPI
                  // =====================================================

                  BankingKpiCards(
                    totalBankBalance:
                    data.totalBankBalance,
                    totalCashBalance:
                    data.totalCashBalance,
                    receivedChecks:
                    data.receivedChecks.totalAmount,
                    paidChecks:
                    data.paidChecks.totalAmount,
                  ),

                  const SizedBox(height: 24),

                  // =====================================================
                  // PETTY CASH OVERVIEW
                  // =====================================================

                  _PettyCashOverview(
                    count:
                    data.pettyCashAccounts.length,
                    balance:
                    data.totalPettyCashBalance,
                    receipts:
                    data.totalPettyCashReceipts,
                    payments:
                    data.totalPettyCashPayments,
                    discrepancy:
                    data.totalPettyCashDiscrepancy,
                  ),

                  const SizedBox(height: 24),

                  // =====================================================
                  // BANK CHART
                  // =====================================================

                  BankBalanceBarChart(
                    accounts:
                    data.bankAccounts,
                  ),

                  const SizedBox(height: 24),

                  // =====================================================
                  // GENERAL ALERTS
                  // =====================================================

                  BankingAlertsCard(
                    data: data,
                  ),

                  const SizedBox(height: 24),

                  // =====================================================
                  // DISCREPANCY
                  // =====================================================

                  _DiscrepancyCard(
                    bankDiscrepancy:
                    data.totalBankDiscrepancy,
                    cashDiscrepancy:
                    data.totalCashDiscrepancy,
                    bankCount:
                    data.bankDiscrepancyCount,
                    cashCount:
                    data.cashDiscrepancyCount,
                  ),

                  const SizedBox(height: 24),

                  // =====================================================
                  // CHECK ALERTS
                  // =====================================================

                  BankingCheckAlerts(
                    receivedChecks:
                    data.receivedChecks.checks,
                    paidChecks:
                    data.paidChecks.checks,
                  ),

                  const SizedBox(height: 24),

                  // =====================================================
                  // BANK ACCOUNTS
                  // =====================================================

                  BankAccountsTable(
                    companyId:
                    companyId,
                    accounts:
                    data.bankAccounts,
                  ),

                  const SizedBox(height: 24),

                  // =====================================================
                  // CASH BOXES
                  // =====================================================

                  CashBoxesTable(
                    companyId:
                    companyId,
                    cashBoxes:
                    data.cashBoxes,
                  ),

                  const SizedBox(height: 32),

                  // =====================================================
                  // PETTY CASH
                  // =====================================================

                  _SectionHeader(
                    title:
                    'تنخواه',
                    icon:
                    Icons.account_balance_wallet_rounded,
                  ),

                  const SizedBox(height: 16),

                  PettyCashTable(
                    companyId:
                    companyId,
                    pettyCashAccounts:
                    data.pettyCashAccounts,
                  ),

                  const SizedBox(height: 32),

                  // =====================================================
                  // LOANS
                  // =====================================================

                  _SectionHeader(
                    title:
                    'تسهیلات بانکی',
                    icon:
                    Icons.account_balance_rounded,
                  ),

                  const SizedBox(height: 16),

                  BankLoanKpiCards(
                    loanCount:
                    data.loanCount,
                    totalPrincipal:
                    data.totalLoanPrincipal,
                    totalRemaining:
                    data.totalLoanRemaining,
                    totalMonthlyInstallments:
                    data.totalMonthlyInstallments,
                  ),

                  const SizedBox(height: 20),

                  BankLoansTable(
                    companyId:
                    companyId,
                    loans:
                    data.bankLoans,
                  ),

                  const SizedBox(height: 32),

                  // =====================================================
                  // CHECKS
                  // =====================================================

                  _SectionHeader(
                    title:
                    'چک‌ها',
                    icon:
                    Icons.receipt_long_rounded,
                  ),

                  const SizedBox(height: 16),

                  _ChecksOverview(
                    receivedCount:
                    data.receivedChecks.count,
                    receivedAmount:
                    data.receivedChecks.totalAmount,
                    paidCount:
                    data.paidChecks.count,
                    paidAmount:
                    data.paidChecks.totalAmount,
                  ),

                  const SizedBox(height: 20),

                  ReceivedChecksTable(
                    companyId:
                    companyId,
                    checks:
                    data.receivedChecks.checks,
                  ),

                  const SizedBox(height: 20),

                  PaidChecksTable(
                    companyId:
                    companyId,
                    checks:
                    data.paidChecks.checks,
                  ),

                  const SizedBox(height: 40),
                ],
              ),
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
    required this.totalLiquidity,
    required this.companyId,
  });

  final double totalLiquidity;
  final String companyId;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1B4332),
            Color(0xFF40916C),
          ],
        ),

        borderRadius:
        BorderRadius.circular(24),
      ),

      child: LayoutBuilder(
        builder: (
            context,
            constraints,
            ) {
          final compact =
              constraints.maxWidth < 900;

          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,

            children: [
              _BankActionButton(
                label:
                'ثبت حساب بانکی',
                icon:
                Icons.add_business_rounded,
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) {
                      return BankAccountFormDialog(
                        companyId:
                        companyId,
                      );
                    },
                  );
                },
              ),

              _BankActionButton(
                label:
                'ثبت صندوق',
                icon:
                Icons.point_of_sale_rounded,
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) {
                      return CashBoxFormDialog(
                        companyId:
                        companyId,
                      );
                    },
                  );
                },
              ),

              _BankActionButton(
                label:
                'ثبت تنخواه',
                icon:
                Icons.account_balance_wallet_rounded,
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) {
                      return PettyCashFormDialog(
                        companyId:
                        companyId,
                      );
                    },
                  );
                },
              ),

              _BankActionButton(
                label:
                'ثبت تسهیلات',
                icon:
                Icons.request_quote_rounded,
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) {
                      return BankLoanFormDialog(
                        companyId:
                        companyId,
                      );
                    },
                  );
                },
              ),

              _BankActionButton(
                label:
                'ثبت چک دریافتی',
                icon:
                Icons.call_received_rounded,
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) {
                      return CheckFormDialog(
                        companyId:
                        companyId,
                        type:
                        CheckType.received,
                      );
                    },
                  );
                },
              ),

              _BankActionButton(
                label:
                'ثبت چک پرداختی',
                icon:
                Icons.call_made_rounded,
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) {
                      return CheckFormDialog(
                        companyId:
                        companyId,
                        type:
                        CheckType.paid,
                      );
                    },
                  );
                },
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,

                      decoration:
                      BoxDecoration(
                        color:
                        Colors.white,
                        borderRadius:
                        BorderRadius.circular(16),
                      ),

                      child: const Icon(
                        Icons.account_balance_rounded,
                        color:
                        Color(0xFF1B4332),
                        size:
                        31,
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child:
                      _HeaderTitle(
                        totalLiquidity:
                        totalLiquidity,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment:
            CrossAxisAlignment.center,

            children: [
              Container(
                width: 58,
                height: 58,

                decoration:
                BoxDecoration(
                  color:
                  Colors.white,
                  borderRadius:
                  BorderRadius.circular(16),
                ),

                child: const Icon(
                  Icons.account_balance_rounded,
                  color:
                  Color(0xFF1B4332),
                  size:
                  31,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child:
                _HeaderTitle(
                  totalLiquidity:
                  totalLiquidity,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                flex: 3,
                child: Align(
                  alignment:
                  Alignment.centerRight,
                  child: actions,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


// ============================================================
// HEADER TITLE
// ============================================================

class _HeaderTitle
    extends StatelessWidget {
  const _HeaderTitle({
    required this.totalLiquidity,
  });

  final double totalLiquidity;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [
        const Text(
          'داشبورد بانک و نقد',
          style: TextStyle(
            color:
            Colors.white,
            fontSize:
            21,
            fontWeight:
            FontWeight.w900,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'نقدینگی کل: '
              '${totalLiquidity.toStringAsFixed(0)}',

          style: const TextStyle(
            color:
            Colors.white70,
            fontSize:
            12,
          ),
        ),
      ],
    );
  }
}


// ============================================================
// ACTION BUTTON
// ============================================================

class _BankActionButton
    extends StatelessWidget {
  const _BankActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(
      BuildContext context,
      ) {
    return FilledButton.icon(
      style:
      FilledButton.styleFrom(
        backgroundColor:
        Colors.white,
        foregroundColor:
        const Color(0xFF1B4332),
        padding:
        const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
      ),

      onPressed:
      onPressed,

      icon:
      Icon(icon),

      label:
      Text(label),
    );
  }
}


// ============================================================
// SECTION HEADER
// ============================================================

class _SectionHeader
    extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,

          decoration:
          BoxDecoration(
            color:
            const Color(0xFF1B4332)
                .withOpacity(.10),
            borderRadius:
            BorderRadius.circular(13),
          ),

          child: Icon(
            icon,
            color:
            const Color(0xFF1B4332),
          ),
        ),

        const SizedBox(width: 12),

        Text(
          title,
          style:
          const TextStyle(
            fontSize:
            18,
            fontWeight:
            FontWeight.w900,
          ),
        ),
      ],
    );
  }
}


// ============================================================
// PETTY CASH OVERVIEW
// ============================================================

class _PettyCashOverview
    extends StatelessWidget {
  const _PettyCashOverview({
    required this.count,
    required this.balance,
    required this.receipts,
    required this.payments,
    required this.discrepancy,
  });

  final int count;
  final double balance;
  final double receipts;
  final double payments;
  final double discrepancy;

  String _money(double value) {
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      width:
      double.infinity,

      padding:
      const EdgeInsets.all(22),

      decoration:
      BoxDecoration(
        color:
        Colors.white,

        borderRadius:
        BorderRadius.circular(22),

        border:
        Border.all(
          color:
          Colors.grey.shade200,
        ),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,

                decoration:
                BoxDecoration(
                  color:
                  const Color(0xFF1B4332)
                      .withOpacity(.10),

                  borderRadius:
                  BorderRadius.circular(13),
                ),

                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color:
                  Color(0xFF1B4332),
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Text(
                  'خلاصه تنخواه',
                  style:
                  TextStyle(
                    fontSize:
                    17,
                    fontWeight:
                    FontWeight.w900,
                  ),
                ),
              ),

              Text(
                '$count تنخواه',
                style:
                TextStyle(
                  color:
                  Colors.grey.shade600,
                  fontSize:
                  12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          LayoutBuilder(
            builder:
                (context, constraints) {
              int countColumns;

              if (constraints.maxWidth >= 1000) {
                countColumns = 4;
              } else if (constraints.maxWidth >= 650) {
                countColumns = 2;
              } else {
                countColumns = 1;
              }

              return GridView.count(
                shrinkWrap:
                true,

                physics:
                const NeverScrollableScrollPhysics(),

                crossAxisCount:
                countColumns,

                crossAxisSpacing:
                14,

                mainAxisSpacing:
                14,

                childAspectRatio:
                2.6,

                children: [
                  _PettyKpi(
                    title:
                    'مانده تنخواه',
                    value:
                    _money(balance),
                    icon:
                    Icons.account_balance_wallet_outlined,
                  ),

                  _PettyKpi(
                    title:
                    'دریافت‌ها',
                    value:
                    _money(receipts),
                    icon:
                    Icons.arrow_downward_rounded,
                  ),

                  _PettyKpi(
                    title:
                    'پرداخت‌ها',
                    value:
                    _money(payments),
                    icon:
                    Icons.arrow_upward_rounded,
                  ),

                  _PettyKpi(
                    title:
                    'مغایرت',
                    value:
                    _money(discrepancy),
                    icon:
                    discrepancy != 0
                        ? Icons.warning_amber_rounded
                        : Icons.verified_rounded,
                    danger:
                    discrepancy != 0,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}


// ============================================================
// PETTY CASH KPI
// ============================================================

class _PettyKpi
    extends StatelessWidget {
  const _PettyKpi({
    required this.title,
    required this.value,
    required this.icon,
    this.danger = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final bool danger;

  @override
  Widget build(
      BuildContext context,
      ) {
    final iconColor =
    danger
        ? Colors.orange.shade700
        : const Color(0xFF1B4332);

    return Container(
      padding:
      const EdgeInsets.all(16),

      decoration:
      BoxDecoration(
        color:
        Colors.grey.shade50,

        borderRadius:
        BorderRadius.circular(16),

        border:
        Border.all(
          color:
          Colors.grey.shade200,
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,

            decoration:
            BoxDecoration(
              color:
              iconColor.withOpacity(.10),

              borderRadius:
              BorderRadius.circular(12),
            ),

            child: Icon(
              icon,
              color:
              iconColor,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,

              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style:
                  TextStyle(
                    color:
                    Colors.grey.shade600,
                    fontSize:
                    11,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  value,

                  style:
                  const TextStyle(
                    fontSize:
                    16,
                    fontWeight:
                    FontWeight.w900,
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
// CHECKS OVERVIEW
// ============================================================

class _ChecksOverview
    extends StatelessWidget {
  const _ChecksOverview({
    required this.receivedCount,
    required this.receivedAmount,
    required this.paidCount,
    required this.paidAmount,
  });

  final int receivedCount;
  final double receivedAmount;

  final int paidCount;
  final double paidAmount;

  String _money(double value) {
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return LayoutBuilder(
      builder:
          (context, constraints) {
        int count;

        if (constraints.maxWidth >= 1000) {
          count = 4;
        } else if (constraints.maxWidth >= 650) {
          count = 2;
        } else {
          count = 1;
        }

        return GridView.count(
          shrinkWrap:
          true,

          physics:
          const NeverScrollableScrollPhysics(),

          crossAxisCount:
          count,

          crossAxisSpacing:
          16,

          mainAxisSpacing:
          16,

          childAspectRatio:
          2.3,

          children: [
            _CheckKpi(
              title:
              'تعداد چک دریافتی',
              value:
              receivedCount.toString(),
              icon:
              Icons.receipt_long_rounded,
            ),

            _CheckKpi(
              title:
              'مبلغ چک دریافتی',
              value:
              _money(receivedAmount),
              icon:
              Icons.call_received_rounded,
            ),

            _CheckKpi(
              title:
              'تعداد چک پرداختی',
              value:
              paidCount.toString(),
              icon:
              Icons.receipt_rounded,
            ),

            _CheckKpi(
              title:
              'مبلغ چک پرداختی',
              value:
              _money(paidAmount),
              icon:
              Icons.call_made_rounded,
            ),
          ],
        );
      },
    );
  }
}


// ============================================================
// CHECK KPI
// ============================================================

class _CheckKpi
    extends StatelessWidget {
  const _CheckKpi({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.all(18),

      decoration:
      BoxDecoration(
        color:
        Colors.white,

        borderRadius:
        BorderRadius.circular(20),

        border:
        Border.all(
          color:
          Colors.grey.shade200,
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,

            decoration:
            BoxDecoration(
              color:
              const Color(0xFF1B4332)
                  .withOpacity(.10),

              borderRadius:
              BorderRadius.circular(14),
            ),

            child: Icon(
              icon,
              color:
              const Color(0xFF1B4332),
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

                  style:
                  TextStyle(
                    color:
                    Colors.grey.shade600,
                    fontSize:
                    12,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  value,

                  style:
                  const TextStyle(
                    fontSize:
                    18,
                    fontWeight:
                    FontWeight.w900,
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
// DISCREPANCY CARD
// ============================================================

class _DiscrepancyCard
    extends StatelessWidget {
  const _DiscrepancyCard({
    required this.bankDiscrepancy,
    required this.cashDiscrepancy,
    required this.bankCount,
    required this.cashCount,
  });

  final double bankDiscrepancy;
  final double cashDiscrepancy;

  final int bankCount;
  final int cashCount;

  @override
  Widget build(
      BuildContext context,
      ) {
    final hasDiscrepancy =
        bankDiscrepancy != 0 ||
            cashDiscrepancy != 0;

    return Container(
      width:
      double.infinity,

      padding:
      const EdgeInsets.all(22),

      decoration:
      BoxDecoration(
        color:
        Colors.white,

        borderRadius:
        BorderRadius.circular(22),

        border:
        Border.all(
          color:
          hasDiscrepancy
              ? Colors.orange.shade200
              : Colors.grey.shade200,
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,

            decoration:
            BoxDecoration(
              color:
              hasDiscrepancy
                  ? Colors.orange.withOpacity(.12)
                  : Colors.green.withOpacity(.12),

              borderRadius:
              BorderRadius.circular(14),
            ),

            child: Icon(
              hasDiscrepancy
                  ? Icons.warning_amber_rounded
                  : Icons.verified_rounded,

              color:
              hasDiscrepancy
                  ? Colors.orange.shade700
                  : Colors.green.shade700,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Text(
                  hasDiscrepancy
                      ? 'مغایرت‌های نیازمند بررسی'
                      : 'مغایرت بانکی و صندوقی وجود ندارد',

                  style:
                  const TextStyle(
                    fontSize:
                    15,
                    fontWeight:
                    FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  hasDiscrepancy
                      ? 'بانک: $bankCount مورد | '
                      'صندوق: $cashCount مورد'
                      : 'وضعیت فعلی تایید شده است',

                  style:
                  TextStyle(
                    color:
                    Colors.grey.shade600,
                    fontSize:
                    12,
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