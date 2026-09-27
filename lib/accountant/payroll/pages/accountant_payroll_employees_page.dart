import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarazyar/accountant/payroll/application/accountant_payroll_employees_provider.dart';
import 'package:tarazyar/accountant/dashboard/presentation/widgets/accountant_scaffold.dart';

class AccountantPayrollEmployeesPage extends ConsumerStatefulWidget {
  final String companyId;

  const AccountantPayrollEmployeesPage({super.key, required this.companyId});

  @override
  ConsumerState<AccountantPayrollEmployeesPage> createState() =>
      _AccountantPayrollEmployeesPageState();
}

class _AccountantPayrollEmployeesPageState
    extends ConsumerState<AccountantPayrollEmployeesPage> {
  String _search = '';
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      accountantPayrollEmployeesProvider(widget.companyId),
    );

    return AccountantScaffold(
      currentRoute: '/accountant/payroll/employees',
      title: 'کارکنان',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) {
            return _ErrorView(
              error: error,
              onRetry: () {
                ref.invalidate(
                  accountantPayrollEmployeesProvider(widget.companyId),
                );
              },
            );
          },
          data: (employees) {
            return _buildContent(context, employees);
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<AccountantPayrollEmployee> employees,
  ) {
    final filtered =
        employees.where((employee) {
          final query = _search.trim().toLowerCase();

          final matchesSearch =
              query.isEmpty ||
              employee.fullName.toLowerCase().contains(query) ||
              employee.personnelCode.toLowerCase().contains(query) ||
              (employee.nationalId ?? '').toLowerCase().contains(query) ||
              (employee.mobile ?? '').toLowerCase().contains(query) ||
              (employee.department ?? '').toLowerCase().contains(query) ||
              (employee.jobTitle ?? '').toLowerCase().contains(query);

          final matchesStatus =
              _statusFilter == 'all' ||
              employee.status.trim().toLowerCase() == _statusFilter;

          return matchesSearch && matchesStatus;
        }).toList();

    final activeCount = employees.where((e) => e.isActive).length;
    final inactiveCount = employees.length - activeCount;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 850;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 14 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                total: employees.length,
                active: activeCount,
                inactive: inactiveCount,
                onAdd: () {
                  _openEmployeeDialog(context);
                },
              ),
              const SizedBox(height: 16),
              _FilterBar(
                search: _search,
                statusFilter: _statusFilter,
                onSearchChanged: (value) {
                  setState(() {
                    _search = value;
                  });
                },
                onStatusChanged: (value) {
                  setState(() {
                    _statusFilter = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                const _EmptyState()
              else if (isMobile)
                _MobileList(
                  employees: filtered,
                  onEdit: _openEmployeeDialog,
                  onDelete: _confirmDelete,
                )
              else
                _DesktopTable(
                  employees: filtered,
                  onEdit: _openEmployeeDialog,
                  onDelete: _confirmDelete,
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openEmployeeDialog(
    BuildContext context, [
    AccountantPayrollEmployee? employee,
  ]) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _EmployeeDialog(employee: employee, companyId: widget.companyId);
      },
    );

    if (result == true && mounted) {
      ref.invalidate(accountantPayrollEmployeesProvider(widget.companyId));
    }
  }

  Future<void> _confirmDelete(AccountantPayrollEmployee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('حذف کارمند'),
            content: Text('آیا از حذف «${employee.fullName}» اطمینان دارید؟'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text('انصراف'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('حذف'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await AccountantPayrollEmployeesRepository.delete(employee.id);

      ref.invalidate(accountantPayrollEmployeesProvider(widget.companyId));

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('کارمند با موفقیت حذف شد')));
    } catch (error) {
      if (!mounted) return;

      _showError(context, error);
    }
  }

  void _showError(BuildContext context, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade700,
        content: Text('خطا: $error', textDirection: TextDirection.rtl),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int total;
  final int active;
  final int inactive;
  final VoidCallback onAdd;

  const _Header({
    required this.total,
    required this.active,
    required this.inactive,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 700;

        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'مدیریت کارکنان',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text(
              '$total کارمند • $active فعال • $inactive غیرفعال',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        );

        final button = FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
          label: const Text('افزودن کارمند'),
        );

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E9ED)),
          ),
          child:
              mobile
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [title, const SizedBox(height: 12), button],
                  )
                  : Row(children: [Expanded(child: title), button]),
        );
      },
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String search;
  final String statusFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;

  const _FilterBar({
    required this.search,
    required this.statusFilter,
    required this.onSearchChanged,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EBEF)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mobile = constraints.maxWidth < 650;

          final searchField = TextFormField(
            initialValue: search,
            onChanged: onSearchChanged,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: 'جستجو نام، کد پرسنلی، کد ملی، موبایل، واحد...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: const Color(0xFFF7F9FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: BorderSide.none,
              ),
            ),
          );

          final statusField = DropdownButtonFormField<String>(
            value: statusFilter,
            decoration: InputDecoration(
              labelText: 'وضعیت',
              filled: true,
              fillColor: const Color(0xFFF7F9FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('همه')),
              DropdownMenuItem(value: 'active', child: Text('فعال')),
              DropdownMenuItem(value: 'inactive', child: Text('غیرفعال')),
            ],
            onChanged: (value) {
              if (value != null) {
                onStatusChanged(value);
              }
            },
          );

          if (mobile) {
            return Column(
              children: [searchField, const SizedBox(height: 10), statusField],
            );
          }

          return Row(
            children: [
              Expanded(flex: 3, child: searchField),
              const SizedBox(width: 12),
              Expanded(child: statusField),
            ],
          );
        },
      ),
    );
  }
}

