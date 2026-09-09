import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

import '../../application/income_dashboard_provider.dart';
import '../../application/income_provider.dart';
import '../widgets/income_record_dialog.dart';

class IncomeRecordsPage extends ConsumerWidget {
  final String companyId;

  const IncomeRecordsPage({super.key, required this.companyId});

  String _toPersianDigits(String value) {
    const english = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';

    var result = value;

    for (var i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], persian[i]);
    }

    return result;
  }

  String _formatAmount(dynamic value) {
    final number = num.tryParse(value?.toString() ?? '');

    if (number == null) return '۰';

    final text =
        number.truncateToDouble() == number
            ? number.toStringAsFixed(0)
            : number.toStringAsFixed(2);

    final parts = text.split('.');

    final integerPart = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    final result = parts.length > 1 ? '$integerPart.${parts[1]}' : integerPart;

    return _toPersianDigits(result);
  }

  String _formatJalaliDate(dynamic value) {
    if (value == null) return '-';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return '-';

    final jalali = Jalali.fromDateTime(date);

    return '${_toPersianDigits(jalali.year.toString())}/'
        '${_toPersianDigits(jalali.month.toString().padLeft(2, '0'))}/'
        '${_toPersianDigits(jalali.day.toString().padLeft(2, '0'))}';
  }

  String _statusText(String status) {
    switch (status) {
      case 'received':
        return 'دریافت شده';
      case 'pending':
        return 'در انتظار';
      case 'cancelled':
        return 'لغو شده';
      default:
        return status;
    }
  }

  Color _statusColor(BuildContext context, String status) {
    switch (status) {
      case 'received':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => IncomeRecordDialog(companyId: companyId),
    );

    if (result == true) {
      ref.invalidate(incomeProvider(companyId));
      ref.invalidate(incomeDashboardProvider(companyId));
    }
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> record,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => IncomeRecordDialog(companyId: companyId, record: record),
    );

    if (result == true) {
      ref.invalidate(incomeProvider(companyId));
      ref.invalidate(incomeDashboardProvider(companyId));
    }
  }

  Future<void> _deleteRecord(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> record,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('حذف درآمد'),
            content: Text(
              'آیا از حذف «${record['title'] ?? '-'}» اطمینان دارید؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('انصراف'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('حذف'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;

    try {
      final service = ref.read(incomeServiceProvider);

      await service.deleteIncome(record['id'].toString());

      ref.invalidate(incomeProvider(companyId));
      ref.invalidate(incomeDashboardProvider(companyId));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('درآمد با موفقیت حذف شد.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _statusChip(BuildContext context, String status) {
    final color = _statusColor(context, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusText(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeAsync = ref.watch(incomeProvider(companyId));

    return CompanyScaffold(
      currentRoute: '/consultant/companies/$companyId/income/records',
      companyId: companyId,
      title: 'درآمدها',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'درآمدها',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'مدیریت و ثبت درآمدهای شرکت',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showCreateDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('ثبت درآمد'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: incomeAsync.when(
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error:
                      (error, stack) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 48),
                            const SizedBox(height: 12),
                            const Text(
                              'خطا در دریافت درآمدها',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              error.toString().replaceFirst('Exception: ', ''),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () {
                                ref.invalidate(incomeProvider(companyId));
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('تلاش مجدد'),
                            ),
                          ],
                        ),
                      ),
                  data: (records) {
                    if (records.isEmpty) {
                      return _emptyState(context, ref);
                    }

                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth,
                              ),
                              child: SingleChildScrollView(
                                child: DataTable(
                                  headingRowHeight: 52,
                                  dataRowMinHeight: 64,
                                  dataRowMaxHeight: 76,
                                  columnSpacing: 28,
                                  columns: const [
                                    DataColumn(label: Text('عنوان')),
                                    DataColumn(label: Text('دسته‌بندی')),
                                    DataColumn(label: Text('مبلغ')),
                                    DataColumn(label: Text('تاریخ')),
                                    DataColumn(label: Text('وضعیت')),
                                    DataColumn(label: Text('شماره مرجع')),
                                    DataColumn(label: Text('عملیات')),
                                  ],
                                  rows:
                                      records.map((record) {
                                        final category =
                                            record['income_categories'];

                                        final categoryName =
                                            category is Map
                                                ? category['name']
                                                        ?.toString() ??
                                                    '-'
                                                : '-';

                                        final status =
                                            record['status']?.toString() ??
                                            'received';

                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              SizedBox(
                                                width: 180,
                                                child: Text(
                                                  record['title']?.toString() ??
                                                      '-',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(Text(categoryName)),
                                            DataCell(
                                              Text(
                                                '${_formatAmount(record['amount'])} ریال',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                _formatJalaliDate(
                                                  record['income_date'],
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              _statusChip(context, status),
                                            ),
                                            DataCell(
                                              Text(
                                                record['reference_number']
                                                        ?.toString() ??
                                                    '-',
                                              ),
                                            ),
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    tooltip: 'ویرایش',
                                                    onPressed:
                                                        () => _showEditDialog(
                                                          context,
                                                          ref,
                                                          record,
                                                        ),
                                                    icon: const Icon(
                                                      Icons.edit_outlined,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    tooltip: 'حذف',
                                                    onPressed:
                                                        () => _deleteRecord(
                                                          context,
                                                          ref,
                                                          record,
                                                        ),
                                                    icon: const Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.red,
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
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'هنوز درآمدی ثبت نشده است',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'اولین درآمد شرکت را ثبت کنید.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _showCreateDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('ثبت اولین درآمد'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
