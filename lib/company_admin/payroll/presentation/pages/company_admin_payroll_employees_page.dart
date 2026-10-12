import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/company_admin/dashboard/presentation/widgets/company_admin_scaffold.dart';
import 'package:tarazyar/company_admin/payroll/application/company_admin_payroll_employees_provider.dart';

class CompanyAdminPayrollEmployeesPage extends ConsumerStatefulWidget {
  const CompanyAdminPayrollEmployeesPage({super.key});

  @override
  ConsumerState<CompanyAdminPayrollEmployeesPage> createState() =>
      _CompanyAdminPayrollEmployeesPageState();
}

class _CompanyAdminPayrollEmployeesPageState
    extends ConsumerState<CompanyAdminPayrollEmployeesPage> {
  final TextEditingController _searchController = TextEditingController();

  String _statusFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CompanyAdminPayrollEmployee> _filterEmployees(
    List<CompanyAdminPayrollEmployee> employees,
  ) {
    final search = _searchController.text.trim().toLowerCase();

    return employees.where((employee) {
      final matchesStatus =
          _statusFilter == 'all' || employee.status == _statusFilter;

      if (!matchesStatus) return false;
      if (search.isEmpty) return true;

      final values = [
        employee.personnelCode,
        employee.firstName,
        employee.lastName,
        employee.fullName,
        employee.nationalId ?? '',
        employee.mobile ?? '',
        employee.jobTitle ?? '',
        employee.department ?? '',
        employee.employmentType ?? '',
      ];

      return values.any((value) => value.toLowerCase().contains(search));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(companyAdminPayrollEmployeesProvider);

    return CompanyAdminScaffold(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xfff6f7f9),
          appBar: AppBar(
            title: const Text('کارکنان'),
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            actions: [
              IconButton(
                tooltip: 'بارگذاری مجدد',
                onPressed: () {
                  ref.invalidate(companyAdminPayrollEmployeesProvider);
                },
                icon: const Icon(Icons.refresh),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: state.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) {
              return _ErrorView(
                message: error.toString(),
                onRetry: () {
                  ref.invalidate(companyAdminPayrollEmployeesProvider);
                },
              );
            },
            data: (data) {
              final employees = _filterEmployees(data.employees);

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(companyAdminPayrollEmployeesProvider);
                  await ref.read(companyAdminPayrollEmployeesProvider.future);
                },
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildSummary(data),
                    const SizedBox(height: 20),
                    _buildFilters(data),
                    const SizedBox(height: 20),
                    if (employees.isEmpty)
                      _EmptyEmployeesView(
                        hasFilter:
                            _searchController.text.isNotEmpty ||
                            _statusFilter != 'all',
                        onCreate: () => _openEmployeeDialog(),
                      )
                    else
                      ...employees.map(
                        (employee) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _EmployeeCard(
                            employee: employee,
                            onDetails: () => _showDetails(employee),
                            onEdit:
                                () => _openEmployeeDialog(employee: employee),
                            onDelete: () => _deleteEmployee(employee),
                            onToggleStatus: () => _toggleStatus(employee),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'مدیریت کارکنان',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'ثبت، ویرایش و کنترل اطلاعات کارکنان شرکت',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: () => _openEmployeeDialog(),
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('کارمند جدید'),
        ),
      ],
    );
  }

  Widget _buildSummary(CompanyAdminPayrollEmployeesData data) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _SummaryCard(
          title: 'کل کارکنان',
          value: data.totalCount.toString(),
          icon: Icons.groups,
        ),
        _SummaryCard(
          title: 'فعال',
          value: data.activeCount.toString(),
          icon: Icons.check_circle_outline,
        ),
        _SummaryCard(
          title: 'غیرفعال',
          value: data.inactiveCount.toString(),
          icon: Icons.pause_circle_outline,
        ),
        _SummaryCard(
          title: 'خاتمه همکاری',
          value: data.terminatedCount.toString(),
          icon: Icons.person_off_outlined,
        ),
        _SummaryCard(
          title: 'تعلیق',
          value: data.suspendedCount.toString(),
          icon: Icons.block_outlined,
        ),
      ],
    );
  }

  Widget _buildFilters(CompanyAdminPayrollEmployeesData data) {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 360,
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'جستجو بر اساس نام، کد پرسنلی، کد ملی، سمت...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      _searchController.text.isEmpty
                          ? null
                          : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.clear),
                          ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String>(
                value: _statusFilter,
                decoration: InputDecoration(
                  labelText: 'وضعیت',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('همه')),
                  DropdownMenuItem(value: 'active', child: Text('فعال')),
                  DropdownMenuItem(value: 'inactive', child: Text('غیرفعال')),
                  DropdownMenuItem(
                    value: 'terminated',
                    child: Text('خاتمه همکاری'),
                  ),
                  DropdownMenuItem(value: 'suspended', child: Text('تعلیق')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _statusFilter = value);
                },
              ),
            ),
            Text(
              'نمایش: ${_filterEmployees(data.employees).length} نفر',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEmployeeDialog({
    CompanyAdminPayrollEmployee? employee,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => _EmployeeFormDialog(
            employee: employee,
            onSave: ({
              required String personnelCode,
              required String firstName,
              required String lastName,
              String? nationalId,
              String? mobile,
              String? jobTitle,
              String? department,
              String? employmentType,
              DateTime? hireDate,
              DateTime? terminationDate,
              required String status,
            }) async {
              final repository = CompanyAdminPayrollEmployeesRepository(
                Supabase.instance.client,
              );

              if (employee == null) {
                await repository.createEmployee(
                  personnelCode: personnelCode,
                  firstName: firstName,
                  lastName: lastName,
                  nationalId: nationalId,
                  mobile: mobile,
                  jobTitle: jobTitle,
                  department: department,
                  employmentType: employmentType,
                  hireDate: hireDate,
                  terminationDate: terminationDate,
                  status: status,
                );
              } else {
                await repository.updateEmployee(
                  employeeId: employee.id,
                  personnelCode: personnelCode,
                  firstName: firstName,
                  lastName: lastName,
                  nationalId: nationalId,
                  mobile: mobile,
                  jobTitle: jobTitle,
                  department: department,
                  employmentType: employmentType,
                  hireDate: hireDate,
                  terminationDate: terminationDate,
                  status: status,
                );
              }
            },
          ),
    );

    if (result == true && mounted) {
      ref.invalidate(companyAdminPayrollEmployeesProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            employee == null
                ? 'کارمند با موفقیت ثبت شد.'
                : 'اطلاعات کارمند با موفقیت ویرایش شد.',
          ),
        ),
      );
    }
  }

  Future<void> _deleteEmployee(CompanyAdminPayrollEmployee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('حذف کارمند'),
          content: Text(
            'آیا از حذف «${employee.fullName}» اطمینان دارید؟\n\n'
            'اگر برای این کارمند سوابق قرارداد یا حقوق وجود داشته باشد، '
            'دیتابیس اجازه حذف را نخواهد داد.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('انصراف'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final repository = CompanyAdminPayrollEmployeesRepository(
        Supabase.instance.client,
      );

      await repository.deleteEmployee(employee.id);

      if (!mounted) return;

      ref.invalidate(companyAdminPayrollEmployeesProvider);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('کارمند با موفقیت حذف شد.')));
    } on PostgrestException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حذف انجام نشد: ${error.message}')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حذف انجام نشد: $error')));
    }
  }

  Future<void> _toggleStatus(CompanyAdminPayrollEmployee employee) async {
    final nextStatus = employee.status == 'active' ? 'inactive' : 'active';

    try {
      final repository = CompanyAdminPayrollEmployeesRepository(
        Supabase.instance.client,
      );

      await repository.updateStatus(
        employeeId: employee.id,
        status: nextStatus,
      );

      if (!mounted) return;

      ref.invalidate(companyAdminPayrollEmployeesProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextStatus == 'active' ? 'کارمند فعال شد.' : 'کارمند غیرفعال شد.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تغییر وضعیت انجام نشد: $error')));
    }
  }

  void _showDetails(CompanyAdminPayrollEmployee employee) {
    showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(employee.fullName),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _DetailRow(title: 'کد پرسنلی', value: employee.personnelCode),
                  _DetailRow(title: 'نام', value: employee.firstName),
                  _DetailRow(title: 'نام خانوادگی', value: employee.lastName),
                  _DetailRow(title: 'کد ملی', value: employee.nationalId),
                  _DetailRow(title: 'موبایل', value: employee.mobile),
                  _DetailRow(title: 'سمت', value: employee.jobTitle),
                  _DetailRow(title: 'دپارتمان', value: employee.department),
                  _DetailRow(
                    title: 'نوع استخدام',
                    value: employee.employmentType,
                  ),
                  _DetailRow(
                    title: 'تاریخ استخدام',
                    value: _formatJalali(employee.hireDate),
                  ),
                  _DetailRow(
                    title: 'تاریخ خاتمه همکاری',
                    value: _formatJalali(employee.terminationDate),
                  ),
                  _DetailRow(
                    title: 'وضعیت',
                    value: _statusLabel(employee.status),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('بستن'),
            ),
          ],
        );
      },
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final CompanyAdminPayrollEmployee employee;
  final VoidCallback onDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const _EmployeeCard({
    required this.employee,
    required this.onDetails,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final active = employee.status == 'active';

    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: Text(
                employee.firstName.isNotEmpty
                    ? employee.firstName.substring(0, 1)
                    : '?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Wrap(
                spacing: 30,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: 170,
                    child: _InfoText(title: 'کارمند', value: employee.fullName),
                  ),
                  SizedBox(
                    width: 120,
                    child: _InfoText(
                      title: 'کد پرسنلی',
                      value: employee.personnelCode,
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: _InfoText(title: 'سمت', value: employee.jobTitle),
                  ),
                  SizedBox(
                    width: 140,
                    child: _InfoText(
                      title: 'دپارتمان',
                      value: employee.department,
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: _InfoText(
                      title: 'وضعیت',
                      value: _statusLabel(employee.status),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'details':
                    onDetails();
                    break;
                  case 'edit':
                    onEdit();
                    break;
                  case 'status':
                    onToggleStatus();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                }
              },
              itemBuilder:
                  (_) => [
                    const PopupMenuItem(
                      value: 'details',
                      child: Text('مشاهده جزئیات'),
                    ),
                    const PopupMenuItem(value: 'edit', child: Text('ویرایش')),
                    PopupMenuItem(
                      value: 'status',
                      child: Text(active ? 'غیرفعال کردن' : 'فعال کردن'),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'delete', child: Text('حذف')),
                  ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeFormDialog extends StatefulWidget {
  final CompanyAdminPayrollEmployee? employee;

  final Future<void> Function({
    required String personnelCode,
    required String firstName,
    required String lastName,
    String? nationalId,
    String? mobile,
    String? jobTitle,
    String? department,
    String? employmentType,
    DateTime? hireDate,
    DateTime? terminationDate,
    required String status,
  })
  onSave;

  const _EmployeeFormDialog({required this.employee, required this.onSave});

  @override
  State<_EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<_EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _personnelCode;
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _nationalId;
  late final TextEditingController _mobile;
  late final TextEditingController _jobTitle;
  late final TextEditingController _department;
  late final TextEditingController _employmentType;

  DateTime? _hireDate;
  DateTime? _terminationDate;

  String _status = 'active';
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final employee = widget.employee;

    _personnelCode = TextEditingController(text: employee?.personnelCode ?? '');
    _firstName = TextEditingController(text: employee?.firstName ?? '');
    _lastName = TextEditingController(text: employee?.lastName ?? '');
    _nationalId = TextEditingController(text: employee?.nationalId ?? '');
    _mobile = TextEditingController(text: employee?.mobile ?? '');
    _jobTitle = TextEditingController(text: employee?.jobTitle ?? '');
    _department = TextEditingController(text: employee?.department ?? '');
    _employmentType = TextEditingController(
      text: employee?.employmentType ?? '',
    );

    _hireDate = employee?.hireDate;
    _terminationDate = employee?.terminationDate;
    _status = employee?.status ?? 'active';
  }

  @override
  void dispose() {
    _personnelCode.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _nationalId.dispose();
    _mobile.dispose();
    _jobTitle.dispose();
    _department.dispose();
    _employmentType.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.employee != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(isEdit ? 'ویرایش کارمند' : 'ثبت کارمند جدید'),
        content: SizedBox(
          width: 720,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _field(
                    controller: _personnelCode,
                    label: 'کد پرسنلی',
                    requiredField: true,
                  ),
                  _field(
                    controller: _firstName,
                    label: 'نام',
                    requiredField: true,
                  ),
                  _field(
                    controller: _lastName,
                    label: 'نام خانوادگی',
                    requiredField: true,
                  ),
                  _field(controller: _nationalId, label: 'کد ملی'),
                  _field(controller: _mobile, label: 'موبایل'),
                  _field(controller: _jobTitle, label: 'سمت'),
                  _field(controller: _department, label: 'دپارتمان'),
                  _field(controller: _employmentType, label: 'نوع استخدام'),
                  const SizedBox(height: 4),

                  // انتخاب تاریخ شمسی استخدام
                  _dateField(
                    label: 'تاریخ استخدام',
                    value: _hireDate,
                    onTap: () async {
                      final date = await _pickDate(_hireDate);

                      if (date != null && mounted) {
                        setState(() => _hireDate = date);
                      }
                    },
                    onClear: () {
                      setState(() => _hireDate = null);
                    },
                  ),

                  const SizedBox(height: 12),

                  // انتخاب تاریخ شمسی خاتمه همکاری
                  _dateField(
                    label: 'تاریخ خاتمه همکاری',
                    value: _terminationDate,
                    onTap: () async {
                      final date = await _pickDate(_terminationDate);

                      if (date != null && mounted) {
                        setState(() => _terminationDate = date);
                      }
                    },
                    onClear: () {
                      setState(() => _terminationDate = null);
                    },
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: InputDecoration(
                      labelText: 'وضعیت',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('فعال')),
                      DropdownMenuItem(
                        value: 'inactive',
                        child: Text('غیرفعال'),
                      ),
                      DropdownMenuItem(
                        value: 'terminated',
                        child: Text('خاتمه همکاری'),
                      ),
                      DropdownMenuItem(
                        value: 'suspended',
                        child: Text('تعلیق'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _status = value);
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
            onPressed: _saving ? null : () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon:
                _saving
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.save),
            label: Text(_saving ? 'در حال ذخیره...' : 'ذخیره'),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    bool requiredField = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator:
            requiredField
                ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'این فیلد الزامی است.';
                  }
                  return null;
                }
                : null,
      ),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return TextFormField(
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        hintText: '۱۴۰۵/۰۱/۰۱',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.calendar_month),
        suffixIcon:
            value == null
                ? null
                : IconButton(
                  tooltip: 'پاک کردن تاریخ',
                  onPressed: onClear,
                  icon: const Icon(Icons.clear),
                ),
      ),
      controller: TextEditingController(text: _formatJalali(value)),
    );
  }

  /// تقویم انتخاب تاریخ کاملاً شمسی است.
  /// خروجی به DateTime تبدیل می‌شود تا با Provider فعلی سازگار بماند.
  Future<DateTime?> _pickDate(DateTime? initialDate) async {
    final initialJalali =
        initialDate == null ? Jalali.now() : Jalali.fromDateTime(initialDate);

    final selected = await showDialog<Jalali>(
      context: context,
      builder: (_) => _JalaliDatePickerDialog(initialDate: initialJalali),
    );

    return selected?.toDateTime();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await widget.onSave(
        personnelCode: _personnelCode.text.trim(),
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        nationalId: _nationalId.text.trim(),
        mobile: _mobile.text.trim(),
        jobTitle: _jobTitle.text.trim(),
        department: _department.text.trim(),
        employmentType: _employmentType.text.trim(),
        hireDate: _hireDate,
        terminationDate: _terminationDate,
        status: _status,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ذخیره اطلاعات انجام نشد: $error')),
      );
    }
  }
}

