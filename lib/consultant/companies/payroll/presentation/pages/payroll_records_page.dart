import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarazyar/consultant/companies/payroll/presentation/widgets/payroll_cost_center_record_form_dialog.dart';
import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

import '../../application/payroll_period_provider.dart';
import '../../data/payroll_cost_center_record_model.dart';
import '../../data/payroll_cost_center_record_provider.dart';
import '../../data/payroll_period_model.dart';

class PayrollRecordsPage extends ConsumerWidget {
  const PayrollRecordsPage({
    super.key,
    required this.companyId,
    required this.period,
  });

  final String companyId;
  final PayrollPeriodModel period;

  String get _currentRoute =>
      '/consultant/companies/$companyId/payroll/records';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(payrollCostCenterRecordsProvider(period.id));

    return CompanyScaffold(
      companyId: companyId,
      currentRoute: _currentRoute,
      title: 'حقوق و دستمزد',
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: recordsAsync.when(
          loading: () {
            return const Center(child: CircularProgressIndicator());
          },
          error: (error, stackTrace) {
            return _ErrorView(
              error: _friendlyError(error),
              onRetry: () {
                ref.invalidate(payrollCostCenterRecordsProvider(period.id));
              },
            );
          },
          data: (records) {
            return _RecordsView(
              companyId: companyId,
              period: period,
              records: records,
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// RECORDS VIEW
// ============================================================

class _RecordsView extends ConsumerWidget {
  const _RecordsView({
    required this.companyId,
    required this.period,
    required this.records,
  });

  final String companyId;
  final PayrollPeriodModel period;
  final List<PayrollCostCenterRecordModel> records;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalEmployees = records.fold<int>(
      0,
      (sum, record) => sum + record.employeeCount,
    );

    final totalBaseSalary = records.fold<double>(
      0,
      (sum, record) => sum + record.baseSalary,
    );

    final totalAllowances = records.fold<double>(
      0,
      (sum, record) => sum + record.totalAllowances,
    );

    final totalPersonnelCosts = records.fold<double>(
      0,
      (sum, record) => sum + record.totalPersonnelCosts,
    );

    final totalEmployerInsurance = records.fold<double>(
      0,
      (sum, record) => sum + record.employerInsurance,
    );

    final totalUnemploymentInsurance = records.fold<double>(
      0,
      (sum, record) => sum + record.unemploymentInsurance,
    );

    final totalPayrollCost = records.fold<double>(
      0,
      (sum, record) => sum + record.totalPayrollCost,
    );

    final isLocked =
        period.status == 'ceo_approved' ||
        period.status == 'pending_consultant' ||
        period.status == 'consultant_approved' ||
        period.status == 'paid';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ======================================================
        // HEADER
        // ======================================================
        Row(
          children: [
            IconButton(
              tooltip: 'بازگشت به دوره‌های حقوق',
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.arrow_forward_rounded),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'حقوق ${_periodTitle(period)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'مدیریت حقوق مراکز هزینه این دوره',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),

            _StatusChip(status: period.status),

            const SizedBox(width: 10),

            OutlinedButton.icon(
              onPressed: () {
                _showStatusDialog(context, ref);
              },
              icon: const Icon(Icons.sync_alt_rounded),
              label: const Text('تغییر وضعیت'),
            ),

            const SizedBox(width: 10),

            FilledButton.icon(
              onPressed:
                  isLocked
                      ? null
                      : () async {
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) {
                            return PayrollCostCenterRecordFormDialog(
                              companyId: companyId,
                              payrollPeriodId: period.id,
                            );
                          },
                        );

                        if (!context.mounted) {
                          return;
                        }

                        if (result == true) {
                          ref.invalidate(
                            payrollCostCenterRecordsProvider(period.id),
                          );
                        }
                      },
              icon: Icon(isLocked ? Icons.lock_rounded : Icons.add_rounded),
              label: Text(isLocked ? 'دوره قفل است' : 'ثبت حقوق'),
            ),
          ],
        ),

        // ======================================================
        // LOCKED
        // ======================================================
        if (isLocked) ...[
          const SizedBox(height: 12),
          _LockedBanner(status: period.status),
        ],

        const SizedBox(height: 18),

        // ======================================================
        // SUMMARY
        // ======================================================
        SizedBox(
          height: 90,
          child: Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'تعداد مرکز هزینه',
                  value: _toPersianDigits(records.length.toString()),
                  icon: Icons.account_tree_rounded,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _SummaryCard(
                  title: 'تعداد پرسنل',
                  value: _toPersianDigits(totalEmployees.toString()),
                  icon: Icons.people_alt_rounded,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _SummaryCard(
                  title: 'حقوق پایه',
                  value: _formatMoney(totalBaseSalary),
                  icon: Icons.account_balance_wallet_rounded,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _SummaryCard(
                  title: 'مزایا',
                  value: _formatMoney(totalAllowances),
                  icon: Icons.card_giftcard_rounded,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _SummaryCard(
                  title: 'هزینه پرسنلی',
                  value: _formatMoney(totalPersonnelCosts),
                  icon: Icons.payments_rounded,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _SummaryCard(
                  title: 'هزینه کل',
                  value: _formatMoney(totalPayrollCost),
                  icon: Icons.calculate_rounded,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ======================================================
        // SECOND SUMMARY
        // ======================================================
        Row(
          children: [
            Expanded(
              child: _MiniSummaryCard(
                title: 'بیمه سهم کارفرما',
                value: _formatMoney(totalEmployerInsurance),
                icon: Icons.health_and_safety_rounded,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _MiniSummaryCard(
                title: 'بیمه بیکاری',
                value: _formatMoney(totalUnemploymentInsurance),
                icon: Icons.security_rounded,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ======================================================
        // TABLE
        // ======================================================
        Expanded(
          child:
              records.isEmpty
                  ? const _EmptyRecords()
                  : _CostCenterRecordsTable(
                    records: records,
                    isLocked: isLocked,
                    onEdit: (record) async {
                      if (isLocked) {
                        return;
                      }

                      final result = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) {
                          return PayrollCostCenterRecordFormDialog(
                            companyId: companyId,
                            payrollPeriodId: period.id,
                            record: record,
                          );
                        },
                      );

                      if (!context.mounted) {
                        return;
                      }

                      if (result == true) {
                        ref.invalidate(
                          payrollCostCenterRecordsProvider(period.id),
                        );
                      }
                    },
                    onDelete: (record) async {
                      if (isLocked) {
                        return;
                      }

                      await _deleteRecord(context, ref, record);
                    },
                  ),
        ),
      ],
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _deleteRecord(
    BuildContext context,
    WidgetRef ref,
    PayrollCostCenterRecordModel record,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'حذف حقوق مرکز هزینه',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(
            'آیا از حذف رکورد مرکز '
            '«${record.costCenterName ?? 'نامشخص'}» '
            'مطمئن هستید؟',
          ),
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
      final repository = ref.read(payrollCostCenterRecordRepositoryProvider);

      await repository.delete(record.id);

      ref.invalidate(payrollCostCenterRecordsProvider(period.id));

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رکورد حقوق مرکز هزینه حذف شد.')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(_friendlyError(error)),
        ),
      );
    }
  }

  // ============================================================
  // STATUS
  // ============================================================

  Future<void> _showStatusDialog(BuildContext context, WidgetRef ref) async {
    final currentStatus = period.status;

    final availableStatuses = _availableNextStatuses(currentStatus);

    if (availableStatuses.isEmpty) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'برای وضعیت «${_statusTitle(currentStatus)}» '
            'تغییر وضعیت دیگری تعریف نشده است.',
          ),
        ),
      );

      return;
    }

    String selectedStatus = availableStatuses.first;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 520,
                    minWidth: 360,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _statusColor(
                                  currentStatus,
                                ).withOpacity(.10),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(
                                _statusIcon(currentStatus),
                                color: _statusColor(currentStatus),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'تغییر وضعیت دوره حقوق',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _periodTitle(period),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'بستن',
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 19,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  'وضعیت فعلی: '
                                  '${_statusTitle(currentStatus)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          value: selectedStatus,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'وضعیت بعدی',
                            prefixIcon: Icon(_statusIcon(selectedStatus)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items:
                              availableStatuses.map((status) {
                                return DropdownMenuItem<String>(
                                  value: status,
                                  child: Text(
                                    _statusTitle(status),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }

                            setState(() {
                              selectedStatus = value;
                            });
                          },
                        ),

                        const SizedBox(height: 14),

                        _StatusHint(
                          icon: _statusIcon(selectedStatus),
                          text: _statusDescription(selectedStatus),
                        ),

                        const SizedBox(height: 22),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(dialogContext).pop();
                                },
                                child: const Text('انصراف'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () {
                                  Navigator.of(
                                    dialogContext,
                                  ).pop(selectedStatus);
                                },
                                icon: const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                ),
                                label: const Text('ادامه'),
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
          },
        );
      },
    );

    if (result == null || result == currentStatus) {
      return;
    }

    if (_needsConfirmation(result)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'تأیید تغییر وضعیت',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            content: Text(_statusConfirmMessage(result)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
                child: const Text('انصراف'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                },
                child: const Text('تأیید'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        return;
      }
    }

    try {
      final repository = ref.read(payrollPeriodRepositoryProvider);

      await repository.updateStatus(id: period.id, status: result);

      ref.invalidate(payrollPeriodsProvider(companyId));

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'وضعیت دوره به '
            '«${_statusTitle(result)}» '
            'تغییر کرد.',
          ),
        ),
      );

      Navigator.of(context).pop();
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(_friendlyError(error)),
        ),
      );
    }
  }
}

