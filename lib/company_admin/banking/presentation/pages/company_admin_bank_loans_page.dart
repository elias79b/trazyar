import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';

import 'package:tarazyar/company_admin/banking/application/company_admin_bank_loans_provider.dart';
import 'package:tarazyar/company_admin/dashboard/presentation/widgets/company_admin_scaffold.dart';

class CompanyAdminBankLoansPage extends ConsumerWidget {
  const CompanyAdminBankLoansPage({super.key});

  String _money(double value) {
    return value
        .round()
        .toString()
        .replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match.group(1)},',
    );
  }

  String _date(DateTime? value) {
    if (value == null) return '-';

    final jalali = Jalali.fromDateTime(value.toLocal());

    return '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(companyAdminBankLoansProvider);

    return CompanyAdminScaffold(
      child: Scaffold(
        backgroundColor: const Color(0xfff7f8fa),
        appBar: AppBar(
          title: const Text('وام‌های بانکی'),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          actions: [
            IconButton(
              tooltip: 'بازخوانی',
              onPressed: () {
                ref.invalidate(companyAdminBankLoansProvider);
              },
              icon: const Icon(Icons.refresh),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: loansAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => _ErrorView(
            error: error,
            onRetry: () {
              ref.invalidate(companyAdminBankLoansProvider);
            },
          ),
          data: (items) {
            return _LoanContent(
              items: items,
              money: _money,
              date: _date,
              onAdd: () => _showAddDialog(context, ref),
              onEdit: (loan) =>
                  _showEditDialog(context, ref, loan),
              onDelete: (loan) =>
                  _showDeleteDialog(context, ref, loan),
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
    final result = await showDialog<_LoanFormResult>(
      context: context,
      builder: (_) => const _LoanFormDialog(
        title: 'افزودن وام بانکی',
        confirmText: 'ثبت وام',
      ),
    );

    if (result == null) return;

    try {
      await ref
          .read(companyAdminBankLoansControllerProvider)
          .addLoan(
        bankName: result.bankName,
        loanType: result.loanType,
        principalAmount: result.principalAmount,
        remainingAmount: result.remainingAmount,
        interestRate: result.interestRate,
        startDate: result.startDate,
        endDate: result.endDate,
        monthlyInstallment: result.monthlyInstallment,
      );

      if (context.mounted) {
        _showMessage(
          context,
          'وام بانکی با موفقیت ثبت شد.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showMessage(
          context,
          'خطا در ثبت وام:\n$e',
          isError: true,
        );
      }
    }
  }

  Future<void> _showEditDialog(
      BuildContext context,
      WidgetRef ref,
      CompanyAdminBankLoan loan,
      ) async {
    final result = await showDialog<_LoanFormResult>(
      context: context,
      builder: (_) => _LoanFormDialog(
        title: 'ویرایش وام بانکی',
        confirmText: 'ذخیره تغییرات',
        initial: loan,
      ),
    );

    if (result == null) return;

    try {
      await ref
          .read(companyAdminBankLoansControllerProvider)
          .updateLoan(
        id: loan.id,
        bankName: result.bankName,
        loanType: result.loanType,
        principalAmount: result.principalAmount,
        remainingAmount: result.remainingAmount,
        interestRate: result.interestRate,
        startDate: result.startDate,
        endDate: result.endDate,
        monthlyInstallment: result.monthlyInstallment,
      );

      if (context.mounted) {
        _showMessage(
          context,
          'وام با موفقیت ویرایش شد.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showMessage(
          context,
          'خطا در ویرایش وام:\n$e',
          isError: true,
        );
      }
    }
  }

  Future<void> _showDeleteDialog(
      BuildContext context,
      WidgetRef ref,
      CompanyAdminBankLoan loan,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('حذف وام'),
          content: Text(
            'آیا از حذف وام بانک «${loan.bankName}» مطمئن هستید؟',
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
          .read(companyAdminBankLoansControllerProvider)
          .deleteLoan(loan.id);

      if (context.mounted) {
        _showMessage(
          context,
          'وام حذف شد.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showMessage(
          context,
          'حذف وام انجام نشد:\n$e',
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

class _LoanContent extends StatelessWidget {
  final List<CompanyAdminBankLoan> items;
  final String Function(double) money;
  final String Function(DateTime?) date;
  final VoidCallback onAdd;
  final void Function(CompanyAdminBankLoan) onEdit;
  final void Function(CompanyAdminBankLoan) onDelete;

  const _LoanContent({
    required this.items,
    required this.money,
    required this.date,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final totalPrincipal = items.fold<double>(
      0,
          (sum, item) => sum + item.principalAmount,
    );

    final totalRemaining = items.fold<double>(
      0,
          (sum, item) => sum + item.remainingAmount,
    );

    final totalInstallments = items.fold<double>(
      0,
          (sum, item) => sum + item.monthlyInstallment,
    );

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
                      'مدیریت وام‌های بانکی',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'مدیریت تسهیلات و بدهی‌های بانکی شرکت',
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
                label: const Text('افزودن وام'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SummaryCard(
                title: 'تعداد وام',
                value: '${items.length}',
                icon: Icons.account_balance_outlined,
              ),
              _SummaryCard(
                title: 'اصل تسهیلات',
                value: money(totalPrincipal),
                suffix: 'ریال',
                icon: Icons.payments_outlined,
              ),
              _SummaryCard(
                title: 'مانده بدهی',
                value: money(totalRemaining),
                suffix: 'ریال',
                icon: Icons.account_balance_wallet_outlined,
              ),
              _SummaryCard(
                title: 'اقساط ماهانه',
                value: money(totalInstallments),
                suffix: 'ریال',
                icon: Icons.calendar_month_outlined,
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (items.isEmpty)
            const _EmptyState()
          else
            _LoanTable(
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

class _LoanTable extends StatelessWidget {
  final List<CompanyAdminBankLoan> items;
  final String Function(double) money;
  final String Function(DateTime?) date;
  final void Function(CompanyAdminBankLoan) onEdit;
  final void Function(CompanyAdminBankLoan) onDelete;

  const _LoanTable({
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
            DataColumn(
              label: Text('عملیات'),
            ),
            DataColumn(
              label: Text('بانک'),
            ),
            DataColumn(
              label: Text('نوع وام'),
            ),
            DataColumn(
              label: Text('اصل وام'),
            ),
            DataColumn(
              label: Text('مانده'),
            ),
            DataColumn(
              label: Text('نرخ سود'),
            ),
            DataColumn(
              label: Text('قسط ماهانه'),
            ),
            DataColumn(
              label: Text('شروع'),
            ),
            DataColumn(
              label: Text('پایان'),
            ),
          ],
          rows: items.map((loan) {
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
                          onPressed: () => onEdit(loan),
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 21,
                          ),
                        ),
                        IconButton(
                          tooltip: 'حذف',
                          onPressed: () => onDelete(loan),
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
                    loan.bankName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    loan.loanType?.isNotEmpty == true
                        ? loan.loanType!
                        : '-',
                  ),
                ),
                DataCell(
                  Text(
                    '${money(loan.principalAmount)} ریال',
                  ),
                ),
                DataCell(
                  Text(
                    '${money(loan.remainingAmount)} ریال',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: loan.remainingAmount > 0
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '${loan.interestRate.toStringAsFixed(2)}٪',
                  ),
                ),
                DataCell(
                  Text(
                    '${money(loan.monthlyInstallment)} ریال',
                  ),
                ),
                DataCell(
                  Text(date(loan.startDate)),
                ),
                DataCell(
                  Text(date(loan.endDate)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _LoanFormResult {
  final String bankName;
  final String loanType;
  final double principalAmount;
  final double remainingAmount;
  final double interestRate;
  final DateTime? startDate;
  final DateTime? endDate;
  final double monthlyInstallment;

  const _LoanFormResult({
    required this.bankName,
    required this.loanType,
    required this.principalAmount,
    required this.remainingAmount,
    required this.interestRate,
    required this.startDate,
    required this.endDate,
    required this.monthlyInstallment,
  });
}

class _LoanFormDialog extends StatefulWidget {
  final String title;
  final String confirmText;
  final CompanyAdminBankLoan? initial;

  const _LoanFormDialog({
    required this.title,
    required this.confirmText,
    this.initial,
  });

  @override
  State<_LoanFormDialog> createState() =>
      _LoanFormDialogState();
}

class _LoanFormDialogState extends State<_LoanFormDialog> {
  late final TextEditingController bankController;
  late final TextEditingController typeController;
  late final TextEditingController principalController;
  late final TextEditingController remainingController;
  late final TextEditingController interestController;
  late final TextEditingController installmentController;

  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();

    final loan = widget.initial;

    bankController = TextEditingController(
      text: loan?.bankName ?? '',
    );

    typeController = TextEditingController(
      text: loan?.loanType ?? '',
    );

    principalController = TextEditingController(
      text: loan == null
          ? ''
          : _numberText(loan.principalAmount),
    );

    remainingController = TextEditingController(
      text: loan == null
          ? ''
          : _numberText(loan.remainingAmount),
    );

    interestController = TextEditingController(
      text: loan == null
          ? ''
          : _numberText(loan.interestRate),
    );

    installmentController = TextEditingController(
      text: loan == null
          ? ''
          : _numberText(loan.monthlyInstallment),
    );

    startDate = loan?.startDate;
    endDate = loan?.endDate;
  }

  String _numberText(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }

    return value.toString();
  }

  @override
  void dispose() {
    bankController.dispose();
    typeController.dispose();
    principalController.dispose();
    remainingController.dispose();
    interestController.dispose();
    installmentController.dispose();
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

  Future<void> _pickStartDate() async {
    final selected = await _showJalaliDatePicker(
      context,
      initialDate: startDate,
      title: 'انتخاب تاریخ شروع',
    );

    if (selected != null) {
      setState(() {
        startDate = selected;
      });
    }
  }

  Future<void> _pickEndDate() async {
    final selected = await _showJalaliDatePicker(
      context,
      initialDate: endDate ?? startDate,
      title: 'انتخاب تاریخ پایان',
    );

    if (selected != null) {
      setState(() {
        endDate = selected;
      });
    }
  }

  String _dateText(DateTime? value) {
    if (value == null) {
      return 'انتخاب نشده';
    }

    final jalali = Jalali.fromDateTime(value.toLocal());

    return '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')}';
  }

  void _submit() {
    final bankName = bankController.text.trim();
    final loanType = typeController.text.trim();

    final principal = _number(principalController.text);
    final remaining = _number(remainingController.text);
    final interest = _number(interestController.text);
    final installment = _number(installmentController.text);

    if (bankName.isEmpty) {
      _error('نام بانک را وارد کنید.');
      return;
    }

    if (principal == null || principal < 0) {
      _error('مبلغ اصل وام معتبر نیست.');
      return;
    }

    if (remaining == null || remaining < 0) {
      _error('مبلغ مانده وام معتبر نیست.');
      return;
    }

    if (interest == null || interest < 0) {
      _error('نرخ سود معتبر نیست.');
      return;
    }

    if (installment == null || installment < 0) {
      _error('مبلغ قسط ماهانه معتبر نیست.');
      return;
    }

    if (startDate != null &&
        endDate != null &&
        endDate!.isBefore(startDate!)) {
      _error(
        'تاریخ پایان نمی‌تواند قبل از تاریخ شروع باشد.',
      );
      return;
    }

    Navigator.of(context).pop(
      _LoanFormResult(
        bankName: bankName,
        loanType: loanType,
        principalAmount: principal,
        remainingAmount: remaining,
        interestRate: interest,
        startDate: startDate,
        endDate: endDate,
        monthlyInstallment: installment,
      ),
    );
  }

  void _error(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bankController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'نام بانک *',
                  hintText: 'مثلاً بانک ملت',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: typeController,
                decoration: const InputDecoration(
                  labelText: 'نوع وام',
                  hintText: 'مثلاً سرمایه در گردش',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: principalController,
                keyboardType:
                const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'اصل وام *',
                  suffixText: 'ریال',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: remainingController,
                keyboardType:
                const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'مانده وام *',
                  suffixText: 'ریال',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: interestController,
                keyboardType:
                const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'نرخ سود',
                  suffixText: '٪',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: installmentController,
                keyboardType:
                const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'قسط ماهانه',
                  suffixText: 'ریال',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickStartDate,
                      icon: const Icon(
                        Icons.calendar_today_outlined,
                      ),
                      label: Text(
                        'شروع: ${_dateText(startDate)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickEndDate,
                      icon: const Icon(
                        Icons.event_outlined,
                      ),
                      label: Text(
                        'پایان: ${_dateText(endDate)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
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
        FilledButton(
          onPressed: _submit,
          child: Text(widget.confirmText),
        ),
      ],
    );
  }
}

/// ------------------------------------------------------------
/// تقویم شمسی اختصاصی
/// ------------------------------------------------------------

Future<DateTime?> _showJalaliDatePicker(
    BuildContext context, {
      DateTime? initialDate,
      required String title,
    }) async {
  final initialJalali = initialDate == null
      ? Jalali.now()
      : Jalali.fromDateTime(initialDate.toLocal());

  return showDialog<DateTime>(
    context: context,
    builder: (dialogContext) {
      return _JalaliDatePickerDialog(
        title: title,
        initialDate: initialJalali,
      );
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

class _JalaliDatePickerDialogState
    extends State<_JalaliDatePickerDialog> {
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
    return Jalali(
      visibleYear,
      visibleMonth,
      1,
    ).monthLength;
  }

  int get firstWeekDay {
    final firstDay = Jalali(
      visibleYear,
      visibleMonth,
      1,
    );

    return firstDay.weekDay;
  }

  void _previousMonth() {
    setState(() {
      if (visibleMonth == 1) {
        visibleMonth = 12;
        visibleYear--;
      } else {
        visibleMonth--;
      }

      final maxDay = Jalali(
        visibleYear,
        visibleMonth,
        1,
      ).monthLength;

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

      final maxDay = Jalali(
        visibleYear,
        visibleMonth,
        1,
      ).monthLength;

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
    final jalali = Jalali(
      selectedYear,
      selectedMonth,
      selectedDay,
    );

    Navigator.of(context).pop(
      jalali.toDateTime(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstDayOffset = firstWeekDay - 1;
    final totalCells = firstDayOffset + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
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
                      icon: const Icon(
                        Icons.today_outlined,
                      ),
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
                        icon: const Icon(
                          Icons.chevron_right,
                        ),
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
                        icon: const Icon(
                          Icons.chevron_left,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: weekDays.map((day) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: day == 'جمعه'
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
                    physics:
                    const NeverScrollableScrollPhysics(),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                    ),
                    itemCount: rowCount * 7,
                    itemBuilder: (context, index) {
                      if (index < firstDayOffset ||
                          index >=
                              firstDayOffset + daysInMonth) {
                        return const SizedBox.shrink();
                      }

                      final day =
                          index - firstDayOffset + 1;

                      final isSelected =
                          selectedYear == visibleYear &&
                              selectedMonth == visibleMonth &&
                              selectedDay == day;

                      final dayOfWeek =
                          (index % 7) + 1;

                      final isFriday =
                          dayOfWeek == 7;

                      return InkWell(
                        borderRadius:
                        BorderRadius.circular(50),
                        onTap: () => _selectDay(day),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xff17815b)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            day.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.end,
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

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String? suffix;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    this.suffix,
    required this.icon,
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
                  color: const Color(0xffeef2ff),
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xff3949ab),
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
              Icons.account_balance_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'هنوز وام بانکی ثبت نشده است.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'برای شروع، یک وام بانکی ثبت کنید.',
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
              'دریافت اطلاعات وام‌ها با خطا مواجه شد.',
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