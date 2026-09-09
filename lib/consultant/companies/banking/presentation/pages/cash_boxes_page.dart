import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

import '../../application/banking_provider.dart';
import '../widgets/cash_box_form_dialog.dart';
import '../widgets/cash_boxes_table.dart';

class CashBoxesPage extends ConsumerWidget {
  const CashBoxesPage({
    super.key,
    required this.companyId,
  });

  final String companyId;

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final dashboardAsync =
    ref.watch(
      bankingDashboardProvider(companyId),
    );

    return CompanyScaffold(
      companyId: companyId,
      currentRoute:
      '/consultant/companies/$companyId/banking/cash-boxes',
      title: 'صندوق‌ها',
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
          return SingleChildScrollView(
            padding:
            const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                _Header(
                  companyId: companyId,
                  count:
                  data.cashBoxes.length,
                  totalBalance:
                  data.totalCashBalance,
                  discrepancyCount:
                  data.cashDiscrepancyCount,
                ),

                const SizedBox(height: 24),

                _OverviewCards(
                  count:
                  data.cashBoxes.length,
                  totalBalance:
                  data.totalCashBalance,
                  totalReceipts:
                  data.cashBoxes.fold<double>(
                    0,
                        (sum, item) =>
                    sum + item.totalReceipts,
                  ),
                  totalPayments:
                  data.cashBoxes.fold<double>(
                    0,
                        (sum, item) =>
                    sum + item.totalPayments,
                  ),
                  discrepancy:
                  data.totalCashDiscrepancy,
                ),

                const SizedBox(height: 24),

                CashBoxesTable(
                  companyId: companyId,
                  cashBoxes:
                  data.cashBoxes,
                ),

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
    required this.totalBalance,
    required this.discrepancyCount,
  });

  final String companyId;
  final int count;
  final double totalBalance;
  final int discrepancyCount;

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
              constraints.maxWidth < 850;

          final title = Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Text(
                'صندوق‌ها',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight:
                  FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$count صندوق',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          );

          final button =
          FilledButton.icon(
            style:
            FilledButton.styleFrom(
              backgroundColor:
              Colors.white,
              foregroundColor:
              const Color(0xFF1B4332),
            ),
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
            icon: const Icon(
              Icons.point_of_sale_rounded,
            ),
            label:
            const Text(
              'ثبت صندوق',
            ),
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
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(
                          16,
                        ),
                      ),
                      child:
                      const Icon(
                        Icons
                            .point_of_sale_rounded,
                        color:
                        Color(0xFF1B4332),
                        size: 31,
                      ),
                    ),
                    const SizedBox(
                      width: 16,
                    ),
                    Expanded(
                      child: title,
                    ),
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
                decoration:
                BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(
                    16,
                  ),
                ),
                child:
                const Icon(
                  Icons.point_of_sale_rounded,
                  color:
                  Color(0xFF1B4332),
                  size: 31,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: title,
              ),
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

class _OverviewCards
    extends StatelessWidget {
  const _OverviewCards({
    required this.count,
    required this.totalBalance,
    required this.totalReceipts,
    required this.totalPayments,
    required this.discrepancy,
  });

  final int count;
  final double totalBalance;
  final double totalReceipts;
  final double totalPayments;
  final double discrepancy;

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
        int columns;

        if (constraints.maxWidth >= 1100) {
          columns = 5;
        } else if (constraints.maxWidth >= 700) {
          columns = 2;
        } else {
          columns = 1;
        }

        return GridView.count(
          shrinkWrap: true,
          physics:
          const NeverScrollableScrollPhysics(),
          crossAxisCount:
          columns,
          crossAxisSpacing:
          16,
          mainAxisSpacing:
          16,
          childAspectRatio:
          2.3,
          children: [
            _OverviewCard(
              title: 'تعداد صندوق',
              value:
              count.toString(),
              icon:
              Icons.point_of_sale_outlined,
            ),
            _OverviewCard(
              title: 'مانده کل',
              value:
              _money(totalBalance),
              icon:
              Icons.account_balance_wallet_outlined,
            ),
            _OverviewCard(
              title: 'مجموع دریافت',
              value:
              _money(totalReceipts),
              icon:
              Icons.arrow_downward_rounded,
            ),
            _OverviewCard(
              title: 'مجموع پرداخت',
              value:
              _money(totalPayments),
              icon:
              Icons.arrow_upward_rounded,
            ),
            _OverviewCard(
              title: 'مغایرت',
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
    );
  }
}


// ============================================================
// OVERVIEW CARD
// ============================================================

class _OverviewCard
    extends StatelessWidget {
  const _OverviewCard({
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
    final iconColor = danger
        ? Colors.orange.shade700
        : const Color(0xFF1B4332);

    return Container(
      padding:
      const EdgeInsets.all(18),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),
        border:
        Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration:
            BoxDecoration(
              color: iconColor
                  .withOpacity(.10),
              borderRadius:
              BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: iconColor,
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
                    color:
                    Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style:
                  const TextStyle(
                    fontSize: 18,
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