import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/consultant/companies/banking/presentation/widgets/create_bank_account_dialog.dart';

import '../../application/banking_provider.dart';
import '../../data/banking_repository.dart';

class BankAccountsTable extends ConsumerWidget {
  const BankAccountsTable({
    super.key,
    required this.companyId,
    required this.accounts,
  });

  final String companyId;
  final List<BankAccountModel> accounts;

  String _money(double value) {
    return value.toStringAsFixed(0);
  }

  Future<void> _edit(
      BuildContext context,
      BankAccountModel account,
      ) async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        return BankAccountFormDialog(
          companyId: companyId,
          account: account,
        );
      },
    );
  }

  Future<void> _delete(
      BuildContext context,
      WidgetRef ref,
      BankAccountModel account,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'حذف حساب بانکی',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            'آیا از حذف حساب ${account.bankName} اطمینان دارید؟',
          ),
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
      await ref
          .read(bankingRepositoryProvider)
          .deleteBankAccount(account.id);

      ref.invalidate(
        bankingDashboardProvider(companyId),
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'حساب بانکی با موفقیت حذف شد.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            error.toString(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'حساب‌های بانکی',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 18),

          if (accounts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 30,
              ),
              child: Center(
                child: Text(
                  'برای این شرکت حساب بانکی ثبت نشده است.',
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(
                    label: Text('بانک'),
                  ),
                  DataColumn(
                    label: Text('شماره حساب'),
                  ),
                  DataColumn(
                    label: Text('اول دوره'),
                  ),
                  DataColumn(
                    label: Text('بدهکار'),
                  ),
                  DataColumn(
                    label: Text('بستانکار'),
                  ),
                  DataColumn(
                    label: Text('پایان دوره'),
                  ),
                  DataColumn(
                    label: Text('مغایرت'),
                  ),
                  DataColumn(
                    label: Text('عملیات'),
                  ),
                ],
                rows: accounts.map((account) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(account.bankName),
                      ),

                      DataCell(
                        Text(account.accountNumber),
                      ),

                      DataCell(
                        Text(
                          _money(
                            account.openingBalance,
                          ),
                        ),
                      ),

                      DataCell(
                        Text(
                          _money(
                            account.debitTurnover,
                          ),
                        ),
                      ),

                      DataCell(
                        Text(
                          _money(
                            account.creditTurnover,
                          ),
                        ),
                      ),

                      DataCell(
                        Text(
                          _money(
                            account.closingBalance,
                          ),
                        ),
                      ),

                      DataCell(
                        Text(
                          _money(
                            account.discrepancy,
                          ),
                          style: TextStyle(
                            color:
                            account.discrepancy != 0
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                            fontWeight:
                            FontWeight.w800,
                          ),
                        ),
                      ),

                      DataCell(
                        Row(
                          mainAxisSize:
                          MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'ویرایش',
                              onPressed: () {
                                _edit(
                                  context,
                                  account,
                                );
                              },
                              icon: const Icon(
                                Icons.edit_outlined,
                              ),
                            ),

                            IconButton(
                              tooltip: 'حذف',
                              color:
                              Colors.red.shade700,
                              onPressed: () {
                                _delete(
                                  context,
                                  ref,
                                  account,
                                );
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