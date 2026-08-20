import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/banking_provider.dart';
import '../../data/banking_repository.dart';

class CashBoxFormDialog extends ConsumerStatefulWidget {
  const CashBoxFormDialog({super.key, required this.companyId, this.cashBox});

  final String companyId;
  final CashBoxModel? cashBox;

  bool get isEdit => cashBox != null;

  @override
  ConsumerState<CashBoxFormDialog> createState() => _CashBoxFormDialogState();
}

class _CashBoxFormDialogState extends ConsumerState<CashBoxFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _boxNameController;
  late final TextEditingController _openingBalanceController;
  late final TextEditingController _totalReceiptsController;
  late final TextEditingController _totalPaymentsController;
  late final TextEditingController _closingBalanceController;
  late final TextEditingController _ledgerBalanceController;
  late final TextEditingController _discrepancyController;
  late final TextEditingController _fiscalYearController;
  late final TextEditingController _fiscalMonthController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final box = widget.cashBox;

    _boxNameController = TextEditingController(text: box?.boxName ?? '');

    _openingBalanceController = TextEditingController(
      text: box == null ? '' : _format(box.openingBalance),
    );

    _totalReceiptsController = TextEditingController(
      text: box == null ? '' : _format(box.totalReceipts),
    );

    _totalPaymentsController = TextEditingController(
      text: box == null ? '' : _format(box.totalPayments),
    );

    _closingBalanceController = TextEditingController(
      text: box == null ? '' : _format(box.closingBalance),
    );

    _ledgerBalanceController = TextEditingController(
      text: box == null ? '' : _format(box.ledgerBalance),
    );

    _discrepancyController = TextEditingController(
      text: box == null ? '' : _format(box.discrepancy),
    );

    _fiscalYearController = TextEditingController(text: box == null ? '' : '');

    _fiscalMonthController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isEdit ? 'ویرایش صندوق' : 'ثبت صندوق',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      content: SizedBox(
        width: 650,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _textField(
                  controller: _boxNameController,
                  label: 'نام صندوق',
                  requiredField: true,
                ),
                _numberField(
                  controller: _openingBalanceController,
                  label: 'مانده اول دوره',
                ),
                _numberField(
                  controller: _totalReceiptsController,
                  label: 'مجموع دریافت',
                ),
                _numberField(
                  controller: _totalPaymentsController,
                  label: 'مجموع پرداخت',
                ),
                _numberField(
                  controller: _closingBalanceController,
                  label: 'مانده پایان دوره',
                ),
                _numberField(
                  controller: _ledgerBalanceController,
                  label: 'مانده دفتر',
                ),
                _numberField(
                  controller: _discrepancyController,
                  label: 'مغایرت',
                ),
                Row(
                  children: [
                    Expanded(
                      child: _integerField(
                        controller: _fiscalYearController,
                        label: 'سال مالی',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _integerField(
                        controller: _fiscalMonthController,
                        label: 'ماه',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
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
          label: Text(widget.isEdit ? 'ذخیره تغییرات' : 'ثبت صندوق'),
        ),
      ],
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required bool requiredField,
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
          if (!requiredField) return null;

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
            return null;
          }

          if (_parseDouble(value) == null) {
            return 'مقدار عددی معتبر وارد کنید.';
          }

          return null;
        },
      ),
    );
  }

  Widget _integerField({
    required TextEditingController controller,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return null;
          }

          if (int.tryParse(value.trim()) == null) {
            return 'عدد صحیح معتبر وارد کنید.';
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

    setState(() {
      _saving = true;
    });

    try {
      final repository = ref.read(bankingRepositoryProvider);

      if (widget.isEdit) {
        await repository.updateCashBox(
          id: widget.cashBox!.id,
          boxName: _boxNameController.text.trim(),
          openingBalance: _parseDouble(_openingBalanceController.text) ?? 0,
          totalReceipts: _parseDouble(_totalReceiptsController.text) ?? 0,
          totalPayments: _parseDouble(_totalPaymentsController.text) ?? 0,
          closingBalance: _parseDouble(_closingBalanceController.text) ?? 0,
          ledgerBalance: _parseDouble(_ledgerBalanceController.text) ?? 0,
          discrepancy: _parseDouble(_discrepancyController.text) ?? 0,
          fiscalYear: _parseInt(_fiscalYearController.text),
          fiscalMonth: _parseInt(_fiscalMonthController.text),
        );
      } else {
        await repository.createCashBox(
          companyId: widget.companyId,
          boxName: _boxNameController.text.trim(),
          openingBalance: _parseDouble(_openingBalanceController.text) ?? 0,
          totalReceipts: _parseDouble(_totalReceiptsController.text) ?? 0,
          totalPayments: _parseDouble(_totalPaymentsController.text) ?? 0,
          closingBalance: _parseDouble(_closingBalanceController.text) ?? 0,
          ledgerBalance: _parseDouble(_ledgerBalanceController.text) ?? 0,
          discrepancy: _parseDouble(_discrepancyController.text) ?? 0,
          fiscalYear: _parseInt(_fiscalYearController.text),
          fiscalMonth: _parseInt(_fiscalMonthController.text),
        );
      }

      ref.invalidate(bankingDashboardProvider(widget.companyId));

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEdit
                ? 'صندوق با موفقیت ویرایش شد.'
                : 'صندوق با موفقیت ثبت شد.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

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

    if (cleaned.isEmpty) return null;

    return double.tryParse(cleaned);
  }

  int? _parseInt(String value) {
    final cleaned = value.trim();

    if (cleaned.isEmpty) return null;

    return int.tryParse(cleaned);
  }

  String _format(double value) {
    return value.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _boxNameController.dispose();
    _openingBalanceController.dispose();
    _totalReceiptsController.dispose();
    _totalPaymentsController.dispose();
    _closingBalanceController.dispose();
    _ledgerBalanceController.dispose();
    _discrepancyController.dispose();
    _fiscalYearController.dispose();
    _fiscalMonthController.dispose();

    super.dispose();
  }
}
