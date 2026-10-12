import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';

import 'package:tarazyar/company_admin/banking/application/company_admin_received_checks_provider.dart';
import 'package:tarazyar/company_admin/dashboard/presentation/widgets/company_admin_scaffold.dart';

class CompanyAdminReceivedChecksPage extends ConsumerWidget {
  const CompanyAdminReceivedChecksPage({super.key});

  String _money(double value) {
    return value.round().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match.group(1)},',
    );
  }

  String _date(DateTime? value) {
    if (value == null) return '-';

    final jalali = Jalali.fromDateTime(value.toLocal());

    return '${jalali.year}/'
        '${jalali.month.toString().padLeft(2, '0')}/'
        '${jalali.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checksAsync = ref.watch(companyAdminReceivedChecksProvider);

    return CompanyAdminScaffold(
      child: Scaffold(
        backgroundColor: const Color(0xfff7f8fa),
        appBar: AppBar(
          title: const Text('چک‌های دریافتی'),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          actions: [
            IconButton(
              tooltip: 'بازخوانی',
              onPressed: () {
                ref.invalidate(companyAdminReceivedChecksProvider);
              },
              icon: const Icon(Icons.refresh),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: checksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, stack) => _ErrorView(
                error: error,
                onRetry: () {
                  ref.invalidate(companyAdminReceivedChecksProvider);
                },
              ),
          data: (items) {
            return _ReceivedChecksContent(
              items: items,
              money: _money,
              date: _date,
              onAdd: () => _showAddDialog(context, ref),
              onEdit: (item) => _showEditDialog(context, ref, item),
              onDelete: (item) => _showDeleteDialog(context, ref, item),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_ReceivedCheckFormResult>(
      context: context,
      builder:
          (_) => const _ReceivedCheckFormDialog(
            title: 'افزودن چک دریافتی',
            confirmText: 'ثبت چک',
          ),
    );

    if (result == null) return;

    try {
      await ref
          .read(companyAdminReceivedChecksControllerProvider)
          .addCheck(
            checkNumber: result.checkNumber,
            bankName: result.bankName,
            amount: result.amount,
            dueDate: result.dueDate,
            status: result.status,
          );

      if (context.mounted) {
        _showMessage(context, 'چک دریافتی با موفقیت ثبت شد.');
      }
    } catch (e) {
      if (context.mounted) {
        _showMessage(context, 'خطا در ثبت چک:\n$e', isError: true);
      }
    }
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    CompanyAdminReceivedCheck item,
  ) async {
    final result = await showDialog<_ReceivedCheckFormResult>(
      context: context,
      builder:
          (_) => _ReceivedCheckFormDialog(
            title: 'ویرایش چک دریافتی',
            confirmText: 'ذخیره تغییرات',
            initial: item,
          ),
    );

    if (result == null) return;

    try {
      await ref
          .read(companyAdminReceivedChecksControllerProvider)
          .updateCheck(
            id: item.id,
            checkNumber: result.checkNumber,
            bankName: result.bankName,
            amount: result.amount,
            dueDate: result.dueDate,
            status: result.status,
          );

      if (context.mounted) {
        _showMessage(context, 'چک با موفقیت ویرایش شد.');
      }
    } catch (e) {
      if (context.mounted) {
        _showMessage(context, 'خطا در ویرایش چک:\n$e', isError: true);
      }
    }
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    CompanyAdminReceivedCheck item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('حذف چک دریافتی'),
          content: Text(
            'آیا از حذف چک '
            '«${item.checkNumber ?? 'بدون شماره'}» '
            'مطمئن هستید؟',
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
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(companyAdminReceivedChecksControllerProvider)
          .deleteCheck(item.id);

      if (context.mounted) {
        _showMessage(context, 'چک حذف شد.');
      }
    } catch (e) {
      if (context.mounted) {
        _showMessage(context, 'حذف چک انجام نشد:\n$e', isError: true);
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

class _ReceivedChecksContent extends StatelessWidget {
  final List<CompanyAdminReceivedCheck> items;
  final String Function(double) money;
  final String Function(DateTime?) date;
  final VoidCallback onAdd;
  final void Function(CompanyAdminReceivedCheck) onEdit;
  final void Function(CompanyAdminReceivedCheck) onDelete;

  const _ReceivedChecksContent({
    required this.items,
    required this.money,
    required this.date,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final totalAmount = items.fold<double>(0, (sum, item) => sum + item.amount);

    final today = DateTime.now();

    final dueItems =
        items.where((item) {
          if (item.dueDate == null) return false;

          final due = item.dueDate!.toLocal();

          return !due.isAfter(DateTime(today.year, today.month, today.day));
        }).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مدیریت چک‌های دریافتی',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'مدیریت چک‌های دریافتی شرکت و تاریخ سررسید آن‌ها',
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('افزودن چک'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SummaryCard(
                title: 'تعداد چک',
                value: '${items.length}',
                icon: Icons.receipt_long_outlined,
              ),
              _SummaryCard(
                title: 'مجموع مبلغ',
                value: money(totalAmount),
                suffix: 'ریال',
                icon: Icons.payments_outlined,
              ),
              _SummaryCard(
                title: 'سررسید شده',
                value: '$dueItems',
                icon: Icons.event_busy_outlined,
                warning: dueItems > 0,
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (items.isEmpty)
            const _EmptyState()
          else
            _ReceivedChecksTable(
              items: items,
              money: money,
              date: date,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
        ],
      ),
    );
  }
}

class _ReceivedChecksTable extends StatelessWidget {
  final List<CompanyAdminReceivedCheck> items;
  final String Function(double) money;
  final String Function(DateTime?) date;
  final void Function(CompanyAdminReceivedCheck) onEdit;
  final void Function(CompanyAdminReceivedCheck) onDelete;

  const _ReceivedChecksTable({
    required this.items,
    required this.money,
    required this.date,
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
          dataRowMinHeight: 64,
          dataRowMaxHeight: 76,
          columns: const [
            DataColumn(label: Text('عملیات')),
            DataColumn(label: Text('شماره چک')),
            DataColumn(label: Text('بانک')),
            DataColumn(label: Text('مبلغ')),
            DataColumn(label: Text('سررسید')),
            DataColumn(label: Text('وضعیت')),
          ],
          rows:
              items.map((item) {
                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'ویرایش',
                              onPressed: () => onEdit(item),
                              icon: const Icon(Icons.edit_outlined, size: 21),
                            ),
                            IconButton(
                              tooltip: 'حذف',
                              onPressed: () => onDelete(item),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 21,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        item.checkNumber?.isNotEmpty == true
                            ? item.checkNumber!
                            : '-',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DataCell(
                      Text(
                        item.bankName?.isNotEmpty == true
                            ? item.bankName!
                            : '-',
                      ),
                    ),
                    DataCell(Text('${money(item.amount)} ریال')),
                    DataCell(Text(date(item.dueDate))),
                    DataCell(
                      _StatusBadge(status: item.status, dueDate: item.dueDate),
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
  final String? status;
  final DateTime? dueDate;

  const _StatusBadge({required this.status, required this.dueDate});

  @override
  Widget build(BuildContext context) {
    final value = status?.trim();

    if (value == null || value.isEmpty) {
      return const _Badge(
        text: 'بدون وضعیت',
        icon: Icons.info_outline,
        background: Color(0xfff1f3f5),
        foreground: Colors.black54,
      );
    }

    final lower = value.toLowerCase();

    if (lower.contains('paid') ||
        lower.contains('cleared') ||
        lower.contains('وصول') ||
        lower.contains('پرداخت')) {
      return _Badge(
        text: value,
        icon: Icons.check_circle_outline,
        background: const Color(0xffe8f5e9),
        foreground: const Color(0xff2e7d32),
      );
    }

    if (lower.contains('returned') ||
        lower.contains('bounced') ||
        lower.contains('برگشت')) {
      return _Badge(
        text: value,
        icon: Icons.cancel_outlined,
        background: const Color(0xffffebee),
        foreground: const Color(0xffc62828),
      );
    }

    return _Badge(
      text: value,
      icon: Icons.schedule_outlined,
      background: const Color(0xfffff3cd),
      foreground: const Color(0xff856404),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
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

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String? suffix;
  final IconData icon;
  final bool warning;

  const _SummaryCard({
    required this.title,
    required this.value,
    this.suffix,
    required this.icon,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                      warning
                          ? const Color(0xfffff3cd)
                          : const Color(0xffeef2ff),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color:
                      warning
                          ? const Color(0xff856404)
                          : const Color(0xff3949ab),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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

class _ReceivedCheckFormResult {
  final String? checkNumber;
  final String? bankName;
  final double amount;
  final DateTime? dueDate;
  final String? status;

  const _ReceivedCheckFormResult({
    required this.checkNumber,
    required this.bankName,
    required this.amount,
    required this.dueDate,
    required this.status,
  });
}

class _ReceivedCheckFormDialog extends StatefulWidget {
  final String title;
  final String confirmText;
  final CompanyAdminReceivedCheck? initial;

  const _ReceivedCheckFormDialog({
    required this.title,
    required this.confirmText,
    this.initial,
  });

  @override
  State<_ReceivedCheckFormDialog> createState() =>
      _ReceivedCheckFormDialogState();
}

class _ReceivedCheckFormDialogState extends State<_ReceivedCheckFormDialog> {
  late final TextEditingController checkNumberController;
  late final TextEditingController bankController;
  late final TextEditingController amountController;
  late final TextEditingController statusController;

  DateTime? dueDate;

  @override
  void initState() {
    super.initState();

    final initial = widget.initial;

    checkNumberController = TextEditingController(
      text: initial?.checkNumber ?? '',
    );

    bankController = TextEditingController(text: initial?.bankName ?? '');

    amountController = TextEditingController(
      text: initial == null ? '' : _numberText(initial.amount),
    );

    statusController = TextEditingController(text: initial?.status ?? '');

    dueDate = initial?.dueDate;
  }

  String _numberText(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }

    return value.toString();
  }

  @override
  void dispose() {
    checkNumberController.dispose();
    bankController.dispose();
    amountController.dispose();
    statusController.dispose();
    super.dispose();
  }

  double? _number(String value) {
    final normalized = value
        .trim()
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll(' ', '');

    return double.tryParse(normalized);
  }

  String _dateText(DateTime? value) {
    if (value == null) {
      return 'انتخاب نشده';
    }

    final jalali = Jalali.fromDateTime(value.toLocal());

    return '${jalali.year}/'
        '${jalali.month.toString().padLeft(2, '0')}/'
        '${jalali.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDueDate() async {
    final selected = await _showJalaliDatePicker(
      context,
      initialDate: dueDate,
      title: 'انتخاب تاریخ سررسید',
    );

    if (selected != null) {
      setState(() {
        dueDate = selected;
      });
    }
  }

  void _submit() {
    final amount = _number(amountController.text);

    if (amount == null || amount < 0) {
      _error('مبلغ چک معتبر نیست.');
      return;
    }

    Navigator.of(context).pop(
      _ReceivedCheckFormResult(
        checkNumber:
            checkNumberController.text.trim().isEmpty
                ? null
                : checkNumberController.text.trim(),
        bankName:
            bankController.text.trim().isEmpty
                ? null
                : bankController.text.trim(),
        amount: amount,
        dueDate: dueDate,
        status:
            statusController.text.trim().isEmpty
                ? null
                : statusController.text.trim(),
      ),
    );
  }

  void _error(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: checkNumberController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'شماره چک',
                  hintText: 'شماره چک را وارد کنید',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: bankController,
                decoration: const InputDecoration(
                  labelText: 'نام بانک',
                  hintText: 'مثلاً بانک ملت',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'مبلغ *',
                  suffixText: 'ریال',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: statusController,
                decoration: const InputDecoration(
                  labelText: 'وضعیت',
                  hintText: 'مثلاً در انتظار وصول، وصول شده، برگشتی',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickDueDate,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text('سررسید: ${_dateText(dueDate)}'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('انصراف'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmText)),
      ],
    );
  }
}

/// ------------------------------------------------------------
/// تقویم شمسی
/// ------------------------------------------------------------

Future<DateTime?> _showJalaliDatePicker(
  BuildContext context, {
  DateTime? initialDate,
  required String title,
}) async {
  final initialJalali =
      initialDate == null
          ? Jalali.now()
          : Jalali.fromDateTime(initialDate.toLocal());

  return showDialog<DateTime>(
    context: context,
    builder: (_) {
      return _JalaliDatePickerDialog(title: title, initialDate: initialJalali);
    },
  );
}

class _JalaliDatePickerDialog extends StatefulWidget {
  final String title;
  final Jalali initialDate;

  const _JalaliDatePickerDialog({
    required this.title,
    required this.initialDate,
  });

  @override
  State<_JalaliDatePickerDialog> createState() =>
      _JalaliDatePickerDialogState();
}

class _JalaliDatePickerDialogState extends State<_JalaliDatePickerDialog> {
  late int selectedYear;
  late int selectedMonth;
  late int selectedDay;

  late int visibleYear;
  late int visibleMonth;

  final List<String> monthNames = const [
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

  final List<String> weekDays = const [
    'شنبه',
    'یکشنبه',
    'دوشنبه',
    'سه‌شنبه',
    'چهارشنبه',
    'پنجشنبه',
    'جمعه',
  ];

  @override
  void initState() {
    super.initState();

    selectedYear = widget.initialDate.year;
    selectedMonth = widget.initialDate.month;
    selectedDay = widget.initialDate.day;

    visibleYear = selectedYear;
    visibleMonth = selectedMonth;
  }

  int get daysInMonth {
    return Jalali(visibleYear, visibleMonth, 1).monthLength;
  }

  int get firstWeekDay {
    return Jalali(visibleYear, visibleMonth, 1).weekDay;
  }

  void _previousMonth() {
    setState(() {
      if (visibleMonth == 1) {
        visibleMonth = 12;
        visibleYear--;
      } else {
        visibleMonth--;
      }

      final maxDay = Jalali(visibleYear, visibleMonth, 1).monthLength;

      if (selectedYear == visibleYear &&
          selectedMonth == visibleMonth &&
          selectedDay > maxDay) {
        selectedDay = maxDay;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (visibleMonth == 12) {
        visibleMonth = 1;
        visibleYear++;
      } else {
        visibleMonth++;
      }

      final maxDay = Jalali(visibleYear, visibleMonth, 1).monthLength;

      if (selectedYear == visibleYear &&
          selectedMonth == visibleMonth &&
          selectedDay > maxDay) {
        selectedDay = maxDay;
      }
    });
  }

  void _goToToday() {
    final today = Jalali.now();

    setState(() {
      visibleYear = today.year;
      visibleMonth = today.month;

      selectedYear = today.year;
      selectedMonth = today.month;
      selectedDay = today.day;
    });
  }

  void _selectDay(int day) {
    setState(() {
      selectedYear = visibleYear;
      selectedMonth = visibleMonth;
      selectedDay = day;
    });
  }

  void _confirm() {
    final jalali = Jalali(selectedYear, selectedMonth, selectedDay);

    Navigator.of(context).pop(jalali.toDateTime());
  }

  @override
  Widget build(BuildContext context) {
    final firstDayOffset = firstWeekDay - 1;
    final totalCells = firstDayOffset + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox(
        width: 430,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'امروز',
                      onPressed: _goToToday,
                      icon: const Icon(Icons.today_outlined),
                    ),
                    IconButton(
                      tooltip: 'بستن',
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffeef7f3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'ماه قبل',
                        onPressed: _previousMonth,
                        icon: const Icon(Icons.chevron_right),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            '${monthNames[visibleMonth - 1]} $visibleYear',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'ماه بعد',
                        onPressed: _nextMonth,
                        icon: const Icon(Icons.chevron_left),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children:
                      weekDays.map((day) {
                        return Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color:
                                    day == 'جمعه'
                                        ? Colors.red.shade600
                                        : Colors.black54,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: rowCount * 46,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                        ),
                    itemCount: rowCount * 7,
                    itemBuilder: (context, index) {
                      if (index < firstDayOffset ||
                          index >= firstDayOffset + daysInMonth) {
                        return const SizedBox.shrink();
                      }

                      final day = index - firstDayOffset + 1;

                      final isSelected =
                          selectedYear == visibleYear &&
                          selectedMonth == visibleMonth &&
                          selectedDay == day;

                      final dayOfWeek = (index % 7) + 1;

                      final isFriday = dayOfWeek == 7;

                      return InkWell(
                        borderRadius: BorderRadius.circular(50),
                        onTap: () => _selectDay(day),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? const Color(0xff17815b)
                                    : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            day.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color:
                                  isSelected
                                      ? Colors.white
                                      : isFriday
                                      ? Colors.red.shade600
                                      : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'تاریخ انتخاب‌شده: '
                    '$selectedYear/'
                    '${selectedMonth.toString().padLeft(2, '0')}/'
                    '${selectedDay.toString().padLeft(2, '0')}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('انصراف'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _confirm,
                      child: const Text('تأیید'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'هنوز چک دریافتی ثبت نشده است.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'برای شروع، یک چک دریافتی ثبت کنید.',
              style: TextStyle(color: Colors.black54),
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

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'دریافت اطلاعات چک‌ها با خطا مواجه شد.',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SelectableText(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
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
