import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/banking_provider.dart';
import '../../data/banking_repository.dart';
import 'banking_form_helpers.dart';

class BankLoanFormDialog extends ConsumerStatefulWidget {
  const BankLoanFormDialog({super.key, required this.companyId, this.loan});

  final String companyId;
  final BankLoanModel? loan;

  bool get isEdit => loan != null;

  @override
  ConsumerState<BankLoanFormDialog> createState() => _BankLoanFormDialogState();
}

class _BankLoanFormDialogState extends ConsumerState<BankLoanFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _bankNameController;

  late final TextEditingController _loanTypeController;

  late final TextEditingController _principalAmountController;

  late final TextEditingController _remainingAmountController;

  late final TextEditingController _interestRateController;

  late final TextEditingController _startDateController;

  late final TextEditingController _endDateController;

  late final TextEditingController _monthlyInstallmentController;

  DateTime? _startDate;
  DateTime? _endDate;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final loan = widget.loan;

    _bankNameController = TextEditingController(text: loan?.bankName ?? '');

    _loanTypeController = TextEditingController(text: loan?.loanType ?? '');

    _principalAmountController = TextEditingController(
      text: loan == null ? '' : formatMoneyInput(loan.principalAmount),
    );

    _remainingAmountController = TextEditingController(
      text: loan == null ? '' : formatMoneyInput(loan.remainingAmount),
    );

    _interestRateController = TextEditingController(
      text: loan == null ? '' : formatMoneyInput(loan.interestRate),
    );

    _startDate = loan?.startDate;

    _endDate = loan?.endDate;

    _startDateController = TextEditingController(
      text: loan?.startDate == null ? '' : formatShamsiDate(loan!.startDate!),
    );

    _endDateController = TextEditingController(
      text: loan?.endDate == null ? '' : formatShamsiDate(loan!.endDate!),
    );

    _monthlyInstallmentController = TextEditingController(
      text: loan == null ? '' : formatMoneyInput(loan.monthlyInstallment),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isEdit ? 'ویرایش تسهیلات بانکی' : 'ثبت تسهیلات بانکی',
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
                  controller: _bankNameController,
                  label: 'نام بانک',
                  requiredField: true,
                ),

                _textField(
                  controller: _loanTypeController,
                  label: 'نوع تسهیلات',
                  requiredField: true,
                ),

                _numberField(
                  controller: _principalAmountController,
                  label: 'مبلغ اولیه تسهیلات',
                ),

                _numberField(
                  controller: _remainingAmountController,
                  label: 'مانده تسهیلات',
                ),

                _numberField(
                  controller: _interestRateController,
                  label: 'نرخ سود',
                ),

                BankingDateField(
                  controller: _startDateController,
                  label: 'تاریخ شروع',
                  initialDate: _startDate,
                  requiredField: false,
                  onDateSelected: (date) {
                    setState(() {
                      _startDate = date;

                      _startDateController.value = TextEditingValue(
                        text: formatShamsiDate(date),
                        selection: TextSelection.collapsed(
                          offset: formatShamsiDate(date).length,
                        ),
                      );
                    });
                  },
                ),

                BankingDateField(
                  controller: _endDateController,
                  label: 'تاریخ پایان',
                  initialDate: _endDate,
                  requiredField: false,
                  onDateSelected: (date) {
                    setState(() {
                      _endDate = date;

                      _endDateController.value = TextEditingValue(
                        text: formatShamsiDate(date),
                        selection: TextSelection.collapsed(
                          offset: formatShamsiDate(date).length,
                        ),
                      );
                    });
                  },
                ),

                _numberField(
                  controller: _monthlyInstallmentController,
                  label: 'قسط ماهانه',
                ),
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
          label: Text(widget.isEdit ? 'ذخیره تغییرات' : 'ثبت تسهیلات'),
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
        textDirection: TextDirection.rtl,
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
        textDirection: TextDirection.ltr,
        inputFormatters: const [ThousandsSeparatorFormatter()],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return null;
          }

          if (parseFormattedDouble(value) == null) {
            return 'مقدار عددی معتبر وارد کنید.';
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

    if (_startDate != null &&
        _endDate != null &&
        _endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تاریخ پایان نمی‌تواند قبل از تاریخ شروع باشد.'),
        ),
      );

      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final repository = ref.read(bankingRepositoryProvider);

      final principalAmount =
          parseFormattedDouble(_principalAmountController.text) ?? 0;

      final remainingAmount =
          parseFormattedDouble(_remainingAmountController.text) ?? 0;

      final interestRate =
          parseFormattedDouble(_interestRateController.text) ?? 0;

      final monthlyInstallment =
          parseFormattedDouble(_monthlyInstallmentController.text) ?? 0;

      if (widget.isEdit) {
        await repository.updateBankLoan(
          id: widget.loan!.id,
          bankName: _bankNameController.text.trim(),
          loanType: _loanTypeController.text.trim(),
          principalAmount: principalAmount,
          remainingAmount: remainingAmount,
          interestRate: interestRate,
          startDate: _startDate,
          endDate: _endDate,
          monthlyInstallment: monthlyInstallment,
        );
      } else {
        await repository.createBankLoan(
          companyId: widget.companyId,
          bankName: _bankNameController.text.trim(),
          loanType: _loanTypeController.text.trim(),
          principalAmount: principalAmount,
          remainingAmount: remainingAmount,
          interestRate: interestRate,
          startDate: _startDate,
          endDate: _endDate,
          monthlyInstallment: monthlyInstallment,
        );
      }

      ref.invalidate(bankingDashboardProvider(widget.companyId));

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEdit
                ? 'تسهیلات با موفقیت ویرایش شد.'
                : 'تسهیلات با موفقیت ثبت شد.',
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

  @override
  void dispose() {
    _bankNameController.dispose();
    _loanTypeController.dispose();
    _principalAmountController.dispose();
    _remainingAmountController.dispose();
    _interestRateController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _monthlyInstallmentController.dispose();

    super.dispose();
  }
}
