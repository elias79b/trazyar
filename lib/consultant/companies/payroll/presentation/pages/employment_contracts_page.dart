import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

import '../../application/employment_contract_provider.dart';
import '../../application/employee_provider.dart';
import '../../data/employment_contract_model.dart';
import '../../data/employee_model.dart';
import '../widgets/employment_contract_form_dialog.dart';

class EmploymentContractsPage extends ConsumerStatefulWidget {
  const EmploymentContractsPage({super.key, required this.companyId});

  final String companyId;

  @override
  ConsumerState<EmploymentContractsPage> createState() =>
      _EmploymentContractsPageState();
}

class _EmploymentContractsPageState
    extends ConsumerState<EmploymentContractsPage> {
  final TextEditingController _searchController = TextEditingController();

  String _search = '';

  String? _selectedStatus;
  String? _selectedCostCenterId;

  List<Map<String, dynamic>> _costCenters = [];

  bool _loadingCostCenters = true;

  @override
  void initState() {
    super.initState();
    _loadCostCenters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCostCenters() async {
    try {
      final response = await Supabase.instance.client
          .from('cost_centers')
          .select('id, name, code, description, is_active')
          .eq('company_id', widget.companyId)
          .eq('is_active', true)
          .order('name', ascending: true);

      if (!mounted) return;

      setState(() {
        _costCenters =
            (response as List)
                .map((row) => Map<String, dynamic>.from(row))
                .toList();

        _loadingCostCenters = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadingCostCenters = false;
      });

      _showError(_cleanError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final contractsAsync = ref.watch(
      employmentContractsProvider(widget.companyId),
    );

    final employeesAsync = ref.watch(employeesProvider(widget.companyId));

    return CompanyScaffold(
      companyId: widget.companyId,
      currentRoute:
          '/consultant/companies/${widget.companyId}/payroll/contracts',
      title: 'قراردادها',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildHeader(contractsAsync),
              const SizedBox(height: 18),
              _buildFilters(),
              const SizedBox(height: 18),
              Expanded(
                child: contractsAsync.when(
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => _buildError(error),
                  data: (contracts) {
                    final employees =
                        employeesAsync.valueOrNull ?? const <EmployeeModel>[];
                    final filtered = _filterContracts(contracts, employees);

                    if (filtered.isEmpty) {
                      return _buildEmpty();
                    }

                    return _buildTable(
                      filtered,
                      employees,
                      employeesAsync.isLoading,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    AsyncValue<List<EmploymentContractModel>> contractsAsync,
  ) {
    final count = contractsAsync.maybeWhen(
      data: (items) => items.length,
      orElse: () => 0,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF40916C)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.description_rounded,
              size: 28,
              color: Color(0xFF1B4332),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'قراردادها',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_toPersianNumber(count)} قرارداد ثبت شده',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: _openCreateDialog,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1B4332),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('ثبت قرارداد'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchController,
              textDirection: TextDirection.rtl,
              onChanged: (value) {
                setState(() {
                  _search = value.trim();
                });
              },
              decoration: InputDecoration(
                hintText:
                    'جستجو در نام پرسنل، کد پرسنلی، سمت، واحد، شماره قرارداد یا مرکز هزینه...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon:
                    _search.isEmpty
                        ? null
                        : IconButton(
                          onPressed: () {
                            _searchController.clear();

                            setState(() {
                              _search = '';
                            });
                          },
                          icon: const Icon(Icons.clear_rounded),
                        ),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: _buildCostCenterFilter()),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: _buildStatusFilter()),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.filter_alt_off_rounded),
            label: const Text('حذف فیلتر'),
          ),
        ],
      ),
    );
  }

  Widget _buildCostCenterFilter() {
    if (_loadingCostCenters) {
      return const InputDecorator(
        decoration: InputDecoration(
          labelText: 'مرکز هزینه',
          border: OutlineInputBorder(),
        ),
        child: SizedBox(
          height: 24,
          child: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    return DropdownButtonFormField<String?>(
      value: _selectedCostCenterId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'مرکز هزینه',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.account_tree_rounded),
      ),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('همه مراکز')),
        ..._costCenters.map((center) {
          final id = center['id'].toString();

          final name = (center['name'] ?? '').toString();

          final code = center['code']?.toString();

          return DropdownMenuItem<String?>(
            value: id,
            child: Text(
              code == null || code.trim().isEmpty ? name : '$code - $name',
              overflow: TextOverflow.ellipsis,
            ),
          );
        }),
      ],
      onChanged: (value) {
        setState(() {
          _selectedCostCenterId = value;
        });
      },
    );
  }

  Widget _buildStatusFilter() {
    return DropdownButtonFormField<String?>(
      value: _selectedStatus,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'وضعیت',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.toggle_on_rounded),
      ),
      items: const [
        DropdownMenuItem<String?>(value: null, child: Text('همه وضعیت‌ها')),
        DropdownMenuItem<String?>(value: 'active', child: Text('فعال')),
        DropdownMenuItem<String?>(value: 'expired', child: Text('منقضی')),
        DropdownMenuItem<String?>(
          value: 'terminated',
          child: Text('خاتمه‌یافته'),
        ),
        DropdownMenuItem<String?>(value: 'cancelled', child: Text('لغوشده')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedStatus = value;
        });
      },
    );
  }

  List<EmploymentContractModel> _filterContracts(
    List<EmploymentContractModel> contracts,
    List<EmployeeModel> employees,
  ) {
    final query = _search.toLowerCase();

    final employeeMap = <String, EmployeeModel>{
      for (final employee in employees) employee.id: employee,
    };

    return contracts.where((contract) {
      final center = _findCostCenter(contract.costCenterId);

      final centerName = center?['name']?.toString() ?? '';
      final centerCode = center?['code']?.toString() ?? '';

      final employee = employeeMap[contract.employeeId];

      final employeeName = employee?.fullName.toLowerCase() ?? '';
      final personnelCode = employee?.personnelCode.toLowerCase() ?? '';
      final jobTitle = employee?.jobTitle?.toLowerCase() ?? '';
      final department = employee?.department?.toLowerCase() ?? '';

      final contractNumber = (contract.contractNumber ?? '').toLowerCase();
      final contractType = contract.contractType.toLowerCase();

      final matchesSearch =
          query.isEmpty ||
          contractNumber.contains(query) ||
          contractType.contains(query) ||
          centerName.toLowerCase().contains(query) ||
          centerCode.toLowerCase().contains(query) ||
          employeeName.contains(query) ||
          personnelCode.contains(query) ||
          jobTitle.contains(query) ||
          department.contains(query);

      final matchesCenter =
          _selectedCostCenterId == null ||
          contract.costCenterId == _selectedCostCenterId;

      final matchesStatus =
          _selectedStatus == null || contract.status == _selectedStatus;

      return matchesSearch && matchesCenter && matchesStatus;
    }).toList();
  }

  Widget _buildTable(
    List<EmploymentContractModel> contracts,
    List<EmployeeModel> employees,
    bool employeesLoading,
  ) {
    final employeeMap = <String, EmployeeModel>{
      for (final employee in employees) employee.id: employee,
    };

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
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 54,
              dataRowMinHeight: 78,
              dataRowMaxHeight: 96,
              columnSpacing: 24,
              horizontalMargin: 18,
              headingTextStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF25302B),
              ),
              columns: const [
                DataColumn(label: Text('پرسنل')),
                DataColumn(label: Text('سمت')),
                DataColumn(label: Text('واحد سازمانی')),
                DataColumn(label: Text('شماره قرارداد')),
                DataColumn(label: Text('نوع قرارداد')),
                DataColumn(label: Text('مرکز هزینه')),
                DataColumn(label: Text('حقوق پایه')),
                DataColumn(label: Text('تاریخ شروع')),
                DataColumn(label: Text('تاریخ پایان')),
                DataColumn(label: Text('باقی‌مانده')),
                DataColumn(label: Text('وضعیت')),
                DataColumn(label: Text('عملیات')),
              ],
              rows:
                  contracts.map((contract) {
                    final employee = employeeMap[contract.employeeId];
                    final center = _findCostCenter(contract.costCenterId);

                    return DataRow(
                      cells: [
                        // =====================================================
                        // EMPLOYEE
                        // =====================================================
                        DataCell(
                          SizedBox(
                            width: 220,
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF2D6A4F,
                                    ).withOpacity(.08),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    size: 19,
                                    color: Color(0xFF2D6A4F),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child:
                                      employee == null
                                          ? Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                employeesLoading
                                                    ? 'در حال دریافت پرسنل...'
                                                    : 'پرسنل نامشخص',
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                  color:
                                                      employeesLoading
                                                          ? Colors.grey.shade600
                                                          : Colors.red.shade700,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                'شناسه: ${contract.employeeId}',
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          )
                                          : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                employee.fullName,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                'کد پرسنلی: ${employee.personnelCode}',
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // =====================================================
                        // JOB TITLE
                        // =====================================================
                        DataCell(
                          SizedBox(
                            width: 150,
                            child: Text(
                              employee?.jobTitle?.trim().isNotEmpty == true
                                  ? employee!.jobTitle!.trim()
                                  : '-',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        // =====================================================
                        // DEPARTMENT
                        // =====================================================
                        DataCell(
                          SizedBox(
                            width: 150,
                            child: Text(
                              employee?.department?.trim().isNotEmpty == true
                                  ? employee!.department!.trim()
                                  : '-',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),

                        // =====================================================
                        // CONTRACT NUMBER
                        // =====================================================
                        DataCell(
                          Text(
                            _valueOrDash(contract.contractNumber),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        // =====================================================
                        // CONTRACT TYPE
                        // =====================================================
                        DataCell(
                          _ContractTypeChip(value: contract.contractType),
                        ),

                        // =====================================================
                        // COST CENTER
                        // =====================================================
                        DataCell(
                          SizedBox(
                            width: 180,
                            child: Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF2D6A4F,
                                    ).withOpacity(.07),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.account_tree_rounded,
                                    size: 16,
                                    color: Color(0xFF2D6A4F),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        center?['name']?.toString() ?? 'نامشخص',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      if (center?['code'] != null)
                                        Text(
                                          center!['code'].toString(),
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // =====================================================
                        // BASE SALARY
                        // =====================================================
                        DataCell(
                          Text(
                            _formatMoney(contract.baseSalary),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),

                        // =====================================================
                        // START DATE
                        // =====================================================
                        DataCell(
                          Text(
                            _formatDate(contract.startDate),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),

                        // =====================================================
                        // END DATE
                        // =====================================================
                        DataCell(
                          Text(
                            _formatDate(contract.endDate),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),

                        // =====================================================
                        // REMAINING DAYS
                        // =====================================================
                        DataCell(_RemainingDaysChip(endDate: contract.endDate)),

                        // =====================================================
                        // STATUS
                        // =====================================================
                        DataCell(_StatusChip(status: contract.status)),

                        // =====================================================
                        // ACTIONS
                        // =====================================================
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'ویرایش',
                                onPressed: () {
                                  _openEditDialog(contract);
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
                                  _deleteContract(contract);
                                },
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 19,
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
      ),
    );
  }

  Future<void> _openCreateDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => EmploymentContractFormDialog(companyId: widget.companyId),
    );

    if (!mounted) return;

    if (result == true) {
      ref.invalidate(employmentContractsProvider(widget.companyId));
    }
  }

  Future<void> _openEditDialog(EmploymentContractModel contract) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (_) => EmploymentContractFormDialog(
            companyId: widget.companyId,
            contract: contract,
          ),
    );

    if (!mounted) return;

    if (result == true) {
      ref.invalidate(employmentContractsProvider(widget.companyId));
    }
  }

  Future<void> _deleteContract(EmploymentContractModel contract) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('حذف قرارداد'),
              content: Text(
                'آیا از حذف قرارداد ${_valueOrDash(contract.contractNumber)} مطمئن هستید؟',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('انصراف'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('حذف'),
                ),
              ],
            ),
          ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await Supabase.instance.client
          .from('employment_contracts')
          .delete()
          .eq('id', contract.id);

      ref.invalidate(employmentContractsProvider(widget.companyId));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('قرارداد با موفقیت حذف شد.')),
      );
    } catch (error) {
      if (!mounted) return;

      _showError(_cleanError(error));
    }
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.description_outlined,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 14),
          const Text(
            'قراردادی برای نمایش وجود ندارد.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _openCreateDialog,
            icon: const Icon(Icons.add_rounded),
            label: const Text('ثبت قرارداد'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Object error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 52,
            color: Colors.red.shade700,
          ),
          const SizedBox(height: 12),
          Text(_cleanError(error), textAlign: TextAlign.center),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () {
              ref.invalidate(employmentContractsProvider(widget.companyId));
              ref.invalidate(employeesProvider(widget.companyId));
              _loadCostCenters();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('تلاش مجدد'),
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _search = '';
      _selectedStatus = null;
      _selectedCostCenterId = null;
    });
  }

  Map<String, dynamic>? _findCostCenter(String? id) {
    if (id == null) {
      return null;
    }

    for (final center in _costCenters) {
      if (center['id']?.toString() == id) {
        return center;
      }
    }

    return null;
  }

  String _valueOrDash(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '-';
    }

    return value;
  }

  String _formatMoney(double value) {
    final integer = value.round().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < integer.length; i++) {
      if (i > 0 && (integer.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(integer[i]);
    }

    return _toPersianNumber(buffer.toString());
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '-';
    }

    final jalali = Jalali.fromDateTime(value);

    return '${_toPersianNumber(jalali.year)}/'
        '${_toPersianNumber(jalali.month).padLeft(2, '۰')}/'
        '${_toPersianNumber(jalali.day).padLeft(2, '۰')}';
  }

  String _toPersianNumber(Object value) {
    const english = '0123456789';

    const persian = '۰۱۲۳۴۵۶۷۸۹';

    var result = value.toString();

    for (var i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], persian[i]);
    }

    return result;
  }

  String _cleanError(Object error) {
    final text = error.toString();

    if (text.startsWith('Exception: ')) {
      return text.substring(11);
    }

    return text;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.red.shade700, content: Text(message)),
    );
  }
}

