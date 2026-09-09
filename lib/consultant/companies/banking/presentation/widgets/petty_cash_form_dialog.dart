import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/banking_provider.dart';
import '../../data/banking_repository.dart';
import 'banking_form_helpers.dart';

class PettyCashFormDialog
    extends ConsumerStatefulWidget {
  const PettyCashFormDialog({
    super.key,
    required this.companyId,
    this.pettyCash,
  });

  final String companyId;
  final PettyCashModel? pettyCash;

  bool get isEdit =>
      pettyCash != null;

  @override
  ConsumerState<PettyCashFormDialog>
  createState() =>
      _PettyCashFormDialogState();
}

class _PettyCashFormDialogState
    extends ConsumerState<PettyCashFormDialog> {
  final _formKey =
  GlobalKey<FormState>();

  late final TextEditingController
  _nameController;

  late final TextEditingController
  _responsibleUserController;

  late final TextEditingController
  _openingBalanceController;

  late final TextEditingController
  _totalReceiptsController;

  late final TextEditingController
  _totalPaymentsController;

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

    final pettyCash =
        widget.pettyCash;

    _nameController =
        TextEditingController(
          text:
          pettyCash?.name ?? '',
        );

    _responsibleUserController =
        TextEditingController(
          text:
          pettyCash
              ?.responsibleUserId ??
              '',
        );

    _openingBalanceController =
        TextEditingController(
          text:
          pettyCash == null
              ? ''
              : formatMoneyInput(
            pettyCash
                .openingBalance,
          ),
        );

    _totalReceiptsController =
        TextEditingController(
          text:
          pettyCash == null
              ? ''
              : formatMoneyInput(
            pettyCash
                .totalReceipts,
          ),
        );

    _totalPaymentsController =
        TextEditingController(
          text:
          pettyCash == null
              ? ''
              : formatMoneyInput(
            pettyCash
                .totalPayments,
          ),
        );

    _closingBalanceController =
        TextEditingController(
          text:
          pettyCash == null
              ? ''
              : formatMoneyInput(
            pettyCash
                .closingBalance,
          ),
        );

    _ledgerBalanceController =
        TextEditingController(
          text:
          pettyCash == null
              ? ''
              : formatMoneyInput(
            pettyCash
                .ledgerBalance,
          ),
        );

    _discrepancyController =
        TextEditingController(
          text:
          pettyCash == null
              ? ''
              : formatMoneyInput(
            pettyCash
                .discrepancy,
          ),
        );

    _fiscalYearController =
        TextEditingController(
          text:
          pettyCash?.fiscalYear
              ?.toString() ??
              '',
        );

    _fiscalMonthController =
        TextEditingController(
          text:
          pettyCash?.fiscalMonth
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
            ? 'ویرایش تنخواه'
            : 'ثبت تنخواه',
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
                  _nameController,
                  label:
                  'نام تنخواه',
                  requiredField:
                  true,
                ),

                _responsibleUserField(),

                _numberField(
                  controller:
                  _openingBalanceController,
                  label:
                  'مانده اول دوره',
                ),

                _numberField(
                  controller:
                  _totalReceiptsController,
                  label:
                  'مجموع دریافت',
                ),

                _numberField(
                  controller:
                  _totalPaymentsController,
                  label:
                  'مجموع پرداخت',
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
                : 'ثبت تنخواه',
          ),
        ),
      ],
    );
  }

  Widget _responsibleUserField() {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 12,
      ),
      child:
      TextFormField(
        controller:
        _responsibleUserController,
        decoration:
        const InputDecoration(
          labelText:
          'شناسه مسئول تنخواه',
          hintText:
          'اختیاری - UUID کاربر',
          border:
          OutlineInputBorder(),
        ),
        validator:
            (value) {
          final text =
              value?.trim() ?? '';

          if (text.isEmpty) {
            return null;
          }

          if (!_isValidUuid(text)) {
            return 'شناسه کاربر باید UUID معتبر باشد.';
          }

          return null;
        },
      ),
    );
  }

  Widget _textField({
    required TextEditingController
    controller,
    required String label,
    required bool requiredField,
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
        decoration:
        InputDecoration(
          labelText:
          label,
          border:
          const OutlineInputBorder(),
        ),
        validator:
            (value) {
          if (!requiredField) {
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

      final responsibleUserId =
      _getValidatedResponsibleUserId();

      if (widget.isEdit) {
        await repository
            .updatePettyCash(
          id:
          widget.pettyCash!.id,
          name:
          _nameController.text
              .trim(),
          responsibleUserId:
          responsibleUserId,
          openingBalance:
          parseFormattedDouble(
            _openingBalanceController
                .text,
          ) ??
              0,
          totalReceipts:
          parseFormattedDouble(
            _totalReceiptsController
                .text,
          ) ??
              0,
          totalPayments:
          parseFormattedDouble(
            _totalPaymentsController
                .text,
          ) ??
              0,
          closingBalance:
          parseFormattedDouble(
            _closingBalanceController
                .text,
          ) ??
              0,
          ledgerBalance:
          parseFormattedDouble(
            _ledgerBalanceController
                .text,
          ) ??
              0,
          discrepancy:
          parseFormattedDouble(
            _discrepancyController
                .text,
          ) ??
              0,
          fiscalYear:
          parseFormattedInt(
            _fiscalYearController
                .text,
          ),
          fiscalMonth:
          parseFormattedInt(
            _fiscalMonthController
                .text,
          ),
        );
      } else {
        await repository
            .createPettyCash(
          companyId:
          widget.companyId,
          name:
          _nameController.text
              .trim(),
          responsibleUserId:
          responsibleUserId,
          openingBalance:
          parseFormattedDouble(
            _openingBalanceController
                .text,
          ) ??
              0,
          totalReceipts:
          parseFormattedDouble(
            _totalReceiptsController
                .text,
          ) ??
              0,
          totalPayments:
          parseFormattedDouble(
            _totalPaymentsController
                .text,
          ) ??
              0,
          closingBalance:
          parseFormattedDouble(
            _closingBalanceController
                .text,
          ) ??
              0,
          ledgerBalance:
          parseFormattedDouble(
            _ledgerBalanceController
                .text,
          ) ??
              0,
          discrepancy:
          parseFormattedDouble(
            _discrepancyController
                .text,
          ) ??
              0,
          fiscalYear:
          parseFormattedInt(
            _fiscalYearController
                .text,
          ),
          fiscalMonth:
          parseFormattedInt(
            _fiscalMonthController
                .text,
          ),
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
                ? 'تنخواه با موفقیت ویرایش شد.'
                : 'تنخواه با موفقیت ثبت شد.',
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

  String? _getValidatedResponsibleUserId() {
    final value =
    _responsibleUserController
        .text
        .trim();

    if (value.isEmpty) {
      return null;
    }

    if (!_isValidUuid(value)) {
      return null;
    }

    return value;
  }

  bool _isValidUuid(
      String value,
      ) {
    final regex =
    RegExp(
      r'^[0-9a-fA-F]{8}-'
      r'[0-9a-fA-F]{4}-'
      r'[1-5][0-9a-fA-F]{3}-'
      r'[89abAB][0-9a-fA-F]{3}-'
      r'[0-9a-fA-F]{12}$',
    );

    return regex.hasMatch(
      value,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _responsibleUserController.dispose();
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