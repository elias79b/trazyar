import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/accountant/banking/application/accountant_received_checks_provider.dart';
import 'package:tarazyar/accountant/dashboard/presentation/widgets/accountant_scaffold.dart';
import 'package:shamsi_date/shamsi_date.dart';

class AccountantReceivedChecksPage extends ConsumerWidget {
  final String companyId;

  const AccountantReceivedChecksPage({super.key, required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountantReceivedChecksProvider(companyId));

    return AccountantScaffold(
      currentRoute: '/accountant/banking/received-checks',
      title: 'چک‌های دریافتی',
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stackTrace) => _ErrorView(
              message: error.toString(),
              onRetry: () {
                ref.invalidate(accountantReceivedChecksProvider(companyId));
              },
            ),
        data: (checks) {
          return _ChecksContent(companyId: companyId, checks: checks);
        },
      ),
    );
  }
}

class _ChecksContent extends ConsumerWidget {
  final String companyId;
  final List<AccountantReceivedCheck> checks;

  const _ChecksContent({required this.companyId, required this.checks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalAmount = checks.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );

    final pendingCount =
        checks.where((e) => e.status.toLowerCase() == 'pending').length;

    final paidCount =
        checks.where((e) => e.status.toLowerCase() == 'paid').length;

    final returnedCount =
        checks.where((e) => e.status.toLowerCase() == 'returned').length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(accountantReceivedChecksProvider(companyId));

              await ref.read(
                accountantReceivedChecksProvider(companyId).future,
              );
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'مدیریت چک‌های دریافتی',
                        style: TextStyle(
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        _showCheckDialog(context, companyId: companyId);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('ثبت چک'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                GridView.count(
                  crossAxisCount: isMobile ? 1 : 4,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: isMobile ? 3.2 : 1.9,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _SummaryCard(
                      title: 'تعداد کل',
                      value: checks.length.toString(),
                      icon: Icons.receipt_long_outlined,
                    ),
                    _SummaryCard(
                      title: 'مبلغ کل',
                      value: _money(totalAmount),
                      icon: Icons.payments_outlined,
                    ),
                    _SummaryCard(
                      title: 'در انتظار',
                      value: pendingCount.toString(),
                      icon: Icons.schedule_outlined,
                    ),
                    _SummaryCard(
                      title: 'وصول‌شده',
                      value: paidCount.toString(),
                      icon: Icons.check_circle_outline,
                      footer:
                          returnedCount > 0 ? '$returnedCount برگشتی' : null,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (checks.isEmpty)
                  _EmptyState(
                    onAdd: () {
                      _showCheckDialog(context, companyId: companyId);
                    },
                  )
                else
                  ...checks.map(
                    (check) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CheckCard(
                        check: check,
                        onEdit: () {
                          _showCheckDialog(
                            context,
                            companyId: companyId,
                            check: check,
                          );
                        },
                        onDelete: () async {
                          final confirmed = await _confirmDelete(context);

                          if (!confirmed || !context.mounted) {
                            return;
                          }

                          try {
                            await AccountantReceivedChecksRepository.delete(
                              check.id,
                            );

                            ref.invalidate(
                              accountantReceivedChecksProvider(companyId),
                            );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('چک با موفقیت حذف شد.'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('خطا در حذف چک:\n$e')),
                            );
                          }
                        },
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف چک'),
          content: const Text('آیا از حذف این چک دریافتی مطمئن هستید؟'),
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

    return result ?? false;
  }

  Future<void> _showCheckDialog(
    BuildContext context, {
    required String companyId,
    AccountantReceivedCheck? check,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return _CheckDialog(companyId: companyId, check: check);
      },
    );

    if (result == true && context.mounted) {
      final container = ProviderScope.containerOf(context);

      container.invalidate(accountantReceivedChecksProvider(companyId));
    }
  }

  static String _money(double value) {
    return '${value.toStringAsFixed(0)} ریال';
  }
}

class _CheckCard extends StatelessWidget {
  final AccountantReceivedCheck check;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CheckCard({
    required this.check,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final status = _statusInfo(check.status);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          runSpacing: 14,
          spacing: 20,
          children: [
            SizedBox(
              width: 180,
              child: _Info(
                title: 'شماره چک',
                value:
                    check.checkNumber.isEmpty
                        ? 'بدون شماره'
                        : check.checkNumber,
              ),
            ),
            SizedBox(
              width: 180,
              child: _Info(
                title: 'بانک',
                value: check.bankName.isEmpty ? 'ثبت نشده' : check.bankName,
              ),
            ),
            SizedBox(
              width: 180,
              child: _Info(
                title: 'مبلغ',
                value: _ChecksContent._money(check.amount),
              ),
            ),
            SizedBox(
              width: 160,
              child: _Info(title: 'سررسید', value: _formatDate(check.dueDate)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: status.color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status.label,
                style: TextStyle(
                  color: status.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'ویرایش',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'حذف',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'ثبت نشده';
    }

    final parts = value.split('-');

    if (parts.length == 3) {
      return '${parts[0]}/${parts[1]}/${parts[2]}';
    }

    return value;
  }

  static _StatusInfo _statusInfo(String value) {
    switch (value.toLowerCase()) {
      case 'paid':
      case 'received':
      case 'collected':
        return const _StatusInfo(label: 'وصول‌شده', color: Colors.green);

      case 'returned':
        return const _StatusInfo(label: 'برگشتی', color: Colors.red);

      case 'cancelled':
      case 'canceled':
        return const _StatusInfo(label: 'باطل‌شده', color: Colors.grey);

      default:
        return const _StatusInfo(label: 'در انتظار', color: Colors.orange);
    }
  }
}

class _StatusInfo {
  final String label;
  final Color color;

  const _StatusInfo({required this.label, required this.color});
}

class _Info extends StatelessWidget {
  final String title;
  final String value;

  const _Info({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final String? footer;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(radius: 22, child: Icon(icon)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  if (footer != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      footer!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 24),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'هنوز چک دریافتی ثبت نشده است.',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
            const SizedBox(height: 8),
            Text(
              'اولین چک دریافتی شرکت را ثبت کنید.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('ثبت اولین چک'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 52),
            const SizedBox(height: 16),
            const Text(
              'خطا در دریافت چک‌های دریافتی',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('تلاش مجدد')),
          ],
        ),
      ),
    );
  }
}

class _CheckDialog extends StatefulWidget {
  final String companyId;
  final AccountantReceivedCheck? check;

  const _CheckDialog({required this.companyId, this.check});

  @override
  State<_CheckDialog> createState() => _CheckDialogState();
}

class _CheckDialogState extends State<_CheckDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _checkNumberController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _amountController;

  String? _selectedDate;
  String _status = 'pending';
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final check = widget.check;

    _checkNumberController = TextEditingController(
      text: check?.checkNumber ?? '',
    );

    _bankNameController = TextEditingController(text: check?.bankName ?? '');

    _amountController = TextEditingController(
      text: check == null ? '' : check.amount.toStringAsFixed(0),
    );

    _selectedDate = check?.dueDate;
    _status = check?.status ?? 'pending';
  }

  @override
  void dispose() {
    _checkNumberController.dispose();
    _bankNameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.check != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(isEdit ? 'ویرایش چک دریافتی' : 'ثبت چک دریافتی'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _checkNumberController,
                    decoration: const InputDecoration(
                      labelText: 'شماره چک',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'شماره چک را وارد کنید.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _bankNameController,
                    decoration: const InputDecoration(
                      labelText: 'نام بانک',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'نام بانک را وارد کنید.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'مبلغ',
                      suffixText: 'ریال',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final amount = double.tryParse(
                        (value ?? '').replaceAll(',', '').trim(),
                      );

                      if (amount == null || amount < 0) {
                        return 'مبلغ معتبر وارد کنید.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  _DatePickerField(
                    selectedDate: _selectedDate,
                    onChanged: (value) {
                      setState(() {
                        _selectedDate = value;
                      });
                    },
                  ),

                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'وضعیت',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('در انتظار'),
                      ),
                      DropdownMenuItem(value: 'paid', child: Text('وصول‌شده')),
                      DropdownMenuItem(
                        value: 'returned',
                        child: Text('برگشتی'),
                      ),
                      DropdownMenuItem(
                        value: 'cancelled',
                        child: Text('باطل‌شده'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _status = value;
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
            onPressed: _saving ? null : () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child:
                _saving
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Text(isEdit ? 'ذخیره تغییرات' : 'ثبت چک'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = Jalali.fromDateTime(now);

    Jalali initialDate = today;

    if (widget.check?.dueDate != null) {
      final parsed = _parseJalali(widget.check!.dueDate!);

      if (parsed != null) {
        initialDate = parsed;
      }
    }

    final picked = await showDialog<Jalali>(
      context: context,
      builder: (context) {
        return _JalaliDatePickerDialog(initialDate: initialDate);
      },
    );

    if (picked == null || !mounted) return;

    setState(() {
      _selectedDate = _formatJalali(picked);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null || _selectedDate!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تاریخ سررسید را انتخاب کنید.')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final amount = double.parse(
        _amountController.text.replaceAll(',', '').trim(),
      );

      if (widget.check == null) {
        await AccountantReceivedChecksRepository.create(
          companyId: widget.companyId,
          checkNumber: _checkNumberController.text.trim(),
          bankName: _bankNameController.text.trim(),
          amount: amount,
          dueDate: _jalaliToGregorianDate(_selectedDate!),
          status: _status,
        );
      } else {
        await AccountantReceivedChecksRepository.update(
          id: widget.check!.id,
          checkNumber: _checkNumberController.text.trim(),
          bankName: _bankNameController.text.trim(),
          amount: amount,
          dueDate: _jalaliToGregorianDate(_selectedDate!),
          status: _status,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در ذخیره چک:\n$e')));
    }
  }

  static Jalali? _parseJalali(String value) {
    final normalized = value
        .replaceAll('۰', '0')
        .replaceAll('۱', '1')
        .replaceAll('۲', '2')
        .replaceAll('۳', '3')
        .replaceAll('۴', '4')
        .replaceAll('۵', '5')
        .replaceAll('۶', '6')
        .replaceAll('۷', '7')
        .replaceAll('۸', '8')
        .replaceAll('۹', '9')
        .replaceAll('-', '/');

    final parts = normalized.split('/');

    if (parts.length != 3) {
      return null;
    }

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);

    if (year == null || month == null || day == null) {
      return null;
    }

    try {
      return Jalali(year, month, day);
    } catch (_) {
      return null;
    }
  }

  static String _formatJalali(Jalali date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String _jalaliToGregorianDate(String value) {
    final jalali = _parseJalali(value);

    if (jalali == null) {
      throw Exception('تاریخ انتخاب‌شده معتبر نیست.');
    }

    final gregorian = jalali.toGregorian();

    return '${gregorian.year.toString().padLeft(4, '0')}-'
        '${gregorian.month.toString().padLeft(2, '0')}-'
        '${gregorian.day.toString().padLeft(2, '0')}';
  }
}

class _DatePickerField extends StatelessWidget {
  final String? selectedDate;
  final ValueChanged<String> onChanged;

  const _DatePickerField({required this.selectedDate, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final now = DateTime.now();
        final today = Jalali.fromDateTime(now);

        Jalali initialDate = today;

        if (selectedDate != null) {
          final parts = selectedDate!.split('-');

          if (parts.length == 3) {
            final y = int.tryParse(parts[0]);
            final m = int.tryParse(parts[1]);
            final d = int.tryParse(parts[2]);

            if (y != null && m != null && d != null) {
              try {
                initialDate = Jalali(y, m, d);
              } catch (_) {}
            }
          }
        }

        final picked = await showDialog<Jalali>(
          context: context,
          builder: (context) {
            return _JalaliDatePickerDialog(initialDate: initialDate);
          },
        );

        if (picked == null) return;

        onChanged(
          '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}',
        );
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'تاریخ سررسید',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_month_outlined),
        ),
        child: Text(
          selectedDate == null ? 'انتخاب تاریخ' : _toPersianDate(selectedDate!),
          style: TextStyle(
            color: selectedDate == null ? Colors.grey.shade600 : null,
          ),
        ),
      ),
    );
  }

  static String _toPersianDate(String value) {
    return value
        .replaceAll('-', '/')
        .replaceAll('0', '۰')
        .replaceAll('1', '۱')
        .replaceAll('2', '۲')
        .replaceAll('3', '۳')
        .replaceAll('4', '۴')
        .replaceAll('5', '۵')
        .replaceAll('6', '۶')
        .replaceAll('7', '۷')
        .replaceAll('8', '۸')
        .replaceAll('9', '۹');
  }
}

class _JalaliDatePickerDialog extends StatefulWidget {
  final Jalali initialDate;

  const _JalaliDatePickerDialog({required this.initialDate});

  @override
  State<_JalaliDatePickerDialog> createState() =>
      _JalaliDatePickerDialogState();
}

class _JalaliDatePickerDialogState extends State<_JalaliDatePickerDialog> {
  late Jalali _selectedDate;
  late Jalali _visibleMonth;

  @override
  void initState() {
    super.initState();

    _selectedDate = widget.initialDate;
    _visibleMonth = Jalali(
      widget.initialDate.year,
      widget.initialDate.month,
      1,
    );
  }

  void _previousMonth() {
    setState(() {
      if (_visibleMonth.month == 1) {
        _visibleMonth = Jalali(_visibleMonth.year - 1, 12, 1);
      } else {
        _visibleMonth = Jalali(_visibleMonth.year, _visibleMonth.month - 1, 1);
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_visibleMonth.month == 12) {
        _visibleMonth = Jalali(_visibleMonth.year + 1, 1, 1);
      } else {
        _visibleMonth = Jalali(_visibleMonth.year, _visibleMonth.month + 1, 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthLength = _visibleMonth.monthLength;
    final firstDay = _visibleMonth;

    final firstWeekday = firstDay.toDateTime().weekday % 7;

    final cells = <Widget>[];

    for (int i = 0; i < firstWeekday; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= monthLength; day++) {
      final date = Jalali(_visibleMonth.year, _visibleMonth.month, day);

      final isSelected =
          date.year == _selectedDate.year &&
          date.month == _selectedDate.month &&
          date.day == _selectedDate.day;

      cells.add(
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.pop(context, date);
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              day.toString(),
              style: TextStyle(
                color:
                    isSelected ? Theme.of(context).colorScheme.onPrimary : null,
                fontWeight: isSelected ? FontWeight.w800 : null,
              ),
            ),
          ),
        ),
      );
    }

    const weekDays = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '${_monthName(_visibleMonth.month)} '
                      '${_visibleMonth.year}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _previousMonth,
                  icon: const Icon(Icons.chevron_left),
                ),
              ],
            ),
          ],
        ),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GridView.builder(
                shrinkWrap: true,
                itemCount: 7,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                ),
                itemBuilder: (context, index) {
                  return Center(
                    child: Text(
                      weekDays[index],
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 7,
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
                children: cells,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('انصراف'),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
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
}
