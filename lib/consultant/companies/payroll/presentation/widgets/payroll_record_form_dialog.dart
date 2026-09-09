import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarazyar/consultant/companies/payroll/application/employee_provider.dart';
import 'package:tarazyar/consultant/companies/payroll/application/employment_contract_provider.dart';
import 'package:tarazyar/consultant/companies/payroll/data/employee_model.dart';
import 'package:tarazyar/consultant/companies/payroll/data/employment_contract_model.dart';

import '../../application/payroll_record_provider.dart';
import '../../data/payroll_record_model.dart';

class PayrollRecordFormDialog extends ConsumerStatefulWidget {
  const PayrollRecordFormDialog({
    super.key,
    required this.companyId,
    required this.payrollPeriodId,
    this.record,
  });

  final String companyId;
  final String payrollPeriodId;
  final PayrollRecordModel? record;

  bool get isEdit => record != null;

  @override
  ConsumerState<PayrollRecordFormDialog> createState() =>
      _PayrollRecordFormDialogState();
}

class _PayrollRecordFormDialogState
    extends ConsumerState<PayrollRecordFormDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedEmployeeId;
  String? _selectedContractId;

  late final TextEditingController _baseSalaryController;

  late final TextEditingController _overtimeHoursController;

  late final TextEditingController _overtimeAmountController;

  late final TextEditingController _bonusController;

  late final TextEditingController _allowanceController;

  late final TextEditingController _employeeInsuranceController;

  late final TextEditingController _employerInsuranceController;

  late final TextEditingController _taxController;

  late final TextEditingController _absenceController;

  late final TextEditingController _otherDeductionsController;

  late final TextEditingController _advanceController;

  late final TextEditingController _notesController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final record = widget.record;

    _selectedEmployeeId = record?.employeeId;

    _selectedContractId = record?.contractId;

    _baseSalaryController = TextEditingController(
      text: record == null ? '' : _formatNumber(record.baseSalary),
    );

    _overtimeHoursController = TextEditingController(
      text: record == null ? '0' : _formatNumber(record.overtimeHours),
    );

    _overtimeAmountController = TextEditingController(
      text: record == null ? '0' : _formatNumber(record.overtimeAmount),
    );

    _bonusController = TextEditingController(
      text: record == null ? '0' : _formatNumber(record.bonusAmount),
    );

    _allowanceController = TextEditingController(
      text: record == null ? '0' : _formatNumber(record.allowanceAmount),
    );

    _employeeInsuranceController = TextEditingController(
      text: record == null ? '0' : _formatNumber(record.employeeInsurance),
    );

    _employerInsuranceController = TextEditingController(
      text: record == null ? '0' : _formatNumber(record.employerInsurance),
    );

    _taxController = TextEditingController(
      text: record == null ? '0' : _formatNumber(record.taxAmount),
    );

    _absenceController = TextEditingController(
      text: record == null ? '0' : _formatNumber(record.absenceAmount),
    );

    _otherDeductionsController = TextEditingController(
      text: record == null ? '0' : _formatNumber(record.otherDeductions),
    );

    _advanceController = TextEditingController(
      text: record == null ? '0' : _formatNumber(record.advanceAmount),
    );

    _notesController = TextEditingController(text: record?.notes ?? '');

    _addListeners();
  }

  void _addListeners() {
    _baseSalaryController.addListener(_recalculate);

    _overtimeAmountController.addListener(_recalculate);

    _bonusController.addListener(_recalculate);

    _allowanceController.addListener(_recalculate);

    _employeeInsuranceController.addListener(_recalculate);

    _taxController.addListener(_recalculate);

    _absenceController.addListener(_recalculate);

    _otherDeductionsController.addListener(_recalculate);

    _advanceController.addListener(_recalculate);
  }

  void _recalculate() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesProvider(widget.companyId));

    final contractsAsync =
        _selectedEmployeeId == null
            ? const AsyncValue.data(<EmploymentContractModel>[])
            : ref.watch(employmentContractsProvider(widget.companyId));

    final employees = employeesAsync.valueOrNull ?? const <EmployeeModel>[];

    final allContracts =
        contractsAsync.valueOrNull ?? const <EmploymentContractModel>[];

    final contracts =
        allContracts
            .where((contract) => contract.employeeId == _selectedEmployeeId)
            .toList();

    final grossSalary = _calculateGrossSalary();

    final netSalary = _calculateNetSalary(grossSalary);

    return AlertDialog(
      title: Text(
        widget.isEdit ? 'ویرایش حقوق پرسنل' : 'ثبت حقوق پرسنل',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),

      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildEmployeeField(employees, employeesAsync.isLoading),

                _buildContractField(contracts, contractsAsync.isLoading),

                const SizedBox(height: 4),

                _buildSectionTitle('دریافتی‌ها', Icons.add_card_rounded),

                _moneyField(
                  controller: _baseSalaryController,
                  label: 'حقوق پایه',
                  requiredField: true,
                ),

                _numberField(
                  controller: _overtimeHoursController,
                  label: 'ساعات اضافه‌کاری',
                ),

                _moneyField(
                  controller: _overtimeAmountController,
                  label: 'مبلغ اضافه‌کاری',
                ),

                _moneyField(controller: _allowanceController, label: 'مزایا'),

                _moneyField(controller: _bonusController, label: 'پاداش'),

                _buildCalculatedCard(
                  title: 'حقوق ناخالص',
                  value: grossSalary,
                  icon: Icons.account_balance_wallet_rounded,
                ),

                const SizedBox(height: 8),

                _buildSectionTitle(
                  'کسورات',
                  Icons.remove_circle_outline_rounded,
                ),

                _moneyField(
                  controller: _employeeInsuranceController,
                  label: 'بیمه سهم کارمند',
                ),

                _moneyField(
                  controller: _employerInsuranceController,
                  label: 'بیمه سهم کارفرما',
                ),

                _moneyField(controller: _taxController, label: 'مالیات'),

                _moneyField(controller: _absenceController, label: 'کسری غیبت'),

                _moneyField(
                  controller: _otherDeductionsController,
                  label: 'سایر کسورات',
                ),

                _moneyField(
                  controller: _advanceController,
                  label: 'علی‌الحساب',
                ),

                _buildCalculatedCard(
                  title: 'حقوق خالص',
                  value: netSalary,
                  icon: Icons.payments_rounded,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'توضیحات',
                    alignLabelWithHint: true,
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
          label: Text(widget.isEdit ? 'ذخیره تغییرات' : 'ثبت حقوق'),
        ),
      ],
    );
  }

  // ============================================================
  // EMPLOYEE
  // ============================================================

  Widget _buildEmployeeField(List<EmployeeModel> employees, bool loading) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value:
            employees.any((employee) => employee.id == _selectedEmployeeId)
                ? _selectedEmployeeId
                : null,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'پرسنل',
          border: OutlineInputBorder(),
        ),
        items:
            employees.map((employee) {
              return DropdownMenuItem<String>(
                value: employee.id,
                child: Text(
                  '${employee.fullName} - '
                  '${employee.personnelCode}',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
        onChanged:
            _saving
                ? null
                : (value) {
                  setState(() {
                    _selectedEmployeeId = value;

                    _selectedContractId = null;
                  });

                  if (value != null) {
                    _loadEmployeeContractValues(value);
                  }
                },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'پرسنل را انتخاب کنید.';
          }

          return null;
        },
        hint:
            loading
                ? const Text('در حال دریافت پرسنل...')
                : const Text('انتخاب پرسنل'),
      ),
    );
  }

  // ============================================================
  // CONTRACT
  // ============================================================

  Widget _buildContractField(
    List<EmploymentContractModel> contracts,
    bool loading,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value:
            contracts.any((contract) => contract.id == _selectedContractId)
                ? _selectedContractId
                : null,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'قرارداد',
          border: OutlineInputBorder(),
        ),
        items:
            contracts.map((contract) {
              return DropdownMenuItem<String>(
                value: contract.id,
                child: Text(
                  _contractTitle(contract),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
        onChanged:
            _saving
                ? null
                : (value) {
                  setState(() {
                    _selectedContractId = value;
                  });

                  if (value != null) {
                    final contract = contracts.firstWhere(
                      (item) => item.id == value,
                    );

                    _applyContractSalary(contract);
                  }
                },
        validator: (value) {
          if (_selectedEmployeeId != null &&
              contracts.isNotEmpty &&
              (value == null || value.isEmpty)) {
            return 'قرارداد را انتخاب کنید.';
          }

          return null;
        },
        hint:
            _selectedEmployeeId == null
                ? const Text('ابتدا پرسنل را انتخاب کنید')
                : loading
                ? const Text('در حال دریافت قرارداد...')
                : contracts.isEmpty
                ? const Text('قراردادی برای این پرسنل وجود ندارد')
                : const Text('انتخاب قرارداد'),
      ),
    );
  }

  void _loadEmployeeContractValues(String employeeId) {
    final contracts = ref.read(employmentContractsProvider(widget.companyId));

    contracts.whenData((items) {
      final employeeContracts =
          items.where((contract) => contract.employeeId == employeeId).toList();

      if (employeeContracts.length == 1 && !widget.isEdit) {
        final contract = employeeContracts.first;

        setState(() {
          _selectedContractId = contract.id;
        });

        _applyContractSalary(contract);
      }
    });
  }

  void _applyContractSalary(EmploymentContractModel contract) {
    _baseSalaryController.text = _formatNumber(contract.baseSalary);
  }

  String _contractTitle(EmploymentContractModel contract) {
    final number =
        contract.contractNumber?.trim().isNotEmpty == true
            ? contract.contractNumber!
            : 'بدون شماره';

    return '$number - '
        '${_contractTypeTitle(contract.contractType)}';
  }

  String _contractTypeTitle(String type) {
    switch (type) {
      case 'permanent':
        return 'دائم';

      case 'temporary':
        return 'موقت';

      case 'contract':
        return 'قراردادی';

      case 'probation':
        return 'آزمایشی';

      case 'internship':
        return 'کارآموزی';

      default:
        return type;
    }
  }

  // ============================================================
  // SECTION
  // ============================================================

  Widget _buildSectionTitle(String title, IconData icon) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4332).withOpacity(.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: const Color(0xFF1B4332)),

          const SizedBox(width: 8),

          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MONEY
  // ============================================================

  Widget _moneyField({
    required TextEditingController controller,
    required String label,
    bool requiredField = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: false),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9۰-۹,]')),
        ],
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
        ).copyWith(labelText: label, suffixText: 'تومان'),
        onChanged: (_) {
          _formatController(controller);
        },
        validator: (value) {
          final parsed = _parseNumber(value ?? '');

          if (requiredField && (value == null || value.trim().isEmpty)) {
            return 'این فیلد الزامی است.';
          }

          if (parsed == null || parsed < 0) {
            return 'مبلغ معتبر وارد کنید.';
          }

          return null;
        },
      ),
    );
  }

  // ============================================================
  // NUMBER
  // ============================================================

  Widget _numberField({
    required TextEditingController controller,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9۰-۹.]')),
        ],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (_parseNumber(value ?? '') == null) {
            return 'عدد معتبر وارد کنید.';
          }

          return null;
        },
      ),
    );
  }

  // ============================================================
  // CALCULATED CARD
  // ============================================================

  Widget _buildCalculatedCard({
    required String title,
    required double value,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4332).withOpacity(.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1B4332).withOpacity(.14)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1B4332)),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),

          Text(
            '${_formatNumber(value)} تومان',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CALCULATIONS
  // ============================================================

  double _calculateGrossSalary() {
    final base = _parseNumber(_baseSalaryController.text) ?? 0;

    final overtime = _parseNumber(_overtimeAmountController.text) ?? 0;

    final allowance = _parseNumber(_allowanceController.text) ?? 0;

    final bonus = _parseNumber(_bonusController.text) ?? 0;

    return base + overtime + allowance + bonus;
  }

  double _calculateNetSalary(double grossSalary) {
    final insurance = _parseNumber(_employeeInsuranceController.text) ?? 0;

    final tax = _parseNumber(_taxController.text) ?? 0;

    final absence = _parseNumber(_absenceController.text) ?? 0;

    final other = _parseNumber(_otherDeductionsController.text) ?? 0;

    final advance = _parseNumber(_advanceController.text) ?? 0;

    final deductions = insurance + tax + absence + other + advance;

    final result = grossSalary - deductions;

    return result < 0 ? 0 : result;
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedEmployeeId == null) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final repository = ref.read(payrollRecordRepositoryProvider);

      final baseSalary = _parseNumber(_baseSalaryController.text) ?? 0;

      final overtimeHours = _parseNumber(_overtimeHoursController.text) ?? 0;

      final overtimeAmount = _parseNumber(_overtimeAmountController.text) ?? 0;

      final bonusAmount = _parseNumber(_bonusController.text) ?? 0;

      final allowanceAmount = _parseNumber(_allowanceController.text) ?? 0;

      final employeeInsurance =
          _parseNumber(_employeeInsuranceController.text) ?? 0;

      final employerInsurance =
          _parseNumber(_employerInsuranceController.text) ?? 0;

      final taxAmount = _parseNumber(_taxController.text) ?? 0;

      final absenceAmount = _parseNumber(_absenceController.text) ?? 0;

      final otherDeductions =
          _parseNumber(_otherDeductionsController.text) ?? 0;

      final advanceAmount = _parseNumber(_advanceController.text) ?? 0;

      final grossSalary = _calculateGrossSalary();

      final netSalary = _calculateNetSalary(grossSalary);

      if (widget.isEdit) {
        await repository.updateRecord(
          id: widget.record!.id,
          contractId: _selectedContractId,
          baseSalary: baseSalary,
          overtimeHours: overtimeHours,
          overtimeAmount: overtimeAmount,
          bonusAmount: bonusAmount,
          allowanceAmount: allowanceAmount,
          grossSalary: grossSalary,
          employeeInsurance: employeeInsurance,
          employerInsurance: employerInsurance,
          taxAmount: taxAmount,
          absenceAmount: absenceAmount,
          otherDeductions: otherDeductions,
          advanceAmount: advanceAmount,
          netSalary: netSalary,
          notes: _notesController.text.trim(),
        );
      } else {
        await repository.createRecord(
          companyId: widget.companyId,
          payrollPeriodId: widget.payrollPeriodId,
          employeeId: _selectedEmployeeId!,
          contractId: _selectedContractId,
          baseSalary: baseSalary,
          overtimeHours: overtimeHours,
          overtimeAmount: overtimeAmount,
          bonusAmount: bonusAmount,
          allowanceAmount: allowanceAmount,
          grossSalary: grossSalary,
          employeeInsurance: employeeInsurance,
          employerInsurance: employerInsurance,
          taxAmount: taxAmount,
          absenceAmount: absenceAmount,
          otherDeductions: otherDeductions,
          advanceAmount: advanceAmount,
          netSalary: netSalary,
          notes: _notesController.text.trim(),
        );
      }

      ref.invalidate(payrollRecordsByPeriodProvider(widget.payrollPeriodId));

      ref.invalidate(payrollRecordsProvider(widget.companyId));

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEdit
                ? 'حقوق پرسنل با موفقیت ویرایش شد.'
                : 'حقوق پرسنل با موفقیت ثبت شد.',
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

  // ============================================================
  // NUMBER HELPERS
  // ============================================================

  double? _parseNumber(String value) {
    var cleaned = value.trim();

    if (cleaned.isEmpty) {
      return null;
    }

    const persian = '۰۱۲۳۴۵۶۷۸۹';

    const arabic = '٠١٢٣٤٥٦٧٨٩';

    const english = '0123456789';

    for (var i = 0; i < 10; i++) {
      cleaned = cleaned.replaceAll(persian[i], english[i]);

      cleaned = cleaned.replaceAll(arabic[i], english[i]);
    }

    cleaned = cleaned.replaceAll(',', '');

    return double.tryParse(cleaned);
  }

  String _formatNumber(double value) {
    final rounded = value.round();

    final text = rounded.toString();

    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      final position = text.length - i;

      buffer.write(text[i]);

      if (position > 1 && position % 3 == 1) {
        buffer.write(',');
      }
    }

    return _toPersianDigits(buffer.toString());
  }

  void _formatController(TextEditingController controller) {
    final value = _parseNumber(controller.text);

    if (value == null) {
      return;
    }

    final formatted = _formatNumber(value);

    if (controller.text == formatted) {
      return;
    }

    controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
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

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _baseSalaryController.dispose();

    _overtimeHoursController.dispose();

    _overtimeAmountController.dispose();

    _bonusController.dispose();

    _allowanceController.dispose();

    _employeeInsuranceController.dispose();

    _employerInsuranceController.dispose();

    _taxController.dispose();

    _absenceController.dispose();

    _otherDeductionsController.dispose();

    _advanceController.dispose();

    _notesController.dispose();

    super.dispose();
  }
}
