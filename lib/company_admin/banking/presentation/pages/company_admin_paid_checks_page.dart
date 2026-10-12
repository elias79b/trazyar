import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';

import 'package:tarazyar/company_admin/banking/application/company_admin_paid_checks_provider.dart';
import 'package:tarazyar/company_admin/dashboard/presentation/widgets/company_admin_scaffold.dart';

class CompanyAdminPaidChecksPage extends ConsumerStatefulWidget {
  const CompanyAdminPaidChecksPage({super.key});

  @override
  ConsumerState<CompanyAdminPaidChecksPage> createState() =>
      _CompanyAdminPaidChecksPageState();
}

class _CompanyAdminPaidChecksPageState
    extends ConsumerState<CompanyAdminPaidChecksPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(
      () => ref.read(companyAdminPaidChecksProvider.notifier).load(),
    );
  }

  String _formatAmount(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';

    final jalali = Jalali.fromDateTime(date);

    return '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')}';
  }

  bool _isOverdue(CompanyAdminPaidCheck check) {
    if (check.dueDate == null) return false;

    return check.dueDate!.isBefore(
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'پرداخت شده':
        return Colors.green;

      case 'cancelled':
      case 'canceled':
      case 'لغو شده':
        return Colors.red;

      case 'pending':
      case 'در انتظار':
        return Colors.orange;

      case 'returned':
      case 'برگشتی':
        return Colors.deepOrange;

      default:
        return Colors.blueGrey;
    }
  }

  String _statusTitle(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'پرداخت شده';
      case 'pending':
        return 'در انتظار';
      case 'cancelled':
      case 'canceled':
        return 'لغو شده';
      case 'returned':
        return 'برگشتی';
      default:
        return status.isEmpty ? 'در انتظار' : status;
    }
  }

  Future<void> _showCheckDialog({CompanyAdminPaidCheck? check}) async {
    final checkNumberController = TextEditingController(
      text: check?.checkNumber ?? '',
    );

    final bankController = TextEditingController(text: check?.bankName ?? '');

    final amountController = TextEditingController(
      text: check == null ? '' : check.amount.toStringAsFixed(0),
    );

    DateTime? selectedDate = check?.dueDate;

    String selectedStatus = check?.status ?? 'pending';

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                check == null ? 'ثبت چک پرداختی' : 'ویرایش چک پرداختی',
              ),
              content: SizedBox(
                width: 500,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: checkNumberController,
                          decoration: const InputDecoration(
                            labelText: 'شماره چک',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: bankController,
                          decoration: const InputDecoration(
                            labelText: 'بانک',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'مبلغ',
                            suffixText: 'ریال',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'مبلغ را وارد کنید';
                            }

                            final amount = double.tryParse(
                              value.replaceAll(',', ''),
                            );

                            if (amount == null || amount < 0) {
                              return 'مبلغ نامعتبر است';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () async {
                            final picked = await _showJalaliDatePicker(
                              context,
                              initialDate: selectedDate,
                            );

                            if (picked != null) {
                              setDialogState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'تاریخ سررسید',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_month),
                            ),
                            child: Text(_formatDate(selectedDate)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'وضعیت',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'pending',
                              child: Text('در انتظار'),
                            ),
                            DropdownMenuItem(
                              value: 'paid',
                              child: Text('پرداخت شده'),
                            ),
                            DropdownMenuItem(
                              value: 'returned',
                              child: Text('برگشتی'),
                            ),
                            DropdownMenuItem(
                              value: 'cancelled',
                              child: Text('لغو شده'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                selectedStatus = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('انصراف'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    final amount = double.parse(
                      amountController.text.replaceAll(',', ''),
                    );

                    try {
                      final notifier = ref.read(
                        companyAdminPaidChecksProvider.notifier,
                      );

                      if (check == null) {
                        await notifier.createCheck(
                          checkNumber: checkNumberController.text,
                          bankName: bankController.text,
                          amount: amount,
                          dueDate: selectedDate,
                          status: selectedStatus,
                        );
                      } else {
                        await notifier.updateCheck(
                          id: check.id,
                          checkNumber: checkNumberController.text,
                          bankName: bankController.text,
                          amount: amount,
                          dueDate: selectedDate,
                          status: selectedStatus,
                        );
                      }

                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              check == null
                                  ? 'چک با موفقیت ثبت شد'
                                  : 'چک با موفقیت ویرایش شد',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(
                          dialogContext,
                        ).showSnackBar(SnackBar(content: Text('خطا: $e')));
                      }
                    }
                  },
                  child: Text(check == null ? 'ثبت' : 'ذخیره'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<DateTime?> _showJalaliDatePicker(
    BuildContext context, {
    DateTime? initialDate,
  }) async {
    Jalali current =
        initialDate != null ? Jalali.fromDateTime(initialDate) : Jalali.now();

    Jalali selected = current;

    return showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final monthName = _jalaliMonthName(current.month);

            final firstDay = Jalali(current.year, current.month, 1);
            final daysInMonth =
                current.month <= 6
                    ? 31
                    : current.month <= 11
                    ? 30
                    : current.isLeapYear()
                    ? 30
                    : 29;

            final startWeekday = firstDay.weekDay;

            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        current = current.addMonths(-1);
                      });
                    },
                    icon: const Icon(Icons.chevron_right),
                  ),
                  Text('$monthName ${current.year}'),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        current = current.addMonths(1);
                      });
                    },
                    icon: const Icon(Icons.chevron_left),
                  ),
                ],
              ),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: const [
                        Expanded(child: Center(child: Text('ش'))),
                        Expanded(child: Center(child: Text('ی'))),
                        Expanded(child: Center(child: Text('د'))),
                        Expanded(child: Center(child: Text('س'))),
                        Expanded(child: Center(child: Text('چ'))),
                        Expanded(child: Center(child: Text('پ'))),
                        Expanded(child: Center(child: Text('ج'))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      itemCount: startWeekday - 1 + daysInMonth,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                          ),
                      itemBuilder: (context, index) {
                        if (index < startWeekday - 1) {
                          return const SizedBox.shrink();
                        }

                        final day = index - startWeekday + 2;

                        final isSelected =
                            selected.year == current.year &&
                            selected.month == current.month &&
                            selected.day == day;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              selected = Jalali(
                                current.year,
                                current.month,
                                day,
                              );
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                            ),
                            child: Center(
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : null,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        final today = Jalali.now();

                        setState(() {
                          current = today;
                          selected = today;
                        });
                      },
                      child: const Text('امروز'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('انصراف'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(selected.toDateTime());
                  },
                  child: const Text('انتخاب'),
                ),
              ],
            );
          },
        );
      },
    );
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

    return months[month - 1];
  }

  Future<void> _deleteCheck(CompanyAdminPaidCheck check) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف چک'),
          content: Text(
            'آیا از حذف چک ${check.checkNumber ?? 'بدون شماره'} مطمئن هستید؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('انصراف'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(companyAdminPaidChecksProvider.notifier)
          .deleteCheck(check.id);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('چک با موفقیت حذف شد')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا در حذف: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(companyAdminPaidChecksProvider);
    final checks = state.checks;

    final totalAmount = checks.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );

    final pendingCount =
        checks.where((item) => item.status == 'pending').length;

    final overdueCount = checks.where(_isOverdue).length;

    return CompanyAdminScaffold(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('چک‌های پرداختی'),
          actions: [
            IconButton(
              onPressed:
                  state.isLoading
                      ? null
                      : () =>
                          ref
                              .read(companyAdminPaidChecksProvider.notifier)
                              .load(),
              icon: const Icon(Icons.refresh),
              tooltip: 'بروزرسانی',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body:
            state.isLoading && checks.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                  onRefresh:
                      () =>
                          ref
                              .read(companyAdminPaidChecksProvider.notifier)
                              .load(),
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      if (state.error != null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              state.error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              title: 'تعداد چک‌ها',
                              value: '${checks.length}',
                              icon: Icons.receipt_long,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _SummaryCard(
                              title: 'مجموع مبلغ',
                              value: '${_formatAmount(totalAmount)} ریال',
                              icon: Icons.payments,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _SummaryCard(
                              title: 'در انتظار',
                              value: '$pendingCount',
                              icon: Icons.pending_actions,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _SummaryCard(
                              title: 'سررسید گذشته',
                              value: '$overdueCount',
                              icon: Icons.warning_amber,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: () => _showCheckDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('ثبت چک پرداختی'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child:
                            checks.isEmpty
                                ? const Padding(
                                  padding: EdgeInsets.all(40),
                                  child: Center(
                                    child: Text(
                                      'هنوز چک پرداختی ثبت نشده است.',
                                    ),
                                  ),
                                )
                                : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columns: const [
                                      DataColumn(label: Text('عملیات')),
                                      DataColumn(label: Text('شماره چک')),
                                      DataColumn(label: Text('بانک')),
                                      DataColumn(label: Text('مبلغ')),
                                      DataColumn(label: Text('سررسید')),
                                      DataColumn(label: Text('وضعیت')),
                                    ],
                                    rows:
                                        checks.map((check) {
                                          final overdue = _isOverdue(check);

                                          return DataRow(
                                            cells: [
                                              DataCell(
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      tooltip: 'ویرایش',
                                                      onPressed:
                                                          () =>
                                                              _showCheckDialog(
                                                                check: check,
                                                              ),
                                                      icon: const Icon(
                                                        Icons.edit_outlined,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      tooltip: 'حذف',
                                                      onPressed:
                                                          () => _deleteCheck(
                                                            check,
                                                          ),
                                                      icon: const Icon(
                                                        Icons.delete_outline,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              DataCell(
                                                Text(check.checkNumber ?? '—'),
                                              ),
                                              DataCell(
                                                Text(check.bankName ?? '—'),
                                              ),
                                              DataCell(
                                                Text(
                                                  '${_formatAmount(check.amount)} ریال',
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  _formatDate(check.dueDate),
                                                  style: TextStyle(
                                                    color:
                                                        overdue
                                                            ? Colors.red
                                                            : null,
                                                    fontWeight:
                                                        overdue
                                                            ? FontWeight.bold
                                                            : null,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: _statusColor(
                                                      check.status,
                                                    ).withOpacity(0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    _statusTitle(check.status),
                                                    style: TextStyle(
                                                      color: _statusColor(
                                                        check.status,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(child: Icon(icon)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