// ============================================================
// TABLE
// ============================================================

class _CostCenterRecordsTable extends StatelessWidget {
  const _CostCenterRecordsTable({
    required this.records,
    required this.isLocked,
    required this.onEdit,
    required this.onDelete,
  });

  final List<PayrollCostCenterRecordModel> records;

  final bool isLocked;

  final Future<void> Function(PayrollCostCenterRecordModel record) onEdit;

  final Future<void> Function(PayrollCostCenterRecordModel record) onDelete;

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
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                horizontalMargin: 18,
                columnSpacing: 28,
                headingRowHeight: 52,
                dataRowMinHeight: 72,
                dataRowMaxHeight: 90,
                columns: const [
                  DataColumn(label: Text('مرکز هزینه')),
                  DataColumn(label: Text('تعداد پرسنل')),
                  DataColumn(label: Text('حقوق پایه')),
                  DataColumn(label: Text('مزایا')),
                  DataColumn(label: Text('هزینه پرسنلی')),
                  DataColumn(label: Text('بیمه کارفرما')),
                  DataColumn(label: Text('بیمه بیکاری')),
                  DataColumn(label: Text('جمع کل')),
                  DataColumn(label: Text('عملیات')),
                ],
                rows:
                    records.map((record) {
                      return DataRow(
                        cells: [
                          // ------------------------------------------------
                          // COST CENTER
                          // ------------------------------------------------
                          DataCell(
                            SizedBox(
                              width: 220,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    record.costCenterName ??
                                        'مرکز هزینه نامشخص',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    record.costCenterCode == null ||
                                            record.costCenterCode!.isEmpty
                                        ? 'بدون کد'
                                        : 'کد: ${record.costCenterCode}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ------------------------------------------------
                          // EMPLOYEE COUNT
                          // ------------------------------------------------
                          DataCell(
                            Text(
                              _toPersianDigits(record.employeeCount.toString()),
                            ),
                          ),

                          // ------------------------------------------------
                          // BASE
                          // ------------------------------------------------
                          DataCell(Text(_formatMoney(record.baseSalary))),

                          // ------------------------------------------------
                          // ALLOWANCES
                          // ------------------------------------------------
                          DataCell(Text(_formatMoney(record.totalAllowances))),

                          // ------------------------------------------------
                          // PERSONNEL
                          // ------------------------------------------------
                          DataCell(
                            Text(_formatMoney(record.totalPersonnelCosts)),
                          ),

                          // ------------------------------------------------
                          // EMPLOYER INSURANCE
                          // ------------------------------------------------
                          DataCell(
                            Text(_formatMoney(record.employerInsurance)),
                          ),

                          // ------------------------------------------------
                          // UNEMPLOYMENT
                          // ------------------------------------------------
                          DataCell(
                            Text(_formatMoney(record.unemploymentInsurance)),
                          ),

                          // ------------------------------------------------
                          // TOTAL
                          // ------------------------------------------------
                          DataCell(
                            Text(
                              _formatMoney(record.totalPayrollCost),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),

                          // ------------------------------------------------
                          // ACTIONS
                          // ------------------------------------------------
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: isLocked ? 'دوره قفل است' : 'ویرایش',
                                  onPressed:
                                      isLocked
                                          ? null
                                          : () {
                                            onEdit(record);
                                          },
                                  icon: const Icon(
                                    Icons.edit_rounded,
                                    size: 18,
                                  ),
                                ),
                                IconButton(
                                  tooltip: isLocked ? 'دوره قفل است' : 'حذف',
                                  onPressed:
                                      isLocked
                                          ? null
                                          : () {
                                            onDelete(record);
                                          },
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color:
                                        isLocked
                                            ? Colors.grey
                                            : Colors.red.shade700,
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
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), size: 17, color: color),
          const SizedBox(width: 6),
          Text(
            _statusTitle(status),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// LOCKED BANNER
// ============================================================

class _LockedBanner extends StatelessWidget {
  const _LockedBanner({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_rounded, color: Colors.orange.shade800),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'این دوره در وضعیت '
              '«${_statusTitle(status)}» قرار دارد و '
              'اطلاعات حقوق قابل ویرایش نیست.',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STATUS HINT
// ============================================================

class _StatusHint extends StatelessWidget {
  const _StatusHint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

// ============================================================
// SUMMARY CARD
// ============================================================

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1B4332).withOpacity(.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: const Color(0xFF1B4332)),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
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

// ============================================================
// MINI SUMMARY
// ============================================================

class _MiniSummaryCard extends StatelessWidget {
  const _MiniSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1B4332)),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

// ============================================================
// EMPTY
// ============================================================

class _EmptyRecords extends StatelessWidget {
  const _EmptyRecords();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 14),
          const Text(
            'هنوز حقوقی برای مراکز هزینه ثبت نشده است.',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'برای شروع، روی «ثبت حقوق» کلیک کنید.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ERROR
// ============================================================

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 54,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 12),
          SizedBox(width: 600, child: Text(error, textAlign: TextAlign.center)),
          const SizedBox(height: 14),
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
// HELPERS
// ============================================================

String _periodTitle(PayrollPeriodModel period) {
  return '${period.periodYear}/${period.periodMonth}';
}

String _formatMoney(num value) {
  final rounded = value.round().toString();

  final isNegative = rounded.startsWith('-');

  final digits = isNegative ? rounded.substring(1) : rounded;

  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    final position = digits.length - i;

    buffer.write(digits[i]);

    if (position > 1 && position % 3 == 1) {
      buffer.write(',');
    }
  }

  final result = '${isNegative ? '-' : ''}${buffer.toString()}';

  return '${_toPersianDigits(result)} تومان';
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

String _friendlyError(Object error) {
  final text = error.toString();

  if (text.contains('payroll_cost_center_records_unique') ||
      text.contains('duplicate key') ||
      text.contains('23505')) {
    return 'برای این مرکز هزینه در این دوره حقوق قبلاً ثبت شده است.';
  }

  if (text.contains('payroll_periods_status_check')) {
    return 'وضعیت انتخاب‌شده برای دوره حقوق معتبر نیست.';
  }

  if (text.contains('violates check constraint')) {
    return 'اطلاعات واردشده با قوانین ثبت اطلاعات سازگار نیست.';
  }

  return text.replaceFirst('Exception: ', '');
}

// ============================================================
// STATUS
// ============================================================

List<String> _availableNextStatuses(String status) {
  switch (status) {
    case 'draft':
      return ['pending_ceo', 'rejected', 'cancelled'];

    case 'pending_ceo':
      return ['ceo_approved', 'rejected'];

    case 'ceo_approved':
      return ['pending_consultant'];

    case 'pending_consultant':
      return ['consultant_approved', 'rejected'];

    case 'consultant_approved':
      return ['paid'];

    case 'rejected':
      return ['draft', 'cancelled'];

    case 'paid':
    case 'cancelled':
      return [];

    default:
      return [];
  }
}

String _statusTitle(String status) {
  switch (status) {
    case 'draft':
      return 'پیش‌نویس';

    case 'pending_ceo':
      return 'در انتظار تأیید مدیرعامل';

    case 'ceo_approved':
      return 'تأیید مدیرعامل';

    case 'pending_consultant':
      return 'در انتظار تأیید مشاور';

    case 'consultant_approved':
      return 'تأیید مشاور';

    case 'rejected':
      return 'رد شده';

    case 'paid':
      return 'پرداخت شده';

    case 'cancelled':
      return 'لغو شده';

    default:
      return status;
  }
}

IconData _statusIcon(String status) {
  switch (status) {
    case 'draft':
      return Icons.edit_note_rounded;

    case 'pending_ceo':
      return Icons.pending_actions_rounded;

    case 'ceo_approved':
      return Icons.verified_rounded;

    case 'pending_consultant':
      return Icons.hourglass_top_rounded;

    case 'consultant_approved':
      return Icons.check_circle_rounded;

    case 'rejected':
      return Icons.cancel_rounded;

    case 'paid':
      return Icons.payments_rounded;

    case 'cancelled':
      return Icons.block_rounded;

    default:
      return Icons.info_outline_rounded;
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'draft':
      return Colors.grey;

    case 'pending_ceo':
      return Colors.orange;

    case 'ceo_approved':
      return Colors.green;

    case 'pending_consultant':
      return Colors.blue;

    case 'consultant_approved':
      return Colors.teal;

    case 'rejected':
      return Colors.red;

    case 'paid':
      return Colors.green.shade800;

    case 'cancelled':
      return Colors.red.shade800;

    default:
      return Colors.grey;
  }
}

String _statusDescription(String status) {
  switch (status) {
    case 'pending_ceo':
      return 'دوره برای تأیید مدیرعامل ارسال می‌شود.';

    case 'ceo_approved':
      return 'مدیرعامل دوره را تأیید کرده است.';

    case 'pending_consultant':
      return 'دوره در انتظار بررسی مشاور است.';

    case 'consultant_approved':
      return 'مشاور دوره را تأیید کرده است.';

    case 'rejected':
      return 'دوره رد شده و می‌تواند دوباره به پیش‌نویس برگردد.';

    case 'paid':
      return 'پرداخت حقوق انجام شده است.';

    case 'cancelled':
      return 'دوره لغو شده است.';

    default:
      return 'وضعیت دوره تغییر خواهد کرد.';
  }
}

bool _needsConfirmation(String status) {
  return status == 'ceo_approved' ||
      status == 'consultant_approved' ||
      status == 'paid' ||
      status == 'cancelled';
}

String _statusConfirmMessage(String status) {
  switch (status) {
    case 'ceo_approved':
      return 'با تأیید مدیرعامل، اطلاعات حقوق این دوره قفل خواهد شد. ادامه می‌دهید؟';

    case 'consultant_approved':
      return 'با تأیید مشاور، اطلاعات حقوق این دوره قفل خواهد شد. ادامه می‌دهید؟';

    case 'paid':
      return 'با ثبت پرداخت، دوره حقوق به حالت پرداخت‌شده می‌رود. ادامه می‌دهید؟';

    case 'cancelled':
      return 'آیا از لغو این دوره حقوق مطمئن هستید؟';

    default:
      return 'آیا از تغییر وضعیت مطمئن هستید؟';
  }
}
