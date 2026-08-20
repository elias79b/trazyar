import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/banking_provider.dart';
import '../../data/banking_repository.dart';
import 'check_form_dialog.dart';

class ReceivedChecksTable extends ConsumerWidget {
  const ReceivedChecksTable({
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
          type: CheckType.received,
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
            'حذف چک دریافتی',
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
      await ref.read(bankingRepositoryProvider).deleteReceivedCheck(check.id);

      ref.invalidate(bankingDashboardProvider(companyId));

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('چک دریافتی با موفقیت حذف شد.')),
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
    return _CheckTableCard(
      title: 'چک‌های دریافتی',
      emptyText: 'برای این شرکت چک دریافتی ثبت نشده است.',
      checks: checks,
      money: _money,
      date: _date,
      onEdit: (check) {
        _edit(context, check);
      },
      onDelete: (check) {
        _delete(context, ref, check);
      },
    );
  }
}

class _CheckTableCard extends StatelessWidget {
  const _CheckTableCard({
    required this.title,
    required this.emptyText,
    required this.checks,
    required this.money,
    required this.date,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final String emptyText;
  final List<CheckModel> checks;
  final String Function(double) money;
  final String Function(DateTime?) date;
  final ValueChanged<CheckModel> onEdit;
  final ValueChanged<CheckModel> onDelete;

  @override
  Widget build(BuildContext context) {
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
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 18),
          if (checks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(child: Text(emptyText)),
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
                          DataCell(Text(money(check.amount))),
                          DataCell(Text(date(check.dueDate))),
                          DataCell(Text(check.status)),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'ویرایش',
                                  onPressed: () {
                                    onEdit(check);
                                  },
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'حذف',
                                  color: Colors.red.shade700,
                                  onPressed: () {
                                    onDelete(check);
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
