import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tarazyar/company_admin/dashboard/presentation/widgets/company_admin_scaffold.dart';

class CompanyAdminEmploymentContractsPage extends StatefulWidget {
  const CompanyAdminEmploymentContractsPage({super.key});

  @override
  State<CompanyAdminEmploymentContractsPage> createState() =>
      _CompanyAdminEmploymentContractsPageState();
}

class _CompanyAdminEmploymentContractsPageState
    extends State<CompanyAdminEmploymentContractsPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loading = true;
  bool _saving = false;

  String? _companyId;

  List<Map<String, dynamic>> _contracts = [];
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _costCenters = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _str(dynamic value) => value?.toString() ?? '';

  String _employeeName(Map<String, dynamic> employee) {
    final name =
        '${_str(employee['first_name'])} ${_str(employee['last_name'])}'.trim();

    if (name.isNotEmpty) return name;

    final code = _str(employee['personnel_code']);
    return code.isNotEmpty ? code : 'کارمند بدون نام';
  }

  String _formatJalali(dynamic value) {
    if (value == null || value.toString().isEmpty) return '—';

    try {
      final date = DateTime.parse(value.toString());
      final jalali = Jalali.fromDateTime(date);

      return '${jalali.year}/'
          '${jalali.month.toString().padLeft(2, '0')}/'
          '${jalali.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return '—';
    }
  }

  void _message(String text, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _loading = true);

    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        throw Exception('ابتدا وارد حساب کاربری شوید.');
      }

      final membership =
          await _supabase
              .from('company_users')
              .select('company_id')
              .eq('user_id', user.id)
              .eq('role', 'company_admin')
              .eq('is_active', true)
              .limit(1)
              .maybeSingle();

      if (membership == null) {
        throw Exception('شرکت فعالی برای مدیر پیدا نشد.');
      }

      final companyId = _str(membership['company_id']);

      final results = await Future.wait([
        _supabase
            .from('employment_contracts')
            .select()
            .eq('company_id', companyId)
            .order('created_at', ascending: false),
        _supabase
            .from('employees')
            .select(
              'id, company_id, personnel_code, first_name, last_name, status',
            )
            .eq('company_id', companyId)
            .order('first_name'),
        _supabase
            .from('cost_centers')
            .select('id, company_id, name, code, is_active')
            .eq('company_id', companyId)
            .eq('is_active', true)
            .order('name'),
      ]);

      if (!mounted) return;

      setState(() {
        _companyId = companyId;
        _contracts = List<Map<String, dynamic>>.from(results[0]);
        _employees = List<Map<String, dynamic>>.from(results[1]);
        _costCenters = List<Map<String, dynamic>>.from(results[2]);
      });
    } catch (e) {
      _message('خطا در دریافت اطلاعات: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Jalali? _parseJalali(String value) {
    final normalized = value.trim().replaceAll('-', '/');
    if (normalized.isEmpty) return null;

    final parts = normalized.split('/');
    if (parts.length != 3) return null;

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);

    if (year == null || month == null || day == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;

    try {
      final date = Jalali(year, month, day);
      final converted = Jalali.fromDateTime(date.toDateTime());

      if (converted.year != year ||
          converted.month != month ||
          converted.day != day) {
        return null;
      }

      return date;
    } catch (_) {
      return null;
    }
  }

  String _toIsoDate(Jalali date) {
    final gregorian = date.toDateTime();

    return '${gregorian.year.toString().padLeft(4, '0')}-'
        '${gregorian.month.toString().padLeft(2, '0')}-'
        '${gregorian.day.toString().padLeft(2, '0')}';
  }

  Future<String?> _pickDate(String currentValue) {
    return showDialog<String>(
      context: context,
      builder:
          (_) => _JalaliDatePickerDialog(
            initialDate: _parseJalali(currentValue) ?? Jalali.now(),
          ),
    );
  }

  Future<void> _openForm({Map<String, dynamic>? contract}) async {
    if (_companyId == null) {
      _message('اطلاعات شرکت در دسترس نیست.', error: true);
      return;
    }

    final formKey = GlobalKey<FormState>();

    final numberController = TextEditingController(
      text: _str(contract?['contract_number']),
    );
    final salaryController = TextEditingController(
      text: _str(contract?['base_salary'] ?? '0'),
    );
    final hoursController = TextEditingController(
      text: _str(contract?['working_hours']),
    );
    final startController = TextEditingController(
      text:
          contract?['start_date'] == null
              ? ''
              : _formatJalali(contract?['start_date']),
    );
    final endController = TextEditingController(
      text:
          contract?['end_date'] == null
              ? ''
              : _formatJalali(contract?['end_date']),
    );

    String? employeeId =
        _str(contract?['employee_id']).isEmpty
            ? null
            : _str(contract?['employee_id']);

    String? costCenterId =
        _str(contract?['cost_center_id']).isEmpty
            ? null
            : _str(contract?['cost_center_id']);

    String contractType =
        _str(contract?['contract_type']).isEmpty
            ? 'permanent'
            : _str(contract?['contract_type']);

    String insuranceStatus =
        _str(contract?['insurance_status']).isEmpty
            ? 'insured'
            : _str(contract?['insurance_status']);

    String taxStatus =
        _str(contract?['tax_status']).isEmpty
            ? 'taxable'
            : _str(contract?['tax_status']);

    String status =
        _str(contract?['status']).isEmpty
            ? 'active'
            : _str(contract?['status']);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: Text(
                  contract == null
                      ? 'ثبت قرارداد استخدام'
                      : 'ویرایش قرارداد استخدام',
                ),
                content: SizedBox(
                  width: 500,
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonFormField<String>(
                            value:
                                _employees.any(
                                      (e) => _str(e['id']) == employeeId,
                                    )
                                    ? employeeId
                                    : null,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'کارمند',
                              border: OutlineInputBorder(),
                            ),
                            items:
                                _employees.map((employee) {
                                  return DropdownMenuItem<String>(
                                    value: _str(employee['id']),
                                    child: Text(_employeeName(employee)),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setDialogState(() => employeeId = value);
                            },
                            validator:
                                (value) =>
                                    value == null
                                        ? 'کارمند را انتخاب کنید.'
                                        : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value:
                                _costCenters.any(
                                      (e) => _str(e['id']) == costCenterId,
                                    )
                                    ? costCenterId
                                    : null,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'مرکز هزینه',
                              border: OutlineInputBorder(),
                            ),
                            items:
                                _costCenters.map((center) {
                                  final name = _str(center['name']);
                                  final code = _str(center['code']);

                                  return DropdownMenuItem<String>(
                                    value: _str(center['id']),
                                    child: Text(
                                      code.isEmpty ? name : '$name ($code)',
                                    ),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setDialogState(() => costCenterId = value);
                            },
                            validator:
                                (value) =>
                                    value == null
                                        ? 'مرکز هزینه را انتخاب کنید.'
                                        : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: numberController,
                            decoration: const InputDecoration(
                              labelText: 'شماره قرارداد',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: contractType,
                            decoration: const InputDecoration(
                              labelText: 'نوع قرارداد',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'permanent',
                                child: Text('دائم'),
                              ),
                              DropdownMenuItem(
                                value: 'temporary',
                                child: Text('موقت'),
                              ),
                              DropdownMenuItem(
                                value: 'project',
                                child: Text('پروژه‌ای'),
                              ),
                              DropdownMenuItem(
                                value: 'probation',
                                child: Text('آزمایشی'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() => contractType = value);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          _dateField(
                            controller: startController,
                            label: 'تاریخ شروع (شمسی)',
                            onPick: () async {
                              final value = await _pickDate(
                                startController.text,
                              );
                              if (value != null) startController.text = value;
                            },
                          ),
                          const SizedBox(height: 12),
                          _dateField(
                            controller: endController,
                            label: 'تاریخ پایان (شمسی)',
                            onPick: () async {
                              final value = await _pickDate(endController.text);
                              if (value != null) endController.text = value;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: salaryController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'حقوق پایه',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final salary = num.tryParse(
                                (value ?? '').replaceAll(',', '').trim(),
                              );

                              if (salary == null || salary < 0) {
                                return 'حقوق پایه معتبر وارد کنید.';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: hoursController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'ساعات کاری (اختیاری)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return null;
                              }

                              final hours = num.tryParse(value.trim());
                              if (hours == null || hours < 0) {
                                return 'ساعات کاری معتبر وارد کنید.';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: insuranceStatus,
                            decoration: const InputDecoration(
                              labelText: 'وضعیت بیمه',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'insured',
                                child: Text('دارای بیمه'),
                              ),
                              DropdownMenuItem(
                                value: 'not_insured',
                                child: Text('بدون بیمه'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() => insuranceStatus = value);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: taxStatus,
                            decoration: const InputDecoration(
                              labelText: 'وضعیت مالیات',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'taxable',
                                child: Text('مشمول مالیات'),
                              ),
                              DropdownMenuItem(
                                value: 'not_taxable',
                                child: Text('غیرمشمول مالیات'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() => taxStatus = value);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: status,
                            decoration: const InputDecoration(
                              labelText: 'وضعیت قرارداد',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'active',
                                child: Text('فعال'),
                              ),
                              DropdownMenuItem(
                                value: 'inactive',
                                child: Text('غیرفعال'),
                              ),
                              DropdownMenuItem(
                                value: 'terminated',
                                child: Text('خاتمه‌یافته'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() => status = value);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('انصراف'),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;

                      final start = _parseJalali(startController.text);
                      final end = _parseJalali(endController.text);

                      if (startController.text.trim().isNotEmpty &&
                          start == null) {
                        _message('تاریخ شروع معتبر نیست.', error: true);
                        return;
                      }

                      if (endController.text.trim().isNotEmpty && end == null) {
                        _message('تاریخ پایان معتبر نیست.', error: true);
                        return;
                      }

                      // Jalali متد isBefore ندارد؛ تاریخ‌ها را به DateTime
                      // تبدیل می‌کنیم و سپس مقایسه انجام می‌دهیم.
                      if (start != null &&
                          end != null &&
                          end.toDateTime().isBefore(start.toDateTime())) {
                        _message(
                          'تاریخ پایان نمی‌تواند قبل از تاریخ شروع باشد.',
                          error: true,
                        );
                        return;
                      }

                      Navigator.pop(dialogContext, true);
                    },
                    child: const Text('ذخیره'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == true) {
      await _saveContract(
        contract: contract,
        employeeId: employeeId,
        costCenterId: costCenterId,
        contractType: contractType,
        insuranceStatus: insuranceStatus,
        taxStatus: taxStatus,
        status: status,
        number: numberController.text.trim(),
        salary: salaryController.text.trim(),
        hours: hoursController.text.trim(),
        startDate: _parseJalali(startController.text),
        endDate: _parseJalali(endController.text),
      );
    }

    numberController.dispose();
    salaryController.dispose();
    hoursController.dispose();
    startController.dispose();
    endController.dispose();
  }

  Widget _dateField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onPick,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.datetime,
      decoration: InputDecoration(
        labelText: label,
        hintText: '1405/01/01',
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          tooltip: 'انتخاب تاریخ',
          onPressed: onPick,
          icon: const Icon(Icons.calendar_month),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return null;

        return _parseJalali(value) == null
            ? 'تاریخ شمسی را به شکل 1405/01/01 وارد کنید.'
            : null;
      },
    );
  }

  Future<void> _saveContract({
    required Map<String, dynamic>? contract,
    required String? employeeId,
    required String? costCenterId,
    required String contractType,
    required String insuranceStatus,
    required String taxStatus,
    required String status,
    required String number,
    required String salary,
    required String hours,
    required Jalali? startDate,
    required Jalali? endDate,
  }) async {
    if (_companyId == null || employeeId == null || costCenterId == null) {
      _message('کارمند و مرکز هزینه را انتخاب کنید.', error: true);
      return;
    }

    setState(() => _saving = true);

    try {
      final payload = <String, dynamic>{
        'company_id': _companyId,
        'employee_id': employeeId,
        'cost_center_id': costCenterId,
        'contract_number': number.isEmpty ? null : number,
        'contract_type': contractType,
        'start_date': startDate == null ? null : _toIsoDate(startDate),
        'end_date': endDate == null ? null : _toIsoDate(endDate),
        'base_salary': num.parse(salary.replaceAll(',', '').trim()),
        'working_hours': hours.trim().isEmpty ? null : num.parse(hours.trim()),
        'insurance_status': insuranceStatus,
        'tax_status': taxStatus,
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (contract == null) {
        payload['created_by'] = _supabase.auth.currentUser?.id;

        await _supabase.from('employment_contracts').insert(payload);
        _message('قرارداد با موفقیت ثبت شد.');
      } else {
        await _supabase
            .from('employment_contracts')
            .update(payload)
            .eq('id', _str(contract['id']))
            .eq('company_id', _companyId!);

        _message('قرارداد با موفقیت ویرایش شد.');
      }

      await _loadData();
    } catch (e) {
      _message('خطا در ذخیره قرارداد: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteContract(Map<String, dynamic> contract) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('حذف قرارداد'),
              content: const Text('آیا از حذف این قرارداد اطمینان دارید؟'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('انصراف'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('حذف'),
                ),
              ],
            ),
          ),
    );

    if (confirmed != true || _companyId == null) return;

    try {
      await _supabase
          .from('employment_contracts')
          .delete()
          .eq('id', _str(contract['id']))
          .eq('company_id', _companyId!);

      _message('قرارداد حذف شد.');
      await _loadData();
    } catch (e) {
      _message('خطا در حذف قرارداد: $e', error: true);
    }
  }

  String _contractTypeLabel(dynamic value) {
    switch (_str(value)) {
      case 'permanent':
        return 'دائم';
      case 'temporary':
        return 'موقت';
      case 'project':
        return 'پروژه‌ای';
      case 'probation':
        return 'آزمایشی';
      default:
        return _str(value).isEmpty ? '—' : _str(value);
    }
  }

  String _insuranceLabel(dynamic value) {
    switch (_str(value)) {
      case 'insured':
        return 'دارای بیمه';
      case 'not_insured':
        return 'بدون بیمه';
      default:
        return _str(value).isEmpty ? '—' : _str(value);
    }
  }

  String _taxLabel(dynamic value) {
    switch (_str(value)) {
      case 'taxable':
        return 'مشمول مالیات';
      case 'not_taxable':
        return 'غیرمشمول مالیات';
      default:
        return _str(value).isEmpty ? '—' : _str(value);
    }
  }

  String _statusLabel(dynamic value) {
    switch (_str(value)) {
      case 'active':
        return 'فعال';
      case 'inactive':
        return 'غیرفعال';
      case 'terminated':
        return 'خاتمه‌یافته';
      default:
        return _str(value).isEmpty ? 'نامشخص' : _str(value);
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: Colors.grey.shade700)),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompanyAdminScaffold(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('قراردادهای استخدام'),
            actions: [
              IconButton(
                tooltip: 'بارگذاری مجدد',
                onPressed: _loading ? null : _loadData,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body:
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildBody(),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _saving ? null : () => _openForm(),
            icon: const Icon(Icons.add),
            label: const Text('قرارداد جدید'),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_contracts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 140),
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 16),
            const Center(child: Text('هنوز قراردادی ثبت نشده است.')),
            if (_employees.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: Text('ابتدا یک کارمند ثبت کنید.')),
              ),
            if (_costCenters.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(
                  child: Text('ابتدا یک مرکز هزینه فعال ایجاد کنید.'),
                ),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        itemCount: _contracts.length,
        itemBuilder: (context, index) {
          final contract = _contracts[index];

          Map<String, dynamic>? findById(
            List<Map<String, dynamic>> list,
            dynamic id,
          ) {
            for (final item in list) {
              if (_str(item['id']) == _str(id)) return item;
            }
            return null;
          }

          final employee = findById(_employees, contract['employee_id']);
          final center = findById(_costCenters, contract['cost_center_id']);

          final employeeName =
              employee == null ? 'کارمند حذف‌شده' : _employeeName(employee);
          final centerName =
              center == null ? 'مرکز هزینه نامشخص' : _str(center['name']);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        child: Icon(Icons.description_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employeeName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _str(contract['contract_number']).isEmpty
                                  ? 'بدون شماره قرارداد'
                                  : 'شماره قرارداد: ${_str(contract['contract_number'])}',
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _openForm(contract: contract);
                          } else if (value == 'delete') {
                            _deleteContract(contract);
                          }
                        },
                        itemBuilder:
                            (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('ویرایش'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('حذف'),
                              ),
                            ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _infoRow('مرکز هزینه', centerName),
                  _infoRow(
                    'نوع قرارداد',
                    _contractTypeLabel(contract['contract_type']),
                  ),
                  _infoRow('تاریخ شروع', _formatJalali(contract['start_date'])),
                  _infoRow('تاریخ پایان', _formatJalali(contract['end_date'])),
                  _infoRow('حقوق پایه', _str(contract['base_salary'])),
                  _infoRow(
                    'وضعیت بیمه',
                    _insuranceLabel(contract['insurance_status']),
                  ),
                  _infoRow('وضعیت مالیات', _taxLabel(contract['tax_status'])),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(label: Text(_statusLabel(contract['status']))),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _JalaliDatePickerDialog extends StatefulWidget {
  const _JalaliDatePickerDialog({required this.initialDate});

  final Jalali initialDate;

  @override
  State<_JalaliDatePickerDialog> createState() =>
      _JalaliDatePickerDialogState();
}

class _JalaliDatePickerDialogState extends State<_JalaliDatePickerDialog> {
  late Jalali _selectedDate;
  late Jalali _displayedMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayedMonth = Jalali(
      widget.initialDate.year,
      widget.initialDate.month,
      1,
    );
  }

  String _format(Jalali date) {
    return '${date.year}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}';
  }

  void _changeMonth(int amount) {
    setState(() {
      _displayedMonth = _displayedMonth.addMonths(amount);
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthLength = _displayedMonth.monthLength;
    final firstWeekDay = _displayedMonth.weekDay % 7;
    final cells = <Widget>[];

    const weekdays = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];

    for (final weekday in weekdays) {
      cells.add(
        Center(
          child: Text(
            weekday,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    for (var i = 0; i < firstWeekDay; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (var day = 1; day <= monthLength; day++) {
      final date = Jalali(_displayedMonth.year, _displayedMonth.month, day);

      final selected =
          date.year == _selectedDate.year &&
          date.month == _selectedDate.month &&
          date.day == _selectedDate.day;

      cells.add(
        InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () => setState(() => _selectedDate = date),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? Theme.of(context).colorScheme.primary : null,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$day',
              style: TextStyle(
                color:
                    selected ? Theme.of(context).colorScheme.onPrimary : null,
              ),
            ),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('انتخاب تاریخ شمسی'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => _changeMonth(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '${_displayedMonth.formatter.mN} ${_displayedMonth.year}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _changeMonth(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 4,
                children: cells,
              ),
              const SizedBox(height: 12),
              Text('تاریخ انتخاب‌شده: ${_format(_selectedDate)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _format(_selectedDate)),
            child: const Text('انتخاب'),
          ),
        ],
      ),
    );
  }
}
