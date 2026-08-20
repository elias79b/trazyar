import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/banking_provider.dart';
import '../../data/banking_repository.dart';

enum CheckType { received, paid }

class CheckFormDialog extends ConsumerStatefulWidget {
  const CheckFormDialog({
    super.key,
    required this.companyId,
    required this.type,
    this.check,
  });

  final String companyId;
  final CheckType type;
  final CheckModel? check;

  bool get isEdit => check != null;

  @override
  ConsumerState<CheckFormDialog> createState() => _CheckFormDialogState();
}

class _CheckFormDialogState extends ConsumerState<CheckFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _checkNumberController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _amountController;
  late final TextEditingController _dueDateController;
  late final TextEditingController _statusController;

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
      text: check == null ? '' : _formatNumber(check.amount),
    );

    _dueDateController = TextEditingController(
      text: _formatDate(check?.dueDate),
    );

    _statusController = TextEditingController(text: check?.status ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.isEdit
            ? widget.type == CheckType.received
                ? 'ویرایش چک دریافتی'
                : 'ویرایش چک پرداختی'
            : widget.type == CheckType.received
            ? 'ثبت چک دریافتی'
            : 'ثبت چک پرداختی';

    return AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _textField(
                  controller: _checkNumberController,
                  label: 'شماره چک',
                ),
                _textField(controller: _bankNameController, label: 'نام بانک'),
                _numberField(controller: _amountController, label: 'مبلغ چک'),
                _textField(
                  controller: _dueDateController,
                  label: 'تاریخ سررسید (YYYY-MM-DD)',
                  requiredField: false,
                ),
                _textField(controller: _statusController, label: 'وضعیت'),
              ],
            ),
          ),
        ),
      ),
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
          label: Text(widget.isEdit ? 'ذخیره تغییرات' : 'ثبت چک'),
        ),
      ],
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    bool requiredField = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (!requiredField) {
            return null;
          }

          if (value == null || value.trim().isEmpty) {
            return 'این فیلد الزامی است.';
          }

          return null;
        },
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'این فیلد الزامی است.';
          }

          if (_parseDouble(value) == null) {
            return 'مبلغ معتبر وارد کنید.';
          }

          return null;
        },
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final dueDate = _parseDate(_dueDateController.text);

    setState(() {
      _saving = true;
    });

    try {
      final repository = ref.read(bankingRepositoryProvider);

      final amount = _parseDouble(_amountController.text) ?? 0;

      if (widget.type == CheckType.received) {
        if (widget.isEdit) {
          await repository.updateReceivedCheck(
            id: widget.check!.id,
            checkNumber: _checkNumberController.text.trim(),
            bankName: _bankNameController.text.trim(),
            amount: amount,
            dueDate: dueDate,
            status: _statusController.text.trim(),
          );
        } else {
          await repository.createReceivedCheck(
            companyId: widget.companyId,
            checkNumber: _checkNumberController.text.trim(),
            bankName: _bankNameController.text.trim(),
            amount: amount,
            dueDate: dueDate,
            status: _statusController.text.trim(),
          );
        }
      } else {
        if (widget.isEdit) {
          await repository.updatePaidCheck(
            id: widget.check!.id,
            checkNumber: _checkNumberController.text.trim(),
            bankName: _bankNameController.text.trim(),
            amount: amount,
            dueDate: dueDate,
            status: _statusController.text.trim(),
          );
        } else {
          await repository.createPaidCheck(
            companyId: widget.companyId,
            checkNumber: _checkNumberController.text.trim(),
            bankName: _bankNameController.text.trim(),
            amount: amount,
            dueDate: dueDate,
            status: _statusController.text.trim(),
          );
        }
      }

      ref.invalidate(bankingDashboardProvider(widget.companyId));

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEdit ? 'چک با موفقیت ویرایش شد.' : 'چک با موفقیت ثبت شد.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(error.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  double? _parseDouble(String value) {
    final cleaned = value.replaceAll(',', '').trim();

    if (cleaned.isEmpty) {
      return null;
    }

    return double.tryParse(cleaned);
  }

  DateTime? _parseDate(String value) {
    final cleaned = value.trim();

    if (cleaned.isEmpty) {
      return null;
    }

    return DateTime.tryParse(cleaned);
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '';
    }

    final month = value.month.toString().padLeft(2, '0');

    final day = value.day.toString().padLeft(2, '0');

    return '${value.year}-$month-$day';
  }

  String _formatNumber(double value) {
    return value.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _checkNumberController.dispose();
    _bankNameController.dispose();
    _amountController.dispose();
    _dueDateController.dispose();
    _statusController.dispose();

    super.dispose();
  }
}
