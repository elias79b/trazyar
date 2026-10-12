import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarazyar/company_admin/banking/application/company_admin_petty_cash_provider.dart';
import 'package:tarazyar/company_admin/dashboard/presentation/widgets/company_admin_scaffold.dart';

class CompanyAdminPettyCashPage extends ConsumerWidget {
  const CompanyAdminPettyCashPage({super.key});

  String _money(double value) {
    return value
        .round()
        .toString()
        .replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match.group(1)},',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pettyCashAsync = ref.watch(companyAdminPettyCashProvider);

    return CompanyAdminScaffold(
      child: Scaffold(
        backgroundColor: const Color(0xfff7f8fa),
        appBar: AppBar(
          title: const Text('تنخواه'),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          actions: [
            IconButton(
              tooltip: 'بازخوانی',
              onPressed: () {
                ref.invalidate(companyAdminPettyCashProvider);
              },
              icon: const Icon(Icons.refresh),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: pettyCashAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => _ErrorView(
            error: error,
            onRetry: () {
              ref.invalidate(companyAdminPettyCashProvider);
            },
          ),
          data: (items) {
            return _PettyCashContent(
              items: items,
              money: _money,
              onAdd: () => _showAddDialog(context, ref),
              onEdit: (item) => _showEditDialog(
                context,
                ref,
                item,
              ),
              onDelete: (item) => _showDeleteDialog(
                context,
                ref,
                item,
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showAddDialog(
      BuildContext context,
      WidgetRef ref,
      ) async {
    final nameController = TextEditingController();
    final responsibleController = TextEditingController();

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (_) {
          return _PettyCashFormDialog(
            title: 'افزودن تنخواه',
            nameController: nameController,
            responsibleController: responsibleController,
            confirmText: 'ثبت تنخواه',
          );
        },
      );

      if (result != true) return;

      final name = nameController.text.trim();

      if (name.isEmpty) {
        _showMessage(
          context,
          'نام تنخواه الزامی است.',
          isError: true,
        );
        return;
      }

      try {
        await ref
            .read(companyAdminPettyCashControllerProvider)
            .addPettyCash(
          name: name,
          responsibleUserId: responsibleController.text.trim(),
        );

        if (context.mounted) {
          _showMessage(
            context,
            'تنخواه با موفقیت ایجاد شد.',
          );
        }
      } catch (e) {
        if (context.mounted) {
          _showMessage(
            context,
            'خطا در ایجاد تنخواه:\n$e',
            isError: true,
          );
        }
      }
    } finally {
      nameController.dispose();
      responsibleController.dispose();
    }
  }

  Future<void> _showEditDialog(
      BuildContext context,
      WidgetRef ref,
      CompanyAdminPettyCash item,
      ) async {
    final nameController = TextEditingController(
      text: item.name,
    );

    final responsibleController = TextEditingController(
      text: item.responsibleUserId ?? '',
    );

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (_) {
          return _PettyCashFormDialog(
            title: 'ویرایش تنخواه',
            nameController: nameController,
            responsibleController: responsibleController,
            confirmText: 'ذخیره تغییرات',
          );
        },
      );

      if (result != true) return;

      final name = nameController.text.trim();

      if (name.isEmpty) {
        _showMessage(
          context,
          'نام تنخواه الزامی است.',
          isError: true,
        );
        return;
      }

      try {
        await ref
            .read(companyAdminPettyCashControllerProvider)
            .updatePettyCash(
          id: item.id,
          name: name,
          responsibleUserId: responsibleController.text.trim(),
        );

        if (context.mounted) {
          _showMessage(
            context,
            'تنخواه با موفقیت ویرایش شد.',
          );
        }
      } catch (e) {
        if (context.mounted) {
          _showMessage(
            context,
            'خطا در ویرایش تنخواه:\n$e',
            isError: true,
          );
        }
      }
    } finally {
      nameController.dispose();
      responsibleController.dispose();
    }
  }

  Future<void> _showDeleteDialog(
      BuildContext context,
      WidgetRef ref,
      CompanyAdminPettyCash item,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('حذف تنخواه'),
          content: Text(
            'آیا از حذف تنخواه «${item.name}» مطمئن هستید؟\n\n'
                'اگر برای این تنخواه سابقه دوره مالی ثبت شده باشد، '
                'ممکن است حذف توسط محدودیت دیتابیس رد شود.',
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
                backgroundColor: Colors.red,
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

    if (confirmed != true) return;

    try {
      await ref
          .read(companyAdminPettyCashControllerProvider)
          .deletePettyCash(item.id);

      if (context.mounted) {
        _showMessage(
          context,
          'تنخواه حذف شد.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showMessage(
          context,
          'حذف تنخواه انجام نشد.\n'
              'احتمالاً برای این تنخواه رکورد دوره مالی وجود دارد.\n\n$e',
          isError: true,
        );
      }
    }
  }

  void _showMessage(
      BuildContext context,
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : null,
        ),
      );
  }
}

class _PettyCashContent extends StatelessWidget {
  final List<CompanyAdminPettyCash> items;
  final String Function(double) money;
  final VoidCallback onAdd;
  final void Function(CompanyAdminPettyCash item) onEdit;
  final void Function(CompanyAdminPettyCash item) onDelete;

  const _PettyCashContent({
    required this.items,
    required this.money,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final totalClosing = items.fold<double>(
      0,
          (sum, item) =>
      sum + (item.periodData?.closingBalance ?? 0),
    );

    final totalReceipts = items.fold<double>(
      0,
          (sum, item) =>
      sum + (item.periodData?.totalReceipts ?? 0),
    );

    final totalPayments = items.fold<double>(
      0,
          (sum, item) =>
      sum + (item.periodData?.totalPayments ?? 0),
    );

    final totalDiscrepancy = items.fold<double>(
      0,
          (sum, item) =>
      sum + (item.periodData?.discrepancy ?? 0),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مدیریت تنخواه',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'مدیریت حساب‌های تنخواه شرکت و مشاهده وضعیت آخرین دوره مالی تأییدشده',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add),
                    label: const Text('افزودن تنخواه'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              isWide
                  ? Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'تعداد تنخواه',
                      value: '${items.length}',
                      icon: Icons
                          .account_balance_wallet_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      title: 'مانده تنخواه',
                      value: money(totalClosing),
                      suffix: 'ریال',
                      icon: Icons.payments_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      title: 'دریافت‌ها',
                      value: money(totalReceipts),
                      suffix: 'ریال',
                      icon: Icons.arrow_downward,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      title: 'پرداخت‌ها',
                      value: money(totalPayments),
                      suffix: 'ریال',
                      icon: Icons.arrow_upward,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      title: 'مغایرت',
                      value: money(totalDiscrepancy),
                      suffix: 'ریال',
                      icon:
                      Icons.warning_amber_outlined,
                      isWarning:
                      totalDiscrepancy != 0,
                    ),
                  ),
                ],
              )
                  : Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _SummaryCard(
                    title: 'تعداد تنخواه',
                    value: '${items.length}',
                    icon: Icons
                        .account_balance_wallet_outlined,
                  ),
                  _SummaryCard(
                    title: 'مانده تنخواه',
                    value: money(totalClosing),
                    suffix: 'ریال',
                    icon: Icons.payments_outlined,
                  ),
                  _SummaryCard(
                    title: 'دریافت‌ها',
                    value: money(totalReceipts),
                    suffix: 'ریال',
                    icon: Icons.arrow_downward,
                  ),
                  _SummaryCard(
                    title: 'پرداخت‌ها',
                    value: money(totalPayments),
                    suffix: 'ریال',
                    icon: Icons.arrow_upward,
                  ),
                  _SummaryCard(
                    title: 'مغایرت',
                    value: money(totalDiscrepancy),
                    suffix: 'ریال',
                    icon:
                    Icons.warning_amber_outlined,
                    isWarning:
                    totalDiscrepancy != 0,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              if (items.isEmpty)
                const _EmptyState()
              else
                _PettyCashTable(
                  items: items,
                  money: money,
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PettyCashTable extends StatelessWidget {
  final List<CompanyAdminPettyCash> items;
  final String Function(double) money;
  final void Function(CompanyAdminPettyCash item) onEdit;
  final void Function(CompanyAdminPettyCash item) onDelete;

  const _PettyCashTable({
    required this.items,
    required this.money,
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
          headingRowHeight: 52,
          dataRowMinHeight: 62,
          dataRowMaxHeight: 72,

          // مهم:
          // ستون عملیات را اول گذاشتیم تا در RTL
          // در سمت راست و کاملاً قابل مشاهده باشد.
          columns: const [
            DataColumn(
              label: Text('عملیات'),
            ),
            DataColumn(
              label: Text('نام تنخواه'),
            ),
            DataColumn(
              label: Text('مسئول'),
            ),
            DataColumn(
              label: Text('اول دوره'),
            ),
            DataColumn(
              label: Text('دریافت'),
            ),
            DataColumn(
              label: Text('پرداخت'),
            ),
            DataColumn(
              label: Text('پایان دوره'),
            ),
            DataColumn(
              label: Text('دفتر'),
            ),
            DataColumn(
              label: Text('مغایرت'),
            ),
            DataColumn(
              label: Text('وضعیت'),
            ),
          ],

          rows: items.map((item) {
            final period = item.periodData;

            return DataRow(
              cells: [
                // عملیات
                DataCell(
                  SizedBox(
                    width: 100,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'ویرایش تنخواه',
                          onPressed: () => onEdit(item),
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 21,
                          ),
                        ),
                        IconButton(
                          tooltip: 'حذف تنخواه',
                          onPressed: () => onDelete(item),
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 21,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // نام
                DataCell(
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // مسئول
                DataCell(
                  SizedBox(
                    width: 180,
                    child: Text(
                      item.responsibleUserId ??
                          'تعیین نشده',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // اول دوره
                DataCell(
                  Text(
                    period == null
                        ? '-'
                        : '${money(period.openingBalance)} ریال',
                  ),
                ),

                // دریافت
                DataCell(
                  Text(
                    period == null
                        ? '-'
                        : '${money(period.totalReceipts)} ریال',
                  ),
                ),

                // پرداخت
                DataCell(
                  Text(
                    period == null
                        ? '-'
                        : '${money(period.totalPayments)} ریال',
                  ),
                ),

                // پایان دوره
                DataCell(
                  Text(
                    period == null
                        ? '-'
                        : '${money(period.closingBalance)} ریال',
                  ),
                ),

                // دفتر
                DataCell(
                  Text(
                    period == null
                        ? '-'
                        : '${money(period.ledgerBalance)} ریال',
                  ),
                ),

                // مغایرت
                DataCell(
                  _DiscrepancyCell(
                    value: period?.discrepancy ?? 0,
                    money: money,
                  ),
                ),

                // وضعیت
                DataCell(
                  _StatusBadge(
                    period: period,
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
  final PettyCashPeriodData? period;

  const _StatusBadge({
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    if (period == null) {
      return _Badge(
        text: 'بدون اطلاعات دوره',
        icon: Icons.info_outline,
        background: const Color(0xfff1f3f5),
        foreground: Colors.black54,
      );
    }

    if (period!.discrepancy != 0) {
      return _Badge(
        text: 'دارای مغایرت',
        icon: Icons.warning_amber_outlined,
        background: const Color(0xfffff3cd),
        foreground: const Color(0xff856404),
      );
    }

    return _Badge(
      text: 'تأیید شده',
      icon: Icons.check_circle_outline,
      background: const Color(0xffe8f5e9),
      foreground: const Color(0xff2e7d32),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color background;
  final Color foreground;

  const _Badge({
    required this.text,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: foreground,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscrepancyCell extends StatelessWidget {
  final double value;
  final String Function(double) money;

  const _DiscrepancyCell({
    required this.value,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    if (value == 0) {
      return const Text(
        '0 ریال',
        style: TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Text(
      '${money(value)} ریال',
      style: const TextStyle(
        color: Colors.red,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String? suffix;
  final IconData icon;
  final bool isWarning;

  const _SummaryCard({
    required this.title,
    required this.value,
    this.suffix,
    required this.icon,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isWarning
                      ? const Color(0xfffff3cd)
                      : const Color(0xffeef2ff),
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isWarning
                      ? const Color(0xff856404)
                      : const Color(0xff3949ab),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      value,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (suffix != null)
                      Text(
                        suffix!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PettyCashFormDialog extends StatelessWidget {
  final String title;
  final TextEditingController nameController;
  final TextEditingController responsibleController;
  final String confirmText;

  const _PettyCashFormDialog({
    required this.title,
    required this.nameController,
    required this.responsibleController,
    required this.confirmText,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'نام تنخواه *',
                hintText: 'مثلاً تنخواه دفتر مرکزی',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text('انصراف'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: Text(confirmText),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 60,
        ),
        child: Column(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'هنوز تنخواهی ثبت نشده است.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'برای شروع، یک حساب تنخواه ایجاد کنید.',
              style: TextStyle(
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 56,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'دریافت اطلاعات تنخواه با خطا مواجه شد.',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
              ),
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