import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarazyar/accountant/dashboard/presentation/widgets/accountant_scaffold.dart';
import 'package:tarazyar/accountant/payroll/application/accountant_payroll_records_provider.dart';

class AccountantPayrollRecordsPage extends ConsumerStatefulWidget {
  final String periodId;

  const AccountantPayrollRecordsPage({
    super.key,
    required this.periodId,
  });

  @override
  ConsumerState<AccountantPayrollRecordsPage> createState() =>
      _AccountantPayrollRecordsPageState();
}

class _AccountantPayrollRecordsPageState
    extends ConsumerState<AccountantPayrollRecordsPage> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      accountantPayrollRecordsProvider(widget.periodId),
    );

    return AccountantScaffold(
      currentRoute: '/accountant/payroll/periods',
      title: 'ثبت حقوق دوره',
      body:  state.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => _ErrorView(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(
              accountantPayrollRecordsProvider(widget.periodId),
            );
          },
        ),
        data: (data) {
          final query = search.trim().toLowerCase();

          final records = data.records.where((record) {
            if (query.isEmpty) {
              return true;
            }

            final employee = data.employeeById(
              record.employeeId,
            );

            final contract = data.contractById(
              record.contractId,
            );

            final searchable = [
              employee?.fullName ?? '',
              employee?.personnelCode ?? '',
              employee?.department ?? '',
              employee?.jobTitle ?? '',
              contract?.contractNumber ?? '',
              contract?.contractType ?? '',
              contract?.costCenterName ?? '',
            ].join(' ').toLowerCase();

            return searchable.contains(query);
          }).toList();

          return Directionality(
            textDirection: TextDirection.rtl,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _PeriodHeader(
                  data: data,
                  onAdd: data.period.isDraft
                      ? () => _openRecordDialog(data)
                      : null,
                ),
                const SizedBox(height: 16),
                _SearchBox(
                  value: search,
                  onChanged: (value) {
                    setState(() {
                      search = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _PeriodSummary(
                  data: data,
                ),
                const SizedBox(height: 16),
                if (records.isEmpty)
                  _EmptyRecords(
                    isDraft: data.period.isDraft,
                    onAdd: data.period.isDraft
                        ? () => _openRecordDialog(data)
                        : null,
                  )
                else
                  _RecordsList(
                    data: data,
                    records: records,
                    onEdit: data.period.isDraft
                        ? (record) {
                      _openRecordDialog(
                        data,
                        record: record,
                      );
                    }
                        : null,
                    onDelete: data.period.isDraft
                        ? _deleteRecord
                        : null,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openRecordDialog(
      AccountantPayrollRecordsData data, {
        AccountantPayrollRecord? record,
      }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return _PayrollRecordDialog(
          data: data,
          record: record,
        );
      },
    );

    if (result == true && mounted) {
      ref.invalidate(
        accountantPayrollRecordsProvider(widget.periodId),
      );
    }
  }

  Future<void> _deleteRecord(
      AccountantPayrollRecord record,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('حذف رکورد حقوق'),
            content: const Text(
              'آیا رکورد حقوق این پرسنل حذف شود؟',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text('انصراف'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text('حذف'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await AccountantPayrollRecordsRepository.delete(
        id: record.id,
        periodId: record.payrollPeriodId,
      );

      ref.invalidate(
        accountantPayrollRecordsProvider(widget.periodId),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'رکورد حقوق حذف شد.',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }
  }
}

class _PeriodHeader extends StatelessWidget {
  final AccountantPayrollRecordsData data;
  final VoidCallback? onAdd;

  const _PeriodHeader({
    required this.data,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final period = data.period;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 800;

            final titleSection = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  period.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'ثبت حقوق پرسنل و تخصیص مرکز هزینه از طریق قرارداد',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 10),
                _StatusChip(
                  status: period.normalizedStatus,
                  title: payrollStatusName(
                    period.status,
                  ),
                ),
              ],
            );

            final addButton = FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(
                Icons.add,
              ),
              label: const Text(
                'ثبت حقوق',
              ),
            );

            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  titleSection,
                  const SizedBox(height: 16),
                  addButton,
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: titleSection,
                ),
                const SizedBox(width: 20),
                addButton,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PeriodSummary extends StatelessWidget {
  final AccountantPayrollRecordsData data;

  const _PeriodSummary({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000 ? 4 : 2;

        final width =
            (constraints.maxWidth - ((columns - 1) * 12)) /
                columns;

        final items = [
          _SummaryItem(
            title: 'پرسنل',
            value: _number(data.employeeCount),
            icon: Icons.people_outline,
          ),
          _SummaryItem(
            title: 'حقوق ناخالص',
            value: _money(data.totalGrossSalary),
            icon: Icons.payments_outlined,
          ),
          _SummaryItem(
            title: 'کسورات',
            value: _money(data.totalDeductions),
            icon: Icons.remove_circle_outline,
          ),
          _SummaryItem(
            title: 'خالص پرداختی',
            value: _money(data.totalNetSalary),
            icon: Icons.account_balance_wallet_outlined,
          ),
        ];

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            return SizedBox(
              width: width,
              child: item,
            );
          }).toList(),
        );
      },
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _SearchBox({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: TextFormField(
          initialValue: value,
          onChanged: onChanged,
          decoration: const InputDecoration(
            labelText: 'جستجو',
            hintText:
            'نام پرسنل، کد پرسنلی، قرارداد یا مرکز هزینه...',
            prefixIcon: Icon(
              Icons.search,
            ),
            border: OutlineInputBorder(),
          ),
        ),
      ),
    );
  }
}

class _RecordsList extends StatelessWidget {
  final AccountantPayrollRecordsData data;
  final List<AccountantPayrollRecord> records;
  final ValueChanged<AccountantPayrollRecord>? onEdit;
  final ValueChanged<AccountantPayrollRecord>? onDelete;

  const _RecordsList({
    required this.data,
    required this.records,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return _MobileRecordsList(
            data: data,
            records: records,
            onEdit: onEdit,
            onDelete: onDelete,
          );
        }

        return _DesktopRecordsTable(
          data: data,
          records: records,
          onEdit: onEdit,
          onDelete: onDelete,
        );
      },
    );
  }
}

