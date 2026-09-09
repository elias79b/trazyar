import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/payroll_period_provider.dart';
import '../../data/payroll_period_model.dart';

class PayrollPeriodFormDialog extends ConsumerStatefulWidget {
  const PayrollPeriodFormDialog({
    super.key,
    required this.companyId,
    this.period,
    this.initialYear,
    this.initialMonth,
  });

  final String companyId;
  final PayrollPeriodModel? period;

  final int? initialYear;
  final int? initialMonth;

  bool get isEdit => period != null;

  @override
  ConsumerState<PayrollPeriodFormDialog> createState() =>
      _PayrollPeriodFormDialogState();
}

class _PayrollPeriodFormDialogState
    extends ConsumerState<PayrollPeriodFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _yearController;
  late final TextEditingController _notesController;

  int? _selectedMonth;

  // ============================================================
  // DATABASE STATUS
  // ============================================================
  //
  // این‌ها باید دقیقاً با CHECK CONSTRAINT دیتابیس یکی باشند.
  //

  static const List<String> _validStatuses = [
    'draft',
    'pending_ceo',
    'ceo_approved',
    'pending_consultant',
    'consultant_approved',
    'rejected',
    'paid',
    'cancelled',
  ];

  String _selectedStatus = 'draft';

  bool _saving = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    final period = widget.period;

    _yearController = TextEditingController(
      text:
          period?.periodYear.toString() ??
          widget.initialYear?.toString() ??
          '1405',
    );

    _notesController = TextEditingController(text: period?.notes ?? '');

    _selectedMonth = period?.periodMonth ?? widget.initialMonth ?? 1;

    if (period != null && _validStatuses.contains(period.status)) {
      _selectedStatus = period.status;
    } else {
      _selectedStatus = 'draft';
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isEdit ? 'ویرایش دوره حقوق' : 'ایجاد دوره حقوق',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),

      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ==================================================
                // YEAR
                // ==================================================
                TextFormField(
                  controller: _yearController,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'سال',
                    hintText: 'مثلاً 1405',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today_rounded),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';

                    if (text.isEmpty) {
                      return 'سال را وارد کنید.';
                    }

                    final year = int.tryParse(text);

                    if (year == null) {
                      return 'سال معتبر وارد کنید.';
                    }

                    if (year < 1300 || year > 1600) {
                      return 'سال باید بین 1300 تا 1600 باشد.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ==================================================
                // MONTH
                // ==================================================
                DropdownButtonFormField<int>(
                  value: _selectedMonth,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'ماه',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_month_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('فروردین')),
                    DropdownMenuItem(value: 2, child: Text('اردیبهشت')),
                    DropdownMenuItem(value: 3, child: Text('خرداد')),
                    DropdownMenuItem(value: 4, child: Text('تیر')),
                    DropdownMenuItem(value: 5, child: Text('مرداد')),
                    DropdownMenuItem(value: 6, child: Text('شهریور')),
                    DropdownMenuItem(value: 7, child: Text('مهر')),
                    DropdownMenuItem(value: 8, child: Text('آبان')),
                    DropdownMenuItem(value: 9, child: Text('آذر')),
                    DropdownMenuItem(value: 10, child: Text('دی')),
                    DropdownMenuItem(value: 11, child: Text('بهمن')),
                    DropdownMenuItem(value: 12, child: Text('اسفند')),
                  ],
                  onChanged:
                      _saving
                          ? null
                          : (value) {
                            setState(() {
                              _selectedMonth = value;
                            });
                          },
                  validator: (value) {
                    if (value == null) {
                      return 'ماه را انتخاب کنید.';
                    }

                    if (value < 1 || value > 12) {
                      return 'ماه نامعتبر است.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ==================================================
                // STATUS
                // ==================================================
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'وضعیت دوره',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.flag_rounded),
                  ),

                  // ==================================================
                  // IMPORTANT
                  // ==================================================
                  //
                  // دیگر calculated و approved نداریم.
                  //
                  items: const [
                    DropdownMenuItem(value: 'draft', child: Text('پیش‌نویس')),

                    DropdownMenuItem(
                      value: 'pending_ceo',
                      child: Text('محاسبه‌شده / در انتظار تأیید مدیرعامل'),
                    ),

                    DropdownMenuItem(
                      value: 'ceo_approved',
                      child: Text('تأیید مدیرعامل'),
                    ),

                    DropdownMenuItem(
                      value: 'pending_consultant',
                      child: Text('در انتظار بررسی مشاور'),
                    ),

                    DropdownMenuItem(
                      value: 'consultant_approved',
                      child: Text('تأیید مشاور'),
                    ),

                    DropdownMenuItem(value: 'rejected', child: Text('ردشده')),

                    DropdownMenuItem(value: 'paid', child: Text('پرداخت‌شده')),

                    DropdownMenuItem(value: 'cancelled', child: Text('لغوشده')),
                  ],

                  onChanged:
                      _saving
                          ? null
                          : (value) {
                            if (value == null) {
                              return;
                            }

                            setState(() {
                              _selectedStatus = value;
                            });
                          },

                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'وضعیت را انتخاب کنید.';
                    }

                    if (!_validStatuses.contains(value)) {
                      return 'وضعیت انتخاب شده معتبر نیست.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // ==================================================
                // STATUS INFO
                // ==================================================
                _StatusInfo(status: _selectedStatus),

                const SizedBox(height: 16),

                // ==================================================
                // NOTES
                // ==================================================
                TextFormField(
                  controller: _notesController,
                  enabled: !_saving,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'توضیحات',
                    hintText: 'توضیحات دوره حقوق...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 60),
                      child: Icon(Icons.notes_rounded),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // ==========================================================
      // ACTIONS
      // ==========================================================
      actions: [
        TextButton(
          onPressed:
              _saving
                  ? null
                  : () {
                    Navigator.of(context).pop();
                  },
          child: const Text('انصراف'),
        ),

        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon:
              _saving
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Icon(Icons.save_rounded),
          label: Text(widget.isEdit ? 'ذخیره تغییرات' : 'ثبت دوره'),
        ),
      ],
    );
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // ==========================================================
    // YEAR
    // ==========================================================

    final yearText = _yearController.text.trim();

    final year = int.tryParse(yearText);

    if (year == null) {
      _showError('سال وارد شده معتبر نیست.');
      return;
    }

    // ==========================================================
    // MONTH
    // ==========================================================

    final month = _selectedMonth;

    if (month == null || month < 1 || month > 12) {
      _showError('ماه انتخاب شده معتبر نیست.');
      return;
    }

    // ==========================================================
    // FINAL STATUS CHECK
    // ==========================================================

    if (!_validStatuses.contains(_selectedStatus)) {
      _showError('وضعیت دوره معتبر نیست.');
      return;
    }

    // ==========================================================
    // SAVE
    // ==========================================================

    setState(() {
      _saving = true;
    });

    try {
      final repository = ref.read(payrollPeriodRepositoryProvider);

      // ========================================================
      // CREATE
      // ========================================================

      if (!widget.isEdit) {
        await repository.createPeriod(
          companyId: widget.companyId,
          periodYear: year,
          periodMonth: month,

          // فقط status معتبر
          status: _selectedStatus,

          notes: _cleanText(_notesController.text),
        );
      }
      // ========================================================
      // UPDATE
      // ========================================================
      else {
        await repository.updatePeriod(
          id: widget.period!.id,
          periodYear: year,
          periodMonth: month,

          // فقط status معتبر
          status: _selectedStatus,

          notes: _cleanText(_notesController.text),
        );
      }

      // ========================================================
      // REFRESH
      // ========================================================

      ref.invalidate(payrollPeriodsProvider(widget.companyId));

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      _showError(_friendlyError(error));
    }
  }

  // ============================================================
  // STATUS INFO
  // ============================================================

  String _statusDescription(String status) {
    switch (status) {
      case 'draft':
        return 'دوره در حالت پیش‌نویس است و امکان ثبت و ویرایش حقوق وجود دارد.';

      case 'pending_ceo':
        return 'حقوق محاسبه شده و برای تأیید مدیرعامل آماده است.';

      case 'ceo_approved':
        return 'مدیرعامل دوره را تأیید کرده است.';

      case 'pending_consultant':
        return 'دوره برای بررسی مشاور ارسال شده است.';

      case 'consultant_approved':
        return 'مشاور دوره را تأیید کرده و دوره آماده پرداخت است.';

      case 'rejected':
        return 'دوره رد شده و نیازمند اصلاح است.';

      case 'paid':
        return 'پرداخت انجام شده و اطلاعات دوره قفل است.';

      case 'cancelled':
        return 'دوره لغو شده است.';

      default:
        return '';
    }
  }

  // ============================================================
  // STATUS TITLE
  // ============================================================

  String _statusTitle(String status) {
    switch (status) {
      case 'draft':
        return 'پیش‌نویس';

      case 'pending_ceo':
        return 'محاسبه‌شده';

      case 'ceo_approved':
        return 'تأیید مدیرعامل';

      case 'pending_consultant':
        return 'در انتظار بررسی مشاور';

      case 'consultant_approved':
        return 'تأیید مشاور';

      case 'rejected':
        return 'ردشده';

      case 'paid':
        return 'پرداخت‌شده';

      case 'cancelled':
        return 'لغوشده';

      default:
        return status;
    }
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _statusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.blue;

      case 'pending_ceo':
        return Colors.orange;

      case 'ceo_approved':
        return Colors.indigo;

      case 'pending_consultant':
        return Colors.deepPurple;

      case 'consultant_approved':
        return Colors.green;

      case 'rejected':
        return Colors.red;

      case 'paid':
        return Colors.teal;

      case 'cancelled':
        return Colors.grey;

      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // CLEAN TEXT
  // ============================================================

  String? _cleanText(String value) {
    final text = value.trim();

    if (text.isEmpty) {
      return null;
    }

    return text;
  }

  // ============================================================
  // ERROR
  // ============================================================

  String _friendlyError(Object error) {
    final message = error.toString();

    if (message.contains('payroll_periods_status_check') ||
        message.contains('23514')) {
      return 'وضعیت انتخاب شده با وضعیت‌های مجاز دیتابیس سازگار نیست.';
    }

    if (message.contains('23505') ||
        message.toLowerCase().contains('duplicate')) {
      return 'این دوره حقوق قبلاً ثبت شده است.';
    }

    if (message.contains('42501') ||
        message.toLowerCase().contains('permission denied')) {
      return 'دسترسی لازم برای ثبت یا ویرایش دوره حقوق وجود ندارد.';
    }

    if (message.contains('23503')) {
      return 'اطلاعات مرتبط با این دوره معتبر نیست.';
    }

    return message;
  }

  // ============================================================
  // SHOW ERROR
  // ============================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.red.shade700, content: Text(message)),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _yearController.dispose();
    _notesController.dispose();

    super.dispose();
  }
}

