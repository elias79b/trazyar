import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarazyar/accountant/dashboard/presentation/widgets/accountant_scaffold.dart';
import 'package:tarazyar/accountant/payroll/application/accountant_payroll_contracts_provider.dart';

class AccountantPayrollContractsPage extends ConsumerStatefulWidget {
  final String companyId;

  const AccountantPayrollContractsPage({super.key, required this.companyId});

  @override
  ConsumerState<AccountantPayrollContractsPage> createState() =>
      _AccountantPayrollContractsPageState();
}

class _AccountantPayrollContractsPageState
    extends ConsumerState<AccountantPayrollContractsPage> {
  String _search = '';
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      accountantPayrollContractsProvider(widget.companyId),
    );

    return AccountantScaffold(
      currentRoute: '/accountant/payroll/contracts',
      title: 'قراردادهای کارکنان',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, stackTrace) => _ErrorView(
                error: error,
                onRetry: () {
                  ref.invalidate(
                    accountantPayrollContractsProvider(widget.companyId),
                  );
                },
              ),
          data: (contracts) => _buildContent(context, contracts),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<AccountantPayrollContract> contracts,
  ) {
    final filtered =
        contracts.where((contract) {
          final query = _search.trim().toLowerCase();

          final matchesSearch =
              query.isEmpty ||
              (contract.employeeName ?? '').toLowerCase().contains(query) ||
              (contract.personnelCode ?? '').toLowerCase().contains(query) ||
              (contract.contractNumber ?? '').toLowerCase().contains(query) ||
              contract.contractType.toLowerCase().contains(query) ||
              (contract.costCenterName ?? '').toLowerCase().contains(query);

          final matchesStatus =
              _statusFilter == 'all' ||
              contract.status.trim().toLowerCase() == _statusFilter;

          return matchesSearch && matchesStatus;
        }).toList();

    final activeCount =
        contracts
            .where((e) => e.status.trim().toLowerCase() == 'active')
            .length;

    final otherCount = contracts.length - activeCount;

    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 850;

        return SingleChildScrollView(
          padding: EdgeInsets.all(mobile ? 14 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                total: contracts.length,
                active: activeCount,
                other: otherCount,
                onAdd: () => _openDialog(context),
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
              else if (mobile)
                _MobileList(
                  contracts: filtered,
                  onEdit: (contract) => _openDialog(context, contract),
                  onDelete: _confirmDelete,
                )
              else
                _DesktopTable(
                  contracts: filtered,
                  onEdit: (contract) => _openDialog(context, contract),
                  onDelete: _confirmDelete,
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openDialog(
    BuildContext context, [
    AccountantPayrollContract? contract,
  ]) async {
    // مهم:
    // قبل از باز کردن فرم قرارداد، اطلاعات فرم را
    // invalidate می‌کنیم تا مراکز هزینه جدید
    // بدون Refresh دستی صفحه خوانده شوند.
    ref.invalidate(accountantPayrollContractFormProvider(widget.companyId));

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) =>
              _ContractDialog(companyId: widget.companyId, contract: contract),
    );

    if (result == true && mounted) {
      ref.invalidate(accountantPayrollContractsProvider(widget.companyId));

      ref.invalidate(accountantPayrollContractFormProvider(widget.companyId));
    }
  }

  Future<void> _confirmDelete(AccountantPayrollContract contract) async {
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

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await AccountantPayrollContractsRepository.delete(contract.id);

      ref.invalidate(accountantPayrollContractsProvider(widget.companyId));

      ref.invalidate(accountantPayrollContractFormProvider(widget.companyId));

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('قرارداد حذف شد')));
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
  final int other;
  final VoidCallback onAdd;

  const _Header({
    required this.total,
    required this.active,
    required this.other,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E9ED)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mobile = constraints.maxWidth < 700;

          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'مدیریت قراردادها',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 5),
              Text(
                '$total قرارداد • $active فعال • $other سایر وضعیت‌ها',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          );

          final button = FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.note_add_outlined, size: 18),
            label: const Text('افزودن قرارداد'),
          );

          if (mobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [title, const SizedBox(height: 12), button],
            );
          }

          return Row(children: [Expanded(child: title), button]);
        },
      ),
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
              hintText: 'جستجو کارمند، قرارداد، مرکز هزینه...',
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
              labelText: 'وضعیت قرارداد',
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
              DropdownMenuItem(value: 'expired', child: Text('منقضی')),
              DropdownMenuItem(value: 'terminated', child: Text('خاتمه یافته')),
              DropdownMenuItem(value: 'cancelled', child: Text('لغو شده')),
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
  final List<AccountantPayrollContract> contracts;
  final ValueChanged<AccountantPayrollContract> onEdit;
  final Future<void> Function(AccountantPayrollContract) onDelete;

  const _DesktopTable({
    required this.contracts,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5EBEF)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 50,
          dataRowMinHeight: 60,
          dataRowMaxHeight: 70,
          columnSpacing: 26,
          columns: const [
            DataColumn(label: Text('مرکز هزینه')),
            DataColumn(label: Text('پرسنل')),
            DataColumn(label: Text('شماره قرارداد')),
            DataColumn(label: Text('نوع قرارداد')),
            DataColumn(label: Text('شروع')),
            DataColumn(label: Text('پایان')),
            DataColumn(label: Text('حقوق پایه')),
            DataColumn(label: Text('وضعیت')),
            DataColumn(label: Text('عملیات')),
          ],
          rows:
              contracts.map((contract) {
                return DataRow(
                  cells: [
                    DataCell(Text(contract.costCenterName ?? '—')),
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contract.employeeName ?? '—',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (contract.personnelCode != null)
                            Text(
                              contract.personnelCode!,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    DataCell(Text(contract.contractNumber ?? '—')),
                    DataCell(Text(contractTypeLabel(contract.contractType))),
                    DataCell(Text(formatJalaliDate(contract.startDate))),
                    DataCell(Text(formatJalaliDate(contract.endDate))),
                    DataCell(Text(formatMoney(contract.baseSalary))),
                    DataCell(_StatusChip(status: contract.status)),
                    DataCell(
                      _Actions(
                        onEdit: () => onEdit(contract),
                        onDelete: () => onDelete(contract),
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
  final List<AccountantPayrollContract> contracts;
  final ValueChanged<AccountantPayrollContract> onEdit;
  final Future<void> Function(AccountantPayrollContract) onDelete;

  const _MobileList({
    required this.contracts,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final contract in contracts) ...[
          _ContractCard(
            contract: contract,
            onEdit: () => onEdit(contract),
            onDelete: () => onDelete(contract),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ContractCard extends StatelessWidget {
  final AccountantPayrollContract contract;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ContractCard({
    required this.contract,
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
              const CircleAvatar(
                radius: 22,
                child: Icon(Icons.description_outlined),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contract.employeeName ?? 'کارمند نامشخص',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contract.contractNumber ?? 'بدون شماره قرارداد',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(status: contract.status),
            ],
          ),
          const Divider(height: 22),
          _InfoRow(label: 'مرکز هزینه', value: contract.costCenterName ?? '—'),
          _InfoRow(
            label: 'نوع قرارداد',
            value: contractTypeLabel(contract.contractType),
          ),
          _InfoRow(label: 'حقوق پایه', value: formatMoney(contract.baseSalary)),
          _InfoRow(
            label: 'شروع قرارداد',
            value: formatJalaliDate(contract.startDate),
          ),
          _InfoRow(
            label: 'پایان قرارداد',
            value: formatJalaliDate(contract.endDate),
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
                color: Colors.red,
                style: IconButton.styleFrom(
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
            width: 100,
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
    final normalized = status.trim().toLowerCase();

    final label = switch (normalized) {
      'active' => 'فعال',
      'expired' => 'منقضی',
      'terminated' => 'خاتمه یافته',
      'cancelled' => 'لغو شده',
      _ => status.isEmpty ? 'نامشخص' : status,
    };

    final color = switch (normalized) {
      'active' => const Color(0xFF159957),
      'expired' => const Color(0xFFE69A00),
      'terminated' => const Color(0xFF7A7F87),
      'cancelled' => const Color(0xFFD64545),
      _ => const Color(0xFF7A7F87),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
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
          Icon(
            Icons.description_outlined,
            size: 52,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          const Text(
            'قراردادی برای نمایش وجود ندارد',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ContractDialog extends ConsumerStatefulWidget {
  final String companyId;
  final AccountantPayrollContract? contract;

  const _ContractDialog({required this.companyId, required this.contract});

  @override
  ConsumerState<_ContractDialog> createState() => _ContractDialogState();
}

class _ContractDialogState extends ConsumerState<_ContractDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _contractNumberController;

  late final TextEditingController _baseSalaryController;

  late final TextEditingController _workingHoursController;

  late final TextEditingController _insuranceController;

  late final TextEditingController _taxController;

  String? _employeeId;
  String? _costCenterId;

  String _contractType = 'permanent';
  String _status = 'active';

  DateTime? _startDate;
  DateTime? _endDate;

  bool _saving = false;

  bool get isEdit => widget.contract != null;

  @override
  void initState() {
    super.initState();

    final contract = widget.contract;

    _employeeId = contract?.employeeId;

    _costCenterId = contract?.costCenterId;

    _contractNumberController = TextEditingController(
      text: contract?.contractNumber ?? '',
    );

    _baseSalaryController = TextEditingController(
      text: contract == null ? '' : contract.baseSalary.toString(),
    );

    _workingHoursController = TextEditingController(
      text: contract?.workingHours?.toString() ?? '',
    );

    _insuranceController = TextEditingController(
      text: contract?.insuranceStatus ?? 'insured',
    );

    _taxController = TextEditingController(
      text: contract?.taxStatus ?? 'taxable',
    );

    _contractType = contract?.contractType.trim().toLowerCase() ?? 'permanent';

    _status = contract?.status.trim().toLowerCase() ?? 'active';

    _startDate = contract?.startDate;

    _endDate = contract?.endDate;
  }

  @override
  void dispose() {
    _contractNumberController.dispose();
    _baseSalaryController.dispose();
    _workingHoursController.dispose();
    _insuranceController.dispose();
    _taxController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(
      accountantPayrollContractFormProvider(widget.companyId),
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(
          isEdit ? 'ویرایش قرارداد' : 'ثبت قرارداد',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        content: SizedBox(
          width: 700,
          child: formState.when(
            loading:
                () => const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator()),
                ),
            error:
                (error, stackTrace) => _FormError(
                  error: error,
                  onRetry: () {
                    ref.invalidate(
                      accountantPayrollContractFormProvider(widget.companyId),
                    );
                  },
                ),
            data: (formData) => _buildForm(formData),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined, size: 18),
            label: Text(isEdit ? 'ذخیره تغییرات' : 'ثبت قرارداد'),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(AccountantPayrollContractFormData data) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildCostCenterDropdown(data.costCenters),
            const SizedBox(height: 12),
            _buildEmployeeDropdown(data.employees),
            const SizedBox(height: 12),
            _field(
              controller: _contractNumberController,
              label: 'شماره قرارداد',
              icon: Icons.tag_rounded,
            ),
            const SizedBox(height: 12),
            _buildContractTypeDropdown(),
            const SizedBox(height: 12),
            _twoFields(
              _dateField(
                label: 'تاریخ شروع',
                value: _startDate,
                onTap: () => _pickDate(isStart: true),
              ),
              _dateField(
                label: 'تاریخ پایان',
                value: _endDate,
                onTap: () => _pickDate(isStart: false),
              ),
            ),
            const SizedBox(height: 12),
            _field(
              controller: _baseSalaryController,
              label: 'حقوق پایه *',
              icon: Icons.payments_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: _moneyValidator,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _workingHoursController,
              label: 'ساعات کاری',
              icon: Icons.schedule_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
            _twoFields(
              _field(
                controller: _insuranceController,
                label: 'وضعیت بیمه *',
                icon: Icons.health_and_safety_outlined,
                validator: _required,
              ),
              _field(
                controller: _taxController,
                label: 'وضعیت مالیات *',
                icon: Icons.receipt_long_outlined,
                validator: _required,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatusDropdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildCostCenterDropdown(
    List<AccountantPayrollCostCenterOption> costCenters,
  ) {
    return DropdownButtonFormField<String>(
      value: _validSelectedValue(
        _costCenterId,
        costCenters.map((e) => e.id).toSet(),
      ),
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'مرکز هزینه *',
        prefixIcon: Icon(Icons.account_tree_outlined),
        border: OutlineInputBorder(),
      ),
      items:
          costCenters
              .map(
                (center) => DropdownMenuItem<String>(
                  value: center.id,
                  child: Text(center.label, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
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
          return 'مرکز هزینه را انتخاب کنید';
        }

        return null;
      },
    );
  }

  Widget _buildEmployeeDropdown(
    List<AccountantPayrollEmployeeOption> employees,
  ) {
    return DropdownButtonFormField<String>(
      value: _validSelectedValue(
        _employeeId,
        employees.map((e) => e.id).toSet(),
      ),
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'پرسنل *',
        prefixIcon: Icon(Icons.person_outline_rounded),
        border: OutlineInputBorder(),
      ),
      items:
          employees
              .map(
                (employee) => DropdownMenuItem<String>(
                  value: employee.id,
                  child: Text(employee.label, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
      onChanged:
          _saving
              ? null
              : (value) {
                setState(() {
                  _employeeId = value;
                });
              },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'پرسنل را انتخاب کنید';
        }

        return null;
      },
    );
  }

  Widget _buildContractTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _contractType,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'نوع قرارداد *',
        prefixIcon: Icon(Icons.description_outlined),
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'permanent', child: Text('دائم')),
        DropdownMenuItem(value: 'temporary', child: Text('موقت')),
        DropdownMenuItem(value: 'contract', child: Text('قراردادی')),
        DropdownMenuItem(value: 'probation', child: Text('آزمایشی')),
        DropdownMenuItem(value: 'internship', child: Text('کارآموزی')),
      ],
      onChanged:
          _saving
              ? null
              : (value) {
                if (value != null) {
                  setState(() {
                    _contractType = value;
                  });
                }
              },
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _status,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'وضعیت قرارداد',
        prefixIcon: Icon(Icons.toggle_on_outlined),
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'active', child: Text('فعال')),
        DropdownMenuItem(value: 'expired', child: Text('منقضی')),
        DropdownMenuItem(value: 'terminated', child: Text('خاتمه یافته')),
        DropdownMenuItem(value: 'cancelled', child: Text('لغو شده')),
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
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
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
          prefixIcon: const Icon(Icons.calendar_month_outlined),
          border: const OutlineInputBorder(),
          suffixIcon:
              value == null
                  ? null
                  : IconButton(
                    onPressed:
                        _saving
                            ? null
                            : () {
                              setState(() {
                                if (label == 'تاریخ شروع') {
                                  _startDate = null;
                                } else {
                                  _endDate = null;
                                }
                              });
                            },
                    icon: const Icon(Icons.clear, size: 18),
                  ),
        ),
        child: Text(
          value == null ? 'انتخاب تاریخ شمسی' : formatJalaliDate(value),
          style: TextStyle(
            color: value == null ? Colors.grey.shade600 : Colors.black87,
            fontWeight: value == null ? FontWeight.normal : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final currentDate =
        isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now());

    final initialJalali = _JalaliDate.fromDateTime(currentDate);

    final selected = await showDialog<_JalaliDate>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _JalaliDatePickerDialog(initialDate: initialJalali),
    );

    if (selected == null || !mounted) {
      return;
    }

    final gregorian = selected.toDateTime();

    setState(() {
      if (isStart) {
        _startDate = gregorian;
      } else {
        _endDate = gregorian;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_employeeId == null || _costCenterId == null) {
      return;
    }

    final baseSalary = double.tryParse(
      _baseSalaryController.text.replaceAll(',', '').trim(),
    );

    if (baseSalary == null) {
      return;
    }

    final workingHours = double.tryParse(
      _workingHoursController.text.replaceAll(',', '').trim(),
    );

    setState(() {
      _saving = true;
    });

    try {
      if (isEdit) {
        await AccountantPayrollContractsRepository.update(
          id: widget.contract!.id,
          employeeId: _employeeId!,
          costCenterId: _costCenterId!,
          contractNumber: _contractNumberController.text,
          contractType: _contractType,
          startDate: _startDate,
          endDate: _endDate,
          baseSalary: baseSalary,
          workingHours: workingHours,
          insuranceStatus: _insuranceController.text,
          taxStatus: _taxController.text,
          status: _status,
        );
      } else {
        await AccountantPayrollContractsRepository.create(
          companyId: widget.companyId,
          employeeId: _employeeId!,
          costCenterId: _costCenterId!,
          contractNumber: _contractNumberController.text,
          contractType: _contractType,
          startDate: _startDate,
          endDate: _endDate,
          baseSalary: baseSalary,
          workingHours: workingHours,
          insuranceStatus: _insuranceController.text,
          taxStatus: _taxController.text,
          status: _status,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? 'قرارداد بروزرسانی شد' : 'قرارداد با موفقیت ثبت شد',
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
            'خطا در ذخیره قرارداد: $error',
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

  String? _moneyValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'حقوق پایه الزامی است';
    }

    if (double.tryParse(value.replaceAll(',', '').trim()) == null) {
      return 'مبلغ معتبر نیست';
    }

    return null;
  }

  String? _validSelectedValue(String? value, Set<String> validValues) {
    if (value == null) {
      return null;
    }

    return validValues.contains(value) ? value : null;
  }
}

class _FormError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _FormError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 46),
            const SizedBox(height: 12),
            Text(
              'خطا در دریافت اطلاعات فرم\n\n$error',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
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

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48),
          const SizedBox(height: 12),
          const Text(
            'خطا در دریافت قراردادها',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            '$error',
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
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
// JALALI DATE PICKER
// ============================================================

class _JalaliDatePickerDialog extends StatefulWidget {
  final _JalaliDate initialDate;

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
        _JalaliDate(year: _year, month: _month, day: 1).toDateTime();

    final firstWeekday = firstDayGregorian.weekday;

    final leadingEmpty = (firstWeekday + 1) % 7;

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
                      onPressed: _nextMonth,
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
                      onPressed: _previousMonth,
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
                            _JalaliDate(year: _year, month: _month, day: _day),
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
// JALALI DATE
// ============================================================

class _JalaliDate {
  final int year;
  final int month;
  final int day;

  const _JalaliDate({
    required this.year,
    required this.month,
    required this.day,
  });

  factory _JalaliDate.fromDateTime(DateTime date) {
    final result = _gregorianToJalali(date.year, date.month, date.day);

    return _JalaliDate(year: result.$1, month: result.$2, day: result.$3);
  }

  DateTime toDateTime() {
    final result = _jalaliToGregorian(year, month, day);

    return DateTime(result.$1, result.$2, result.$3);
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

String formatJalaliDate(DateTime? date) {
  if (date == null) {
    return '—';
  }

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

String formatMoney(double value) {
  final text = value.round().toString();

  final buffer = StringBuffer();

  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) {
      buffer.write(',');
    }

    buffer.write(text[i]);
  }

  return '${buffer.toString()} ریال';
}

String contractTypeLabel(String value) {
  switch (value.trim().toLowerCase()) {
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
      return value.isEmpty ? '—' : value;
  }
}