class _DesktopTable extends StatelessWidget {
  final List<AccountantPayrollEmployee> employees;
  final void Function(BuildContext, AccountantPayrollEmployee) onEdit;
  final Future<void> Function(AccountantPayrollEmployee) onDelete;

  const _DesktopTable({
    required this.employees,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5EBEF)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 50,
          dataRowMinHeight: 58,
          dataRowMaxHeight: 68,
          columnSpacing: 28,
          columns: const [
            DataColumn(label: Text('کد پرسنلی')),
            DataColumn(label: Text('نام و نام خانوادگی')),
            DataColumn(label: Text('کد ملی')),
            DataColumn(label: Text('واحد سازمانی')),
            DataColumn(label: Text('سمت')),
            DataColumn(label: Text('نوع استخدام')),
            DataColumn(label: Text('وضعیت')),
            DataColumn(label: Text('عملیات')),
          ],
          rows:
              employees.map((employee) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        employee.personnelCode,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    DataCell(Text(employee.fullName)),
                    DataCell(Text(employee.nationalId ?? '—')),
                    DataCell(Text(employee.department ?? '—')),
                    DataCell(Text(employee.jobTitle ?? '—')),
                    DataCell(
                      Text(_employmentTypeLabel(employee.employmentType)),
                    ),
                    DataCell(_StatusChip(status: employee.status)),
                    DataCell(
                      _Actions(
                        onEdit: () {
                          onEdit(context, employee);
                        },
                        onDelete: () {
                          onDelete(employee);
                        },
                      ),
                    ),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }
}

class _MobileList extends StatelessWidget {
  final List<AccountantPayrollEmployee> employees;
  final void Function(BuildContext, AccountantPayrollEmployee) onEdit;
  final Future<void> Function(AccountantPayrollEmployee) onDelete;

