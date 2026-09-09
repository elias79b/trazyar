import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shamsi_date/shamsi_date.dart';

// ============================================================
// DIGIT HELPERS
// ============================================================

String normalizeDigits(String value) {
  return value
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
      .replaceAll('٠', '0')
      .replaceAll('١', '1')
      .replaceAll('٢', '2')
      .replaceAll('٣', '3')
      .replaceAll('٤', '4')
      .replaceAll('٥', '5')
      .replaceAll('٦', '6')
      .replaceAll('٧', '7')
      .replaceAll('٨', '8')
      .replaceAll('٩', '9');
}

String toPersianDigits(String value) {
  const english = '0123456789';
  const persian = '۰۱۲۳۴۵۶۷۸۹';

  var result = value;

  for (var i = 0; i < english.length; i++) {
    result = result.replaceAll(
      english[i],
      persian[i],
    );
  }

  return result;
}

// ============================================================
// MONEY FORMATTER
// ============================================================

class ThousandsSeparatorFormatter
    extends TextInputFormatter {
  const ThousandsSeparatorFormatter();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final text = normalizeDigits(newValue.text);

    if (text.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(
          offset: 0,
        ),
      );
    }

    final isNegative = text.startsWith('-');

    final withoutNegative = isNegative
        ? text.substring(1)
        : text;

    // فقط اعداد و یک نقطه اعشار
    final cleaned = withoutNegative.replaceAll(
      RegExp(r'[^0-9.]'),
      '',
    );

    if (cleaned.isEmpty) {
      return oldValue;
    }

    final parts = cleaned.split('.');

    final integerPart = parts.first;

    if (integerPart.isEmpty) {
      return oldValue;
    }

    final formattedInteger =
    _formatThousands(integerPart);

    String result = formattedInteger;

    if (parts.length > 1) {
      result =
      '$formattedInteger.${parts.sublist(1).join()}';
    }

    if (isNegative) {
      result = '-$result';
    }

    final cursor = _calculateCursor(
      original: text,
      formatted: result,
      originalOffset:
      newValue.selection.baseOffset,
    );

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(
        offset: cursor,
      ),
      composing: TextRange.empty,
    );
  }

  static String _formatThousands(String value) {
    final buffer = StringBuffer();

    for (var i = 0; i < value.length; i++) {
      if (i > 0 &&
          (value.length - i) % 3 == 0) {
        buffer.write(',');
      }

      buffer.write(value[i]);
    }

    return buffer.toString();
  }

  static int _calculateCursor({
    required String original,
    required String formatted,
    required int originalOffset,
  }) {
    final safeOffset = originalOffset.clamp(
      0,
      original.length,
    );

    final originalBeforeCursor =
    original.substring(
      0,
      safeOffset,
    );

    final normalizedBeforeCursor =
    originalBeforeCursor.replaceAll(
      ',',
      '',
    );

    var nonCommaCount = 0;

    for (var i = 0; i < formatted.length; i++) {
      if (formatted[i] != ',') {
        nonCommaCount++;
      }

      if (nonCommaCount >=
          normalizedBeforeCursor.length) {
        return i + 1;
      }
    }

    return formatted.length;
  }
}

// ============================================================
// PARSERS
// ============================================================

double? parseFormattedDouble(String value) {
  final cleaned = normalizeDigits(value)
      .replaceAll(',', '')
      .trim();

  if (cleaned.isEmpty) {
    return null;
  }

  return double.tryParse(cleaned);
}

int? parseFormattedInt(String value) {
  final cleaned =
  normalizeDigits(value).trim();

  if (cleaned.isEmpty) {
    return null;
  }

  return int.tryParse(cleaned);
}

// ============================================================
// FORMAT MONEY FOR INITIAL VALUE
// ============================================================

String formatMoneyInput(num value) {
  final number = value.round().toString();

  final negative = number.startsWith('-');

  final digits = negative
      ? number.substring(1)
      : number;

  final formatted =
  ThousandsSeparatorFormatter._formatThousands(
    digits,
  );

  return negative
      ? '-$formatted'
      : formatted;
}

// ============================================================
// JALALI DATE
// ============================================================

