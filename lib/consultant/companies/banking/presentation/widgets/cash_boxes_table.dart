import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/banking_provider.dart';
import '../../data/banking_repository.dart';
import 'cash_box_form_dialog.dart';

class CashBoxesTable extends ConsumerWidget {
  const CashBoxesTable({
    super.key,
    required this.companyId,
    required this.cashBoxes,
  });

  final String companyId;
  final List<CashBoxModel> cashBoxes;

  String _money(double value) {
    return value.toStringAsFixed(0);
  }

  Future<void> _edit(BuildContext context, CashBoxModel cashBox) async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        return CashBoxFormDialog(companyId: companyId, cashBox: cashBox);
      },
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    CashBoxModel cashBox,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'حذف صندوق',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text('آیا از حذف صندوق «${cashBox.boxName}» مطمئن هستید؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('انصراف'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ref.read(bankingRepositoryProvider).deleteCashBox(cashBox.id);

      ref.invalidate(bankingDashboardProvider(companyId));

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('صندوق با موفقیت حذف شد.')));
    } catch (error) {
      if (!context.mounted) return;

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
            'صندوق‌ها',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 18),
          if (cashBoxes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: Text('برای این شرکت صندوقی ثبت نشده است.')),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('صندوق')),
                  DataColumn(label: Text('اول دوره')),
                  DataColumn(label: Text('دریافت')),
                  DataColumn(label: Text('پرداخت')),
                  DataColumn(label: Text('پایان دوره')),
                  DataColumn(label: Text('مانده دفتر')),
                  DataColumn(label: Text('مغایرت')),
                  DataColumn(label: Text('عملیات')),
                ],
                rows:
                    cashBoxes.map((cashBox) {
                      return DataRow(
                        cells: [
                          DataCell(Text(cashBox.boxName)),
                          DataCell(Text(_money(cashBox.openingBalance))),
                          DataCell(Text(_money(cashBox.totalReceipts))),
                          DataCell(Text(_money(cashBox.totalPayments))),
                          DataCell(Text(_money(cashBox.closingBalance))),
                          DataCell(Text(_money(cashBox.ledgerBalance))),
                          DataCell(
                            Text(
                              _money(cashBox.discrepancy),
                              style: TextStyle(
                                color:
                                    cashBox.discrepancy != 0
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
                                    _edit(context, cashBox);
                                  },
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'حذف',
                                  color: Colors.red.shade700,
                                  onPressed: () {
                                    _delete(context, ref, cashBox);
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
