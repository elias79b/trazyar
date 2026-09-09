import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

class PersianDateField extends StatefulWidget {
  const PersianDateField({
    super.key,
    required this.controller,
    required this.label,
    this.initialDate,
    this.requiredField = false,
    this.onDateSelected,
  });

  final TextEditingController controller;
  final String label;
  final DateTime? initialDate;
  final bool requiredField;
  final ValueChanged<DateTime>? onDateSelected;

  @override
  State<PersianDateField> createState() => _PersianDateFieldState();
}

class _PersianDateFieldState extends State<PersianDateField> {
  late String _displayValue;

  @override
  void initState() {
    super.initState();

    _displayValue = widget.controller.text;

    widget.controller.addListener(_controllerChanged);
  }

  void _controllerChanged() {
    if (!mounted) {
      return;
    }

    final value = widget.controller.text;

    if (value != _displayValue) {
      setState(() {
        _displayValue = value;
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_controllerChanged);
    super.dispose();
  }

  Future<void> _pick() async {
    final initial =
        widget.initialDate == null
            ? Jalali.now()
            : Jalali.fromDateTime(widget.initialDate!);

    final selected = await showDialog<Jalali>(
      context: context,
      builder: (context) {
        return _PersianDatePicker(initialDate: initial);
      },
    );

    if (selected == null) {
      return;
    }

    final formatted = _format(selected);

    widget.controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );

    if (mounted) {
      setState(() {
        _displayValue = formatted;
      });
    }

    widget.onDateSelected?.call(selected.toDateTime());
  }

  String _format(Jalali value) {
    return '${_fa(value.year)}/'
        '${_fa(value.month.toString().padLeft(2, '0'))}/'
        '${_fa(value.day.toString().padLeft(2, '0'))}';
  }

  String _fa(dynamic value) {
    final text = value.toString();

    const en = '0123456789';
    const fa = '۰۱۲۳۴۵۶۷۸۹';

    var result = text;

    for (var i = 0; i < en.length; i++) {
      result = result.replaceAll(en[i], fa[i]);
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = _displayValue.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: _pick,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: _pick,
              tooltip: 'انتخاب تاریخ شمسی',
              icon: const Icon(Icons.calendar_month_rounded),
            ),
          ),
          child: Text(
            hasValue ? _displayValue : 'انتخاب تاریخ',
            style: TextStyle(
              color: hasValue ? Colors.black87 : Colors.grey.shade600,
              fontWeight: hasValue ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _PersianDatePicker extends StatefulWidget {
  const _PersianDatePicker({required this.initialDate});

  final Jalali initialDate;

  @override
  State<_PersianDatePicker> createState() => _PersianDatePickerState();
}

class _PersianDatePickerState extends State<_PersianDatePicker> {
  late int _year;
  late int _month;
  late int _day;

  static const _months = [
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

  static const _weekdays = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];

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
    return Jalali(_year, _month, 1).monthLength;
  }

  Jalali get _selected {
    return Jalali(_year, _month, _day);
  }

  String _fa(String value) {
    const en = '0123456789';
    const fa = '۰۱۲۳۴۵۶۷۸۹';

    var result = value;

    for (var i = 0; i < en.length; i++) {
      result = result.replaceAll(en[i], fa[i]);
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          width: 390,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _year--;

                          if (_day > _monthLength) {
                            _day = _monthLength;
                          }
                        });
                      },
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '${_fa(_year.toString())} ${_months[_month - 1]}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            color: Color(0xFF1B4332),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _year++;

                          if (_day > _monthLength) {
                            _day = _monthLength;
                          }
                        });
                      },
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DropdownButton<int>(
                      value: _month,
                      underline: const SizedBox(),
                      items: List.generate(12, (index) {
                        final month = index + 1;

                        return DropdownMenuItem<int>(
                          value: month,
                          child: Text(_months[index]),
                        );
                      }),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _month = value;

                          if (_day > _monthLength) {
                            _day = _monthLength;
                          }
                        });
                      },
                    ),

                    const SizedBox(width: 12),

                    DropdownButton<int>(
                      value: _year,
                      underline: const SizedBox(),
                      items: List.generate(41, (index) {
                        final year = Jalali.now().year - 20 + index;

                        return DropdownMenuItem<int>(
                          value: year,
                          child: Text(_fa(year.toString())),
                        );
                      }),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _year = value;

                          if (_day > _monthLength) {
                            _day = _monthLength;
                          }
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children:
                      _weekdays.map((day) {
                        return Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),

                const SizedBox(height: 6),

                _calendar(),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('انصراف'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1B4332),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop(_selected);
                        },
                        child: const Text('انتخاب'),
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

  Widget _calendar() {
    final first = Jalali(_year, _month, 1);

    final offset = first.weekDay - 1;

    final total = _monthLength;

    final cells = ((offset + total + 6) ~/ 7) * 7;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      children: List.generate(cells, (index) {
        final day = index - offset + 1;

        if (day < 1 || day > total) {
          return const SizedBox();
        }

        final selected = day == _day;

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _day = day;
            });
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF1B4332) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _fa(day.toString()),
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