String formatShamsiDate(DateTime value) {
  final jalali =
  Jalali.fromDateTime(value);

  final year =
  toPersianDigits(
    jalali.year.toString(),
  );

  final month =
  toPersianDigits(
    jalali.month
        .toString()
        .padLeft(2, '0'),
  );

  final day =
  toPersianDigits(
    jalali.day
        .toString()
        .padLeft(2, '0'),
  );

  return '$year/$month/$day';
}

Jalali dateTimeToJalali(DateTime value) {
  return Jalali.fromDateTime(value);
}

DateTime jalaliToDateTime(Jalali value) {
  return value.toDateTime();
}

// ============================================================
// PERSIAN MONTHS
// ============================================================

const List<String> persianMonthNames = [
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

const List<String> persianWeekDays = [
  'ش',
  'ی',
  'د',
  'س',
  'چ',
  'پ',
  'ج',
];

// ============================================================
// OPEN DATE PICKER
// ============================================================

Future<DateTime?> pickBankingDate(
    BuildContext context, {
      DateTime? initialDate,
    }) async {
  final initialJalali = initialDate == null
      ? Jalali.now()
      : Jalali.fromDateTime(
    initialDate,
  );

  final selected =
  await showDialog<Jalali>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return BankingShamsiDatePicker(
        initialDate: initialJalali,
      );
    },
  );

  if (selected == null) {
    return null;
  }

  return selected.toDateTime();
}

// ============================================================
// SHAMSI DATE FIELD
// ============================================================

class BankingDateField extends StatefulWidget {
  const BankingDateField({
    super.key,
    required this.controller,
    required this.label,
    this.initialDate,
    this.onDateSelected,
    this.requiredField = false,
  });

  final TextEditingController controller;
  final String label;
  final DateTime? initialDate;
  final ValueChanged<DateTime>? onDateSelected;
  final bool requiredField;

  @override
  State<BankingDateField> createState() =>
      _BankingDateFieldState();
}

