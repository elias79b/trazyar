import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/payroll_cost_center_record_model.dart';
import '../../data/payroll_cost_center_record_provider.dart';

class PayrollCostCenterRecordFormDialog extends ConsumerStatefulWidget {
  const PayrollCostCenterRecordFormDialog({
    super.key,
    required this.companyId,
    required this.payrollPeriodId,
    this.record,
  });

  final String companyId;
  final String payrollPeriodId;
  final PayrollCostCenterRecordModel? record;

  bool get isEdit => record != null;

  @override
  ConsumerState<PayrollCostCenterRecordFormDialog> createState() =>
      _PayrollCostCenterRecordFormDialogState();
}

class _PayrollCostCenterRecordFormDialogState
    extends ConsumerState<PayrollCostCenterRecordFormDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _costCenterId;

  late final TextEditingController _employeeCount;

  late final TextEditingController _baseSalary;

  late final TextEditingController _senioritySalary;

  late final TextEditingController _mealAllowance;

  late final TextEditingController _housingAllowance;

  late final TextEditingController _maritalAllowance;

  late final TextEditingController _overtimeAmount;

  late final TextEditingController _missionAllowance;

  late final TextEditingController _performanceBonus;

  late final TextEditingController _productionIncreaseBonus;

  late final TextEditingController _monthlySeniorityBenefit;

  late final TextEditingController _monthlyEndServiceBonus;

  late final TextEditingController _missionTravelCost;

  late final TextEditingController _employerInsurance;

  late final TextEditingController _unemploymentInsurance;

  bool _saving = false;

  late Future<List<Map<String, dynamic>>> _centersFuture;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    final record = widget.record;

    _costCenterId = record?.costCenterId;

    _employeeCount = _controller(record?.employeeCount);

    _baseSalary = _controller(record?.baseSalary);

    _senioritySalary = _controller(record?.senioritySalary);

    _mealAllowance = _controller(record?.mealAllowance);

    _housingAllowance = _controller(record?.housingAllowance);

    _maritalAllowance = _controller(record?.maritalAllowance);

    _overtimeAmount = _controller(record?.overtimeAmount);

    _missionAllowance = _controller(record?.missionAllowance);

    _performanceBonus = _controller(record?.performanceBonus);

    _productionIncreaseBonus = _controller(record?.productionIncreaseBonus);

    _monthlySeniorityBenefit = _controller(record?.monthlySeniorityBenefit);

    _monthlyEndServiceBonus = _controller(record?.monthlyEndServiceBonus);

    _missionTravelCost = _controller(record?.missionTravelCost);

    _employerInsurance = _controller(record?.employerInsurance);

    _unemploymentInsurance = _controller(record?.unemploymentInsurance);

    _centersFuture = _loadAvailableCostCenters();
  }

  // ============================================================
  // LOAD AVAILABLE COST CENTERS
  // ============================================================

  Future<List<Map<String, dynamic>>> _loadAvailableCostCenters() async {
    final client = Supabase.instance.client;

    // تمام مراکز فعال شرکت
    final centersResponse = await client
        .from('cost_centers')
        .select('id, name, code, is_active')
        .eq('company_id', widget.companyId)
        .eq('is_active', true)
        .order('name', ascending: true);

    final centers =
        (centersResponse as List)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

    // رکوردهای ثبت شده همین دوره
    final repository = ref.read(payrollCostCenterRecordRepositoryProvider);

    final existingRecords = await repository.getByPeriod(
      widget.payrollPeriodId,
    );

    final usedCenterIds =
        existingRecords.map((record) => record.costCenterId).toSet();

    // در حالت ویرایش، مرکز فعلی حذف نشود
    if (widget.record != null) {
      usedCenterIds.remove(widget.record!.costCenterId);
    }

    return centers.where((center) {
      final id = center['id']?.toString() ?? '';

      return !usedCenterIds.contains(id);
    }).toList();
  }

  // ============================================================
  // CONTROLLER
  // ============================================================

  TextEditingController _controller(dynamic value) {
    if (value == null) {
      return TextEditingController(text: '0');
    }

    if (value is num) {
      return TextEditingController(text: value.toDouble().round().toString());
    }

    return TextEditingController(text: value.toString());
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _employeeCount.dispose();
    _baseSalary.dispose();
    _senioritySalary.dispose();
    _mealAllowance.dispose();
    _housingAllowance.dispose();
    _maritalAllowance.dispose();
    _overtimeAmount.dispose();
    _missionAllowance.dispose();
    _performanceBonus.dispose();
    _productionIncreaseBonus.dispose();
    _monthlySeniorityBenefit.dispose();
    _monthlyEndServiceBonus.dispose();
    _missionTravelCost.dispose();
    _employerInsurance.dispose();
    _unemploymentInsurance.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(
          widget.isEdit ? 'ویرایش حقوق مرکز هزینه' : 'ثبت حقوق مرکز هزینه',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        content: SizedBox(
          width: 760,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // ==================================================
                  // COST CENTER
                  // ==================================================
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _centersFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            'خطا در دریافت مراکز هزینه:\n'
                            '${snapshot.error}',
                          ),
                        );
                      }

                      final centers =
                          snapshot.data ?? const <Map<String, dynamic>>[];

                      if (centers.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: Colors.orange.shade800,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  widget.isEdit
                                      ? 'مرکز هزینه فعال دیگری برای انتخاب وجود ندارد.'
                                      : 'تمام مراکز هزینه فعال این دوره قبلاً ثبت شده‌اند.',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return DropdownButtonFormField<String>(
                        value:
                            centers.any(
                                  (center) =>
                                      center['id'].toString() == _costCenterId,
                                )
                                ? _costCenterId
                                : null,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'مرکز هزینه *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.account_tree_rounded),
                        ),
                        items:
                            centers.map((center) {
                              final id = center['id'].toString();

                              final name = center['name']?.toString() ?? '';

                              final code = center['code']?.toString();

                              return DropdownMenuItem<String>(
                                value: id,
                                child: Text(
                                  code == null || code.isEmpty
                                      ? name
                                      : '$code - $name',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                        onChanged:
                            _saving
                                ? null
                                : (value) {
                                  setState(() {
                                    _costCenterId = value;
                                  });
                                },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'مرکز هزینه را انتخاب کنید.';
                          }

                          return null;
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // ==================================================
                  // EMPLOYEE COUNT
                  // ==================================================
                  _numberField(_employeeCount, 'تعداد پرسنل'),

                  // ==================================================
                  // GENERAL
                  // ==================================================
                  _section('اطلاعات عمومی', [
                    _moneyField(_baseSalary, 'حقوق پایه'),
                    _moneyField(_senioritySalary, 'پایه سنوات'),
                    _moneyField(_mealAllowance, 'حق بن'),
                    _moneyField(_housingAllowance, 'حق مسکن'),
                    _moneyField(_maritalAllowance, 'حق تأهل'),
                    _moneyField(_overtimeAmount, 'اضافه‌کاری'),
                    _moneyField(_missionAllowance, 'فوق‌العاده مأموریت'),
                    _moneyField(_performanceBonus, 'پاداش عملکرد'),
                    _moneyField(_productionIncreaseBonus, 'افزایش تولید'),
                  ]),

                  // ==================================================
                  // PERSONNEL COSTS
                  // ==================================================
                  _section('هزینه‌های پرسنلی', [
                    _moneyField(_monthlySeniorityBenefit, 'حق سنوات ماهانه'),
                    _moneyField(
                      _monthlyEndServiceBonus,
                      'پاداش پایان خدمت ماهانه',
                    ),
                    _moneyField(_missionTravelCost, 'هزینه مأموریت و سفر'),
                  ]),

                  // ==================================================
                  // EMPLOYER
                  // ==================================================
                  _section('بیمه و تعهدات کارفرما', [
                    _moneyField(_employerInsurance, 'بیمه سهم کارفرما'),
                    _moneyField(_unemploymentInsurance, 'بیمه بیکاری'),
                  ]),
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
            label: Text(widget.isEdit ? 'ذخیره تغییرات' : 'ثبت حقوق'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION
  // ============================================================

  Widget _section(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1B4332).withOpacity(.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),

          const SizedBox(height: 10),

          ...children,
        ],
      ),
    );
  }

  // ============================================================
  // NUMBER FIELD
  // ============================================================

  Widget _numberField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: !_saving,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          final number = _parse(value ?? '');

          if (number == null || number < 0) {
            return 'مقدار معتبر وارد کنید.';
          }

          if (number != number.truncateToDouble()) {
            return 'تعداد باید عدد صحیح باشد.';
          }

          return null;
        },
      ),
    );
  }

  // ============================================================
  // MONEY FIELD
  // ============================================================

  Widget _moneyField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: !_saving,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          suffixText: 'ریال',
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          final number = _parse(value ?? '');

          if (number == null || number < 0) {
            return 'مقدار معتبر وارد کنید.';
          }

          return null;
        },
      ),
    );
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_costCenterId == null || _costCenterId!.isEmpty) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final repository = ref.read(payrollCostCenterRecordRepositoryProvider);

      final employeeCount = _parse(_employeeCount.text)?.toInt() ?? 0;

      final baseSalary = _parse(_baseSalary.text) ?? 0;

      final senioritySalary = _parse(_senioritySalary.text) ?? 0;

      final mealAllowance = _parse(_mealAllowance.text) ?? 0;

      final housingAllowance = _parse(_housingAllowance.text) ?? 0;

      final maritalAllowance = _parse(_maritalAllowance.text) ?? 0;

      final overtimeAmount = _parse(_overtimeAmount.text) ?? 0;

      final missionAllowance = _parse(_missionAllowance.text) ?? 0;

      final performanceBonus = _parse(_performanceBonus.text) ?? 0;

      final productionIncreaseBonus =
          _parse(_productionIncreaseBonus.text) ?? 0;

      final monthlySeniorityBenefit =
          _parse(_monthlySeniorityBenefit.text) ?? 0;

      final monthlyEndServiceBonus = _parse(_monthlyEndServiceBonus.text) ?? 0;

      final missionTravelCost = _parse(_missionTravelCost.text) ?? 0;

      final employerInsurance = _parse(_employerInsurance.text) ?? 0;

      final unemploymentInsurance = _parse(_unemploymentInsurance.text) ?? 0;

      // ==========================================================
      // EDIT
      // ==========================================================

      if (widget.isEdit) {
        await repository.update(
          id: widget.record!.id,
          costCenterId: _costCenterId!,
          employeeCount: employeeCount,
          baseSalary: baseSalary,
          senioritySalary: senioritySalary,
          mealAllowance: mealAllowance,
          housingAllowance: housingAllowance,
          maritalAllowance: maritalAllowance,
          overtimeAmount: overtimeAmount,
          missionAllowance: missionAllowance,
          performanceBonus: performanceBonus,
          productionIncreaseBonus: productionIncreaseBonus,
          monthlySeniorityBenefit: monthlySeniorityBenefit,
          monthlyEndServiceBonus: monthlyEndServiceBonus,
          missionTravelCost: missionTravelCost,
          employerInsurance: employerInsurance,
          unemploymentInsurance: unemploymentInsurance,
        );
      }
      // ==========================================================
      // CREATE
      // ==========================================================
      else {
        await repository.create(
          companyId: widget.companyId,
          payrollPeriodId: widget.payrollPeriodId,
          costCenterId: _costCenterId!,
          employeeCount: employeeCount,
          baseSalary: baseSalary,
          senioritySalary: senioritySalary,
          mealAllowance: mealAllowance,
          housingAllowance: housingAllowance,
          maritalAllowance: maritalAllowance,
          overtimeAmount: overtimeAmount,
          missionAllowance: missionAllowance,
          performanceBonus: performanceBonus,
          productionIncreaseBonus: productionIncreaseBonus,
          monthlySeniorityBenefit: monthlySeniorityBenefit,
          monthlyEndServiceBonus: monthlyEndServiceBonus,
          missionTravelCost: missionTravelCost,
          employerInsurance: employerInsurance,
          unemploymentInsurance: unemploymentInsurance,
        );
      }

      ref.invalidate(payrollCostCenterRecordsProvider(widget.payrollPeriodId));

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(_friendlyError(error)),
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
  // PARSE
  // ============================================================

  double? _parse(String value) {
    var text = value.trim();

    const persian = '۰۱۲۳۴۵۶۷۸۹';

    const arabic = '٠١٢٣٤٥٦٧٨٩';

    const english = '0123456789';

    for (var i = 0; i < 10; i++) {
      text = text.replaceAll(persian[i], english[i]);

      text = text.replaceAll(arabic[i], english[i]);
    }

    text = text.replaceAll(',', '');

    text = text.replaceAll('٬', '');

    text = text.replaceAll(' ', '');

    return double.tryParse(text);
  }

  // ============================================================
  // ERROR
  // ============================================================

  String _friendlyError(Object error) {
    final text = error.toString();

    if (text.contains('payroll_cost_center_records_unique') ||
        text.contains('duplicate key') ||
        text.contains('23505')) {
      return 'برای این مرکز هزینه در این دوره حقوق قبلاً ثبت شده است.';
    }

    return text.replaceFirst('Exception: ', '');
  }
}
