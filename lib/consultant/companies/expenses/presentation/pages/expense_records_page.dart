import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:tarazyar/consultant/companies/expenses/application/expense_dashboard_provider.dart';
import 'package:tarazyar/consultant/companies/expenses/presentation/widgets/expense_record_dialog.dart';
import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

import '../../application/expense_categories_provider.dart';
import '../../application/expense_provider.dart';
import '../../data/expense_model.dart';


class ExpenseRecordsPage extends ConsumerWidget {
  const ExpenseRecordsPage({super.key, required this.companyId});

  final String companyId;

  static const routeName = 'expense-records';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider(companyId));

    return CompanyScaffold(
      companyId: companyId,
      currentRoute: '/consultant/companies/$companyId/expenses/records',
      title: 'هزینه‌ها',
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => _ErrorView(
              message: error.toString(),
              onRetry: () {
                ref.invalidate(expensesProvider(companyId));
              },
            ),
        data: (expenses) {
          if (expenses.isEmpty) {
            return _EmptyView(onAdd: () => _openExpenseDialog(context, ref));
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(expensesProvider(companyId));
              ref.invalidate(expenseDashboardProvider(companyId));
              await ref.read(expensesProvider(companyId).future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: expenses.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _Header(
                    count: expenses.length,
                    onAdd: () => _openExpenseDialog(context, ref),
                  );
                }

                final expense = expenses[index - 1];

                return _ExpenseCard(
                  expense: expense,
                  onEdit:
                      () => _openExpenseDialog(context, ref, expense: expense),
                  onDelete: () => _deleteExpense(context, ref, expense),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _openExpenseDialog(
    BuildContext context,
    WidgetRef ref, {
    ExpenseModel? expense,
  }) async {
    final categories = await ref.read(
      activeExpenseCategoriesProvider(companyId).future,
    );

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder:
          (_) => ExpenseRecordDialog(
            companyId: companyId,
            categories: categories,
            expense: expense,
          ),
    );

    ref.invalidate(expensesProvider(companyId));
    ref.invalidate(expenseDashboardProvider(companyId));
  }

  Future<void> _deleteExpense(
    BuildContext context,
    WidgetRef ref,
    ExpenseModel expense,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('حذف هزینه'),
          content: Text('آیا از حذف «${expense.title}» مطمئن هستید؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('انصراف'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(expenseRepositoryProvider);

      await repository.deleteExpense(expense.id);

      ref.invalidate(expensesProvider(companyId));
      ref.invalidate(expenseDashboardProvider(companyId));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('هزینه با موفقیت حذف شد.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا در حذف هزینه: $error')));
      }
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count, required this.onAdd});

  final int count;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'لیست هزینه‌ها',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_persianDigits(count.toString())} مورد ثبت شده',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('ثبت هزینه'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });

  final ExpenseModel expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final date = _formatJalali(expense.expenseDate);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Icon(
                    expense.isPayroll
                        ? Icons.receipt_long
                        : Icons.payments_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (expense.categoryName != null) ...[
                        const SizedBox(height: 4),
                        Text(expense.categoryName!),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder:
                      (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('ویرایش')),
                        PopupMenuItem(value: 'delete', child: Text('حذف')),
                      ],
                ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(icon: Icons.calendar_today_outlined, label: date),
                _InfoChip(
                  icon: Icons.category_outlined,
                  label: expense.isOperational ? 'عملیاتی' : 'غیرعملیاتی',
                ),
                _InfoChip(
                  icon:
                      expense.isPayroll
                          ? Icons.badge_outlined
                          : Icons.edit_note_outlined,
                  label: expense.isPayroll ? 'حقوق و دستمزد' : 'دستی',
                ),
              ],
            ),
            if (expense.isPayroll &&
                expense.payrollPeriodYear != null &&
                expense.payrollPeriodMonth != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'دوره حقوق: ${_jalaliMonthName(expense.payrollPeriodMonth!)} ${_persianDigits(expense.payrollPeriodYear!.toString())}',
                ),
              ),
            ],
            if (expense.description != null &&
                expense.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(expense.description!),
              ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_formatAmount(expense.amount)} ریال',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 17), label: Text(label));
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 72),
            const SizedBox(height: 16),
            const Text(
              'هنوز هزینه‌ای ثبت نشده است.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'اولین هزینه شرکت را ثبت کنید.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('ثبت اولین هزینه'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56),
            const SizedBox(height: 12),
            const Text(
              'خطا در دریافت هزینه‌ها',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('تلاش مجدد')),
          ],
        ),
      ),
    );
  }
}

String _formatJalali(DateTime date) {
  final jalali = Jalali.fromDateTime(date);

  return '${_persianDigits(jalali.year.toString())}/'
      '${_persianDigits(jalali.month.toString().padLeft(2, '0'))}/'
      '${_persianDigits(jalali.day.toString().padLeft(2, '0'))}';
}

String _jalaliMonthName(int month) {
  const months = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  if (month < 1 || month > 12) {
    return month.toString();
  }

  return months[month - 1];
}

String _formatAmount(num amount) {
  final value = amount.round().toString();

  final buffer = StringBuffer();

  for (var i = 0; i < value.length; i++) {
    final reverseIndex = value.length - i;

    buffer.write(value[i]);

    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }

  return _persianDigits(buffer.toString());
}

String _persianDigits(String value) {
  const english = '0123456789';
  const persian = '۰۱۲۳۴۵۶۷۸۹';

  return value.split('').map((char) {
    final index = english.indexOf(char);

    if (index == -1) return char;

    return persian[index];
  }).join();
}
