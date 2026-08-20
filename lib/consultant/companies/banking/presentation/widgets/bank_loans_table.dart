import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/banking_provider.dart';
import '../../data/banking_repository.dart';
import 'bank_loan_form_dialog.dart';

class BankLoansTable extends ConsumerWidget {
  const BankLoansTable({
    super.key,
    required this.companyId,
    required this.loans,
  });

  final String companyId;
  final List<BankLoanModel> loans;

  String _money(double value) {
    return value.toStringAsFixed(0);
  }

  String _date(DateTime? value) {
    if (value == null) {
      return '---';
    }

    final month = value.month.toString().padLeft(2, '0');

    final day = value.day.toString().padLeft(2, '0');

    return '${value.year}-$month-$day';
  }

  Future<void> _edit(BuildContext context, BankLoanModel loan) async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        return BankLoanFormDialog(companyId: companyId, loan: loan);
      },
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    BankLoanModel loan,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'حذف تسهیلات',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text('آیا از حذف تسهیلات ${loan.bankName} اطمینان دارید؟'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('انصراف'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(bankingRepositoryProvider).deleteBankLoan(loan.id);

      ref.invalidate(bankingDashboardProvider(companyId));

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تسهیلات با موفقیت حذف شد.')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(error.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            'تسهیلات بانکی',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 18),
          if (loans.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text('برای این شرکت تسهیلاتی ثبت نشده است.'),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('بانک')),
                  DataColumn(label: Text('نوع تسهیلات')),
                  DataColumn(label: Text('مبلغ اولیه')),
                  DataColumn(label: Text('مانده')),
                  DataColumn(label: Text('نرخ')),
                  DataColumn(label: Text('قسط ماهانه')),
                  DataColumn(label: Text('شروع')),
                  DataColumn(label: Text('پایان')),
                  DataColumn(label: Text('عملیات')),
                ],
                rows:
                    loans.map((loan) {
                      return DataRow(
                        cells: [
                          DataCell(Text(loan.bankName)),
                          DataCell(Text(loan.loanType)),
                          DataCell(Text(_money(loan.principalAmount))),
                          DataCell(Text(_money(loan.remainingAmount))),
                          DataCell(Text('${loan.interestRate}%')),
                          DataCell(Text(_money(loan.monthlyInstallment))),
                          DataCell(Text(_date(loan.startDate))),
                          DataCell(Text(_date(loan.endDate))),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'ویرایش',
                                  onPressed: () {
                                    _edit(context, loan);
                                  },
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'حذف',
                                  color: Colors.red.shade700,
                                  onPressed: () {
                                    _delete(context, ref, loan);
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