/// تقویم شمسی سفارشی؛ از showDatePicker میلادی استفاده نمی‌کند.
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

    // جای خالی روزهای قبل از شروع ماه
    for (var i = 0; i < firstWeekDay; i++) {
      cells.add(const SizedBox.shrink());
    }

    // روزهای ماه شمسی
    for (var day = 1; day <= monthLength; day++) {
      final date = Jalali(_displayedMonth.year, _displayedMonth.month, day);

      final isSelected =
          date.year == _selectedDate.year &&
          date.month == _selectedDate.month &&
          date.day == _selectedDate.day;

      cells.add(
        InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: () {
            setState(() => _selectedDate = date);
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$day',
              style: TextStyle(
                color:
                    isSelected ? Theme.of(context).colorScheme.onPrimary : null,
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
                    tooltip: 'ماه بعد',
                    onPressed: () => _changeMonth(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '${_displayedMonth.formatter.mN} '
                        '${_displayedMonth.year}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'ماه قبل',
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
            child: const Text('لغو'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, _selectedDate);
            },
            child: const Text('تأیید'),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Card(
        elevation: 0,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(child: Icon(icon)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoText extends StatelessWidget {
  final String title;
  final String? value;

  const _InfoText({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 3),
        Text(
          value == null || value!.trim().isEmpty ? '-' : value!,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String title;
  final String? value;

  const _DetailRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 170,
            child: Text(title, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              value == null || value!.trim().isEmpty ? '-' : value!,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyEmployeesView extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onCreate;

  const _EmptyEmployeesView({required this.hasFilter, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(50),
        child: Column(
          children: [
            const Icon(Icons.groups_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              hasFilter
                  ? 'کارمندی با این فیلتر پیدا نشد.'
                  : 'هنوز کارمندی ثبت نشده است.',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            if (!hasFilter) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.person_add),
                label: const Text('ثبت اولین کارمند'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 52),
            const SizedBox(height: 16),
            const Text(
              'خطا در دریافت اطلاعات کارکنان',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatJalali(DateTime? date) {
  if (date == null) return '-';

  final jalali = Jalali.fromDateTime(date);

  return '${jalali.year}/'
      '${jalali.month.toString().padLeft(2, '0')}/'
      '${jalali.day.toString().padLeft(2, '0')}';
}

String _statusLabel(String status) {
  switch (status) {
    case 'active':
      return 'فعال';
    case 'inactive':
      return 'غیرفعال';
    case 'terminated':
      return 'خاتمه همکاری';
    case 'suspended':
      return 'تعلیق';
    default:
      return status;
  }
}
