import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/banking_provider.dart';
import '../../data/banking_repository.dart';
import 'banking_form_helpers.dart';

class BankAccountFormDialog
    extends ConsumerStatefulWidget {
  const BankAccountFormDialog({
    super.key,
    required this.companyId,
    this.account,
  });

  final String companyId;
  final BankAccountModel? account;

  bool get isEdit =>
      account != null;

  @override
  ConsumerState<BankAccountFormDialog>
  createState() =>
      _BankAccountFormDialogState();
}

class _BankAccountFormDialogState
    extends ConsumerState<BankAccountFormDialog> {
  final _formKey =
  GlobalKey<FormState>();

  late final TextEditingController
  _bankNameController;

  late final TextEditingController
  _accountNumberController;

  late final TextEditingController
  _openingBalanceController;

  late final TextEditingController
  _debitTurnoverController;

  late final TextEditingController
  _creditTurnoverController;

  late final TextEditingController
  _closingBalanceController;

  late final TextEditingController
  _ledgerBalanceController;

  late final TextEditingController
  _discrepancyController;

  late final TextEditingController
  _fiscalYearController;

  late final TextEditingController
  _fiscalMonthController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final account =
        widget.account;

    _bankNameController =
        TextEditingController(
          text:
          account?.bankName ?? '',
        );

    _accountNumberController =
        TextEditingController(
          text:
          account?.accountNumber ?? '',
        );

    _openingBalanceController =
        TextEditingController(
          text:
          account == null
              ? ''
              : formatMoneyInput(
            account.openingBalance,
          ),
        );

    _debitTurnoverController =
        TextEditingController(
          text:
          account == null
              ? ''
              : formatMoneyInput(
            account.debitTurnover,
          ),
        );

    _creditTurnoverController =
        TextEditingController(
          text:
          account == null
              ? ''
              : formatMoneyInput(
            account.creditTurnover,
          ),
        );

    _closingBalanceController =
        TextEditingController(
          text:
          account == null
              ? ''
              : formatMoneyInput(
            account.closingBalance,
          ),
        );

    _ledgerBalanceController =
        TextEditingController(
          text:
          account == null
              ? ''
              : formatMoneyInput(
            account.ledgerBalance,
          ),
        );

    _discrepancyController =
        TextEditingController(
          text:
          account == null
              ? ''
              : formatMoneyInput(
            account.discrepancy,
          ),
        );

    _fiscalYearController =
        TextEditingController(
          text:
          account?.fiscalYear
              ?.toString() ??
              '',
        );

    _fiscalMonthController =
        TextEditingController(
          text:
          account?.fiscalMonth
              ?.toString() ??
              '',
        );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return AlertDialog(
      title:
      Text(
        widget.isEdit
            ? 'ویرایش حساب بانکی'
            : 'ثبت حساب بانکی',
        style:
        const TextStyle(
          fontWeight:
          FontWeight.w900,
        ),
      ),

      content:
      SizedBox(
        width:
        650,

        child:
        SingleChildScrollView(
          child:
          Form(
            key:
            _formKey,

            child:
            Column(
              children: [
                _textField(
                  controller:
                  _bankNameController,
                  label:
                  'نام بانک',
                  required:
                  true,
                ),

                _textField(
                  controller:
                  _accountNumberController,
                  label:
                  'شماره حساب',
                  required:
                  true,
                ),

                _numberField(
                  controller:
                  _openingBalanceController,
                  label:
                  'مانده اول دوره',
                ),

                _numberField(
                  controller:
                  _debitTurnoverController,
                  label:
                  'گردش بدهکار',
                ),

                _numberField(
                  controller:
                  _creditTurnoverController,
                  label:
                  'گردش بستانکار',
                ),

                _numberField(
                  controller:
                  _closingBalanceController,
                  label:
                  'مانده پایان دوره',
                ),

                _numberField(
                  controller:
                  _ledgerBalanceController,
                  label:
                  'مانده دفتر',
                ),

                _numberField(
                  controller:
                  _discrepancyController,
                  label:
                  'مغایرت',
                ),

                BankingFiscalPeriodField(
                  yearController:
                  _fiscalYearController,
                  monthController:
                  _fiscalMonthController,
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
            Navigator.of(
              context,
            ).pop();
          },
          child:
          const Text(
            'انصراف',
          ),
        ),

        FilledButton.icon(
          onPressed:
          _saving
              ? null
              : _save,

          icon:
          _saving
              ? const SizedBox(
            width:
            18,
            height:
            18,
            child:
            CircularProgressIndicator(
              strokeWidth:
              2,
              color:
              Colors.white,
            ),
          )
              : const Icon(
            Icons
                .save_rounded,
          ),

          label:
          Text(
            widget.isEdit
                ? 'ذخیره تغییرات'
                : 'ثبت حساب',
          ),
        ),
      ],
    );
  }

  Widget _textField({
    required TextEditingController
    controller,
    required String label,
    required bool required,
  }) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 12,
      ),
      child:
      TextFormField(
        controller:
        controller,
        textDirection:
        TextDirection.rtl,
        decoration:
        InputDecoration(
          labelText:
          label,
          border:
          const OutlineInputBorder(),
        ),
        validator:
            (value) {
          if (!required) {
            return null;
          }

          if (value == null ||
              value.trim().isEmpty) {
            return 'این فیلد الزامی است.';
          }

          return null;
        },
      ),
    );
  }

  Widget _numberField({
    required TextEditingController
    controller,
    required String label,
  }) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 12,
      ),
      child:
      TextFormField(
        controller:
        controller,
        keyboardType:
        const TextInputType
            .numberWithOptions(
          decimal:
          true,
          signed:
          true,
        ),
        textDirection:
        TextDirection.ltr,
        inputFormatters: const [
          ThousandsSeparatorFormatter(),
        ],
        decoration:
        InputDecoration(
          labelText:
          label,
          border:
          const OutlineInputBorder(),
        ),
        validator:
            (value) {
          if (value == null ||
              value.trim().isEmpty) {
            return null;
          }

          if (parseFormattedDouble(
            value,
          ) ==
              null) {
            return 'مقدار عددی معتبر وارد کنید.';
          }

          return null;
        },
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey
        .currentState!
        .validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final repository =
      ref.read(
        bankingRepositoryProvider,
      );

      final opening =
          parseFormattedDouble(
            _openingBalanceController
                .text,
          ) ??
              0;

      final debit =
          parseFormattedDouble(
            _debitTurnoverController
                .text,
          ) ??
              0;

      final credit =
          parseFormattedDouble(
            _creditTurnoverController
                .text,
          ) ??
              0;

      final closing =
          parseFormattedDouble(
            _closingBalanceController
                .text,
          ) ??
              0;

      final ledger =
          parseFormattedDouble(
            _ledgerBalanceController
                .text,
          ) ??
              0;

      final discrepancy =
          parseFormattedDouble(
            _discrepancyController
                .text,
          ) ??
              0;

      final fiscalYear =
      parseFormattedInt(
        _fiscalYearController
            .text,
      );

      final fiscalMonth =
      parseFormattedInt(
        _fiscalMonthController
            .text,
      );

      if (widget.isEdit) {
        await repository
            .updateBankAccount(
          id:
          widget.account!.id,
          bankName:
          _bankNameController
              .text
              .trim(),
          accountNumber:
          _accountNumberController
              .text
              .trim(),
          openingBalance:
          opening,
          debitTurnover:
          debit,
          creditTurnover:
          credit,
          closingBalance:
          closing,
          ledgerBalance:
          ledger,
          discrepancy:
          discrepancy,
          fiscalYear:
          fiscalYear,
          fiscalMonth:
          fiscalMonth,
        );
      } else {
        await repository
            .createBankAccount(
          companyId:
          widget.companyId,
          bankName:
          _bankNameController
              .text
              .trim(),
          accountNumber:
          _accountNumberController
              .text
              .trim(),
          openingBalance:
          opening,
          debitTurnover:
          debit,
          creditTurnover:
          credit,
          closingBalance:
          closing,
          ledgerBalance:
          ledger,
          discrepancy:
          discrepancy,
          fiscalYear:
          fiscalYear,
          fiscalMonth:
          fiscalMonth,
        );
      }

      ref.invalidate(
        bankingDashboardProvider(
          widget.companyId,
        ),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content:
          Text(
            widget.isEdit
                ? 'حساب بانکی با موفقیت ویرایش شد.'
                : 'حساب بانکی با موفقیت ثبت شد.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          backgroundColor:
          Colors.red.shade700,
          content:
          Text(
            error.toString(),
          ),
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
    _accountNumberController.dispose();
    _openingBalanceController.dispose();
    _debitTurnoverController.dispose();
    _creditTurnoverController.dispose();
    _closingBalanceController.dispose();
    _ledgerBalanceController.dispose();
    _discrepancyController.dispose();
    _fiscalYearController.dispose();
    _fiscalMonthController.dispose();

    super.dispose();
  }
}