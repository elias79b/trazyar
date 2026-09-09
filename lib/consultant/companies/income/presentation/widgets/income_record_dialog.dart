import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/income_categories_provider.dart';
import '../../application/income_provider.dart';

class IncomeRecordDialog extends ConsumerStatefulWidget {
  final String companyId;
  final Map<String, dynamic>? record;

  const IncomeRecordDialog({
    super.key,
    required this.companyId,
    this.record,
  });

  bool get isEdit => record != null;

  @override
  ConsumerState<IncomeRecordDialog> createState() =>
      _IncomeRecordDialogState();
}

class _IncomeRecordDialogState extends ConsumerState<IncomeRecordDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _referenceController;

  Jalali _selectedDate = Jalali.now();

  String? _selectedCategoryId;
  String _selectedStatus = 'received';

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final record = widget.record;

    _titleController = TextEditingController(
      text: record?['title']?.toString() ?? '',
    );

    _amountController = TextEditingController(
      text: _formatAmountForInput(record?['amount']),
    );

    _descriptionController = TextEditingController(
      text: record?['description']?.toString() ?? '',
    );

    _referenceController = TextEditingController(
      text: record?['reference_number']?.toString() ?? '',
    );

    _selectedCategoryId = record?['category_id']?.toString();
    _selectedStatus = record?['status']?.toString() ?? 'received';

    final rawDate = record?['income_date'];

    if (rawDate != null) {
      final parsed = DateTime.tryParse(rawDate.toString());

      if (parsed != null) {
        _selectedDate = Jalali.fromDateTime(parsed);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  String _formatAmountForInput(dynamic value) {
    if (value == null) return '';

    final number = num.tryParse(value.toString());

    if (number == null) return '';

    return _toPersianDigits(
      number.toStringAsFixed(
        number.truncateToDouble() == number ? 0 : 2,
      ),
    );
  }

  String _toPersianDigits(String value) {
    const english = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';

    var result = value;

    for (var i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], persian[i]);
    }

    return result;
  }

  String _toEnglishDigits(String value) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const english = '0123456789';

    var result = value;

    for (var i = 0; i < 10; i++) {
      result = result.replaceAll(persian[i], english[i]);
      result = result.replaceAll(arabic[i], english[i]);
    }

    return result;
  }

  String _cleanAmount(String value) {
    var text = _toEnglishDigits(value);

    text = text.replaceAll(',', '');
    text = text.replaceAll('٬', '');
    text = text.replaceAll(' ', '');

    return text;
  }

  String _formatAmountLive(String value) {
    final clean = _cleanAmount(value);

    if (clean.isEmpty) return '';

    final parts = clean.split('.');

    final integerPart = parts.first;

    final formattedInteger = integerPart.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
    );

    if (parts.length > 1) {
      return _toPersianDigits(
        '$formattedInteger.${parts.sublist(1).join('.')}',
      );
    }

    return _toPersianDigits(formattedInteger);
  }

  String _formatJalaliDate(Jalali date) {
    return '${_toPersianDigits(date.year.toString().padLeft(4, '0'))}/'
        '${_toPersianDigits(date.month.toString().padLeft(2, '0'))}/'
        '${_toPersianDigits(date.day.toString().padLeft(2, '0'))}';
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

  Future<void> _pickDate() async {
    Jalali tempDate = _selectedDate;

    final selected = await showDialog<Jalali>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'انتخاب تاریخ درآمد',
              textAlign: TextAlign.right,
            ),
            content: SizedBox(
              width: 420,
              child: StatefulBuilder(
                builder: (context, setStateDialog) {
                  final daysInMonth = tempDate.monthLength;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'ماه قبل',
                            onPressed: () {
                              if (tempDate.month == 1) {
                                tempDate = Jalali(
                                  tempDate.year - 1,
                                  12,
                                  1,
                                );
                              } else {
                                tempDate = Jalali(
                                  tempDate.year,
                                  tempDate.month - 1,
                                  1,
                                );
                              }

                              setStateDialog(() {});
                            },
                            icon: const Icon(Icons.chevron_right),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  _jalaliMonthName(tempDate.month),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                                Text(
                                  _toPersianDigits(
                                    tempDate.year.toString(),
                                  ),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'ماه بعد',
                            onPressed: () {
                              if (tempDate.month == 12) {
                                tempDate = Jalali(
                                  tempDate.year + 1,
                                  1,
                                  1,
                                );
                              } else {
                                tempDate = Jalali(
                                  tempDate.year,
                                  tempDate.month + 1,
                                  1,
                                );
                              }

                              setStateDialog(() {});
                            },
                            icon: const Icon(Icons.chevron_left),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: List.generate(daysInMonth, (index) {
                          final day = index + 1;

                          final isSelected =
                              day == _selectedDate.day &&
                                  tempDate.year == _selectedDate.year &&
                                  tempDate.month == _selectedDate.month;

                          return InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              tempDate = Jalali(
                                tempDate.year,
                                tempDate.month,
                                day,
                              );

                              setStateDialog(() {});
                            },
                            child: Container(
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                              child: Text(
                                _toPersianDigits(day.toString()),
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : null,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('انصراف'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, tempDate),
                child: const Text('تأیید'),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedDate = selected;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amountText = _cleanAmount(_amountController.text);
    final amount = num.tryParse(amountText);

    if (amount == null || amount < 0) {
      _showError('مبلغ درآمد صحیح نیست.');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final service = ref.read(incomeServiceProvider);

      final gregorianDate = _selectedDate.toDateTime();

      if (widget.isEdit) {
        await service.updateIncome(
          id: widget.record!['id'].toString(),
          title: _titleController.text,
          amount: amount,
          incomeDate: gregorianDate,
          categoryId: _selectedCategoryId,
          description: _descriptionController.text,
          referenceNumber: _referenceController.text,
          status: _selectedStatus,
        );
      } else {
        await service.createIncome(
          companyId: widget.companyId,
          title: _titleController.text,
          amount: amount,
          incomeDate: gregorianDate,
          categoryId: _selectedCategoryId,
          description: _descriptionController.text,
          referenceNumber: _referenceController.text,
          status: _selectedStatus,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showError(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration _decoration({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _decoration(
          label: 'تاریخ درآمد',
          icon: Icons.calendar_month_outlined,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _formatJalaliDate(_selectedDate),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              _jalaliMonthName(_selectedDate.month),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      decoration: _decoration(
        label: 'وضعیت',
        icon: Icons.flag_outlined,
      ),
      items: const [
        DropdownMenuItem(
          value: 'received',
          child: Text('دریافت شده'),
        ),
        DropdownMenuItem(
          value: 'pending',
          child: Text('در انتظار'),
        ),
        DropdownMenuItem(
          value: 'cancelled',
          child: Text('لغو شده'),
        ),
      ],
      onChanged: _saving
          ? null
          : (value) {
        if (value != null) {
          setState(() {
            _selectedStatus = value;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync =
    ref.watch(incomeCategoriesProvider(widget.companyId));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 24,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 720,
            maxHeight: 760,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  20,
                  20,
                  20,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.07),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        widget.isEdit
                            ? Icons.edit_note
                            : Icons.add_chart,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isEdit
                                ? 'ویرایش درآمد'
                                : 'ثبت درآمد جدید',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'اطلاعات درآمد را وارد کنید',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(
                          'اطلاعات اصلی',
                          Icons.receipt_long_outlined,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _titleController,
                          enabled: !_saving,
                          decoration: _decoration(
                            label: 'عنوان درآمد',
                            hint: 'مثلاً درآمد فروش خدمات',
                            icon: Icons.title,
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'عنوان درآمد الزامی است.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _amountController,
                                enabled: !_saving,
                                keyboardType:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9۰-۹٠-٩,.]'),
                                  ),
                                ],
                                onChanged: (value) {
                                  final formatted =
                                  _formatAmountLive(value);

                                  if (formatted != value) {
                                    _amountController.value =
                                        TextEditingValue(
                                          text: formatted,
                                          selection:
                                          TextSelection.collapsed(
                                            offset: formatted.length,
                                          ),
                                        );
                                  }
                                },
                                decoration: _decoration(
                                  label: 'مبلغ',
                                  hint: 'مبلغ درآمد',
                                  icon: Icons.payments_outlined,
                                ),
                                validator: (value) {
                                  final amount = num.tryParse(
                                    _cleanAmount(value ?? ''),
                                  );

                                  if (amount == null) {
                                    return 'مبلغ را وارد کنید.';
                                  }

                                  if (amount < 0) {
                                    return 'مبلغ نمی‌تواند منفی باشد.';
                                  }

                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDateField(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        categoriesAsync.when(
                          loading: () => InputDecorator(
                            decoration: _decoration(
                              label: 'دسته‌بندی',
                              icon: Icons.category_outlined,
                            ),
                            child: const SizedBox(
                              height: 20,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                  CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          error: (error, stack) =>
                              InputDecorator(
                                decoration: _decoration(
                                  label: 'دسته‌بندی',
                                  icon: Icons.category_outlined,
                                ),
                                child: const Text(
                                  'خطا در دریافت دسته‌بندی‌ها',
                                ),
                              ),
                          data: (categories) {
                            return DropdownButtonFormField<String?>(
                              value: _selectedCategoryId,
                              decoration: _decoration(
                                label: 'دسته‌بندی',
                                icon: Icons.category_outlined,
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('بدون دسته‌بندی'),
                                ),
                                ...categories.map(
                                      (category) {
                                    return DropdownMenuItem<String?>(
                                      value: category['id']
                                          ?.toString(),
                                      child: Text(
                                        category['name']
                                            ?.toString() ??
                                            '-',
                                      ),
                                    );
                                  },
                                ),
                              ],
                              onChanged: _saving
                                  ? null
                                  : (value) {
                                setState(() {
                                  _selectedCategoryId =
                                      value;
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildStatusSelector(),
                        const SizedBox(height: 24),
                        _sectionTitle(
                          'اطلاعات تکمیلی',
                          Icons.notes_outlined,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _referenceController,
                          enabled: !_saving,
                          decoration: _decoration(
                            label: 'شماره مرجع',
                            hint: 'اختیاری',
                            icon: Icons.tag_outlined,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _descriptionController,
                          enabled: !_saving,
                          minLines: 3,
                          maxLines: 5,
                          decoration: _decoration(
                            label: 'توضیحات',
                            hint: 'توضیحات مربوط به درآمد',
                            icon: Icons.description_outlined,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  14,
                  24,
                  20,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.shade200,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize:
                          const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('انصراف'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(Icons.check),
                        label: Text(
                          _saving
                              ? 'در حال ذخیره...'
                              : widget.isEdit
                              ? 'ذخیره تغییرات'
                              : 'ثبت درآمد',
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize:
                          const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                        ),
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