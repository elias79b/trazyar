import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:tarazyar/consultant/companies/expenses/application/expense_dashboard_provider.dart';

import '../../application/expense_categories_provider.dart';
import '../../application/expense_provider.dart';
import '../../data/expense_category_model.dart';
import '../../data/expense_model.dart';
import '../../data/expense_repository.dart';

class ExpenseRecordDialog extends ConsumerStatefulWidget {
  const ExpenseRecordDialog({
    super.key,
    required this.companyId,
    required this.categories,
    this.expense,
  });

  final String companyId;
  final List<ExpenseCategoryModel> categories;
  final ExpenseModel? expense;

  @override
  ConsumerState<ExpenseRecordDialog> createState() =>
      _ExpenseRecordDialogState();
}

class _ExpenseRecordDialogState extends ConsumerState<ExpenseRecordDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late final TextEditingController _referenceController;

  late String _sourceType;
  late String _expenseType;
  String? _categoryId;
  String? _payrollPeriodId;

  DateTime _expenseDate = DateTime.now();

  bool _saving = false;

  bool get _isEdit => widget.expense != null;

  @override
  void initState() {
    super.initState();

    final expense = widget.expense;

    _titleController = TextEditingController(text: expense?.title ?? '');

    _descriptionController = TextEditingController(
      text: expense?.description ?? '',
    );

    _amountController = TextEditingController(
      text: expense == null ? '' : expense.amount.round().toString(),
    );

    _referenceController = TextEditingController(
      text: expense?.referenceNumber ?? '',
    );

    _sourceType = expense?.sourceType ?? 'manual';

    _expenseType = expense?.expenseType ?? 'operational';

    _categoryId = expense?.categoryId;

    _payrollPeriodId = expense?.payrollPeriodId;

    if (expense != null) {
      _expenseDate = expense.expenseDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _referenceController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final payrollSourcesAsync = ref.watch(
      payrollExpenseSourcesProvider(widget.companyId),
    );

    return AlertDialog(
      title: Text(_isEdit ? 'ویرایش هزینه' : 'ثبت هزینه جدید'),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'manual',
                      icon: Icon(Icons.edit_note),
                      label: Text('ثبت دستی'),
                    ),
                    ButtonSegment(
                      value: 'payroll',
                      icon: Icon(Icons.badge_outlined),
                      label: Text('حقوق و دستمزد'),
                    ),
                  ],
                  selected: {_sourceType},
                  onSelectionChanged:
                      _saving
                          ? null
                          : (selection) {
                            setState(() {
                              _sourceType = selection.first;

                              if (_sourceType == 'manual') {
                                _payrollPeriodId = null;
                              }
                            });
                          },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'عنوان هزینه *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'عنوان هزینه را وارد کنید.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _categoryId,
                  decoration: const InputDecoration(
                    labelText: 'دسته‌بندی *',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      widget.categories.map((category) {
                        return DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        );
                      }).toList(),
                  onChanged:
                      _saving
                          ? null
                          : (value) {
                            setState(() {
                              _categoryId = value;

                              final category = widget.categories.firstWhere(
                                (item) => item.id == value,
                              );

                              _expenseType = category.expenseType;
                            });
                          },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'دسته‌بندی را انتخاب کنید.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                if (_sourceType == 'payroll') ...[
                  payrollSourcesAsync.when(
                    loading:
                        () => const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                    error:
                        (error, stack) =>
                            Text('خطا در دریافت دوره‌های حقوق: $error'),
                    data: (sources) {
                      if (sources.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          child: const Text(
                            'هیچ دوره حقوقی که دارای ریز حقوق باشد پیدا نشد.',
                          ),
                        );
                      }

                      return DropdownButtonFormField<String>(
                        value:
                            sources.any((item) => item.id == _payrollPeriodId)
                                ? _payrollPeriodId
                                : null,
                        decoration: const InputDecoration(
                          labelText: 'دوره حقوق *',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            sources.map((source) {
                              return DropdownMenuItem(
                                value: source.id,
                                child: Text(
                                  '${_jalaliMonthName(source.periodMonth)} '
                                  '${_persianDigits(source.periodYear.toString())}'
                                  ' — ${_formatAmount(source.employerCost)} ریال',
                                ),
                              );
                            }).toList(),
                        onChanged:
                            _saving
                                ? null
                                : (value) {
                                  setState(() {
                                    _payrollPeriodId = value;
                                  });
                                },
                        validator: (value) {
                          if (_sourceType == 'payroll' &&
                              (value == null || value.isEmpty)) {
                            return 'دوره حقوق را انتخاب کنید.';
                          }

                          return null;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  if (_payrollPeriodId != null)
                    ref
                        .watch(payrollExpenseSourceProvider(_payrollPeriodId!))
                        .when(
                          loading: () => const LinearProgressIndicator(),
                          error:
                              (error, stack) =>
                                  Text('خطا در محاسبه هزینه حقوق: $error'),
                          data: (source) {
                            if (source == null) {
                              return const SizedBox.shrink();
                            }

                            return _PayrollCostCard(source: source);
                          },
                        ),
                ],
                if (_sourceType == 'manual')
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'مبلغ *',
                      suffixText: 'ریال',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final amount = num.tryParse(
                        value?.replaceAll(',', '').trim() ?? '',
                      );

                      if (amount == null || amount < 0) {
                        return 'مبلغ معتبر وارد کنید.';
                      }

                      return null;
                    },
                  ),
                if (_sourceType == 'manual') const SizedBox(height: 14),
                InkWell(
                  onTap: _saving ? null : _selectDate,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'تاریخ هزینه *',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined),
                        const SizedBox(width: 10),
                        Text(_formatJalali(_expenseDate)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _referenceController,
                  decoration: const InputDecoration(
                    labelText: 'شماره مرجع',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'توضیحات',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
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
                  : Text(_isEdit ? 'ذخیره تغییرات' : 'ثبت هزینه'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final initial = Jalali.fromDateTime(_expenseDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('fa'),
    );

    if (picked == null) return;

    setState(() {
      _expenseDate = picked;
    });

    // Keep shamsi_date involved for the Jalali representation.
    // Database still receives the Gregorian date.
    initial;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_sourceType == 'payroll' && _payrollPeriodId == null) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final repository = ref.read(expenseRepositoryProvider);

      final manualAmount = num.tryParse(
        _amountController.text.replaceAll(',', '').trim(),
      );

      final selectedPayrollSource =
          _sourceType == 'payroll'
              ? await repository.getPayrollExpenseSource(_payrollPeriodId!)
              : null;

      if (_sourceType == 'payroll' &&
          (selectedPayrollSource == null ||
              selectedPayrollSource.employeeCount == 0)) {
        throw Exception('دوره حقوق انتخاب‌شده فاقد ریز حقوق است.');
      }

      final amount =
          _sourceType == 'payroll'
              ? selectedPayrollSource!.employerCost
              : (manualAmount ?? 0);

      if (_isEdit) {
        await repository.updateExpense(
          expenseId: widget.expense!.id,
          categoryId: _categoryId!,
          title: _titleController.text,
          description: _descriptionController.text,
          amount: amount,
          expenseDate: _expenseDate,
          referenceNumber: _referenceController.text,
          expenseType: _expenseType,
          sourceType: _sourceType,
          payrollPeriodId: _payrollPeriodId,
        );
      } else {
        await repository.createExpense(
          companyId: widget.companyId,
          categoryId: _categoryId!,
          title: _titleController.text,
          description: _descriptionController.text,
          amount: amount,
          expenseDate: _expenseDate,
          referenceNumber: _referenceController.text,
          expenseType: _expenseType,
          sourceType: _sourceType,
          payrollPeriodId: _payrollPeriodId,
        );
      }

      ref.invalidate(expensesProvider(widget.companyId));
      ref.invalidate(expenseDashboardProvider(widget.companyId));
      ref.invalidate(payrollExpenseSourcesProvider(widget.companyId));

      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit
                  ? 'هزینه با موفقیت ویرایش شد.'
                  : 'هزینه با موفقیت ثبت شد.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا: $error')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }
}

class _PayrollCostCard extends StatelessWidget {
  const _PayrollCostCard({required this.source});

  final PayrollExpenseSource source;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _Row(
              title: 'تعداد کارکنان',
              value: _persianDigits(source.employeeCount.toString()),
            ),
            _Row(
              title: 'حقوق ناخالص',
              value: '${_formatAmount(source.grossSalary)} ریال',
            ),
            _Row(
              title: 'بیمه کارفرما',
              value: '${_formatAmount(source.employerInsurance)} ریال',
            ),
            const Divider(),
            _Row(
              title: 'هزینه واقعی کارفرما',
              value: '${_formatAmount(source.employerCost)} ریال',
              bold: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.title, required this.value, this.bold = false});

  final String title;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(title, style: style)),
          Text(value, style: style),
        ],
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
  final chars = value.split('');
  final buffer = StringBuffer();

  for (var i = 0; i < chars.length; i++) {
    final reverseIndex = chars.length - i;

    buffer.write(chars[i]);

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