// ============================================================
// CONTRACT TYPE CHIP
// ============================================================

class _ContractTypeChip extends StatelessWidget {
  const _ContractTypeChip({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _title(value),
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
      ),
    );
  }

  String _title(String value) {
    switch (value) {
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
        return value;
    }
  }
}

// ============================================================
// REMAINING DAYS CHIP
// ============================================================

class _RemainingDaysChip extends StatelessWidget {
  const _RemainingDaysChip({required this.endDate});

  final DateTime? endDate;

  @override
  Widget build(BuildContext context) {
    if (endDate == null) {
      return const _SimpleInfoChip(
        label: 'بدون پایان',
        color: Color(0xFF2D6A4F),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
    final days = end.difference(today).inDays;

    if (days < 0) {
      return const _SimpleInfoChip(label: 'منقضی', color: Color(0xFFC62828));
    }

    if (days == 0) {
      return const _SimpleInfoChip(label: 'امروز', color: Color(0xFFC62828));
    }

    if (days <= 30) {
      return _SimpleInfoChip(
        label: '${_toPersianNumber(days)} روز',
        color: Colors.orange.shade800,
      );
    }

    return _SimpleInfoChip(
      label: '${_toPersianNumber(days)} روز',
      color: Colors.green.shade700,
    );
  }

  String _toPersianNumber(Object value) {
    const english = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';

    var result = value.toString();

    for (var i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], persian[i]);
    }

    return result;
  }
}

class _SimpleInfoChip extends StatelessWidget {
  const _SimpleInfoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

// ============================================================
// STATUS CHIP
// ============================================================

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _color(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _title(status),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Color _color(String value) {
    switch (value) {
      case 'active':
        return Colors.green.shade700;
      case 'expired':
        return Colors.orange.shade700;
      case 'terminated':
        return Colors.red.shade700;
      case 'cancelled':
        return Colors.grey.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  String _title(String value) {
    switch (value) {
      case 'active':
        return 'فعال';
      case 'expired':
        return 'منقضی';
      case 'terminated':
        return 'خاتمه‌یافته';
      case 'cancelled':
        return 'لغوشده';
      default:
        return value;
    }
  }
}