class _BankingDateFieldState
    extends State<BankingDateField> {
  late String _displayValue;

  @override
  void initState() {
    super.initState();

    _displayValue =
        widget.controller.text;

    widget.controller.addListener(
      _onControllerChanged,
    );
  }

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }

    final value =
        widget.controller.text;

    if (value != _displayValue) {
      setState(() {
        _displayValue = value;
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(
      _onControllerChanged,
    );

    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await pickBankingDate(
      context,
      initialDate:
      widget.initialDate,
    );

    if (picked == null) {
      return;
    }

    final formatted =
    formatShamsiDate(picked);

    widget.controller.value =
        TextEditingValue(
          text: formatted,
          selection:
          TextSelection.collapsed(
            offset: formatted.length,
          ),
        );

    if (mounted) {
      setState(() {
        _displayValue = formatted;
      });
    }

    widget.onDateSelected?.call(
      picked,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasValue =
        _displayValue.trim().isNotEmpty;

    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 12,
      ),
      child: InkWell(
        onTap: _selectDate,
        borderRadius:
        BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: '۱۴۰۵/۰۶/۰۴',
            border:
            const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: _selectDate,
              tooltip:
              'انتخاب تاریخ شمسی',
              icon: const Icon(
                Icons.calendar_month_rounded,
              ),
            ),
          ),
          child: Align(
            alignment:
            Alignment.centerRight,
            child: Text(
              hasValue
                  ? _displayValue
                  : 'انتخاب تاریخ',
              style: TextStyle(
                color: hasValue
                    ? Colors.black87
                    : Colors.grey.shade600,
                fontWeight: hasValue
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// FISCAL PERIOD FIELD
// ============================================================

class BankingFiscalPeriodField
    extends StatefulWidget {
  const BankingFiscalPeriodField({
    super.key,
    required this.yearController,
    required this.monthController,
  });

  final TextEditingController
  yearController;

  final TextEditingController
  monthController;

  @override
  State<BankingFiscalPeriodField>
  createState() =>
      _BankingFiscalPeriodFieldState();
}

class _BankingFiscalPeriodFieldState
    extends State<BankingFiscalPeriodField> {
  String _displayValue = '';

  @override
  void initState() {
    super.initState();

    _updateDisplay();

    widget.yearController.addListener(
      _updateDisplay,
    );

    widget.monthController.addListener(
      _updateDisplay,
    );
  }

  void _updateDisplay() {
    final year =
    widget.yearController.text.trim();

    final month =
    widget.monthController.text.trim();

    if (!mounted) {
      return;
    }

    setState(() {
      if (year.isEmpty ||
          month.isEmpty) {
        _displayValue = '';
      } else {
        _displayValue =
        '${toPersianDigits(year)} / '
            '${toPersianDigits(month)}';
      }
    });
  }

  @override
  void dispose() {
    widget.yearController.removeListener(
      _updateDisplay,
    );

    widget.monthController.removeListener(
      _updateDisplay,
    );

    super.dispose();
  }

  Future<void> _selectPeriod() async {
    final year =
    int.tryParse(
      normalizeDigits(
        widget.yearController.text,
      ),
    );

    final month =
    int.tryParse(
      normalizeDigits(
        widget.monthController.text,
      ),
    );

    final initial =
    year != null &&
        month != null &&
        month >= 1 &&
        month <= 12
        ? Jalali(
      year,
      month,
      1,
    )
        : Jalali.now();

    final selected =
    await showDialog<Jalali>(
      context: context,
      builder: (dialogContext) {
        return BankingShamsiDatePicker(
          initialDate: initial,
          onlyMonthAndYear: true,
        );
      },
    );

    if (selected == null) {
      return;
    }

    widget.yearController.text =
        selected.year.toString();

    widget.monthController.text =
        selected.month.toString();

    if (mounted) {
      setState(() {
        _displayValue =
        '${toPersianDigits(selected.year.toString())}'
            ' / '
            '${toPersianDigits(selected.month.toString())}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValue =
        _displayValue.isNotEmpty;

    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 12,
      ),
      child: InkWell(
        onTap: _selectPeriod,
        borderRadius:
        BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText:
            'دوره مالی',
            hintText:
            'انتخاب سال و ماه',
            border:
            const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed:
              _selectPeriod,
              tooltip:
              'انتخاب دوره شمسی',
              icon: const Icon(
                Icons.calendar_month_rounded,
              ),
            ),
          ),
          child: Text(
            hasValue
                ? _displayValue
                : 'انتخاب دوره مالی',
            style: TextStyle(
              color: hasValue
                  ? Colors.black87
                  : Colors.grey.shade600,
              fontWeight: hasValue
                  ? FontWeight.w700
                  : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SHAMSI DATE PICKER WIDGET
// ============================================================

class BankingShamsiDatePicker
    extends StatefulWidget {
  const BankingShamsiDatePicker({
    super.key,
    required this.initialDate,
    this.onlyMonthAndYear = false,
  });

  final Jalali initialDate;
  final bool onlyMonthAndYear;

  @override
  State<BankingShamsiDatePicker>
  createState() =>
      _BankingShamsiDatePickerState();
}

class _BankingShamsiDatePickerState
    extends State<BankingShamsiDatePicker> {
  late int _year;
  late int _month;
  late int _day;

  @override
  void initState() {
    super.initState();

    _year = widget.initialDate.year;
    _month = widget.initialDate.month;
    _day = widget.initialDate.day;

    if (_day > _monthLength) {
      _day = _monthLength;
    }
  }

  int get _monthLength {
    return Jalali(
      _year,
      _month,
      1,
    ).monthLength;
  }

  Jalali get _selectedDate {
    return Jalali(
      _year,
      _month,
      _day,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(22),
      ),
      child:
      Directionality(
        textDirection:
        TextDirection.rtl,
        child: SizedBox(
          width: 390,
          child: Padding(
            padding:
            const EdgeInsets.all(18),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                _buildHeader(),

                const SizedBox(
                  height: 12,
                ),

                if (widget
                    .onlyMonthAndYear)
                  _buildMonthGrid()
                else ...[
                  _buildWeekHeader(),

                  const SizedBox(
                    height: 6,
                  ),

                  _buildCalendarGrid(),
                ],

                const SizedBox(
                  height: 16,
                ),

                Row(
                  children: [
                    Expanded(
                      child:
                      OutlinedButton(
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pop();
                        },
                        child:
                        const Text(
                          'انصراف',
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child:
                      FilledButton(
                        style:
                        FilledButton.styleFrom(
                          backgroundColor:
                          const Color(
                            0xFF1B4332,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pop(
                            _selectedDate,
                          );
                        },
                        child:
                        Text(
                          widget
                              .onlyMonthAndYear
                              ? 'انتخاب دوره'
                              : 'انتخاب',
                        ),
                      ),
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

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip:
              'سال قبل',
              onPressed: () {
                setState(() {
                  _year--;

                  if (_day > _monthLength) {
                    _day =
                        _monthLength;
                  }
                });
              },
              icon:
              const Icon(
                Icons.chevron_right_rounded,
              ),
            ),

            Expanded(
              child:
              Center(
                child:
                Text(
                  toPersianDigits(
                    '$_year ${persianMonthNames[_month - 1]}',
                  ),
                  style:
                  const TextStyle(
                    fontSize: 17,
                    fontWeight:
                    FontWeight.w900,
                    color:
                    Color(0xFF1B4332),
                  ),
                ),
              ),
            ),

            IconButton(
              tooltip:
              'سال بعد',
              onPressed: () {
                setState(() {
                  _year++;

                  if (_day > _monthLength) {
                    _day =
                        _monthLength;
                  }
                });
              },
              icon:
              const Icon(
                Icons.chevron_left_rounded,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 6,
        ),

        Row(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            DropdownButton<int>(
              value: _month,
              underline:
              const SizedBox(),
              items:
              List.generate(
                12,
                    (index) {
                  final month =
                      index + 1;

                  return DropdownMenuItem<int>(
                    value: month,
                    child: Text(
                      persianMonthNames[index],
                    ),
                  );
                },
              ),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _month = value;

                  if (_day > _monthLength) {
                    _day =
                        _monthLength;
                  }
                });
              },
            ),

            const SizedBox(
              width: 12,
            ),

            DropdownButton<int>(
              value: _year,
              underline:
              const SizedBox(),
              items:
              List.generate(
                41,
                    (index) {
                  final year =
                      Jalali.now().year -
                          20 +
                          index;

                  return DropdownMenuItem<int>(
                    value: year,
                    child: Text(
                      toPersianDigits(
                        year.toString(),
                      ),
                    ),
                  );
                },
              ),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _year = value;

                  if (_day > _monthLength) {
                    _day =
                        _monthLength;
                  }
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeekHeader() {
    return Row(
      children: persianWeekDays.map(
            (day) {
          return Expanded(
            child: Center(
              child: Text(
                day,
                style:
                TextStyle(
                  color:
                  Colors.grey.shade600,
                  fontSize: 11,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ).toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay =
    Jalali(
      _year,
      _month,
      1,
    );

    final firstOffset =
        firstDay.weekDay - 1;

    final totalDays =
        _monthLength;

    final totalCells =
        ((firstOffset +
            totalDays +
            6) ~/
            7) *
            7;

    final children = <Widget>[];

    for (
    var i = 0;
    i < totalCells;
    i++
    ) {
      final day =
          i - firstOffset + 1;

      if (day < 1 ||
          day > totalDays) {
        children.add(
          const SizedBox(
            height: 42,
          ),
        );
        continue;
      }

      final isSelected =
          day == _day;

      children.add(
        InkWell(
          borderRadius:
          BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _day = day;
            });
          },
          child:
          Container(
            height: 42,
            margin:
            const EdgeInsets.all(2),
            decoration:
            BoxDecoration(
              color:
              isSelected
                  ? const Color(
                0xFF1B4332,
              )
                  : Colors.transparent,
              borderRadius:
              BorderRadius.circular(12),
            ),
            child:
            Center(
              child: Text(
                toPersianDigits(
                  day.toString(),
                ),
                style:
                TextStyle(
                  color:
                  isSelected
                      ? Colors.white
                      : Colors.black87,
                  fontSize: 12,
                  fontWeight:
                  isSelected
                      ? FontWeight.w900
                      : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics:
      const NeverScrollableScrollPhysics(),
      children: children,
    );
  }

  Widget _buildMonthGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics:
      const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children:
      List.generate(
        12,
            (index) {
          final month =
              index + 1;

          final isSelected =
              month == _month;

          return InkWell(
            borderRadius:
            BorderRadius.circular(12),
            onTap: () {
              setState(() {
                _month = month;
              });
            },
            child:
            Container(
              decoration:
              BoxDecoration(
                color:
                isSelected
                    ? const Color(
                  0xFF1B4332,
                )
                    : Colors
                    .grey.shade100,
                borderRadius:
                BorderRadius.circular(12),
              ),
              child:
              Center(
                child: Text(
                  persianMonthNames[index],
                  style:
                  TextStyle(
                    color:
                    isSelected
                        ? Colors.white
                        : Colors.black87,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}