// ============================================================
// STATUS INFO WIDGET
// ============================================================

class _StatusInfo extends StatelessWidget {
  const _StatusInfo({required this.status});

  final String status;

  String _title(String status) {
    switch (status) {
      case 'draft':
        return 'پیش‌نویس';

      case 'pending_ceo':
        return 'محاسبه‌شده';

      case 'ceo_approved':
        return 'تأیید مدیرعامل';

      case 'pending_consultant':
        return 'در انتظار بررسی مشاور';

      case 'consultant_approved':
        return 'تأیید مشاور';

      case 'rejected':
        return 'ردشده';

      case 'paid':
        return 'پرداخت‌شده';

      case 'cancelled':
        return 'لغوشده';

      default:
        return status;
    }
  }

  IconData _icon(String status) {
    switch (status) {
      case 'draft':
        return Icons.edit_note_rounded;

      case 'pending_ceo':
        return Icons.calculate_rounded;

      case 'ceo_approved':
        return Icons.verified_rounded;

      case 'pending_consultant':
        return Icons.support_agent_rounded;

      case 'consultant_approved':
        return Icons.task_alt_rounded;

      case 'rejected':
        return Icons.cancel_rounded;

      case 'paid':
        return Icons.payments_rounded;

      case 'cancelled':
        return Icons.block_rounded;

      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _color(String status) {
    switch (status) {
      case 'draft':
        return Colors.blue;

      case 'pending_ceo':
        return Colors.orange;

      case 'ceo_approved':
        return Colors.indigo;

      case 'pending_consultant':
        return Colors.deepPurple;

      case 'consultant_approved':
        return Colors.green;

      case 'rejected':
        return Colors.red;

      case 'paid':
        return Colors.teal;

      case 'cancelled':
        return Colors.grey;

      default:
        return Colors.grey;
    }
  }

  String _description(String status) {
    switch (status) {
      case 'draft':
        return 'دوره در حالت پیش‌نویس قرار می‌گیرد.';

      case 'pending_ceo':
        return 'حقوق محاسبه شده و آماده تأیید مدیرعامل است.';

      case 'ceo_approved':
        return 'دوره توسط مدیرعامل تأیید شده است.';

      case 'pending_consultant':
        return 'دوره برای بررسی مشاور ارسال می‌شود.';

      case 'consultant_approved':
        return 'دوره توسط مشاور تأیید شده و آماده پرداخت است.';

      case 'rejected':
        return 'دوره رد شده و نیازمند اصلاح است.';

      case 'paid':
        return 'دوره پرداخت شده و قفل است.';

      case 'cancelled':
        return 'دوره لغو شده است.';

      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withOpacity(.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon(status), size: 18, color: color),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title(status),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  _description(status),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 10,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
