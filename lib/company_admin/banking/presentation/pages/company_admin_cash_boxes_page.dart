import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/company_admin/dashboard/presentation/widgets/company_admin_scaffold.dart';

import '../../application/company_admin_cash_boxes_provider.dart';

class CompanyAdminCashBoxesPage extends ConsumerWidget {
  const CompanyAdminCashBoxesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boxesAsync = ref.watch(companyAdminCashBoxesProvider);

    return CompanyAdminScaffold(
      child: boxesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          return _ErrorView(
            error: error.toString(),
            onRetry: () {
              ref.invalidate(companyAdminCashBoxesProvider);
            },
          );
        },
        data: (boxes) {
          return _CashBoxesContent(boxes: boxes);
        },
      ),
    );
  }
}

class _CashBoxesContent extends ConsumerWidget {
  final List<CompanyAdminCashBox> boxes;

  const _CashBoxesContent({required this.boxes});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalBalance = boxes.fold<double>(
      0,
      (sum, box) => sum + box.closingBalance,
    );

    final totalReceipts = boxes.fold<double>(
      0,
      (sum, box) => sum + box.totalReceipts,
    );

    final totalPayments = boxes.fold<double>(
      0,
      (sum, box) => sum + box.totalPayments,
    );

    final totalDiscrepancy = boxes.fold<double>(
      0,
      (sum, box) => sum + box.discrepancy,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PageHeader(
                boxCount: boxes.length,
                onAdd: () {
                  _showCashBoxDialog(context, ref);
                },
                onRefresh: () {
                  ref.invalidate(companyAdminCashBoxesProvider);
                },
              ),

              const SizedBox(height: 24),

              _SummaryCards(
                boxCount: boxes.length,
                totalBalance: totalBalance,
                totalReceipts: totalReceipts,
                totalPayments: totalPayments,
                totalDiscrepancy: totalDiscrepancy,
              ),

              const SizedBox(height: 24),

              if (boxes.isEmpty)
                _EmptyCashBoxes(
                  onAdd: () {
                    _showCashBoxDialog(context, ref);
                  },
                )
              else
                _CashBoxesTable(
                  boxes: boxes,
                  onEdit: (box) {
                    _showCashBoxDialog(context, ref, box: box);
                  },
                  onDelete: (box) {
                    _showDeleteDialog(context, ref, box);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final int boxCount;
  final VoidCallback onAdd;
  final VoidCallback onRefresh;

  const _PageHeader({
    required this.boxCount,
    required this.onAdd,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'صندوق‌ها',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '$boxCount صندوق ثبت شده',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
        ),

        OutlinedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          label: const Text('بروزرسانی'),
        ),

        const SizedBox(width: 12),

        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('افزودن صندوق'),
        ),
      ],
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final int boxCount;
  final double totalBalance;
  final double totalReceipts;
  final double totalPayments;
  final double totalDiscrepancy;

  const _SummaryCards({
    required this.boxCount,
    required this.totalBalance,
    required this.totalReceipts,
    required this.totalPayments,
    required this.totalDiscrepancy,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final cardWidth =
            width >= 1200
                ? (width - 48) / 4
                : width >= 800
                ? (width - 16) / 2
                : width;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                title: 'تعداد صندوق‌ها',
                value: boxCount.toString(),
                icon: Icons.inventory_2_outlined,
              ),
            ),

            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                title: 'مجموع مانده',
                value: _money(totalBalance),
                icon: Icons.account_balance_wallet,
              ),
            ),

            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                title: 'دریافت‌ها',
                value: _money(totalReceipts),
                icon: Icons.arrow_downward,
              ),
            ),

            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                title: 'مغایرت',
                value: _money(totalDiscrepancy),
                icon: Icons.warning_amber_rounded,
                warning: totalDiscrepancy.abs() > 0.01,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool warning;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    warning
                        ? Colors.orange.withOpacity(.12)
                        : Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color:
                    warning
                        ? Colors.orange.shade700
                        : Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CashBoxesTable extends StatelessWidget {
  final List<CompanyAdminCashBox> boxes;
  final ValueChanged<CompanyAdminCashBox> onEdit;
  final ValueChanged<CompanyAdminCashBox> onDelete;

  const _CashBoxesTable({
    required this.boxes,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 28,
          headingRowHeight: 56,
          dataRowMinHeight: 64,
          dataRowMaxHeight: 72,
          columns: const [
            DataColumn(label: Text('نام صندوق')),
            DataColumn(label: Text('مانده افتتاحیه')),
            DataColumn(label: Text('دریافت‌ها')),
            DataColumn(label: Text('پرداخت‌ها')),
            DataColumn(label: Text('مانده پایان')),
            DataColumn(label: Text('مانده دفاتر')),
            DataColumn(label: Text('مغایرت')),
            DataColumn(label: Text('وضعیت')),
            DataColumn(label: Text('عملیات')),
          ],
          rows:
              boxes.map((box) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(box.boxName.isEmpty ? 'بدون نام' : box.boxName),
                    ),

                    DataCell(Text(_money(box.openingBalance))),

                    DataCell(Text(_money(box.totalReceipts))),

                    DataCell(Text(_money(box.totalPayments))),

                    DataCell(
                      Text(
                        _money(box.closingBalance),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),

                    DataCell(Text(_money(box.ledgerBalance))),

                    DataCell(
                      Text(
                        _money(box.discrepancy),
                        style: TextStyle(
                          color:
                              box.hasDiscrepancy
                                  ? Colors.orange.shade700
                                  : Colors.green.shade700,
                        ),
                      ),
                    ),

                    DataCell(_StatusBadge(box: box)),

                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'ویرایش',
                            onPressed: () => onEdit(box),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'حذف',
                            onPressed: () => onDelete(box),
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.red.shade600,
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
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final CompanyAdminCashBox box;

  const _StatusBadge({required this.box});

  @override
  Widget build(BuildContext context) {
    if (!box.hasPeriodData) {
      return _Badge(
        text: 'بدون دوره',
        background: Colors.grey.shade200,
        foreground: Colors.grey.shade700,
      );
    }

    if (box.hasDiscrepancy) {
      return _Badge(
        text: 'دارای مغایرت',
        background: Colors.orange.withOpacity(.12),
        foreground: Colors.orange.shade800,
      );
    }

    return _Badge(
      text: 'تأیید شده',
      background: Colors.green.withOpacity(.12),
      foreground: Colors.green.shade700,
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const _Badge({
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyCashBoxes extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyCashBoxes({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 24),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 20),

            const Text(
              'هنوز صندوقی ثبت نشده است.',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),

            Text(
              'برای شروع، اولین صندوق شرکت را ثبت کنید.',
              style: TextStyle(color: Colors.grey.shade600),
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('افزودن صندوق'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade400),

            const SizedBox(height: 16),

            const Text(
              'خطا در دریافت صندوق‌ها',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showCashBoxDialog(
  BuildContext context,
  WidgetRef ref, {
  CompanyAdminCashBox? box,
}) async {
  final bool isEdit = box != null;

  final controller = TextEditingController(text: box?.boxName ?? '');

  final formKey = GlobalKey<FormState>();

  try {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(isEdit ? 'ویرایش صندوق' : 'افزودن صندوق'),
            content: SizedBox(
              width: 450,
              child: Form(
                key: formKey,
                child: TextFormField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'نام صندوق',
                    hintText: 'مثلاً صندوق مرکزی',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'نام صندوق را وارد کنید.';
                    }

                    return null;
                  },
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('انصراف'),
              ),

              Consumer(
                builder: (context, ref, child) {
                  final mutation = ref.watch(
                    companyAdminCashBoxesControllerProvider,
                  );

                  final loading = mutation.isLoading;

                  return FilledButton(
                    onPressed:
                        loading
                            ? null
                            : () async {
                              if (!formKey.currentState!.validate()) {
                                return;
                              }

                              final notifier = ref.read(
                                companyAdminCashBoxesControllerProvider
                                    .notifier,
                              );

                              if (isEdit) {
                                await notifier.updateCashBox(
                                  cashBoxId: box!.id,
                                  boxName: controller.text,
                                );
                              } else {
                                await notifier.addCashBox(
                                  boxName: controller.text,
                                );
                              }

                              final result = ref.read(
                                companyAdminCashBoxesControllerProvider,
                              );

                              if (result.hasError) {
                                if (dialogContext.mounted) {
                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _cleanError(result.error.toString()),
                                      ),
                                      backgroundColor: Colors.red.shade700,
                                    ),
                                  );
                                }

                                return;
                              }

                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isEdit
                                          ? 'صندوق با موفقیت ویرایش شد.'
                                          : 'صندوق با موفقیت اضافه شد.',
                                    ),
                                    backgroundColor: Colors.green.shade700,
                                  ),
                                );
                              }
                            },
                    child:
                        loading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : Text(isEdit ? 'ذخیره تغییرات' : 'افزودن'),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  } finally {
    controller.dispose();
  }
}

Future<void> _showDeleteDialog(
  BuildContext context,
  WidgetRef ref,
  CompanyAdminCashBox box,
) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف صندوق'),
          content: Text(
            'آیا از حذف صندوق «${box.boxName}» مطمئن هستید؟\n\n'
            'این عملیات قابل بازگشت نیست.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('انصراف'),
            ),

            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('حذف'),
            ),
          ],
        ),
      );
    },
  );

  if (confirmed != true || !context.mounted) {
    return;
  }

  final notifier = ref.read(companyAdminCashBoxesControllerProvider.notifier);

  await notifier.deleteCashBox(cashBoxId: box.id);

  if (!context.mounted) {
    return;
  }

  final result = ref.read(companyAdminCashBoxesControllerProvider);

  if (result.hasError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_cleanError(result.error.toString())),
        backgroundColor: Colors.red.shade700,
      ),
    );

    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('صندوق با موفقیت حذف شد.'),
      backgroundColor: Colors.green.shade700,
    ),
  );
}

String _money(double value) {
  final rounded = value.round().toString();

  final chars = rounded.split('');

  final buffer = StringBuffer();

  for (var i = 0; i < chars.length; i++) {
    final reverseIndex = chars.length - i;

    buffer.write(chars[i]);

    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }

  return '${buffer.toString()} ریال';
}

String _cleanError(String error) {
  if (error.contains('foreign key')) {
    return 'این صندوق دارای اطلاعات وابسته است و امکان حذف آن وجود ندارد.';
  }

  if (error.contains('duplicate')) {
    return 'اطلاعات واردشده تکراری است.';
  }

  if (error.contains('violates row-level security')) {
    return 'دسترسی لازم برای این عملیات وجود ندارد.';
  }

  return error
      .replaceFirst('Exception: ', '')
      .replaceFirst('PostgrestException(message: ', '')
      .trim();
}
