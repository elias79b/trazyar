import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

import '../../application/employee_provider.dart';
import '../../data/employee_model.dart';
import '../widgets/employee_form_dialog.dart';

class EmployeesPage extends ConsumerStatefulWidget {
  const EmployeesPage({super.key, required this.companyId});

  final String companyId;

  @override
  ConsumerState<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends ConsumerState<EmployeesPage> {
  final TextEditingController _searchController = TextEditingController();

  String _search = '';

  String get _route =>
      '/consultant/companies/${widget.companyId}/payroll/employees';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync =
        _search.isEmpty
            ? ref.watch(employeesProvider(widget.companyId))
            : ref.watch(
              employeeSearchProvider(
                EmployeeSearchParams(
                  companyId: widget.companyId,
                  query: _search,
                ),
              ),
            );

    return CompanyScaffold(
      companyId: widget.companyId,

      currentRoute: _route,

      title: 'پرسنل',

      body: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            _Header(
              onAdd: _openCreateDialog,

              count: employeesAsync.maybeWhen(
                data: (items) => items.length,
                orElse: () => null,
              ),
            ),

            const SizedBox(height: 18),

            _SearchBar(
              controller: _searchController,

              onChanged: (value) {
                setState(() {
                  _search = value.trim();
                });
              },
            ),

            const SizedBox(height: 18),

            Expanded(
              child: employeesAsync.when(
                loading: () {
                  return const Center(child: CircularProgressIndicator());
                },

                error: (error, stackTrace) {
                  return _ErrorState(
                    message: error.toString(),

                    onRetry: () {
                      ref.invalidate(employeesProvider(widget.companyId));
                    },
                  );
                },

                data: (employees) {
                  if (employees.isEmpty) {
                    return _EmptyState(
                      hasSearch: _search.isNotEmpty,

                      onAdd: _openCreateDialog,
                    );
                  }

                  return _EmployeesTable(
                    employees: employees,

                    onEdit: _openEditDialog,

                    onDelete: _deleteEmployee,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCreateDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return EmployeeFormDialog(companyId: widget.companyId);
      },
    );

    if (!mounted) return;

    ref.invalidate(employeesProvider(widget.companyId));
  }

  Future<void> _openEditDialog(EmployeeModel employee) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return EmployeeFormDialog(
          companyId: widget.companyId,
          employee: employee,
        );
      },
    );

    if (!mounted) return;

    ref.invalidate(employeesProvider(widget.companyId));
  }

  Future<void> _deleteEmployee(EmployeeModel employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'حذف پرسنل',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),

          content: Text('آیا از حذف ${employee.fullName} مطمئن هستید؟'),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },

              child: const Text('انصراف'),
            ),

            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),

              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },

              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final repository = ref.read(employeeRepositoryProvider);

      await repository.deleteEmployee(employee.id);

      ref.invalidate(employeesProvider(widget.companyId));

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('پرسنل با موفقیت حذف شد.')));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(error.toString()),
        ),
      );
    }
  }
}

// ============================================================
// HEADER
// ============================================================

class _Header extends StatelessWidget {
  const _Header({required this.onAdd, required this.count});

  final VoidCallback onAdd;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
        ),

        borderRadius: BorderRadius.circular(18),
      ),

      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(14),
            ),

            child: const Icon(
              Icons.people_alt_rounded,

              color: Color(0xFF1B4332),

              size: 25,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'پرسنل',

                  style: TextStyle(
                    color: Colors.white,

                    fontSize: 19,

                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  count == null
                      ? 'مدیریت اطلاعات پرسنل'
                      : '${_toPersian(count!)} نفر ثبت شده',

                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),

          FilledButton.icon(
            onPressed: onAdd,

            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,

              foregroundColor: const Color(0xFF1B4332),
            ),

            icon: const Icon(Icons.person_add_alt_1_rounded),

            label: const Text('ثبت پرسنل'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SEARCH
// ============================================================

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: Colors.grey.shade200),
      ),

      child: TextField(
        controller: controller,

        onChanged: onChanged,

        decoration: const InputDecoration(
          border: InputBorder.none,

          icon: Icon(Icons.search_rounded),

          hintText: 'جستجو بر اساس نام، کد پرسنلی، کد ملی یا موبایل',
        ),
      ),
    );
  }
}

// ============================================================
// TABLE
// ============================================================

class _EmployeesTable extends StatelessWidget {
  const _EmployeesTable({
    required this.employees,
    required this.onEdit,
    required this.onDelete,
  });

  final List<EmployeeModel> employees;

