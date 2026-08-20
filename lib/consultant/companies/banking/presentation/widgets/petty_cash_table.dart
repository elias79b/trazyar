import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/banking_provider.dart';
import '../../data/banking_repository.dart';
import 'petty_cash_form_dialog.dart';

class PettyCashTable extends ConsumerWidget {
  const PettyCashTable({
    super.key,
    required this.companyId,
    required this.pettyCashAccounts,
  });

  final String companyId;
  final List<PettyCashModel> pettyCashAccounts;

  String _money(double value) {
    return value.toStringAsFixed(0);
  }

  Future<void> _edit(BuildContext context, PettyCashModel pettyCash) async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        return PettyCashFormDialog(companyId: companyId, pettyCash: pettyCash);
      },
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    PettyCashModel pettyCash,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'حذف تنخواه',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text('آیا از حذف تنخواه «${pettyCash.name}» مطمئن هستید؟'),
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
      await ref.read(bankingRepositoryProvider).deletePettyCash(pettyCash.id);

      ref.invalidate(bankingDashboardProvider(companyId));

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تنخواه با موفقیت حذف شد.')));
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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'تنخواه‌ها',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '${pettyCashAccounts.length} تنخواه',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),

          const SizedBox(height: 18),

          if (pettyCashAccounts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: Text('برای این شرکت تنخواهی ثبت نشده است.')),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('تنخواه')),
                  DataColumn(label: Text('مسئول')),
                  DataColumn(label: Text('اول دوره')),
                  DataColumn(label: Text('دریافت')),
                  DataColumn(label: Text('پرداخت')),
                  DataColumn(label: Text('پایان دوره')),
                  DataColumn(label: Text('مانده دفتر')),
                  DataColumn(label: Text('مغایرت')),
                  DataColumn(label: Text('عملیات')),
                ],
                rows:
                    pettyCashAccounts.map((pettyCash) {
                      return DataRow(
                        cells: [
                          DataCell(Text(pettyCash.name)),

                          DataCell(
                            Text(
                              pettyCash.responsibleUserId?.isNotEmpty == true
                                  ? pettyCash.responsibleUserId!
                                  : '---',
                            ),
                          ),

                          DataCell(Text(_money(pettyCash.openingBalance))),

                          DataCell(Text(_money(pettyCash.totalReceipts))),

                          DataCell(Text(_money(pettyCash.totalPayments))),

                          DataCell(Text(_money(pettyCash.closingBalance))),

                          DataCell(Text(_money(pettyCash.ledgerBalance))),

                          DataCell(
                            Text(
                              _money(pettyCash.discrepancy),
                              style: TextStyle(
                                color:
                                    pettyCash.discrepancy != 0
                                        ? Colors.red.shade700
                                        : Colors.green.shade700,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),

                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'ویرایش',
                                  onPressed: () {
                                    _edit(context, pettyCash);
                                  },
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'حذف',
                                  color: Colors.red.shade700,
                                  onPressed: () {
                                    _delete(context, ref, pettyCash);
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