class _DesktopRecordsTable extends StatelessWidget {
  final AccountantPayrollRecordsData data;
  final List<AccountantPayrollRecord> records;
  final ValueChanged<AccountantPayrollRecord>? onEdit;
  final ValueChanged<AccountantPayrollRecord>? onDelete;

  const _DesktopRecordsTable({
    required this.data,
    required this.records,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 22,
          headingRowHeight: 52,
          columns: const [
            DataColumn(
              label: Text('پرسنل'),
            ),
            DataColumn(
              label: Text('قرارداد'),
            ),
            DataColumn(
              label: Text('مرکز هزینه'),
            ),
            DataColumn(
              label: Text('حقوق پایه'),
            ),
            DataColumn(
              label: Text('مزایا'),
            ),
            DataColumn(
              label: Text('ناخالص'),
            ),
            DataColumn(
              label: Text('کسورات'),
            ),
            DataColumn(
              label: Text('خالص'),
            ),
            DataColumn(
              label: Text('عملیات'),
            ),
          ],
          rows: records.map((record) {
            final employee = data.employeeById(
              record.employeeId,
            );

            final contract = data.contractById(
              record.contractId,
            );

            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 150,
                    child: Text(
                      employee?.fullName ?? 'نامشخص',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 130,
                    child: Text(
                      contract?.displayName ?? 'بدون قرارداد',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  _CostCenterCell(
                    name: contract?.costCenterName,
                  ),
                ),
                DataCell(
                  Text(
                    _money(record.baseSalary),
                  ),
                ),
                DataCell(
                  Text(
                    _money(
                      record.overtimeAmount +
                          record.bonusAmount +
                          record.allowanceAmount,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    _money(record.grossSalary),
                  ),
                ),
                DataCell(
                  Text(
                    _money(record.totalDeductions),
                  ),
                ),
                DataCell(
                  Text(
                    _money(record.netSalary),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onEdit != null)
                        IconButton(
                          tooltip: 'ویرایش',
                          onPressed: () {
                            onEdit!(record);
                          },
                          icon: const Icon(
                            Icons.edit_outlined,
                          ),
                        ),
                      if (onDelete != null)
                        IconButton(
                          tooltip: 'حذف',
                          onPressed: () {
                            onDelete!(record);
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
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
    );
  }
}

class _MobileRecordsList extends StatelessWidget {
  final AccountantPayrollRecordsData data;
  final List<AccountantPayrollRecord> records;
  final ValueChanged<AccountantPayrollRecord>? onEdit;
  final ValueChanged<AccountantPayrollRecord>? onDelete;

  const _MobileRecordsList({
    required this.data,
    required this.records,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: records.map((record) {
        final employee = data.employeeById(
          record.employeeId,
        );

        final contract = data.contractById(
          record.contractId,
        );

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(
            bottom: 12,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        employee?.fullName ?? 'نامشخص',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (onEdit != null)
                      IconButton(
                        onPressed: () {
                          onEdit!(record);
                        },
                        icon: const Icon(
                          Icons.edit_outlined,
                        ),
                      ),
                    if (onDelete != null)
                      IconButton(
                        onPressed: () {
                          onDelete!(record);
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                _MobileInfoRow(
                  title: 'کد پرسنلی',
                  value: employee?.personnelCode ?? '-',
                ),
                _MobileInfoRow(
                  title: 'قرارداد',
                  value: contract?.displayName ?? '-',
                ),
                _MobileInfoRow(
                  title: 'مرکز هزینه',
                  value: contract?.costCenterName ??
                      'بدون مرکز هزینه',
                  highlighted: true,
                ),
                const Divider(
                  height: 24,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _MobileMoney(
                        title: 'ناخالص',
                        value: record.grossSalary,
                      ),
                    ),
                    Expanded(
                      child: _MobileMoney(
                        title: 'کسورات',
                        value: record.totalDeductions,
                      ),
                    ),
                    Expanded(
                      child: _MobileMoney(
                        title: 'خالص',
                        value: record.netSalary,
                        bold: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MobileInfoRow extends StatelessWidget {
  final String title;
  final String value;
  final bool highlighted;

  const _MobileInfoRow({
    required this.title,
    required this.value,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 7,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: highlighted
                    ? FontWeight.w800
                    : FontWeight.w600,
                color: highlighted
                    ? Colors.blue.shade700
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileMoney extends StatelessWidget {
  final String title;
  final double value;
  final bool bold;

  const _MobileMoney({
    required this.title,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _money(value),
          style: TextStyle(
            fontWeight: bold
                ? FontWeight.w900
                : FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _CostCenterCell extends StatelessWidget {
  final String? name;

  const _CostCenterCell({
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final hasName =
        name != null && name!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: hasName
            ? Colors.blue.shade50
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        hasName ? name! : 'بدون مرکز هزینه',
        style: TextStyle(
          color: hasName
              ? Colors.blue.shade700
              : Colors.red.shade700,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _PayrollRecordDialog extends StatefulWidget {
  final AccountantPayrollRecordsData data;
  final AccountantPayrollRecord? record;

  const _PayrollRecordDialog({
    required this.data,
    this.record,
  });

  @override
  State<_PayrollRecordDialog> createState() =>
      _PayrollRecordDialogState();
}

class _PayrollRecordDialogState
    extends State<_PayrollRecordDialog> {
  String? selectedEmployeeId;
  String? selectedContractId;

  late final TextEditingController baseSalaryController;
  late final TextEditingController overtimeHoursController;
  late final TextEditingController overtimeAmountController;
  late final TextEditingController bonusController;
  late final TextEditingController allowanceController;
  late final TextEditingController employeeInsuranceController;
  late final TextEditingController employerInsuranceController;
  late final TextEditingController taxController;
  late final TextEditingController absenceController;
  late final TextEditingController otherDeductionsController;
  late final TextEditingController advanceController;
  late final TextEditingController notesController;

  bool saving = false;

  @override
  void initState() {
    super.initState();

    final record = widget.record;

    selectedEmployeeId = record?.employeeId;
    selectedContractId = record?.contractId;

    baseSalaryController = _controller(
      record?.baseSalary,
    );

    overtimeHoursController = _controller(
      record?.overtimeHours,
    );

    overtimeAmountController = _controller(
      record?.overtimeAmount,
    );

    bonusController = _controller(
      record?.bonusAmount,
    );

    allowanceController = _controller(
      record?.allowanceAmount,
    );

    employeeInsuranceController = _controller(
      record?.employeeInsurance,
    );

    employerInsuranceController = _controller(
      record?.employerInsurance,
    );

    taxController = _controller(
      record?.taxAmount,
    );

    absenceController = _controller(
      record?.absenceAmount,
    );

    otherDeductionsController = _controller(
      record?.otherDeductions,
    );

    advanceController = _controller(
      record?.advanceAmount,
    );

    notesController = TextEditingController(
      text: record?.notes ?? '',
    );
  }

  TextEditingController _controller(
      double? value,
      ) {
    return TextEditingController(
      text: value == null || value == 0
          ? ''
          : _plainNumber(value),
    );
  }

  @override
  void dispose() {
    baseSalaryController.dispose();
    overtimeHoursController.dispose();
    overtimeAmountController.dispose();
    bonusController.dispose();
    allowanceController.dispose();
    employeeInsuranceController.dispose();
    employerInsuranceController.dispose();
    taxController.dispose();
    absenceController.dispose();
    otherDeductionsController.dispose();
    advanceController.dispose();
    notesController.dispose();
    super.dispose();
  }

  List<AccountantPayrollContract> get selectedEmployeeContracts {
    if (selectedEmployeeId == null) {
      return [];
    }

    return widget.data.contracts
        .where(
          (contract) =>
      contract.employeeId == selectedEmployeeId,
    )
        .toList();
  }

  AccountantPayrollContract? get selectedContract {
    return widget.data.contractById(
      selectedContractId,
    );
  }

  double get grossSalary {
    return _numberValue(baseSalaryController) +
        _numberValue(overtimeAmountController) +
        _numberValue(bonusController) +
        _numberValue(allowanceController);
  }

  double get deductions {
    return _numberValue(
      employeeInsuranceController,
    ) +
        _numberValue(taxController) +
        _numberValue(absenceController) +
        _numberValue(otherDeductionsController) +
        _numberValue(advanceController);
  }

  double get netSalary {
    return grossSalary - deductions;
  }

  @override
  Widget build(BuildContext context) {
    final contracts = selectedEmployeeContracts;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(
          widget.record == null
              ? 'ثبت حقوق پرسنل'
              : 'ویرایش حقوق پرسنل',
        ),
        content: SizedBox(
          width: 820,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _SectionTitle(
                  title: 'پرسنل و مرکز هزینه',
                  icon: Icons.account_tree_outlined,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedEmployeeId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'پرسنل',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.person_outline,
                    ),
                  ),
                  items: widget.data.employees.map(
                        (employee) {
                      return DropdownMenuItem<String>(
                        value: employee.id,
                        child: Text(
                          employee.displayName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ).toList(),
                  onChanged: widget.record != null
                      ? null
                      : (value) {
                    setState(() {
                      selectedEmployeeId = value;
                      selectedContractId = null;
                      baseSalaryController.clear();
                    });
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: selectedContractId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'قرارداد',
                    hintText:
                    'قرارداد پرسنل را انتخاب کنید',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.description_outlined,
                    ),
                  ),
                  items: contracts.map(
                        (contract) {
                      return DropdownMenuItem<String>(
                        value: contract.id,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                contract.displayName,
                                overflow:
                                TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            _CostCenterBadge(
                              name: contract.costCenterName,
                            ),
                          ],
                        ),
                      );
                    },
                  ).toList(),
                  onChanged: selectedEmployeeId == null
                      ? null
                      : (value) {
                    if (value == null) {
                      return;
                    }

                    final contract =
                    widget.data.contractById(
                      value,
                    );

                    setState(() {
                      selectedContractId = value;
                    });

                    if (contract != null) {
                      baseSalaryController.text =
                          _plainNumber(
                            contract.baseSalary,
                          );
                    }
                  },
                ),
                const SizedBox(height: 12),
                if (selectedContract != null)
                  _SelectedContractCard(
                    contract: selectedContract!,
                  ),
                const SizedBox(height: 22),
                _SectionTitle(
                  title: 'حقوق و مزایا',
                  icon: Icons.payments_outlined,
                ),
                const SizedBox(height: 12),
                _FieldsGrid(
                  children: [
                    _MoneyField(
                      controller: baseSalaryController,
                      label: 'حقوق پایه',
                    ),
                    _MoneyField(
                      controller: overtimeHoursController,
                      label: 'ساعات اضافه‌کاری',
                      allowDecimal: true,
                      suffix: 'ساعت',
                    ),
                    _MoneyField(
                      controller: overtimeAmountController,
                      label: 'مبلغ اضافه‌کاری',
                    ),
                    _MoneyField(
                      controller: bonusController,
                      label: 'پاداش',
                    ),
                    _MoneyField(
                      controller: allowanceController,
                      label: 'مزایا',
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _SectionTitle(
                  title: 'کسورات',
                  icon: Icons.remove_circle_outline,
                ),
                const SizedBox(height: 12),
                _FieldsGrid(
                  children: [
                    _MoneyField(
                      controller:
                      employeeInsuranceController,
                      label: 'بیمه سهم کارمند',
                    ),
                    _MoneyField(
                      controller:
                      employerInsuranceController,
                      label: 'بیمه سهم کارفرما',
                    ),
                    _MoneyField(
                      controller: taxController,
                      label: 'مالیات',
                    ),
                    _MoneyField(
                      controller: absenceController,
                      label: 'کسر غیبت',
                    ),
                    _MoneyField(
                      controller:
                      otherDeductionsController,
                      label: 'سایر کسورات',
                    ),
                    _MoneyField(
                      controller: advanceController,
                      label: 'علی‌الحساب',
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _CalculationCard(
                  grossSalary: grossSalary,
                  deductions: deductions,
                  netSalary: netSalary,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'توضیحات',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving
                ? null
                : () {
              Navigator.pop(
                context,
                false,
              );
            },
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: saving ? null : _save,
            child: saving
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Text('ذخیره حقوق'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (selectedEmployeeId == null) {
      _showError(
        'ابتدا پرسنل را انتخاب کنید.',
      );
      return;
    }

    if (selectedContractId == null) {
      _showError(
        'قرارداد پرسنل را انتخاب کنید.',
      );
      return;
    }

    final contract = selectedContract;

    if (contract == null) {
      _showError(
        'قرارداد انتخاب‌شده پیدا نشد.',
      );
      return;
    }

    if (contract.costCenterId.trim().isEmpty) {
      _showError(
        'برای قرارداد انتخاب‌شده مرکز هزینه تعریف نشده است.',
      );
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      if (widget.record == null) {
        await AccountantPayrollRecordsRepository.create(
          periodId: widget.data.period.id,
          companyId: widget.data.period.companyId,
          employeeId: selectedEmployeeId!,
          contractId: selectedContractId!,
          baseSalary: _numberValue(
            baseSalaryController,
          ),
          overtimeHours: _numberValue(
            overtimeHoursController,
          ),
          overtimeAmount: _numberValue(
            overtimeAmountController,
          ),
          bonusAmount: _numberValue(
            bonusController,
          ),
          allowanceAmount: _numberValue(
            allowanceController,
          ),
          employeeInsurance: _numberValue(
            employeeInsuranceController,
          ),
          employerInsurance: _numberValue(
            employerInsuranceController,
          ),
          taxAmount: _numberValue(
            taxController,
          ),
          absenceAmount: _numberValue(
            absenceController,
          ),
          otherDeductions: _numberValue(
            otherDeductionsController,
          ),
          advanceAmount: _numberValue(
            advanceController,
          ),
          notes: _nullable(
            notesController.text,
          ),
        );
      } else {
        await AccountantPayrollRecordsRepository.update(
          id: widget.record!.id,
          periodId: widget.data.period.id,
          employeeId: selectedEmployeeId!,
          contractId: selectedContractId!,
          baseSalary: _numberValue(
            baseSalaryController,
          ),
          overtimeHours: _numberValue(
            overtimeHoursController,
          ),
          overtimeAmount: _numberValue(
            overtimeAmountController,
          ),
          bonusAmount: _numberValue(
            bonusController,
          ),
          allowanceAmount: _numberValue(
            allowanceController,
          ),
          employeeInsurance: _numberValue(
            employeeInsuranceController,
          ),
          employerInsurance: _numberValue(
            employerInsuranceController,
          ),
          taxAmount: _numberValue(
            taxController,
          ),
          absenceAmount: _numberValue(
            absenceController,
          ),
          otherDeductions: _numberValue(
            otherDeductionsController,
          ),
          advanceAmount: _numberValue(
            advanceController,
          ),
          notes: _nullable(
            notesController.text,
          ),
        );
      }

      if (mounted) {
        Navigator.pop(
          context,
          true,
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(
        e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  double _numberValue(
      TextEditingController controller,
      ) {
    final text = controller.text
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .trim();

    return double.tryParse(text) ?? 0;
  }

  String? _nullable(String value) {
    final text = value.trim();

    return text.isEmpty ? null : text;
  }

  String _plainNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }

    return value.toString();
  }
}

class _SelectedContractCard extends StatelessWidget {
  final AccountantPayrollContract contract;

  const _SelectedContractCard({
    required this.contract,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade100,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_tree_outlined,
            color: Colors.blue.shade700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'مرکز هزینه قرارداد',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contract.costCenterTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CostCenterBadge extends StatelessWidget {
  final String? name;

  const _CostCenterBadge({
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final hasName =
        name != null && name!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: hasName
            ? Colors.blue.shade50
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        hasName ? name! : 'بدون مرکز',
        style: TextStyle(
          color: hasName
              ? Colors.blue.shade700
              : Colors.red.shade700,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 21,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _FieldsGrid extends StatelessWidget {
  final List<Widget> children;

  const _FieldsGrid({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
        constraints.maxWidth >= 650 ? 2 : 1;

        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: children.map((child) {
            return SizedBox(
              width: width,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}

class _MoneyField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool allowDecimal;
  final String? suffix;

  const _MoneyField({
    required this.controller,
    required this.label,
    this.allowDecimal = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(
        decimal: allowDecimal,
      ),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix ?? 'ریال',
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _CalculationCard extends StatelessWidget {
  final double grossSalary;
  final double deductions;
  final double netSalary;

  const _CalculationCard({
    required this.grossSalary,
    required this.deductions,
    required this.netSalary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 500;

          final children = [
            _CalculationItem(
              title: 'ناخالص',
              value: grossSalary,
            ),
            _CalculationItem(
              title: 'کسورات',
              value: deductions,
            ),
            _CalculationItem(
              title: 'خالص پرداختی',
              value: netSalary,
              bold: true,
            ),
          ];

          if (narrow) {
            return Column(
              children: children
                  .map(
                    (item) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: item,
                ),
              )
                  .toList(),
            );
          }

          return Row(
            children: children.map((item) {
              return Expanded(
                child: item,
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _CalculationItem extends StatelessWidget {
  final String title;
  final double value;
  final bool bold;

  const _CalculationItem({
    required this.title,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _money(value),
          style: TextStyle(
            fontSize: bold ? 18 : 15,
            fontWeight: bold
                ? FontWeight.w900
                : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _EmptyRecords extends StatelessWidget {
  final bool isDraft;
  final VoidCallback? onAdd;

  const _EmptyRecords({
    required this.isDraft,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 58,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 14),
            const Text(
              'هنوز رکورد حقوقی برای این دوره ثبت نشده است.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ابتدا پرسنل و سپس قرارداد دارای مرکز هزینه را انتخاب کنید.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
              ),
            ),
            if (isDraft && onAdd != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(
                  Icons.add,
                ),
                label: const Text(
                  'ثبت حقوق',
                ),
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

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 52,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
                  'تلاش مجدد',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _StatusChip extends StatelessWidget {
  final String status;
  final String title;

  const _StatusChip({
    required this.status,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    Color background;
    Color foreground;

    switch (status.trim().toLowerCase()) {
      case 'paid':
        background = Colors.green.shade50;
        foreground = Colors.green.shade700;
        break;

      case 'consultant_approved':
        background = Colors.blue.shade50;
        foreground = Colors.blue.shade700;
        break;

      case 'pending_ceo':
        background = Colors.orange.shade50;
        foreground = Colors.orange.shade800;
        break;

      case 'rejected':
      case 'cancelled':
        background = Colors.red.shade50;
        foreground = Colors.red.shade700;
        break;

      case 'draft':
      default:
        background = Colors.grey.shade100;
        foreground = Colors.grey.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
String _money(double value) {
  final text = value.round().toString();
  final buffer = StringBuffer();

  for (int i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) {
      buffer.write(',');
    }

    buffer.write(text[i]);
  }

  return buffer.toString();
}

String _number(int value) {
  final text = value.toString();
  final buffer = StringBuffer();

  for (int i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) {
      buffer.write(',');
    }

    buffer.write(text[i]);
  }

  return buffer.toString();
}