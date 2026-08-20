import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/banking_provider.dart';
import '../../data/banking_repository.dart';
import 'check_form_dialog.dart';

class PaidChecksTable extends ConsumerWidget {
  const PaidChecksTable({
    super.key,
    required this.companyId,
    required this.checks,
  });

  final String companyId;
  final List<CheckModel> checks;

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

  Future<void> _edit(BuildContext context, CheckModel check) async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        return CheckFormDialog(
          companyId: companyId,
          type: CheckType.paid,
          check: check,
        );
      },
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    CheckModel check,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'حذف چک پرداختی',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text('آیا از حذف چک ${check.checkNumber} اطمینان دارید؟'),
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
      await ref.read(bankingRepositoryProvider).deletePaidCheck(check.id);

      ref.invalidate(bankingDashboardProvider(companyId));

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('چک پرداختی با موفقیت حذف شد.')),
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
            'چک‌های پرداختی',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 18),
          if (checks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text('برای این شرکت چک پرداختی ثبت نشده است.'),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('شماره چک')),
                  DataColumn(label: Text('بانک')),
                  DataColumn(label: Text('مبلغ')),
                  DataColumn(label: Text('سررسید')),
                  DataColumn(label: Text('وضعیت')),
                  DataColumn(label: Text('عملیات')),
                ],
                rows:
                    checks.map((check) {
                      return DataRow(
                        cells: [
                          DataCell(Text(check.checkNumber)),
                          DataCell(Text(check.bankName)),
                          DataCell(Text(_money(check.amount))),
                          DataCell(Text(_date(check.dueDate))),
                          DataCell(Text(check.status)),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'ویرایش',
                                  onPressed: () {
                                    _edit(context, check);
                                  },
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'حذف',
                                  color: Colors.red.shade700,
                                  onPressed: () {
                                    _delete(context, ref, check);
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