  const _MobileList({
    required this.employees,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final employee in employees) ...[
          _EmployeeCard(
            employee: employee,
            onEdit: () {
              onEdit(context, employee);
            },
            onDelete: () {
              onDelete(employee);
            },
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final AccountantPayrollEmployee employee;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EmployeeCard({
    required this.employee,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5EBEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: const Color(0xFFEAF3FF),
                child: Text(
                  employee.firstName.isEmpty
                      ? '?'
                      : employee.firstName.substring(0, 1),
                  style: const TextStyle(
                    color: Color(0xFF2878D4),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.fullName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'کد پرسنلی: ${employee.personnelCode}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(status: employee.status),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow(label: 'واحد سازمانی', value: employee.department ?? '—'),
          _InfoRow(label: 'سمت', value: employee.jobTitle ?? '—'),
          _InfoRow(label: 'موبایل', value: employee.mobile ?? '—'),
          _InfoRow(
            label: 'نوع استخدام',
            value: _employmentTypeLabel(employee.employmentType),
          ),
          _InfoRow(
            label: 'تاریخ استخدام',
            value:
                employee.hireDate == null
                    ? '—'
                    : _formatJalaliDate(employee.hireDate!),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('ویرایش'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onDelete,
                tooltip: 'حذف',
                style: IconButton.styleFrom(
                  foregroundColor: Colors.red,
                  backgroundColor: Colors.red.withOpacity(.07),
                ),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _Actions({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onEdit,
          tooltip: 'ویرایش',
          icon: const Icon(Icons.edit_outlined, size: 19),
        ),
        IconButton(
          onPressed: onDelete,
          tooltip: 'حذف',
          color: Colors.red,
          icon: const Icon(Icons.delete_outline_rounded, size: 19),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final active = status.trim().toLowerCase() == 'active';

    final color = active ? const Color(0xFF159957) : const Color(0xFF7A7F87);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        active ? 'فعال' : 'غیرفعال',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 70),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5EBEF)),
      ),
      child: Column(
        children: [
          Icon(Icons.groups_outlined, size: 54, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text(
            'کارمندی برای نمایش وجود ندارد',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _EmployeeDialog extends StatefulWidget {
  final AccountantPayrollEmployee? employee;
  final String companyId;

  const _EmployeeDialog({required this.employee, required this.companyId});

  @override
  State<_EmployeeDialog> createState() => _EmployeeDialogState();
}

class _EmployeeDialogState extends State<_EmployeeDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _personnelCodeController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _nationalIdController;
  late final TextEditingController _mobileController;
  late final TextEditingController _jobTitleController;
  late final TextEditingController _departmentController;
  late final TextEditingController _employmentTypeController;

  String _status = 'active';

  DateTime? _hireDate;
  DateTime? _terminationDate;

  bool _saving = false;

  bool get isEdit => widget.employee != null;

  @override
  void initState() {
    super.initState();

    final employee = widget.employee;

    _personnelCodeController = TextEditingController(
      text: employee?.personnelCode ?? '',
    );

    _firstNameController = TextEditingController(
      text: employee?.firstName ?? '',
    );

    _lastNameController = TextEditingController(text: employee?.lastName ?? '');

    _nationalIdController = TextEditingController(
      text: employee?.nationalId ?? '',
    );

    _mobileController = TextEditingController(text: employee?.mobile ?? '');

    _jobTitleController = TextEditingController(text: employee?.jobTitle ?? '');

    _departmentController = TextEditingController(
      text: employee?.department ?? '',
    );

    _employmentTypeController = TextEditingController(
      text: employee?.employmentType ?? '',
    );

    _status = employee?.status.trim().toLowerCase() ?? 'active';

    _hireDate = employee?.hireDate;
    _terminationDate = employee?.terminationDate;
  }

  @override
  void dispose() {
    _personnelCodeController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nationalIdController.dispose();
    _mobileController.dispose();
    _jobTitleController.dispose();
    _departmentController.dispose();
    _employmentTypeController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(
          isEdit ? 'ویرایش کارمند' : 'افزودن کارمند',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: 620,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _twoFields(
                    _field(
                      controller: _personnelCodeController,
                      label: 'کد پرسنلی *',
                      validator: _required,
                    ),
                    _field(controller: _nationalIdController, label: 'کد ملی'),
                  ),
                  const SizedBox(height: 12),
                  _twoFields(
                    _field(
                      controller: _firstNameController,
                      label: 'نام *',
                      validator: _required,
                    ),
                    _field(
                      controller: _lastNameController,
                      label: 'نام خانوادگی *',
                      validator: _required,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _twoFields(
                    _field(
                      controller: _mobileController,
                      label: 'موبایل',
                      keyboardType: TextInputType.phone,
                    ),
                    _field(controller: _jobTitleController, label: 'سمت'),
                  ),
                  const SizedBox(height: 12),
                  _twoFields(
                    _field(
                      controller: _departmentController,
                      label: 'واحد سازمانی',
                    ),
                    _field(
                      controller: _employmentTypeController,
                      label: 'نوع استخدام',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ==========================================
                  // JALALI DATES
                  // ==========================================
                  _twoFields(
                    _dateField(
                      label: 'تاریخ استخدام',
                      value: _hireDate,
                      onTap: () {
                        _pickDate(isHireDate: true);
                      },
                    ),
                    _dateField(
                      label: 'تاریخ پایان همکاری',
                      value: _terminationDate,
                      onTap: () {
                        _pickDate(isHireDate: false);
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'وضعیت',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('فعال')),
                      DropdownMenuItem(
                        value: 'inactive',
                        child: Text('غیرفعال'),
                      ),
                    ],
                    onChanged:
                        _saving
                            ? null
                            : (value) {
                              if (value != null) {
                                setState(() {
                                  _status = value;
                                });
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
            onPressed:
                _saving
                    ? null
                    : () {
                      Navigator.pop(context, false);
                    },
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child:
                _saving
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : Text(isEdit ? 'ذخیره تغییرات' : 'ثبت کارمند'),
          ),
        ],
      ),
    );
  }

  Widget _twoFields(Widget first, Widget second) {
    return Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: 10),
        Expanded(child: second),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _saving ? null : onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_month_outlined),
          suffixIcon:
              value == null
                  ? null
                  : IconButton(
                    onPressed:
                        _saving
                            ? null
                            : () {
                              setState(() {
                                if (label == 'تاریخ استخدام') {
                                  _hireDate = null;
                                } else {
                                  _terminationDate = null;
                                }
                              });
                            },
                    icon: const Icon(Icons.clear, size: 18),
                  ),
        ),
        child: Text(
          value == null ? 'انتخاب تاریخ شمسی' : _formatJalaliDate(value),
          style: TextStyle(
            color: value == null ? Colors.grey.shade600 : Colors.black87,
            fontWeight: value == null ? FontWeight.normal : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isHireDate}) async {
    final initialDate =
        isHireDate
            ? (_hireDate ?? DateTime.now())
            : (_terminationDate ?? DateTime.now());

    final initialJalali = _GregorianDate.fromDateTime(initialDate);

    final selected = await showDialog<_GregorianDate>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _JalaliDatePickerDialog(initialDate: initialJalali);
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    final gregorian = selected.toDateTime();

    setState(() {
      if (isHireDate) {
        _hireDate = gregorian;
      } else {
        _terminationDate = gregorian;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      if (isEdit) {
        await AccountantPayrollEmployeesRepository.update(
          id: widget.employee!.id,
          personnelCode: _personnelCodeController.text,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          nationalId: _nationalIdController.text,
          mobile: _mobileController.text,
          jobTitle: _jobTitleController.text,
          department: _departmentController.text,
          employmentType: _employmentTypeController.text,
          hireDate: _hireDate,
          terminationDate: _terminationDate,
          status: _status,
        );
      } else {
        await AccountantPayrollEmployeesRepository.create(
          companyId: widget.companyId,
          personnelCode: _personnelCodeController.text,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          nationalId: _nationalIdController.text,
          mobile: _mobileController.text,
          jobTitle: _jobTitleController.text,
          department: _departmentController.text,
          employmentType: _employmentTypeController.text,
          hireDate: _hireDate,
          terminationDate: _terminationDate,
          status: _status,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? 'اطلاعات کارمند بروزرسانی شد' : 'کارمند با موفقیت ثبت شد',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            'خطا در ذخیره اطلاعات: $error',
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'این فیلد الزامی است';
    }

    return null;
  }
}

// ============================================================
// JALALI DATE PICKER
// ============================================================

class _JalaliDatePickerDialog extends StatefulWidget {
  final _GregorianDate initialDate;

  const _JalaliDatePickerDialog({required this.initialDate});

  @override
  State<_JalaliDatePickerDialog> createState() =>
      _JalaliDatePickerDialogState();
}

class _JalaliDatePickerDialogState extends State<_JalaliDatePickerDialog> {
  late int _year;
  late int _month;
  late int _day;

  @override
  void initState() {
    super.initState();

    _year = widget.initialDate.year;
    _month = widget.initialDate.month;
    _day = widget.initialDate.day;
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = _jalaliDaysInMonth(_year, _month);

    if (_day > daysInMonth) {
      _day = daysInMonth;
    }

    final firstDayGregorian =
        _GregorianDate(year: _year, month: _month, day: 1).toDateTime();

    final firstDayWeekday = firstDayGregorian.weekday;

    // DateTime weekday:
    // Monday = 1 ... Sunday = 7
    // Persian calendar starts Saturday.
    final leadingEmpty = (firstDayWeekday + 1) % 7;

    final cells = <Widget>[];

    for (int i = 0; i < leadingEmpty; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final selected = day == _day;

      cells.add(
        InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            setState(() {
              _day = day;
            });
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? Theme.of(context).colorScheme.primary : null,
            ),
            child: Text(
              _toPersianDigits(day.toString()),
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: selected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430, maxHeight: 620),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'ماه بعد',
                      onPressed: () {
                        _nextMonth();
                      },
                      icon: const Icon(Icons.chevron_right),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            _jalaliMonthName(_month),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _toPersianDigits(_year.toString()),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'ماه قبل',
                      onPressed: () {
                        _previousMonth();
                      },
                      icon: const Icon(Icons.chevron_left),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    _WeekDayTitle('ش'),
                    _WeekDayTitle('ی'),
                    _WeekDayTitle('د'),
                    _WeekDayTitle('س'),
                    _WeekDayTitle('چ'),
                    _WeekDayTitle('پ'),
                    _WeekDayTitle('ج'),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 7,
                    mainAxisSpacing: 5,
                    crossAxisSpacing: 5,
                    children: cells,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'تاریخ انتخاب‌شده: '
                    '${_toPersianDigits(_year.toString())}/'
                    '${_toPersianDigits(_month.toString().padLeft(2, '0'))}/'
                    '${_toPersianDigits(_day.toString().padLeft(2, '0'))}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context, null);
                        },
                        child: const Text('انصراف'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            _GregorianDate(
                              year: _year,
                              month: _month,
                              day: _day,
                            ),
                          );
                        },
                        child: const Text('تأیید'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year++;
      } else {
        _month++;
      }

      final max = _jalaliDaysInMonth(_year, _month);

      if (_day > max) {
        _day = max;
      }
    });
  }

  void _previousMonth() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year--;
      } else {
        _month--;
      }

      final max = _jalaliDaysInMonth(_year, _month);

      if (_day > max) {
        _day = max;
      }
    });
  }
}

class _WeekDayTitle extends StatelessWidget {
  final String title;

  const _WeekDayTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// GREGORIAN / JALALI CONVERSION
// ============================================================

class _GregorianDate {
  final int year;
  final int month;
  final int day;

  const _GregorianDate({
    required this.year,
    required this.month,
    required this.day,
  });

  factory _GregorianDate.fromDateTime(DateTime date) {
    final jalali = _gregorianToJalali(date.year, date.month, date.day);

    return _GregorianDate(year: jalali.$1, month: jalali.$2, day: jalali.$3);
  }

  DateTime toDateTime() {
    final gregorian = _jalaliToGregorian(year, month, day);

    return DateTime(gregorian.$1, gregorian.$2, gregorian.$3);
  }
}

(int, int, int) _gregorianToJalali(int gy, int gm, int gd) {
  const gregorianMonthDays = [
    0,
    31,
    28,
    31,
    30,
    31,
    30,
    31,
    31,
    30,
    31,
    30,
    31,
  ];

  final gy2 = gy - 1600;
  final gm2 = gm - 1;
  final gd2 = gd - 1;

  var dayNumber =
      365 * gy2 + ((gy2 + 3) ~/ 4) - ((gy2 + 99) ~/ 100) + ((gy2 + 399) ~/ 400);

  for (int i = 0; i < gm2; i++) {
    dayNumber += gregorianMonthDays[i + 1];
  }

  if (gm2 > 1 && _isGregorianLeapYear(gy)) {
    dayNumber++;
  }

  dayNumber += gd2;

  var jalaliDayNumber = dayNumber - 79;

  final cycle = jalaliDayNumber ~/ 12053;

  jalaliDayNumber %= 12053;

  var jy = 979 + 33 * cycle + 4 * (jalaliDayNumber ~/ 1461);

  jalaliDayNumber %= 1461;

  if (jalaliDayNumber >= 366) {
    jy += (jalaliDayNumber - 1) ~/ 365;

    jalaliDayNumber = (jalaliDayNumber - 1) % 365;
  }

  final jm =
      jalaliDayNumber < 186
          ? 1 + jalaliDayNumber ~/ 31
          : 7 + (jalaliDayNumber - 186) ~/ 30;

  final jd =
      jalaliDayNumber < 186
          ? 1 + jalaliDayNumber % 31
          : 1 + (jalaliDayNumber - 186) % 30;

  return (jy, jm, jd);
}

(int, int, int) _jalaliToGregorian(int jy, int jm, int jd) {
  final y = jy - 979;

  var dayNumber = 365 * y + (y ~/ 33) * 8 + ((y % 33 + 3) ~/ 4);

  if (jm <= 6) {
    dayNumber += (jm - 1) * 31;
  } else {
    dayNumber += (jm - 7) * 30 + 186;
  }

  dayNumber += jd - 1;

  var gregorianDayNumber = dayNumber + 79;

  var gy = 1600 + 400 * (gregorianDayNumber ~/ 146097);

  gregorianDayNumber %= 146097;

  var leap = true;

  if (gregorianDayNumber >= 36525) {
    gregorianDayNumber--;

    gy += 100 * (gregorianDayNumber ~/ 36524);

    gregorianDayNumber %= 36524;

    if (gregorianDayNumber >= 365) {
      gregorianDayNumber++;
    } else {
      leap = false;
    }
  }

  gy += 4 * (gregorianDayNumber ~/ 1461);

  gregorianDayNumber %= 1461;

  if (gregorianDayNumber >= 366) {
    leap = false;

    gregorianDayNumber--;

    gy += gregorianDayNumber ~/ 365;

    gregorianDayNumber %= 365;
  }

  final monthDays =
      leap
          ? const [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
          : const [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

  var gm = 1;
  var gd = gregorianDayNumber + 1;

  while (gd > monthDays[gm]) {
    gd -= monthDays[gm];
    gm++;
  }

  return (gy, gm, gd);
}

bool _isGregorianLeapYear(int year) {
  return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
}

bool _isJalaliLeapYear(int year) {
  final mod = year % 33;

  const leapRemainders = [1, 5, 9, 13, 17, 22, 26, 30];

  return leapRemainders.contains(mod);
}

int _jalaliDaysInMonth(int year, int month) {
  if (month <= 6) {
    return 31;
  }

  if (month <= 11) {
    return 30;
  }

  return _isJalaliLeapYear(year) ? 30 : 29;
}

String _jalaliMonthName(int month) {
  const months = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  return months[month - 1];
}

String _formatJalaliDate(DateTime date) {
  final jalali = _gregorianToJalali(date.year, date.month, date.day);

  return '${_toPersianDigits(jalali.$1.toString())}/'
      '${_toPersianDigits(jalali.$2.toString().padLeft(2, '0'))}/'
      '${_toPersianDigits(jalali.$3.toString().padLeft(2, '0'))}';
}

String _toPersianDigits(String value) {
  const english = '0123456789';
  const persian = '۰۱۲۳۴۵۶۷۸۹';

  var result = value;

  for (int i = 0; i < english.length; i++) {
    result = result.replaceAll(english[i], persian[i]);
  }

  return result;
}

String _employmentTypeLabel(String? value) {
  if (value == null || value.trim().isEmpty) {
    return '—';
  }

  switch (value.trim().toLowerCase()) {
    case 'full_time':
    case 'full-time':
      return 'تمام وقت';

    case 'part_time':
    case 'part-time':
      return 'پاره وقت';

    case 'contract':
    case 'contractual':
      return 'قراردادی';

    case 'temporary':
      return 'موقت';

    case 'permanent':
      return 'دائم';

    default:
      return value;
  }
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 46,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'خطا در دریافت لیست کارکنان',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }
}