  final Future<void> Function(EmployeeModel) onEdit;

  final Future<void> Function(EmployeeModel) onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: Colors.grey.shade200),
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),

        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,

          child: DataTable(
            headingRowHeight: 48,

            dataRowMinHeight: 56,

            dataRowMaxHeight: 64,

            columnSpacing: 26,

            columns: const [
              DataColumn(label: Text('کد پرسنلی')),
              DataColumn(label: Text('نام و نام خانوادگی')),
              DataColumn(label: Text('سمت')),
              DataColumn(label: Text('دپارتمان')),
              DataColumn(label: Text('نوع استخدام')),
              DataColumn(label: Text('وضعیت')),
              DataColumn(label: Text('عملیات')),
            ],

            rows:
                employees.map((employee) {
                  return DataRow(
                    cells: [
                      DataCell(Text(employee.personnelCode)),

                      DataCell(Text(employee.fullName)),

                      DataCell(Text(employee.jobTitle ?? '-')),

                      DataCell(Text(employee.department ?? '-')),

                      DataCell(
                        _SimpleChip(
                          label: _employmentTitle(employee.employmentType),
                        ),
                      ),

                      DataCell(_StatusChip(status: employee.status)),

                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,

                          children: [
                            IconButton(
                              tooltip: 'ویرایش',

                              onPressed: () {
                                onEdit(employee);
                              },

                              icon: const Icon(
                                Icons.edit_rounded,

                                size: 18,

                                color: Color(0xFF2D6A4F),
                              ),
                            ),

                            IconButton(
                              tooltip: 'حذف',

                              onPressed: () {
                                onDelete(employee);
                              },

                              icon: Icon(
                                Icons.delete_outline_rounded,

                                size: 18,

                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CHIPS
// ============================================================

class _SimpleChip extends StatelessWidget {
  const _SimpleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),

      decoration: BoxDecoration(
        color: Colors.grey.shade100,

        borderRadius: BorderRadius.circular(8),
      ),

      child: Text(
        label,

        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;

    switch (status) {
      case 'active':
        color = Colors.green.shade700;
        break;
      case 'inactive':
        color = Colors.grey.shade700;
        break;
      case 'terminated':
        color = Colors.red.shade700;
        break;
      case 'suspended':
        color = Colors.orange.shade700;
        break;
      default:
        color = Colors.blueGrey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),

      decoration: BoxDecoration(
        color: color.withOpacity(.08),

        borderRadius: BorderRadius.circular(8),
      ),

      child: Text(
        _statusTitle(status),

        style: TextStyle(
          color: color,

          fontSize: 9,

          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ============================================================
// EMPTY
// ============================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasSearch, required this.onAdd});

  final bool hasSearch;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(
            hasSearch ? Icons.search_off_rounded : Icons.people_outline_rounded,

            size: 52,

            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 12),

          Text(
            hasSearch
                ? 'پرسنی با این مشخصات پیدا نشد.'
                : 'هنوز پرسنلی ثبت نشده است.',

            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),

          if (!hasSearch) ...[
            const SizedBox(height: 12),

            FilledButton.icon(
              onPressed: onAdd,

              icon: const Icon(Icons.person_add_alt_1_rounded),

              label: const Text('ثبت اولین پرسنل'),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// ERROR
// ============================================================

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(
            Icons.error_outline_rounded,

            size: 44,

            color: Colors.red.shade700,
          ),

          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),

            child: Text(message, textAlign: TextAlign.center),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: onRetry,

            icon: const Icon(Icons.refresh_rounded),

            label: const Text('تلاش مجدد'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HELPERS
// ============================================================

String _employmentTitle(String? value) {
  switch (value) {
    case 'full_time':
      return 'تمام‌وقت';
    case 'part_time':
      return 'پاره‌وقت';
    case 'contract':
      return 'قراردادی';
    case 'temporary':
      return 'موقت';
    case 'intern':
      return 'کارآموز';
    default:
      return value ?? '-';
  }
}

String _statusTitle(String value) {
  switch (value) {
    case 'active':
      return 'فعال';
    case 'inactive':
      return 'غیرفعال';
    case 'terminated':
      return 'خاتمه همکاری';
    case 'suspended':
      return 'معلق';
    default:
      return value;
  }
}

String _toPersian(int value) {
  const english = '0123456789';

  const persian = '۰۱۲۳۴۵۶۷۸۹';

  var result = value.toString();

  for (var i = 0; i < english.length; i++) {
    result = result.replaceAll(english[i], persian[i]);
  }

  return result;
}
